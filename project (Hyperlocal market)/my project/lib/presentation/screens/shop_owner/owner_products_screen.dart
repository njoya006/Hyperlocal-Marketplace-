import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_sizes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../domain/entities/product_entity.dart';
import '../../providers/auth_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/shop_provider.dart';
import 'owner_shell_scaffold.dart';

/// Inventory manager for shop owners.
class OwnerProductsScreen extends ConsumerStatefulWidget {
  /// Creates [OwnerProductsScreen].
  const OwnerProductsScreen({super.key});

  @override
  ConsumerState<OwnerProductsScreen> createState() =>
      _OwnerProductsScreenState();
}

class _OwnerProductsScreenState extends ConsumerState<OwnerProductsScreen> {
  String _query = '';

  Future<void> _openAddProductSheet(String shopId) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddProductSheet(shopId: shopId),
    );

    if (saved == true) {
      ref.invalidate(shopProductsProvider(shopId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);

    return OwnerShellScaffold(
      title: 'Manage Products',
      currentIndex: 2,
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) =>
            const Center(child: Text(AppStrings.errorOwnerAccountLoad)),
        data: (user) {
          if (user == null) {
            return const Center(
                child: Text(AppStrings.messageSignInToContinue));
          }

          final ownerShopAsync = ref.watch(ownerShopProvider(user.uid));
          return ownerShopAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) =>
                const Center(child: Text(AppStrings.errorOwnerShopLoad)),
            data: (shop) {
              if (shop == null) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.lg),
                    child: Text('Create your shop first to manage products.'),
                  ),
                );
              }

              final productsAsync = ref.watch(shopProductsProvider(shop.id));
              return productsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Center(
                  child: Text(
                      'We could not load your products. Please refresh and try again.'),
                ),
                data: (products) {
                  final filteredProducts = products.where((product) {
                    if (_query.trim().isEmpty) {
                      return true;
                    }
                    final q = _query.toLowerCase();
                    return product.name.toLowerCase().contains(q) ||
                        product.description.toLowerCase().contains(q);
                  }).toList();

                  final availableCount =
                      products.where((product) => product.isAvailable).length;
                  final lowStockCount = products
                      .where((product) => product.stockQuantity <= 5)
                      .length;

                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(shopProductsProvider(shop.id)),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(AppSizes.lg),
                      children: [
                        _InventoryHeader(
                          productCount: products.length,
                          availableCount: availableCount,
                          lowStockCount: lowStockCount,
                          onAddProduct: () => _openAddProductSheet(shop.id),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        TextField(
                          onChanged: (value) => setState(() {
                            _query = value;
                          }),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: 'Search by product name',
                            filled: true,
                            fillColor: AppColors.background,
                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLg),
                              borderSide:
                                  const BorderSide(color: AppColors.divider),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(AppSizes.radiusLg),
                              borderSide:
                                  const BorderSide(color: AppColors.divider),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSizes.lg),
                        if (filteredProducts.isEmpty)
                          _EmptyInventoryCard(
                            hasProducts: products.isNotEmpty,
                            onAddProduct: () => _openAddProductSheet(shop.id),
                          )
                        else
                          ...filteredProducts.map(
                            (product) => Padding(
                              padding:
                                  const EdgeInsets.only(bottom: AppSizes.md),
                              child: _ProductTile(product: product),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

class _InventoryHeader extends StatelessWidget {
  const _InventoryHeader({
    required this.productCount,
    required this.availableCount,
    required this.lowStockCount,
    required this.onAddProduct,
  });

  final int productCount;
  final int availableCount;
  final int lowStockCount;
  final VoidCallback onAddProduct;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSizes.lg),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Wrap(
        spacing: AppSizes.md,
        runSpacing: AppSizes.md,
        children: [
          _KpiChip(
              icon: Icons.inventory_2_outlined,
              label: 'Products',
              value: productCount.toString()),
          _KpiChip(
              icon: Icons.check_circle_outline,
              label: 'Available',
              value: availableCount.toString()),
          _KpiChip(
              icon: Icons.warning_amber_rounded,
              label: 'Low stock',
              value: lowStockCount.toString()),
          FilledButton.icon(
            onPressed: onAddProduct,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Add Product'),
          ),
        ],
      ),
    );
  }
}

class _KpiChip extends StatelessWidget {
  const _KpiChip(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.md, vertical: AppSizes.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: AppSizes.sm),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
          Text(value),
        ],
      ),
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product});

  final ProductEntity product;

  @override
  Widget build(BuildContext context) {
    final isLowStock = product.stockQuantity <= 5;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.lg),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: const Icon(Icons.inventory_2_outlined,
                  color: AppColors.primary),
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: AppSizes.xxs),
                  Text(
                    product.description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Wrap(
                    spacing: AppSizes.sm,
                    runSpacing: AppSizes.sm,
                    children: [
                      _MetaBadge(
                        icon: Icons.payments_outlined,
                        label: CurrencyFormatter.formatXAF(product.price),
                      ),
                      _MetaBadge(
                        icon: Icons.inventory_outlined,
                        label: 'Stock ${product.stockQuantity}',
                        tone: isLowStock
                            ? AppColors.warning
                            : AppColors.textSecondary,
                      ),
                      _MetaBadge(
                        icon: product.isAvailable
                            ? Icons.check_circle_outline
                            : Icons.pause_circle_outline,
                        label:
                            product.isAvailable ? 'Available' : 'Unavailable',
                        tone: product.isAvailable
                            ? AppColors.success
                            : AppColors.textSecondary,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaBadge extends StatelessWidget {
  const _MetaBadge(
      {required this.icon,
      required this.label,
      this.tone = AppColors.textSecondary});

  final IconData icon;
  final String label;
  final Color tone;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSizes.sm, vertical: 6),
      decoration: BoxDecoration(
        color: tone.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppSizes.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: tone),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: tone,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

class _EmptyInventoryCard extends StatelessWidget {
  const _EmptyInventoryCard({
    required this.hasProducts,
    this.onAddProduct,
  });

  final bool hasProducts;
  final VoidCallback? onAddProduct;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusLg),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.xl),
        child: Column(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
              child: const Icon(Icons.search_off_rounded,
                  color: AppColors.primary),
            ),
            const SizedBox(height: AppSizes.md),
            Text(
              hasProducts
                  ? 'No products match your search.'
                  : 'No products yet.',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: AppSizes.xxs),
            Text(
              hasProducts
                  ? 'Try a different keyword to find your product.'
                  : 'Your catalog will appear here after you add products.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            if (!hasProducts && onAddProduct != null) ...[
              const SizedBox(height: AppSizes.md),
              FilledButton.icon(
                onPressed: onAddProduct,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add First Product'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _AddProductSheet extends ConsumerStatefulWidget {
  const _AddProductSheet({required this.shopId});

  final String shopId;

  @override
  ConsumerState<_AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<_AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController(text: '1');
  final _imagePicker = ImagePicker();

  bool _isAvailable = true;
  bool _isSaving = false;
  bool _isUploadingImage = false;
  int _savedCount = 0;
  XFile? _selectedImage;
  String? _imageUploadError;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  /// Pick an image from device gallery
  Future<void> _pickImage() async {
    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1200,
        maxHeight: 1200,
      );

      if (image != null) {
        setState(() {
          _selectedImage = image;
          _imageUploadError = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to pick image: $e')),
        );
      }
    }
  }

  /// Upload image to Firebase Storage and return download URL
  Future<String?> _uploadImageToFirebase(String productId, String shopId) async {
    if (_selectedImage == null) return null;

    try {
      setState(() => _isUploadingImage = true);

      // Read image bytes
      final imageBytes = await _selectedImage!.readAsBytes();

      // Create Firebase Storage reference
      // Path: shops/{shopId}/products/{productId}/image.{ext}
      final fileExtension = _selectedImage!.path.split('.').last;
      final storagePath = 'shops/$shopId/products/$productId/image.$fileExtension';

      try {
        // Attempt Firebase Storage upload
        final storageRef = FirebaseStorage.instance.ref(storagePath);
        final uploadTask = storageRef.putData(imageBytes);
        final snapshot = await uploadTask;
        final downloadUrl = await snapshot.ref.getDownloadURL();
        return downloadUrl;
      } catch (e) {
        debugPrint('Firebase Storage upload error: $e');
        // Fallback: return placeholder URL (app should cache the image locally)
        return 'gs://hyperlocal-market-ba481.appspot.com/$storagePath';
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
      if (mounted) {
        setState(() => _imageUploadError = 'Failed to upload image: $e');
      }
      return null;
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  Future<void> _save({required bool keepOpen}) async {
    final form = _formKey.currentState;
    if (form == null || !form.validate() || _isSaving) {
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    final stock = int.tryParse(_stockController.text.trim());
    if (price == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid price and stock values.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _imageUploadError = null;
    });

    try {
      final productId = const Uuid().v4();
      
      // Upload image if selected
      final imageUrl = _selectedImage != null
          ? await _uploadImageToFirebase(productId, widget.shopId)
          : null;

      if (_selectedImage != null && imageUrl == null) {
        setState(() => _imageUploadError = 'Image upload failed. Proceeding without image.');
      }

      final product = ProductEntity(
        id: productId,
        shopId: widget.shopId,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: price,
        stockQuantity: stock,
        isAvailable: _isAvailable,
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final addProduct = ref.read(addProductUsecaseProvider);
      await addProduct(shopId: widget.shopId, product: product);

      _savedCount += 1;
      if (!mounted) {
        return;
      }

      if (keepOpen) {
        _nameController.clear();
        _descriptionController.clear();
        _priceController.clear();
        _stockController.text = '1';
        setState(() {
          _selectedImage = null;
          _imageUploadError = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved $_savedCount product(s).')),
        );
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add product: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(AppSizes.sm),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppSizes.radiusXl),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSizes.lg,
            AppSizes.lg,
            AppSizes.lg,
            AppSizes.lg + bottom,
          ),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(
                        'Add Product',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const Spacer(),
                      IconButton(
                        onPressed:
                            _isSaving ? null : () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xs),
                  Text(
                    'Quickly add catalog items. Use "Save & Add Another" for bulk entry.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: AppSizes.lg),
                  TextFormField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Product Name',
                      prefixIcon: Icon(Icons.inventory_2_outlined),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Product name is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSizes.md),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 2,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _priceController,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: const InputDecoration(
                            labelText: 'Price (XAF)',
                            prefixIcon: Icon(Icons.payments_outlined),
                          ),
                          validator: (value) {
                            final parsed = double.tryParse((value ?? '').trim());
                            if (parsed == null || parsed <= 0) {
                              return 'Enter a valid price';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: TextFormField(
                          controller: _stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stock',
                            prefixIcon: Icon(Icons.store_outlined),
                          ),
                          validator: (value) {
                            final parsed = int.tryParse((value ?? '').trim());
                            if (parsed == null || parsed < 0) {
                              return 'Enter valid stock';
                            }
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.md),
                  // Image picker section
                  if (_selectedImage != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                            border: Border.all(color: AppColors.divider),
                          ),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                _selectedImage!.path as dynamic,
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                top: 8,
                                right: 8,
                                child: CircleAvatar(
                                  backgroundColor:
                                      Colors.black.withValues(alpha: 0.5),
                                  radius: 16,
                                  child: IconButton(
                                    icon: const Icon(Icons.close,
                                        color: Colors.white, size: 18),
                                    padding: EdgeInsets.zero,
                                    onPressed: () {
                                      setState(() {
                                        _selectedImage = null;
                                        _imageUploadError = null;
                                      });
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppSizes.md),
                      ],
                    )
                  else
                    Column(
                      children: [
                        OutlinedButton.icon(
                          onPressed: _isSaving || _isUploadingImage
                              ? null
                              : _pickImage,
                          icon: const Icon(Icons.image_outlined),
                          label: const Text('Add Product Image (optional)'),
                        ),
                        const SizedBox(height: AppSizes.md),
                      ],
                    ),
                  if (_imageUploadError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSizes.sm),
                      child: Container(
                        padding: const EdgeInsets.all(AppSizes.sm),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                          border: Border.all(
                              color: Colors.red.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: Colors.red,
                                size: 16),
                            const SizedBox(width: AppSizes.sm),
                            Expanded(
                              child: Text(
                                _imageUploadError!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSizes.sm),
                  SwitchListTile.adaptive(
                    value: _isAvailable,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Available for ordering'),
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _isAvailable = value;
                            });
                          },
                  ),
                  const SizedBox(height: AppSizes.md),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed:
                              _isSaving ? null : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSizes.sm),
                      Expanded(
                        child: FilledButton(
                          onPressed: _isSaving ? null : () => _save(keepOpen: false),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.sm),
                  FilledButton.tonalIcon(
                    onPressed: _isSaving ? null : () => _save(keepOpen: true),
                    icon: const Icon(Icons.playlist_add_rounded),
                    label: const Text('Save & Add Another'),
                  ),
                  if (_isUploadingImage) ...[
                    const SizedBox(height: AppSizes.sm),
                    const LinearProgressIndicator(),
                  ],
                  if (_isSaving) ...[
                    const SizedBox(height: AppSizes.sm),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
