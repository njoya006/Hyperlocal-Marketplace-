import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/exceptions.dart';
import '../models/shop_model.dart';

/// Abstract interface for shop data access operations.
abstract class IShopDatasource {
  /// Get shops near the specified location within a radius.
  ///
  /// Uses bounding box query technique for efficient Firestore queries.
  /// Only returns approved shops that are visible to customers.
  ///
  /// [lat] and [lng] are the center coordinates (typically user's current location)
  /// [radiusKm] is the search radius in kilometers
  /// Returns a list of [ShopModel] objects sorted by distance.
  /// Throws [ServerException] on Firestore errors.
  Future<List<ShopModel>> getNearbyShops({
    required double lat,
    required double lng,
    required double radiusKm,
  });

  /// Watch a single shop for real-time updates.
  ///
  /// Returns a stream that emits shop updates whenever the document changes.
  /// Useful for displaying shop details or live status updates.
  ///
  /// [shopId] is the Firestore document ID of the shop
  /// Throws [ServerException] on Firestore errors.
  Stream<ShopModel> watchShop(String shopId);

  /// Create a new shop document in Firestore.
  ///
  /// Called when a shop owner creates their first shop.
  /// The shop starts with [isApproved: false] and must be approved by admin.
  ///
  /// [shop] is the shop data to create
  /// Throws [ServerException] on Firestore errors or permission denied.
  Future<void> createShop(ShopModel shop);

  /// Update an existing shop document.
  ///
  /// Only the shop owner or admin can update shop information.
  /// Partial updates - only provided fields are changed.
  ///
  /// [shopId] is the Firestore document ID of the shop to update
  /// [data] is a map of field names and new values
  /// Throws [ServerException] on permission denied or other Firestore errors.
  Future<void> updateShop(String shopId, Map<String, dynamic> data);

  /// Get all shops owned by a specific user.
  ///
  /// Used when a shop owner views their own shops.
  /// Returns all shops regardless of approval status.
  ///
  /// [ownerId] is the user ID of the shop owner
  /// Returns a list of [ShopModel] objects.
  /// Throws [ServerException] on Firestore errors.
  Future<List<ShopModel>> getShopsByOwner(String ownerId);
}

/// Concrete implementation of [IShopDatasource] using Firebase Firestore.
///
/// Handles all shop-related database operations including queries,
/// real-time streams, and mutations.
class FirestoreShopDatasource implements IShopDatasource {
  /// Creates a new [FirestoreShopDatasource].
  const FirestoreShopDatasource({
    required FirebaseFirestore firestore,
  }) : _firestore = firestore;

  final FirebaseFirestore _firestore;

  /// Collection reference for shops.
  CollectionReference<Map<String, dynamic>> get _shopsCollection =>
      _firestore.collection('shops');

  @override
  Future<List<ShopModel>> getNearbyShops({
    required double lat,
    required double lng,
    required double radiusKm,
  }) async {
    try {
      // Bounding box calculation
      // Approximate: 1 degree ≈ 111 km at equator
      final latDelta = radiusKm / 111.0;
      final lngDelta = radiusKm / (111.0 * _cosDegrees(lat));

      final minLat = lat - latDelta;
      final maxLat = lat + latDelta;
      final minLng = lng - lngDelta;
      final maxLng = lng + lngDelta;

      debugPrint('[FIRESTORE] Querying nearby shops:');
      debugPrint('[FIRESTORE] User location: ($lat, $lng), Radius: ${radiusKm}km');
      debugPrint('[FIRESTORE] Bounding box: lat($minLat, $maxLat), lng($minLng, $maxLng)');

      // Attempt 1: Try numeric latitude/longitude fields  (for new data)
      QuerySnapshot<Map<String, dynamic>>? querySnapshot;
      bool usedNumericFields = false;
      
      try {
        debugPrint('[FIRESTORE] Attempting query with numeric latitude/longitude fields...');
        querySnapshot = await _shopsCollection
            .where('latitude', isGreaterThanOrEqualTo: minLat)
            .where('latitude', isLessThanOrEqualTo: maxLat)
            .where('longitude', isGreaterThanOrEqualTo: minLng)
            .where('longitude', isLessThanOrEqualTo: maxLng)
            .get();
        usedNumericFields = true;
        debugPrint('[FIRESTORE] ✅ Numeric field query succeeded, found ${querySnapshot.docs.length} docs');
      } catch (e) {
        debugPrint('[FIRESTORE] ⚠️  Numeric field query failed: $e');
        debugPrint('[FIRESTORE] Falling back to GeoPoint-based filtering...');
      }

      // Fallback: If numeric query failed or returned 0 results, get all shops and filter by GeoPoint
      if (querySnapshot == null || querySnapshot.docs.isEmpty) {
        debugPrint('[FIRESTORE] ⚠️  Numeric query returned 0 results, fetching ALL shops for fallback filtering...');
        querySnapshot = await _shopsCollection.get();
      }

      debugPrint('[FIRESTORE] Found ${querySnapshot.docs.length} documents');

      // Convert to ShopModel, filter by location using GeoPoint if needed, and sort by distance
      final List<ShopModel> shops = [];
      for (final doc in querySnapshot.docs) {
        try {
          final shop = ShopModel.fromFirestore(doc);
          
          // If we used numeric fields, they're already filtered by Firestore
          // If we used fallback, filter here using Haversine distance
          if (!usedNumericFields) {
            final distance = _calculateDistance(
              shop.latitude,
              shop.longitude,
              lat,
              lng,
            );
            if (distance > radiusKm) {
              continue; // Skip shops outside radius
            }
          }
          
          // Now filter by approval status
          if (shop.isApproved) {
            debugPrint('[FIRESTORE] ✅ Include: ${shop.name} (approved)');
            shops.add(shop);
          } else {
            debugPrint('[FIRESTORE] ❌ Skip: ${shop.name} (not approved)');
          }
        } catch (e) {
          debugPrint('[FIRESTORE] Error parsing shop ${doc.id}: $e');
        }
      }

      debugPrint('[FIRESTORE] ✅ Filtered to ${shops.length} approved shops');

      // Sort by distance from user location
      shops.sort((a, b) {
        final distanceA = _calculateDistance(
          a.latitude,
          a.longitude,
          lat,
          lng,
        );
        final distanceB = _calculateDistance(
          b.latitude,
          b.longitude,
          lat,
          lng,
        );
        return distanceA.compareTo(distanceB);
      });

      return shops;
    } on FirebaseException catch (e) {
      debugPrint('[FIRESTORE] Firebase error: ${e.code} - ${e.message}');
      throw ServerException(
        code: e.code,
        message: e.message ?? 'Unknown Firestore error',
      );
    } catch (e) {
      debugPrint('[FIRESTORE] Unknown error: $e');
      throw ServerException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  @override
  Stream<ShopModel> watchShop(String shopId) {
    try {
      return _shopsCollection
          .doc(shopId)
          .snapshots()
          .map((snapshot) {
        if (!snapshot.exists) {
          throw const ServerException(
            code: 'not-found',
            message: 'Shop not found',
          );
        }
        return ShopModel.fromFirestore(snapshot);
      });
    } on ServerException {
      rethrow;
    } catch (e) {
      return Stream.error(
        ServerException(
          code: 'unknown',
          message: e.toString(),
        ),
      );
    }
  }

  @override
  Future<void> createShop(ShopModel shop) async {
    try {
      await _shopsCollection.doc(shop.id).set(shop.toFirestore());
    } on FirebaseException catch (e) {
      throw ServerException(
        code: e.code,
        message: e.message ?? 'Failed to create shop',
      );
    } catch (e) {
      throw ServerException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  @override
  Future<void> updateShop(String shopId, Map<String, dynamic> data) async {
    try {
      // Add updatedAt timestamp
      final updateData = {
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      await _shopsCollection.doc(shopId).update(updateData);
    } on FirebaseException catch (e) {
      throw ServerException(
        code: e.code,
        message: e.message ?? 'Failed to update shop',
      );
    } catch (e) {
      throw ServerException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  @override
  Future<List<ShopModel>> getShopsByOwner(String ownerId) async {
    try {
      final querySnapshot =
          await _shopsCollection.where('ownerId', isEqualTo: ownerId).get();

      return querySnapshot.docs
          .map((doc) => ShopModel.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(
        code: e.code,
        message: e.message ?? 'Failed to fetch shops',
      );
    } catch (e) {
      throw ServerException(
        code: 'unknown',
        message: e.toString(),
      );
    }
  }

  /// Helper method to calculate cosine of an angle in degrees.
  /// Used for longitude delta calculation accounting for Earth's curvature.
  double _cosDegrees(double degrees) {
    final radians = degrees * (pi / 180.0);
    return cos(radians);
  }

  /// Helper method to calculate distance between two points in km using Haversine.
  double _calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    const double earthRadiusKm = 6371;
    final dLat = (lat2 - lat1) * (pi / 180.0);
    final dLng = (lng2 - lng1) * (pi / 180.0);
    final lat1Rad = lat1 * (pi / 180.0);
    final lat2Rad = lat2 * (pi / 180.0);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1Rad) * cos(lat2Rad) * sin(dLng / 2) * sin(dLng / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadiusKm * c;
  }
}
