import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../router/app_router.dart';

/// Screen shown after shop owner submits a shop for approval.
class AwaitingApprovalScreen extends StatelessWidget {
  /// Creates an [AwaitingApprovalScreen].
  const AwaitingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.screenTitleShopOwnerDashboard),
        backgroundColor: Colors.transparent,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                side: const BorderSide(color: AppColors.divider),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
                      decoration: BoxDecoration(
                        color: AppColors.warning.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.hourglass_top_rounded,
                        size: 46,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: AppSizes.lg),
                    Text(
                      'Submission Received',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    const Text(
                      AppStrings.messageAwaitingApproval,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'An admin will review your store details. Once approved, your shop appears to nearby customers.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: AppSizes.xl),
                    FilledButton.icon(
                      onPressed: () => context.go(Routes.ownerDashboard),
                      icon: const Icon(Icons.dashboard_outlined),
                      label: const Text('Back to Dashboard'),
                    ),
                    const SizedBox(height: AppSizes.sm),
                    OutlinedButton(
                      onPressed: () => context.go(Routes.login),
                      child: const Text(AppStrings.buttonClose),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
