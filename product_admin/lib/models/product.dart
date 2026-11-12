import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Model đại diện cho một sản phẩm trong collection `products`.
///
/// Theo yêu cầu bắt buộc, mỗi document Firestore CHỈ chứa đúng 4 trường:
/// `name`, `price`, `soluong`, `image`.
class Product {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    required this.soluong,
    required this.image,
  });

  /// ID của document trên Firestore (chỉ dùng trong app, không lưu thành field).
  final String id;
  final String name;
  final double price;
  final int soluong;
  final String image;

  /// Tạo [Product] từ DocumentSnapshot của Firestore.
  factory Product.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return Product.fromMap(doc.id, data);
  }

  /// Tạo [Product] từ Map dữ liệu và document ID.
  factory Product.fromMap(String id, Map<String, dynamic> map) {
    final dynamic rawPrice = map['price'];
    final dynamic rawQuantity = map['soluong'];

    final double parsedPrice = rawPrice is num
        ? rawPrice.toDouble()
        : double.tryParse(rawPrice?.toString() ?? '') ?? 0;

    final int parsedQuantity = rawQuantity is num
        ? rawQuantity.toInt()
        : int.tryParse(rawQuantity?.toString() ?? '') ?? 0;

    return Product(
      id: id,
      name: (map['name'] ?? '').toString(),
      price: parsedPrice,
      soluong: parsedQuantity,
      image: (map['image'] ?? '').toString(),
    );
  }

  /// Chuyển [Product] thành Map để lưu lên Firestore.
  ///
  /// CHỈ trả về đúng 4 trường: `name`, `price`, `soluong`, `image`.
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'name': name.trim(),
      'price': price % 1 == 0 ? price.toInt() : price,
      'soluong': soluong,
      'image': image.trim(),
    };
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    int? soluong,
    String? image,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      soluong: soluong ?? this.soluong,
      image: image ?? this.image,
    );
  }

  /// Định dạng giá tiền theo chuẩn VNĐ (ví dụ: `30.000.000 đ`).
  String get formattedPrice => formatVnd(price);

  /// Định dạng một số tiền bất kỳ sang chuỗi VNĐ dễ đọc.
  static String formatVnd(num amount) {
    final String formatted = NumberFormat('#,##0', 'en_US')
        .format(amount.round())
        .replaceAll(',', '.');
    return '$formatted đ';
  }
}

