import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import 'admin_shell_scaffold.dart';

/// Admin screen for managing user accounts.
class ManageUsersScreen extends ConsumerStatefulWidget {
  /// Creates [ManageUsersScreen].
  const ManageUsersScreen({super.key});

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    final currentUserId = ref.watch(authStateProvider).maybeWhen(
          data: (user) => user?.uid,
          orElse: () => null,
        );

    return AdminShellScaffold(
      title: AppStrings.screenTitleManageUsers,
      currentIndex: 2,
      body: usersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Text(
              'Failed to load users: $error',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (users) {
          final filteredUsers = users.where((user) {
            final query = _searchQuery.toLowerCase();
            if (query.isEmpty) {
              return true;
            }
            return user.name.toLowerCase().contains(query) ||
                user.email.toLowerCase().contains(query) ||
                user.role.toLowerCase().contains(query) ||
                (user.phone ?? '').toLowerCase().contains(query);
          }).toList();

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminUsersProvider);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSizes.lg),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                TextField(
                  decoration: const InputDecoration(
                    hintText: AppStrings.labelSearchUsers,
                    prefixIcon: Icon(Icons.search),
                  ),
                  onChanged: (value) => setState(() {
                    _searchQuery = value;
                  }),
                ),
                const SizedBox(height: AppSizes.lg),
                _SectionHeader(
                  title: AppStrings.labelAllUsers,
                  count: filteredUsers.length,
                ),
                const SizedBox(height: AppSizes.md),
                if (filteredUsers.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSizes.xl),
                    child: Center(
                      child: Text(
                        AppStrings.messageNoData,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  )
                else
                  ...filteredUsers.map(
                    (user) => Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.md),
                      child: _UserCard(
                        user: user,
                        currentUserId: currentUserId,
                        onToggleActive: () async {
                          final activate = !user.isActive;
                          final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (dialogContext) => AlertDialog(
                                  title: Text(
                                    activate
                                        ? AppStrings.labelActivateUser
                                        : AppStrings.labelDeactivateUser,
                                  ),
                                  content: Text(
                                    activate
                                        ? 'Restore ${user.name} access to the app?'
                                        : 'Suspend ${user.name} from the app?',
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext)
                                              .pop(false),
                                      child:
                                          const Text(AppStrings.buttonCancel),
                                    ),
                                    FilledButton(
                                      onPressed: () =>
                                          Navigator.of(dialogContext).pop(true),
                                      child: const Text(AppStrings.buttonOk),
                                    ),
                                  ],
                                ),
                              ) ??
                              false;
                          if (!confirmed) {
                            return;
                          }
                          await updateUserActiveState(
                            ref,
                            userId: user.uid,
                            isActive: activate,
                          );
                          ref.invalidate(adminUsersProvider);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  activate
                                      ? AppStrings.messageUserActivated
                                      : AppStrings.messageUserDeactivated,
                                ),
                              ),
                            );
                          }
                        },
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.count,
  });

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(width: AppSizes.sm),
        Chip(
          label: Text(count.toString()),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({
    required this.user,
    required this.currentUserId,
    required this.onToggleActive,
  });

  final AdminUserSummary user;
  final String? currentUserId;
  final VoidCallback onToggleActive;

  @override
  Widget build(BuildContext context) {
    final isCurrentAdmin = currentUserId == user.uid;
    final roleLabel = user.role.replaceAll('_', ' ');

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                  child: Icon(Icons.person_outline, color: AppColors.primary),
                ),
                const SizedBox(width: AppSizes.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(user.isActive ? 'Active' : 'Inactive'),
                  backgroundColor: user.isActive
                      ? Colors.green.withValues(alpha: 0.12)
                      : Colors.grey.withValues(alpha: 0.12),
                  side: BorderSide.none,
                ),
              ],
            ),
            const SizedBox(height: AppSizes.md),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.sm,
              children: [
                _InfoChip(label: roleLabel),
                _InfoChip(label: AppStrings.labelUserCreatedDate),
                if (user.phone != null && user.phone!.isNotEmpty)
                  _InfoChip(label: user.phone!),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              MaterialLocalizations.of(context)
                  .formatMediumDate(user.createdAt),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
            ),
            const SizedBox(height: AppSizes.lg),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: isCurrentAdmin ? null : onToggleActive,
                icon: Icon(user.isActive
                    ? Icons.pause_circle_outline
                    : Icons.check_circle_outline),
                label: Text(
                  user.isActive
                      ? AppStrings.labelDeactivateUser
                      : AppStrings.labelActivateUser,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      side: BorderSide(color: Colors.grey.shade300),
    );
  }
}
