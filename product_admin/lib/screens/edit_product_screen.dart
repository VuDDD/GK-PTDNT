import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../services/storage_service.dart';
import '../widgets/product_form.dart';

/// Màn hình chỉnh sửa thông tin sản phẩm hiện có.
///
/// Nếu Admin không chọn ảnh mới, URL ảnh cũ sẽ được giữ nguyên.
class EditProductScreen extends StatelessWidget {
  const EditProductScreen({
    super.key,
    required this.product,
    this.productService,
    this.storageService,
  });

  final Product product;
  final ProductService? productService;
  final StorageService? storageService;

  Future<void> _handleEditProduct(
    BuildContext context,
    ProductFormResult result,
  ) async {
    final ProductService activeProductService =
        productService ?? ProductService();
    final StorageService activeStorageService =
        storageService ?? StorageService();

    try {
      String imageUrl = product.image;
      final bool hasNewImage = result.selectedImageBytes != null;

      if (hasNewImage) {
        imageUrl = await activeStorageService.uploadProductImageBytes(
          bytes: result.selectedImageBytes!,
          fileName: result.selectedImage?.name ?? 'product.jpg',
        );
      }

      final Product updatedProduct = product.copyWith(
        name: result.name,
        price: result.price,
        soluong: result.soluong,
        image: imageUrl,
      );

      await activeProductService.updateProduct(updatedProduct);

      if (hasNewImage && product.image != imageUrl) {
        await activeStorageService.deleteImageByUrl(product.image);
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cập nhật sản phẩm thành công!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(updatedProduct);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi khi cập nhật sản phẩm: ${e.toString().replaceFirst('Exception: ', '')}',
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Sửa sản phẩm'),
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
                  child: ProductForm(
                    initialProduct: product,
                    submitLabel: 'Lưu thay đổi',
                    onSubmit: (result) => _handleEditProduct(context, result),
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
