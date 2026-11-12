import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/product.dart';
import '../utils/validators.dart';
import 'custom_text_field.dart';

/// Dữ liệu hợp lệ được gửi ra từ [ProductForm] khi Admin nhấn lưu.
class ProductFormResult {
  const ProductFormResult({
    required this.name,
    required this.price,
    required this.soluong,
    this.selectedImage,
    this.selectedImageBytes,
  });

  final String name;
  final double price;
  final int soluong;
  final XFile? selectedImage;
  final Uint8List? selectedImageBytes;
}

/// Form nhập liệu sản phẩm dùng chung cho cả Thêm và Sửa sản phẩm.
class ProductForm extends StatefulWidget {
  const ProductForm({
    super.key,
    this.initialProduct,
    required this.submitLabel,
    required this.onSubmit,
  });

  final Product? initialProduct;
  final String submitLabel;
  final Future<void> Function(ProductFormResult result) onSubmit;

  @override
  State<ProductForm> createState() => _ProductFormState();
}

class _ProductFormState extends State<ProductForm> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _quantityController;

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  String? _imageError;
  bool _isSubmitting = false;

  bool get _isEditMode => widget.initialProduct != null;

  @override
  void initState() {
    super.initState();
    final Product? product = widget.initialProduct;
    _nameController = TextEditingController(text: product?.name ?? '');
    _priceController = TextEditingController(
      text: product == null
          ? ''
          : (product.price % 1 == 0
              ? product.price.toInt().toString()
              : product.price.toString()),
    );
    _quantityController = TextEditingController(
      text: product?.soluong.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _quantityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();
      if (!mounted) return;

      setState(() {
        _selectedImage = picked;
        _selectedImageBytes = bytes;
        _imageError = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn hình ảnh: $e')),
      );
    }
  }

  Future<void> _handleSubmit() async {
    final bool isValid = _formKey.currentState?.validate() ?? false;
    final bool hasImage = _selectedImageBytes != null ||
        (_isEditMode && widget.initialProduct!.image.trim().isNotEmpty);

    if (!hasImage) {
      setState(() {
        _imageError = 'Vui lòng chọn hình ảnh sản phẩm từ thiết bị.';
      });
    }

    if (!isValid || !hasImage) {
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      await widget.onSubmit(
        ProductFormResult(
          name: _nameController.text.trim(),
          price: Validators.parsePrice(_priceController.text),
          soluong: Validators.parseQuantity(_quantityController.text),
          selectedImage: _selectedImage,
          selectedImageBytes: _selectedImageBytes,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CustomTextField(
            controller: _nameController,
            label: 'Tên sản phẩm',
            hintText: 'Ví dụ: iPhone 16 Pro Max',
            prefixIcon: Icons.shopping_bag_outlined,
            validator: Validators.validateProductName,
            textInputAction: TextInputAction.next,
            enabled: !_isSubmitting,
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: CustomTextField(
                  controller: _priceController,
                  label: 'Giá sản phẩm (VNĐ)',
                  hintText: 'Ví dụ: 30000000',
                  prefixIcon: Icons.attach_money_rounded,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  validator: Validators.validatePrice,
                  textInputAction: TextInputAction.next,
                  enabled: !_isSubmitting,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _quantityController,
                  label: 'Số lượng',
                  hintText: 'Ví dụ: 10',
                  prefixIcon: Icons.inventory_outlined,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: Validators.validateQuantity,
                  textInputAction: TextInputAction.done,
                  enabled: !_isSubmitting,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'Hình ảnh sản phẩm',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _imageError != null
                    ? colorScheme.error
                    : colorScheme.outlineVariant,
              ),
            ),
            child: Column(
              children: [
                _buildImagePreview(context),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  alignment: WrapAlignment.center,
                  children: [
                    FilledButton.tonalIcon(
                      onPressed: _isSubmitting
                          ? null
                          : () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        kIsWeb
                            ? 'Chọn ảnh từ máy tính'
                            : 'Chọn ảnh từ thư viện',
                      ),
                    ),
                    if (!kIsWeb)
                      OutlinedButton.icon(
                        onPressed: _isSubmitting
                            ? null
                            : () => _pickImage(ImageSource.camera),
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Chụp ảnh'),
                      ),
                  ],
                ),
                if (_isEditMode && _selectedImageBytes == null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Nếu không chọn ảnh mới, hệ thống sẽ giữ nguyên ảnh hiện tại.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (_imageError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _imageError!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              onPressed: _isSubmitting ? null : _handleSubmit,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save_outlined),
              label: Text(
                _isSubmitting ? 'Đang xử lý & tải lên...' : widget.submitLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    if (_selectedImageBytes != null) {
      return Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _selectedImageBytes!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.contain,
            ),
          ),
          if (_selectedImage != null) ...[
            const SizedBox(height: 8),
            Text(
              'Đã chọn: ${_selectedImage!.name}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ],
        ],
      );
    }

    if (_isEditMode && widget.initialProduct!.image.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          widget.initialProduct!.image.trim(),
          height: 200,
          width: double.infinity,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return SizedBox(
              height: 150,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.broken_image_outlined,
                      size: 40,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Không tải được ảnh hiện tại',
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      );
    }

    return SizedBox(
      height: 150,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 8),
            Text(
              'Chưa chọn hình ảnh sản phẩm',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
