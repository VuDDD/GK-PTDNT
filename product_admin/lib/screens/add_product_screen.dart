import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../services/storage_service.dart';
import '../widgets/product_form.dart';

/// Màn hình thêm sản phẩm mới.
///
/// Quy trình:
/// 1. Nhập thông tin và chọn ảnh.
/// 2. Tải ảnh lên Firebase Storage để lấy URL.
/// 3. Lưu đúng 4 trường `name`, `price`, `soluong`, `image` vào Firestore.
class AddProductScreen extends StatelessWidget {
  const AddProductScreen({
    super.key,
    this.productService,
    this.storageService,
  });

  final ProductService? productService;
  final StorageService? storageService;

  Future<void> _handleAddProduct(
    BuildContext context,
    ProductFormResult result,
  ) async {
    final ProductService activeProductService =
        productService ?? ProductService();
    final StorageService activeStorageService =
        storageService ?? StorageService();

    try {
      final String imageUrl = await activeStorageService.uploadProductImageBytes(
        bytes: result.selectedImageBytes!,
        fileName: result.selectedImage?.name ?? 'product.jpg',
      );

      final Product newProduct = Product(
        id: '',
        name: result.name,
        price: result.price,
        soluong: result.soluong,
        image: imageUrl,
      );

      await activeProductService.addProduct(newProduct);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Thêm sản phẩm thành công!'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Lỗi khi thêm sản phẩm: ${e.toString().replaceFirst('Exception: ', '')}',
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
        title: const Text('Thêm sản phẩm mới'),
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
                    submitLabel: 'Thêm sản phẩm',
                    onSubmit: (result) => _handleAddProduct(context, result),
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
