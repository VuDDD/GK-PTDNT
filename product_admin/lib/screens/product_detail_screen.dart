import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../services/storage_service.dart';
import '../widgets/product_card.dart';
import 'edit_product_screen.dart';

/// Hàm xác nhận và thực hiện xóa sản phẩm dùng chung giữa danh sách và chi tiết.
Future<bool> confirmAndDeleteProduct(
  BuildContext context, {
  required Product product,
  required ProductService productService,
  required StorageService storageService,
}) async {
  final bool? confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('Xác nhận xóa sản phẩm'),
        content: Text(
          'Bạn có chắc chắn muốn xóa sản phẩm "${product.name}" khỏi hệ thống không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(dialogContext).colorScheme.error,
              foregroundColor: Theme.of(dialogContext).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa'),
          ),
        ],
      );
    },
  );

  if (confirmed != true) return false;

  try {
    await productService.deleteProduct(product.id);
    await storageService.deleteImageByUrl(product.image);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã xóa sản phẩm "${product.name}".'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return true;
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xóa sản phẩm: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return false;
  }
}

/// Màn hình hiển thị chi tiết thông tin một sản phẩm.
class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    this.productService,
    this.storageService,
  });

  final Product product;
  final ProductService? productService;
  final StorageService? storageService;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late Product _product;
  late final ProductService _productService;
  late final StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _product = widget.product;
    _productService = widget.productService ?? ProductService();
    _storageService = widget.storageService ?? StorageService();
  }

  Future<void> _openEdit() async {
    final Product? updated = await Navigator.of(context).push<Product>(
      MaterialPageRoute(
        builder: (_) => EditProductScreen(
          product: _product,
          productService: _productService,
          storageService: _storageService,
        ),
      ),
    );
    if (updated != null && mounted) {
      setState(() => _product = updated);
    }
  }

  Future<void> _handleDelete() async {
    final bool deleted = await confirmAndDeleteProduct(
      context,
      product: _product,
      productService: _productService,
      storageService: _storageService,
    );
    if (deleted && mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;
    final bool outOfStock = _product.soluong <= 0;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Chi tiết sản phẩm'),
        actions: [
          IconButton(
            tooltip: 'Sửa sản phẩm',
            onPressed: _openEdit,
            icon: const Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: 'Xóa sản phẩm',
            onPressed: _handleDelete,
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Card(
                elevation: 0,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(color: colorScheme.outlineVariant),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: ProductImageThumbnail(
                          imageUrl: _product.image,
                          width: 280,
                          height: 240,
                          borderRadius: 16,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _product.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _product.formattedPrice,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Số lượng tồn kho',
                        value: '${_product.soluong} sản phẩm',
                        badgeText: outOfStock ? 'Hết hàng' : 'Còn hàng',
                        isAlert: outOfStock,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'Document ID (Firestore)',
                        value: _product.id,
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        label: 'URL hình ảnh (image)',
                        value: _product.image,
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: _openEdit,
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Sửa sản phẩm'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _handleDelete,
                              style: OutlinedButton.styleFrom(
                                foregroundColor: colorScheme.error,
                                side: BorderSide(color: colorScheme.error),
                              ),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Xóa sản phẩm'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.badgeText,
    this.isAlert = false,
  });

  final String label;
  final String value;
  final String? badgeText;
  final bool isAlert;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Expanded(
              child: SelectableText(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (badgeText != null)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isAlert
                      ? colorScheme.errorContainer
                      : colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  badgeText!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isAlert
                        ? colorScheme.onErrorContainer
                        : colorScheme.onSecondaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
