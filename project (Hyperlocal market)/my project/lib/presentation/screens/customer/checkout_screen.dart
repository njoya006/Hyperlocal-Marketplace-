import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../domain/entities/order_entity.dart';
import '../../../domain/entities/order_item_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/location_provider.dart';
import '../../providers/order_provider.dart';
import '../../router/app_router.dart';

/// Basic checkout screen for the current cart.
class CheckoutScreen extends ConsumerStatefulWidget {
  /// Creates a [CheckoutScreen].
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  static const String _recentAddressesKey = 'checkout_recent_addresses_v1';
  static const String _lastDeliveryNoteKey = 'checkout_last_delivery_note_v1';
  static const String _lastCheckoutAddressKey = 'checkout_last_checkout_address_v1';
  static const String _lastCheckoutNoteKey = 'checkout_last_checkout_note_v1';

  final TextEditingController _customAddressController = TextEditingController();
  final TextEditingController _deliveryNoteController = TextEditingController();

  bool _isSubmitting = false;
  bool _saveAsDefaultAddress = true;
  List<String> _recentAddresses = const [];
  String? _selectedAddress;
  String? _lastCheckoutAddress;
  String? _lastCheckoutNote;
  String? _addressErrorText;

  @override
  void initState() {
    super.initState();
    _loadRecentAddresses();
    _loadLastDeliveryNote();
    _loadLastCheckoutPreset();
  }

  @override
  void dispose() {
    _customAddressController.dispose();
    _deliveryNoteController.dispose();
    super.dispose();
  }

  Future<void> _loadRecentAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_recentAddressesKey) ?? const [];
    if (!mounted) {
      return;
    }

    setState(() {
      _recentAddresses = saved;
      if (_selectedAddress == null && saved.isNotEmpty) {
        _selectedAddress = saved.first;
      }
    });
  }

  Future<void> _loadLastDeliveryNote() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_lastDeliveryNoteKey) ?? '';
    if (!mounted) {
      return;
    }
    _deliveryNoteController.text = saved;
  }

  Future<void> _loadLastCheckoutPreset() async {
    final prefs = await SharedPreferences.getInstance();
    final address = prefs.getString(_lastCheckoutAddressKey);
    final note = prefs.getString(_lastCheckoutNoteKey);

    if (!mounted) {
      return;
    }

    setState(() {
      _lastCheckoutAddress = address;
      _lastCheckoutNote = note;
    });
  }

  Future<void> _saveRecentAddress(String address) async {
    final trimmed = address.trim();
    if (trimmed.isEmpty) {
      return;
    }

    final next = [
      trimmed,
      ..._recentAddresses.where((existing) => existing != trimmed),
    ].take(5).toList(growable: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentAddressesKey, next);

    if (!mounted) {
      return;
    }
    setState(() {
      _recentAddresses = next;
      _selectedAddress = trimmed;
    });
  }

  Future<void> _removeRecentAddress(String address) async {
    final next = _recentAddresses.where((existing) => existing != address).toList(growable: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentAddressesKey, next);

    if (!mounted) {
      return;
    }
    setState(() {
      _recentAddresses = next;
      if (_selectedAddress == address) {
        _selectedAddress = next.isEmpty ? null : next.first;
      }
    });
  }

  Future<void> _saveLastDeliveryNote(String note) async {
    final prefs = await SharedPreferences.getInstance();
    if (note.trim().isEmpty) {
      await prefs.remove(_lastDeliveryNoteKey);
      return;
    }
    await prefs.setString(_lastDeliveryNoteKey, note.trim());
  }

  Future<void> _saveLastCheckoutPreset({
    required String address,
    required String note,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final trimmedAddress = address.trim();
    final trimmedNote = note.trim();

    if (trimmedAddress.isEmpty) {
      await prefs.remove(_lastCheckoutAddressKey);
    } else {
      await prefs.setString(_lastCheckoutAddressKey, trimmedAddress);
    }

    if (trimmedNote.isEmpty) {
      await prefs.remove(_lastCheckoutNoteKey);
    } else {
      await prefs.setString(_lastCheckoutNoteKey, trimmedNote);
    }
  }

  Future<void> _editRecentAddress(String oldAddress) async {
    final edited = await _promptAddressDialog(
      title: 'Edit Address',
      initialValue: oldAddress,
      submitLabel: 'Save',
    );

    if (edited == null) {
      return;
    }

    final nextAddress = edited.trim();
    if (nextAddress.isEmpty) {
      return;
    }

    final next = _recentAddresses
        .map((existing) => existing == oldAddress ? nextAddress : existing)
        .toSet()
        .take(5)
        .toList(growable: false);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_recentAddressesKey, next);

    if (!mounted) {
      return;
    }
    setState(() {
      _recentAddresses = next;
      if (_selectedAddress == oldAddress) {
        _selectedAddress = nextAddress;
      }
    });
  }

  Future<bool> _handleAddressSwipe(
    String address,
    DismissDirection direction,
  ) async {
    if (direction == DismissDirection.startToEnd) {
      await _editRecentAddress(address);
      return false;
    }

    await _removeRecentAddress(address);
    if (!mounted) {
      return true;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('Address removed.'),
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _saveRecentAddress(address),
          ),
        ),
      );

    return true;
  }

  Future<String?> _promptAddressDialog({
    required String title,
    required String initialValue,
    required String submitLabel,
  }) async {
    final controller = TextEditingController(text: initialValue);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            maxLines: 2,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Address',
              hintText: 'Apartment, street, landmark...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text(AppStrings.buttonCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Text(submitLabel),
            ),
          ],
        );
      },
    );
    controller.dispose();
    return result;
  }

  void _applyLastCheckoutPreset() {
    final address = _lastCheckoutAddress;
    if (address == null || address.isEmpty) {
      return;
    }

    setState(() {
      _customAddressController.text = address;
      _selectedAddress = address;
      _deliveryNoteController.text = _lastCheckoutNote ?? '';
      _saveAsDefaultAddress = true;
      _addressErrorText = null;
    });
  }

  void _showValidationMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  void _setAddressError(String? errorText) {
    setState(() {
      _addressErrorText = errorText;
    });
  }

  Future<void> _confirmOrder() async {
    if (_isSubmitting) {
      return;
    }

    final cartState = ref.read(cartProvider);
    final authState = ref.read(authStateProvider);
    final location = await ref.read(singleLocationProvider.future);
    final user = authState.maybeWhen(data: (value) => value, orElse: () => null);

    if (user == null || cartState.isEmpty) {
      return;
    }

    final customAddress = _customAddressController.text.trim();
    final selectedAddress = customAddress.isNotEmpty ? customAddress : _selectedAddress;

    if (customAddress.isNotEmpty && customAddress.length < 10) {
      _setAddressError('Please enter a more complete delivery address.');
      _showValidationMessage('Please enter a more complete delivery address.');
      return;
    }

    if (selectedAddress == null || selectedAddress.isEmpty) {
      _setAddressError('Select or enter a delivery address.');
      _showValidationMessage('Select or enter a delivery address.');
      return;
    }

    _setAddressError(null);

    final deliveryAddress = selectedAddress.isNotEmpty
        ? selectedAddress
        : 'Current GPS: ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}';
    final deliveryNote = _deliveryNoteController.text.trim();

    setState(() => _isSubmitting = true);

    final orderItems = cartState.items
        .map(
          (item) => OrderItemEntity(
            productId: item.product.id,
            productName: item.product.name,
            unitPrice: item.product.price,
            quantity: item.quantity,
            productImageUrl: item.product.imageUrl,
          ),
        )
        .toList(growable: false);

    final order = OrderEntity(
      id: '',
      customerId: user.uid,
      customerName: user.name,
      shopId: cartState.shopId ?? '',
      items: orderItems,
      subtotal: cartState.total,
      deliveryFee: 0,
      tax: 0,
      total: cartState.total,
      status: OrderStatus.pending,
      deliveryAddress: deliveryAddress,
      deliveryLatitude: location.latitude,
      deliveryLongitude: location.longitude,
      customerNotes: deliveryNote.isEmpty ? null : deliveryNote,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    try {
      final placeOrder = ref.read(placeOrderUsecaseProvider);
      await placeOrder(order: order);

      await _saveLastCheckoutPreset(
        address: deliveryAddress,
        note: deliveryNote,
      );
      await _saveLastDeliveryNote(deliveryNote);
      if (_saveAsDefaultAddress) {
        await _saveRecentAddress(deliveryAddress);
      }

      ref.read(cartProvider.notifier).clearCart();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order placed successfully')),
      );
      context.go(Routes.customerOrders);
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to place order: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartState = ref.watch(cartProvider);
    final authState = ref.watch(authStateProvider);
    final locationAsync = ref.watch(singleLocationProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF8),
      appBar: AppBar(
        title: const Text(AppStrings.screenTitleCheckout),
      ),
      bottomNavigationBar: cartState.isEmpty
          ? null
          : _CheckoutStickyBar(
              itemCount: cartState.items.length,
              total: cartState.total,
              isLoading: _isSubmitting,
              onConfirm: _confirmOrder,
            ),
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSizes.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Failed to load user: $error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSizes.md),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(authStateProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (user) {
          if (cartState.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Your cart is empty. Add items before checkout.'),
                    const SizedBox(height: AppSizes.md),
                    FilledButton.icon(
                      onPressed: () => context.go(Routes.customerHome),
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Browse Shops'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(AppSizes.lg),
            children: [
              Container(
                padding: const EdgeInsets.all(AppSizes.lg),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSizes.radiusXl),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary.withValues(alpha: 0.16),
                      AppColors.secondary.withValues(alpha: 0.1),
                    ],
                  ),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  'Review and confirm your order',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              const SizedBox(height: AppSizes.md),
              if (_lastCheckoutAddress != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.md),
                  child: Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                      side: BorderSide(color: AppColors.divider),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.history_outlined),
                      title: const Text('Use last checkout setup'),
                      subtitle: Text(
                        _lastCheckoutNote == null || _lastCheckoutNote!.isEmpty
                            ? 'Restores your last address.'
                            : 'Restores your last address and note.',
                      ),
                      trailing: TextButton(
                        onPressed: _applyLastCheckoutPreset,
                        child: const Text('Apply'),
                      ),
                    ),
                  ),
                ),
              _buildAddressSection(context, locationAsync),
              const SizedBox(height: AppSizes.md),
              TextField(
                controller: _deliveryNoteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: AppStrings.labelOrderNotes,
                  hintText: 'Gate code, landmark, delivery preference...',
                ),
              ),
              const SizedBox(height: AppSizes.md),
              Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.radiusLg),
                  side: BorderSide(color: AppColors.divider),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Column(
                    children: cartState.items
                        .map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: AppSizes.sm),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.quantity} x ${item.product.name}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                  Text(CurrencyFormatter.formatXAF(item.lineTotal)),
                              ],
                            ),
                          ),
                        )
                        .toList(growable: false),
                  ),
                ),
              ),
              const Divider(height: AppSizes.xl),
              _CheckoutInfoCard(
                title: 'Customer',
                value: user?.name ?? 'Unknown customer',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: AppSizes.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(AppStrings.labelGrandTotal),
                  Text(
                    CurrencyFormatter.formatXAF(cartState.total),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.lg),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAddressSection(BuildContext context, AsyncValue locationAsync) {
    final gpsAddress = locationAsync.when(
      data: (location) =>
          'Current GPS: ${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}',
      loading: () => 'Detecting location...',
      error: (_, __) => 'Location unavailable right now.',
    );

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppStrings.labelDeliveryAddress,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSizes.sm),
            Text(
              'Use your recent address, or type a new one.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSizes.sm),
            Wrap(
              spacing: AppSizes.sm,
              runSpacing: AppSizes.xs,
              children: [
                ChoiceChip(
                  label: const Text('Use GPS Location'),
                  selected: _customAddressController.text.trim().isEmpty && _selectedAddress == null,
                  onSelected: (_) {
                    setState(() {
                      _customAddressController.clear();
                      _selectedAddress = null;
                      _addressErrorText = null;
                    });
                  },
                ),
                ..._recentAddresses.map(
                  (address) => ChoiceChip(
                    label: Text(address),
                    selected: _selectedAddress == address &&
                        _customAddressController.text.trim().isEmpty,
                    onSelected: (_) {
                      setState(() {
                        _selectedAddress = address;
                        _customAddressController.clear();
                        _addressErrorText = null;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSizes.sm),
            TextField(
              controller: _customAddressController,
              maxLines: 2,
              onChanged: (value) {
                if (value.trim().isNotEmpty) {
                  setState(() {
                    _selectedAddress = null;
                    _addressErrorText = null;
                  });
                } else if (_selectedAddress != null) {
                  setState(() {
                    _addressErrorText = null;
                  });
                }
              },
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: 'Apartment, street, landmark...',
                labelText: 'Enter delivery address',
                errorText: _addressErrorText,
              ),
            ),
            const SizedBox(height: AppSizes.xs),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: _saveAsDefaultAddress,
              title: const Text('Save this as default address'),
              subtitle: const Text('Keep it at the top for your next checkout.'),
              onChanged: (value) {
                setState(() {
                  _saveAsDefaultAddress = value;
                });
              },
            ),
            if (_recentAddresses.isNotEmpty) ...[
              const SizedBox(height: AppSizes.xs),
              Text(
                'Manage saved addresses',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: AppSizes.xxs),
              const Text('Swipe right to edit, left to delete.'),
              const SizedBox(height: AppSizes.xs),
              ..._recentAddresses.map(
                (address) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSizes.xxs),
                  child: Dismissible(
                    key: ValueKey('address_$address'),
                    direction: DismissDirection.horizontal,
                    confirmDismiss: (direction) => _handleAddressSwipe(address, direction),
                    background: Container(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.edit_outlined, color: AppColors.primary),
                          SizedBox(width: AppSizes.xs),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    secondaryBackground: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text('Delete'),
                          SizedBox(width: AppSizes.xs),
                          Icon(Icons.delete_outline, color: AppColors.error),
                        ],
                      ),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                        border: Border.all(color: AppColors.divider),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.sm,
                        vertical: AppSizes.xs,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              address,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const Icon(
                            Icons.swipe,
                            size: 16,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSizes.sm),
            _CheckoutInfoCard(
              title: AppStrings.labelDeliveryLocation,
              value: gpsAddress,
              icon: Icons.my_location_outlined,
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutStickyBar extends StatelessWidget {
  const _CheckoutStickyBar({
    required this.itemCount,
    required this.total,
    required this.isLoading,
    required this.onConfirm,
  });

  final int itemCount;
  final double total;
  final bool isLoading;
  final Future<void> Function() onConfirm;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: AppColors.divider.withValues(alpha: 0.75)),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 14,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Row(
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Padding(
                padding: EdgeInsets.all(AppSizes.sm),
                child: Icon(Icons.shopping_bag_outlined, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$itemCount item${itemCount == 1 ? '' : 's'}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '\$${total.toStringAsFixed(2)} ready to place',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton(
              onPressed: isLoading ? null : () => onConfirm(),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppStrings.buttonConfirmOrder),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutInfoCard extends StatelessWidget {
  const _CheckoutInfoCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: AppSizes.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(value),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
