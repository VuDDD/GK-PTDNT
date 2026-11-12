import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import '../services/storage_service.dart';
import '../widgets/product_card.dart';
import 'add_product_screen.dart';
import 'edit_product_screen.dart';
import 'product_detail_screen.dart';

/// Màn hình quản lý danh sách sản phẩm theo thời gian thực từ Firestore.
///
/// Có thể dùng độc lập (`embedded: false`) hoặc nhúng vào Dashboard (`embedded: true`).
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({
    super.key,
    this.embedded = false,
    this.productsOverride,
    this.productService,
    this.storageService,
  });

  final bool embedded;
  final List<Product>? productsOverride;
  final ProductService? productService;
  final StorageService? storageService;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final TextEditingController _searchController = TextEditingController();
  late final ProductService _productService;
  late final StorageService _storageService;

  String _searchQuery = '';
  ProductSortOrder _sortOrder = ProductSortOrder.none;

  @override
  void initState() {
    super.initState();
    _productService = widget.productService ?? ProductService();
    _storageService = widget.storageService ?? StorageService();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddProductScreen(
          productService: _productService,
          storageService: _storageService,
        ),
      ),
    );
  }

  void _openEditProduct(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EditProductScreen(
          product: product,
          productService: _productService,
          storageService: _storageService,
        ),
      ),
    );
  }

  void _openProductDetail(Product product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(
          product: product,
          productService: _productService,
          storageService: _storageService,
        ),
      ),
    );
  }

  Future<void> _deleteProduct(Product product) async {
    await confirmAndDeleteProduct(
      context,
      product: product,
      productService: _productService,
      storageService: _storageService,
    );
  }

  @override
  Widget build(BuildContext context) {
    final Widget content = widget.productsOverride != null
        ? _buildProductBody(context, widget.productsOverride!)
        : StreamBuilder<List<Product>>(
            stream: _productService.watchProducts(),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _ErrorState(error: snapshot.error.toString());
              }
              if (snapshot.connectionState == ConnectionState.waiting &&
                  !snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              return _buildProductBody(
                context,
                snapshot.data ?? const <Product>[],
              );
            },
          );

    if (widget.embedded) {
      return content;
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: const Text('Danh sách sản phẩm'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddProduct,
        icon: const Icon(Icons.add),
        label: const Text('Thêm sản phẩm'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: content,
        ),
      ),
    );
  }

  Widget _buildProductBody(BuildContext context, List<Product> allProducts) {
    final List<Product> visibleProducts = ProductService.filterAndSortProducts(
      products: allProducts,
      searchQuery: _searchQuery,
      sortOrder: _sortOrder,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildToolbar(context, allProducts.length, visibleProducts.length),
        const SizedBox(height: 16),
        if (allProducts.isEmpty)
          _EmptyProductsState(onAddPressed: _openAddProduct)
        else if (visibleProducts.isEmpty)
          _NoSearchMatchState(
            query: _searchQuery,
            onClear: () {
              _searchController.clear();
              setState(() => _searchQuery = '');
            },
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth >= 760) {
                return _buildWebDataTable(
                  context,
                  visibleProducts,
                  constraints.maxWidth,
                );
              }
              return _buildMobileCardList(visibleProducts);
            },
          ),
      ],
    );
  }

  Widget _buildToolbar(
    BuildContext context,
    int totalCount,
    int filteredCount,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 700;
            final Widget searchField = TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                hintText: 'Tìm kiếm sản phẩm theo tên...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        tooltip: 'Xóa tìm kiếm',
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
            );

            final Widget sortDropdown =
                DropdownButtonFormField<ProductSortOrder>(
              initialValue: _sortOrder,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: 'Sắp xếp theo giá',
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceContainerLowest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: colorScheme.outlineVariant),
                ),
              ),
              items: const [
                DropdownMenuItem(
                  value: ProductSortOrder.none,
                  child: Text(
                    'Mặc định (A - Z)',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: ProductSortOrder.priceAsc,
                  child: Text(
                    'Giá tăng dần',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DropdownMenuItem(
                  value: ProductSortOrder.priceDesc,
                  child: Text(
                    'Giá giảm dần',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _sortOrder = value);
                }
              },
            );

            final Widget addButton = FilledButton.icon(
              onPressed: _openAddProduct,
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 14,
                ),
              ),
            );

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (isWide)
                  Row(
                    children: [
                      Expanded(flex: 3, child: searchField),
                      const SizedBox(width: 12),
                      Expanded(flex: 2, child: sortDropdown),
                      const SizedBox(width: 12),
                      addButton,
                    ],
                  )
                else ...[
                  searchField,
                  const SizedBox(height: 12),
                  if (constraints.maxWidth >= 420)
                    Row(
                      children: [
                        Expanded(child: sortDropdown),
                        const SizedBox(width: 10),
                        addButton,
                      ],
                    )
                  else ...[
                    sortDropdown,
                    const SizedBox(height: 10),
                    addButton,
                  ],
                ],
                const SizedBox(height: 12),
                Text(
                  _searchQuery.trim().isEmpty
                      ? 'Tổng số sản phẩm: $totalCount'
                      : 'Tìm thấy $filteredCount / $totalCount sản phẩm',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildWebDataTable(
    BuildContext context,
    List<Product> products,
    double maxWidth,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: ConstrainedBox(
          constraints: BoxConstraints(minWidth: maxWidth - 2),
          child: DataTable(
            headingRowColor: WidgetStatePropertyAll(
              colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            ),
            dataRowMinHeight: 72,
            dataRowMaxHeight: 84,
            columns: const [
              DataColumn(label: Text('Hình ảnh')),
              DataColumn(label: Text('Tên sản phẩm')),
              DataColumn(label: Text('Giá (VNĐ)')),
              DataColumn(label: Text('Số lượng')),
              DataColumn(label: Text('Thao tác')),
            ],
            rows: products.map((product) {
              final bool outOfStock = product.soluong <= 0;
              return DataRow(
                cells: [
                  DataCell(
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: ProductImageThumbnail(
                        imageUrl: product.image,
                        width: 56,
                        height: 56,
                        borderRadius: 10,
                      ),
                    ),
                    onTap: () => _openProductDetail(product),
                  ),
                  DataCell(
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                    onTap: () => _openProductDetail(product),
                  ),
                  DataCell(
                    Text(
                      product.formattedPrice,
                      style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    onTap: () => _openProductDetail(product),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: outOfStock
                            ? colorScheme.errorContainer
                            : colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '${product.soluong}',
                        style: TextStyle(
                          color: outOfStock
                              ? colorScheme.onErrorContainer
                              : colorScheme.onSecondaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    onTap: () => _openProductDetail(product),
                  ),
                  DataCell(
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Xem chi tiết',
                          onPressed: () => _openProductDetail(product),
                          icon: const Icon(Icons.visibility_outlined),
                        ),
                        IconButton(
                          tooltip: 'Sửa sản phẩm',
                          onPressed: () => _openEditProduct(product),
                          icon: Icon(
                            Icons.edit_outlined,
                            color: colorScheme.primary,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Xóa sản phẩm',
                          onPressed: () => _deleteProduct(product),
                          icon: Icon(
                            Icons.delete_outline,
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileCardList(List<Product> products) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final Product product = products[index];
        return ProductCard(
          product: product,
          onTap: () => _openProductDetail(product),
          onEdit: () => _openEditProduct(product),
          onDelete: () => _deleteProduct(product),
        );
      },
    );
  }
}

class _EmptyProductsState extends StatelessWidget {
  const _EmptyProductsState({required this.onAddPressed});

  final VoidCallback onAddPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 56,
              color: colorScheme.primary.withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              'Chưa có sản phẩm nào trong kho',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nhấn nút bên dưới để thêm sản phẩm đầu tiên vào Firestore.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: onAddPressed,
              icon: const Icon(Icons.add),
              label: const Text('Thêm sản phẩm ngay'),
            ),
          ],
        ),
      ),
    );
  }
}

class _NoSearchMatchState extends StatelessWidget {
  const _NoSearchMatchState({
    required this.query,
    required this.onClear,
  });

  final String query;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Card(
      elevation: 0,
      color: colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 48,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              'Không tìm thấy sản phẩm nào khớp với "$query"',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onClear,
              icon: const Icon(Icons.clear),
              label: const Text('Xóa từ khóa tìm kiếm'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.onErrorContainer),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Không thể tải dữ liệu sản phẩm từ Firestore: $error',
                style: TextStyle(color: colorScheme.onErrorContainer),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
