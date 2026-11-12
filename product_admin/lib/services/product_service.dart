import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/product.dart';

/// Tùy chọn sắp xếp danh sách sản phẩm theo giá.
enum ProductSortOrder {
  none,
  priceAsc,
  priceDesc,
}

/// Dịch vụ thao tác dữ liệu sản phẩm với Cloud Firestore.
///
/// Mỗi document trong collection `products` CHỈ chứa đúng 4 trường:
/// `name`, `price`, `soluong`, `image`.
class ProductService {
  ProductService({this.firestore});

  static const String collectionName = 'products';

  final FirebaseFirestore? firestore;
  FirebaseFirestore get _instance => firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _productsRef =>
      _instance.collection(collectionName);

  /// Lắng nghe danh sách sản phẩm theo thời gian thực từ Firestore.
  Stream<List<Product>> watchProducts() {
    return _productsRef.snapshots().map((snapshot) {
      final List<Product> products = snapshot.docs
          .map((doc) => Product.fromFirestore(doc))
          .toList();
      products.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );
      return products;
    });
  }

  /// Thêm một sản phẩm mới (Firestore tự sinh Document ID).
  Future<String> addProduct(Product product) async {
    final DocumentReference<Map<String, dynamic>> docRef =
        await _productsRef.add(product.toMap());
    return docRef.id;
  }

  /// Cập nhật thông tin sản phẩm hiện có theo Document ID.
  Future<void> updateProduct(Product product) async {
    if (product.id.isEmpty) {
      throw ArgumentError('Product ID không được rỗng khi cập nhật.');
    }
    await _productsRef.doc(product.id).update(product.toMap());
  }

  /// Xóa sản phẩm theo Document ID.
  Future<void> deleteProduct(String productId) async {
    if (productId.isEmpty) {
      throw ArgumentError('Product ID không được rỗng khi xóa.');
    }
    await _productsRef.doc(productId).delete();
  }

  /// Lọc theo tên và sắp xếp danh sách sản phẩm theo giá (tính trên dữ liệu hiện có).
  static List<Product> filterAndSortProducts({
    required List<Product> products,
    required String searchQuery,
    required ProductSortOrder sortOrder,
  }) {
    final String normalizedQuery = searchQuery.trim().toLowerCase();

    final List<Product> filtered = normalizedQuery.isEmpty
        ? List<Product>.from(products)
        : products
            .where(
              (product) =>
                  product.name.toLowerCase().contains(normalizedQuery),
            )
            .toList();

    switch (sortOrder) {
      case ProductSortOrder.priceAsc:
        filtered.sort((a, b) => a.price.compareTo(b.price));
        break;
      case ProductSortOrder.priceDesc:
        filtered.sort((a, b) => b.price.compareTo(a.price));
        break;
      case ProductSortOrder.none:
        break;
    }

    return filtered;
  }
}
