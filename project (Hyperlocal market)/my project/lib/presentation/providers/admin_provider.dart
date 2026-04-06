import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_provider.dart';

/// Admin dashboard statistics and activity data.
class AdminDashboardData extends Equatable {
  /// Creates [AdminDashboardData].
  const AdminDashboardData({
    required this.totalUsers,
    required this.totalShops,
    required this.ordersToday,
    required this.recentActivities,
  });

  /// Total number of users in Firestore.
  final int totalUsers;

  /// Total number of shops in Firestore.
  final int totalShops;

  /// Total number of orders created today.
  final int ordersToday;

  /// Recent activity feed items.
  final List<AdminActivity> recentActivities;

  @override
  List<Object?> get props =>
      [totalUsers, totalShops, ordersToday, recentActivities];
}

/// Summary of a shop for admin management screens.
class AdminShopSummary extends Equatable {
  /// Creates [AdminShopSummary].
  const AdminShopSummary({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.ownerName,
    required this.category,
    required this.isOpen,
    required this.isApproved,
    required this.address,
    required this.createdAt,
    required this.rating,
    required this.totalReviews,
    this.moderationState,
  });

  final String id;
  final String name;
  final String ownerId;
  final String ownerName;
  final String category;
  final bool isOpen;
  final bool isApproved;
  final String address;
  final DateTime createdAt;
  final double rating;
  final int totalReviews;
  final String? moderationState;

  bool get isPending => !isApproved && moderationState != 'rejected';
  bool get isRejected => moderationState == 'rejected';

  @override
  List<Object?> get props => [
        id,
        name,
        ownerId,
        ownerName,
        category,
        isOpen,
        isApproved,
        address,
        createdAt,
        rating,
        totalReviews,
        moderationState,
      ];
}

/// Summary of a user for admin management screens.
class AdminUserSummary extends Equatable {
  /// Creates [AdminUserSummary].
  const AdminUserSummary({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
    required this.createdAt,
    this.phone,
  });

  final String uid;
  final String email;
  final String name;
  final String role;
  final bool isActive;
  final DateTime createdAt;
  final String? phone;

  @override
  List<Object?> get props =>
      [uid, email, name, role, isActive, createdAt, phone];
}

/// Single report row for daily aggregation.
class AdminReportRow extends Equatable {
  /// Creates [AdminReportRow].
  const AdminReportRow({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  @override
  List<Object?> get props => [label, count];
}

/// Top shop summary used in reports.
class AdminTopShopReport extends Equatable {
  /// Creates [AdminTopShopReport].
  const AdminTopShopReport({
    required this.shopId,
    required this.shopName,
    required this.orderCount,
    required this.revenue,
  });

  final String shopId;
  final String shopName;
  final int orderCount;
  final double revenue;

  @override
  List<Object?> get props => [shopId, shopName, orderCount, revenue];
}

/// Aggregate data for admin reports.
class AdminReportsData extends Equatable {
  /// Creates [AdminReportsData].
  const AdminReportsData({
    required this.totalOrders,
    required this.totalRevenue,
    required this.pendingShops,
    required this.activeUsers,
    required this.dailyOrders,
    required this.topShops,
  });

  final int totalOrders;
  final double totalRevenue;
  final int pendingShops;
  final int activeUsers;
  final List<AdminReportRow> dailyOrders;
  final List<AdminTopShopReport> topShops;

  @override
  List<Object?> get props => [
        totalOrders,
        totalRevenue,
        pendingShops,
        activeUsers,
        dailyOrders,
        topShops,
      ];
}

/// Single dashboard activity item.
class AdminActivity extends Equatable {
  /// Creates [AdminActivity].
  const AdminActivity({
    required this.title,
    required this.subtitle,
    required this.timestamp,
    required this.icon,
  });

  /// Activity title.
  final String title;

  /// Activity subtitle.
  final String subtitle;

  /// Activity timestamp.
  final DateTime timestamp;

  /// Activity icon.
  final IconData icon;

  @override
  List<Object?> get props => [title, subtitle, timestamp, icon];
}

/// Provides admin dashboard data.
final adminDashboardProvider = FutureProvider<AdminDashboardData>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final usersSnapshot = await firestore.collection('users').get();
  final shopsSnapshot = await firestore.collection('shops').get();
  final ordersSnapshot = await firestore.collection('orders').get();

  final now = DateTime.now();
  final startOfDay = DateTime(now.year, now.month, now.day);

  int ordersToday = 0;
  final activities = <AdminActivity>[];

  for (final doc in ordersSnapshot.docs) {
    final data = doc.data();
    final createdAt = _readTimestamp(data['createdAt']) ?? now;
    if (createdAt.isAfter(startOfDay.subtract(const Duration(seconds: 1)))) {
      ordersToday += 1;
    }
    activities.add(
      AdminActivity(
        title: 'New order ${doc.id}',
        subtitle: 'Order total: ${data['total'] ?? 0}',
        timestamp: createdAt,
        icon: Icons.receipt_long_outlined,
      ),
    );
  }

  for (final doc in shopsSnapshot.docs) {
    final data = doc.data();
    final createdAt = _readTimestamp(data['createdAt']) ?? now;
    activities.add(
      AdminActivity(
        title: 'Shop created: ${data['name'] ?? doc.id}',
        subtitle: (data['isApproved'] as bool? ?? false)
            ? 'Approved shop'
            : 'Awaiting approval',
        timestamp: createdAt,
        icon: Icons.storefront_outlined,
      ),
    );
  }

  for (final doc in usersSnapshot.docs) {
    final data = doc.data();
    final createdAt = _readTimestamp(data['createdAt']) ?? now;
    activities.add(
      AdminActivity(
        title: 'New user: ${data['name'] ?? doc.id}',
        subtitle: 'Role: ${data['role'] ?? 'customer'}',
        timestamp: createdAt,
        icon: Icons.person_outline,
      ),
    );
  }

  activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

  return AdminDashboardData(
    totalUsers: usersSnapshot.docs.length,
    totalShops: shopsSnapshot.docs.length,
    ordersToday: ordersToday,
    recentActivities: activities.take(8).toList(),
  );
});

/// Loads shops for admin moderation screens.
final adminShopsProvider = FutureProvider<List<AdminShopSummary>>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final usersSnapshot = await firestore.collection('users').get();
  final ownerNames = <String, String>{};
  for (final doc in usersSnapshot.docs) {
    ownerNames[doc.id] = (doc.data()['name'] as String?) ?? doc.id;
  }

  final shopsSnapshot = await firestore
      .collection('shops')
      .orderBy('createdAt', descending: true)
      .get();
  return shopsSnapshot.docs.map((doc) {
    final data = doc.data();
    final ownerId = (data['ownerId'] as String?) ?? '';
    return AdminShopSummary(
      id: doc.id,
      name: (data['name'] as String?) ?? doc.id,
      ownerId: ownerId,
      ownerName:
          ownerNames[ownerId] ?? (ownerId.isEmpty ? 'Unknown owner' : ownerId),
      category: (data['category'] as String?) ?? 'other',
      isOpen: data['isOpen'] as bool? ?? false,
      isApproved: data['isApproved'] as bool? ?? false,
      address: (data['address'] as String?) ?? '',
      createdAt: _readTimestamp(data['createdAt']) ?? DateTime.now(),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: data['totalReviews'] as int? ?? 0,
      moderationState: data['moderationState'] as String?,
    );
  }).toList();
});

/// Loads users for admin management screens.
final adminUsersProvider = FutureProvider<List<AdminUserSummary>>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final usersSnapshot = await firestore
      .collection('users')
      .orderBy('createdAt', descending: true)
      .get();
  return usersSnapshot.docs.map((doc) {
    final data = doc.data();
    return AdminUserSummary(
      uid: doc.id,
      email: (data['email'] as String?) ?? '',
      name: (data['name'] as String?) ?? doc.id,
      role: (data['role'] as String?) ?? 'customer',
      isActive: data['isActive'] as bool? ?? true,
      createdAt: _readTimestamp(data['createdAt']) ?? DateTime.now(),
      phone: data['phone'] as String?,
    );
  }).toList();
});

/// Loads admin reporting data.
final adminReportsProvider = FutureProvider<AdminReportsData>((ref) async {
  final firestore = ref.watch(firestoreProvider);

  final ordersSnapshot = await firestore.collection('orders').get();
  final shopsSnapshot = await firestore.collection('shops').get();
  final usersSnapshot = await firestore.collection('users').get();

  final now = DateTime.now();
  final startOfWindow =
      DateTime(now.year, now.month, now.day).subtract(const Duration(days: 6));
  final dailyCounts = <String, int>{};
  for (var offset = 0; offset < 7; offset += 1) {
    final day = startOfWindow.add(Duration(days: offset));
    dailyCounts[_dayLabel(day)] = 0;
  }

  final shopNames = <String, String>{};
  final topShopTotals = <String, _MutableShopReport>{};
  var totalRevenue = 0.0;
  var pendingShops = 0;
  var activeUsers = 0;

  for (final doc in shopsSnapshot.docs) {
    final data = doc.data();
    final shopName = (data['name'] as String?) ?? doc.id;
    shopNames[doc.id] = shopName;
    if (!(data['isApproved'] as bool? ?? false) &&
        data['moderationState'] != 'rejected') {
      pendingShops += 1;
    }
  }

  for (final doc in usersSnapshot.docs) {
    final data = doc.data();
    if (data['isActive'] as bool? ?? true) {
      activeUsers += 1;
    }
  }

  for (final doc in ordersSnapshot.docs) {
    final data = doc.data();
    final createdAt = _readTimestamp(data['createdAt']) ?? now;
    final dayKey =
        _dayLabel(DateTime(createdAt.year, createdAt.month, createdAt.day));
    if (dailyCounts.containsKey(dayKey)) {
      dailyCounts[dayKey] = dailyCounts[dayKey]! + 1;
    }

    final total = (data['total'] as num?)?.toDouble() ?? 0.0;
    totalRevenue += total;

    final shopId = (data['shopId'] as String?) ?? 'unknown';
    final shopName = shopNames[shopId] ?? shopId;
    topShopTotals.putIfAbsent(
      shopId,
      () => _MutableShopReport(shopId: shopId, shopName: shopName),
    );
    topShopTotals[shopId]!.orderCount += 1;
    topShopTotals[shopId]!.revenue += total;
  }

  final dailyOrders = dailyCounts.entries
      .map((entry) => AdminReportRow(label: entry.key, count: entry.value))
      .toList();

  final topShops = topShopTotals.values
      .map((entry) => AdminTopShopReport(
            shopId: entry.shopId,
            shopName: entry.shopName,
            orderCount: entry.orderCount,
            revenue: entry.revenue,
          ))
      .toList()
    ..sort((a, b) => b.orderCount.compareTo(a.orderCount));

  return AdminReportsData(
    totalOrders: ordersSnapshot.docs.length,
    totalRevenue: totalRevenue,
    pendingShops: pendingShops,
    activeUsers: activeUsers,
    dailyOrders: dailyOrders,
    topShops: topShops.take(5).toList(),
  );
});

/// Updates a shop moderation status.
Future<void> updateShopModeration(
  WidgetRef ref, {
  required String shopId,
  required bool isApproved,
  required bool isOpen,
  String? moderationState,
}) async {
  final firestore = ref.read(firestoreProvider);
  final updates = <String, dynamic>{
    'isApproved': isApproved,
    'isOpen': isOpen,
    'updatedAt': FieldValue.serverTimestamp(),
  };
  if (moderationState != null) {
    updates['moderationState'] = moderationState;
  }
  await firestore.collection('shops').doc(shopId).update(updates);
}

/// Updates a user active state.
Future<void> updateUserActiveState(
  WidgetRef ref, {
  required String userId,
  required bool isActive,
}) async {
  final firestore = ref.read(firestoreProvider);
  await firestore.collection('users').doc(userId).update({
    'isActive': isActive,
    'updatedAt': FieldValue.serverTimestamp(),
  });
}

DateTime? _readTimestamp(Object? value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  return null;
}

String _dayLabel(DateTime dateTime) {
  const monthNames = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${monthNames[dateTime.month - 1]} ${dateTime.day}';
}

class _MutableShopReport {
  _MutableShopReport({required this.shopId, required this.shopName});

  final String shopId;
  final String shopName;
  int orderCount = 0;
  double revenue = 0.0;
}
