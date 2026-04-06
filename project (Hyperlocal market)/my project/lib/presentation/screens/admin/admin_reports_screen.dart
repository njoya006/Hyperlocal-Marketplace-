import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/admin_provider.dart';
import 'admin_shell_scaffold.dart';

/// Admin reports screen with summary cards and top performers.
class AdminReportsScreen extends ConsumerWidget {
  /// Creates [AdminReportsScreen].
  const AdminReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportsAsync = ref.watch(adminReportsProvider);

    return AdminShellScaffold(
      title: AppStrings.screenTitleReports,
      currentIndex: 3,
      body: reportsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Text(
              'Failed to load reports: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (reports) {
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminReportsProvider);
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(AppSizes.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _SubtleReveal(
                    delay: 0,
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final crossAxisCount = constraints.maxWidth >= 900
                            ? 4
                            : constraints.maxWidth >= 600
                                ? 2
                                : 1;
                        return GridView.count(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: AppSizes.md,
                          mainAxisSpacing: AppSizes.md,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.5,
                          children: [
                            _MetricCard(
                              title: AppStrings.labelAllOrders,
                              value: reports.totalOrders.toString(),
                              icon: Icons.receipt_long_outlined,
                              color: Colors.teal,
                            ),
                            _MetricCard(
                              title: AppStrings.labelTotalRevenue,
                              value: CurrencyFormatter.formatXAF(reports.totalRevenue),
                              icon: Icons.payments_outlined,
                              color: Colors.deepOrange,
                            ),
                            _MetricCard(
                              title: AppStrings.labelPendingApprovals,
                              value: reports.pendingShops.toString(),
                              icon: Icons.hourglass_top_outlined,
                              color: Colors.orange,
                            ),
                            _MetricCard(
                              title: AppStrings.labelTotalUsers,
                              value: reports.activeUsers.toString(),
                              icon: Icons.people_outline,
                              color: AppColors.primary,
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  _SubtleReveal(
                    delay: 60,
                    child: _ReportSection(
                      title: AppStrings.labelOrdersLast7Days,
                      child: _DailyOrdersList(rows: reports.dailyOrders),
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),
                  _SubtleReveal(
                    delay: 120,
                    child: _ReportSection(
                      title: AppStrings.labelTopShops,
                      child: _TopShopsList(items: reports.topShops),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withValues(alpha: 0.95),
            color.withValues(alpha: 0.72),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Align(
            alignment: Alignment.topRight,
            child: Icon(icon,
                color: Colors.white.withValues(alpha: 0.9), size: 28),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: AppSizes.xxs),
              Text(
                title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.92),
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReportSection extends StatelessWidget {
  const _ReportSection({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: AppSizes.md),
            child,
          ],
        ),
      ),
    );
  }
}

class _DailyOrdersList extends StatelessWidget {
  const _DailyOrdersList({required this.rows});

  final List<AdminReportRow> rows;

  @override
  Widget build(BuildContext context) {
    final maxCount = rows.isEmpty
        ? 1
        : rows.map((row) => row.count).reduce((a, b) => a > b ? a : b);

    return Column(
      children: rows.asMap().entries.map((entry) {
        final index = entry.key;
        final row = entry.value;
        final progress = maxCount == 0 ? 0.0 : row.count / maxCount;
        return _SubtleReveal(
          delay: 30 * index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      row.label,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    Text(row.count.toString()),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(99),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TopShopsList extends StatelessWidget {
  const _TopShopsList({required this.items});

  final List<AdminTopShopReport> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.lg),
        child: Text(
          AppStrings.messageNoData,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
      );
    }

    return Column(
      children: items.asMap().entries.map((entry) {
        final index = entry.key;
        final item = entry.value;
        return _SubtleReveal(
          delay: 35 * index,
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSizes.md),
            child: Container(
              padding: const EdgeInsets.all(AppSizes.md),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                    child: Text(
                      item.shopName.isNotEmpty
                          ? item.shopName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: AppSizes.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.shopName,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${item.orderCount} orders • ${CurrencyFormatter.formatXAF(item.revenue)}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SubtleReveal extends StatelessWidget {
  const _SubtleReveal({required this.child, required this.delay});

  final Widget child;
  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 220 + delay),
      curve: Curves.easeOutCubic,
      tween: Tween<double>(begin: 0, end: 1),
      child: child,
      builder: (context, value, builtChild) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 10),
            child: builtChild,
          ),
        );
      },
    );
  }
}
