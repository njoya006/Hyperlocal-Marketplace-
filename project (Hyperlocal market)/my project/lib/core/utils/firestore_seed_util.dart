import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Development-only utility to seed test shop data in Firestore
class FirestoreSeedUtil {
  static final _firestore = FirebaseFirestore.instance;
  static bool _hasAttemptedSeed = false;

  /// Seeds test shop data with proper numeric latitude/longitude fields
  /// Only available in debug mode
  static Future<void> seedTestShop() async {
    if (_hasAttemptedSeed) {
      return;
    }
    _hasAttemptedSeed = true;

    debugPrint('[FirestoreSeed] >>> seedTestShop() CALLED <<<');

    if (!kDebugMode) {
      debugPrint('[FirestoreSeed] NOT in debug mode, exiting');
      return;
    }

    const testShopId = 'test-shop-soa-001';
    
    try {
      debugPrint('[FirestoreSeed] >>> Deleting old document <<<');
      // Delete old document first to ensure clean state
      await _firestore.collection('shops').doc(testShopId).delete();
      debugPrint('[FirestoreSeed] >>> Old document deleted <<<');

      debugPrint('[FirestoreSeed] >>> Creating new document with all fields <<<');
      // Create fresh document with all required fields
      await _firestore.collection('shops').doc(testShopId).set({
        'ownerId': 'test-owner-001',
        'name': 'Test Grocery Shop',
        'description': 'Fresh groceries and daily essentials',
        'category': 'grocery',
        'latitude': 3.9552,
        'longitude': 11.5883,
        'Location': const GeoPoint(3.9552, 11.5883),
        'address': 'Soa, Cameroon',
        'phone': '650000000',
        'isOpen': true,
        'isApproved': true,
        'rating': 4.5,
        'totalReviews': 10,
        'imageUrl': 'https://picsum.photos/400/300',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('[FirestoreSeed] ✅ ✅ ✅ SUCCESS! Document created with:');
      debugPrint('[FirestoreSeed]   - ID: $testShopId');
      debugPrint('[FirestoreSeed]   - latitude: 3.9552 (DOUBLE)');
      debugPrint('[FirestoreSeed]   - longitude: 11.5883 (DOUBLE)');
      debugPrint('[FirestoreSeed]   - Location: GeoPoint(3.9552, 11.5883)');
      debugPrint('[FirestoreSeed]   - isApproved: true');
    } catch (e) {
      final errorText = e.toString().toLowerCase();
      if (errorText.contains('permission-denied')) {
        debugPrint('[FirestoreSeed] Permission denied. Skipping seed in this environment.');
        return;
      }
      debugPrint('[FirestoreSeed] ❌ ❌ ❌ EXCEPTION: $e');
      debugPrint('[FirestoreSeed] Stack: ${StackTrace.current}');
    }
  }
}
