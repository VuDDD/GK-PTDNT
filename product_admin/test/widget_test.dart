import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:product_admin/models/product.dart';
import 'package:product_admin/screens/edit_product_screen.dart';
import 'package:product_admin/screens/product_list_screen.dart';
import 'package:product_admin/services/product_service.dart';
import 'package:product_admin/utils/validators.dart';
import 'package:product_admin/widgets/product_card.dart';
import 'package:product_admin/widgets/product_form.dart';

void main() {
  group('Product model', () {
    test('toMap chi chua dung 4 truong name, price, soluong, image', () {
      const Product product = Product(
        id: 'doc-123',
        name: '  iPhone 16 Pro Max  ',
        price: 30000000,
        soluong: 10,
        image: ' https://example.com/iphone.jpg ',
      );

      final Map<String, dynamic> map = product.toMap();

      expect(map.keys.toSet(), {'name', 'price', 'soluong', 'image'});
      expect(map['name'], 'iPhone 16 Pro Max');
      expect(map['price'], 30000000);
      expect(map['soluong'], 10);
      expect(map['image'], 'https://example.com/iphone.jpg');
      expect(map.containsKey('id'), isFalse);
    });

    test('fromMap doc dung du lieu so va chuoi', () {
      final Product product = Product.fromMap('abc', <String, dynamic>{
        'name': 'MacBook Air M3',
        'price': 27500000,
        'soluong': 5,
        'image': 'https://example.com/macbook.jpg',
      });

      expect(product.id, 'abc');
      expect(product.name, 'MacBook Air M3');
      expect(product.price, 27500000);
      expect(product.soluong, 5);
      expect(product.formattedPrice, '27.500.000 đ');
    });
  });

  group('Validators', () {
    test('validateProductName khong cho phep rong', () {
      expect(Validators.validateProductName(''), isNotNull);
      expect(Validators.validateProductName('   '), isNotNull);
      expect(Validators.validateProductName('A'), isNotNull);
      expect(Validators.validateProductName('iPad Pro'), isNull);
    });

    test('validatePrice bat buoc lon hon 0', () {
      expect(Validators.validatePrice(''), isNotNull);
      expect(Validators.validatePrice('0'), isNotNull);
      expect(Validators.validatePrice('-100'), isNotNull);
      expect(Validators.validatePrice('abc'), isNotNull);
      expect(Validators.validatePrice('150000'), isNull);
    });

    test('validateQuantity bat buoc >= 0 va la so nguyen', () {
      expect(Validators.validateQuantity(''), isNotNull);
      expect(Validators.validateQuantity('-1'), isNotNull);
      expect(Validators.validateQuantity('1.5'), isNotNull);
      expect(Validators.validateQuantity('0'), isNull);
      expect(Validators.validateQuantity('12'), isNull);
    });

    test('validateEmail va validatePassword kiem tra dung dinh dang', () {
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail('khong-hop-le'), isNotNull);
      expect(Validators.validateEmail('admin@productadmin.com'), isNull);

      expect(Validators.validatePassword(''), isNotNull);
      expect(Validators.validatePassword('12345'), isNotNull);
      expect(Validators.validatePassword('123456'), isNull);
    });
  });

  group('ProductService.filterAndSortProducts', () {
    const List<Product> sample = [
      Product(id: '1', name: 'Tai nghe AirPods', price: 4500000, soluong: 15, image: ''),
      Product(id: '2', name: 'iPhone 16 Pro Max', price: 30000000, soluong: 10, image: ''),
      Product(id: '3', name: 'Chuot Logitech', price: 1200000, soluong: 20, image: ''),
    ];

    test('loc theo ten khong phan biet hoa thuong', () {
      final List<Product> result = ProductService.filterAndSortProducts(
        products: sample,
        searchQuery: 'iphone',
        sortOrder: ProductSortOrder.none,
      );
      expect(result.length, 1);
      expect(result.first.id, '2');
    });

    test('sap xep gia tang dan va giam dan', () {
      final List<Product> asc = ProductService.filterAndSortProducts(
        products: sample,
        searchQuery: '',
        sortOrder: ProductSortOrder.priceAsc,
      );
      expect(asc.map((p) => p.id).toList(), ['3', '1', '2']);

      final List<Product> desc = ProductService.filterAndSortProducts(
        products: sample,
        searchQuery: '',
        sortOrder: ProductSortOrder.priceDesc,
      );
      expect(desc.map((p) => p.id).toList(), ['2', '1', '3']);
    });
  });

  group('Widget tests', () {
    testWidgets('ProductListScreen hien thi thong bao khi danh sach trong', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: ProductListScreen(
            productsOverride: <Product>[],
          ),
        ),
      );

      expect(find.text('Chưa có sản phẩm nào trong kho'), findsOneWidget);
    });

    testWidgets('ProductListScreen tim kiem va hien thi bang tren man hinh rong', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const List<Product> items = [
        Product(id: '1', name: 'iPhone 16 Pro Max', price: 30000000, soluong: 10, image: ''),
        Product(id: '2', name: 'Samsung S25 Ultra', price: 28000000, soluong: 8, image: ''),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: ProductListScreen(productsOverride: items),
        ),
      );

      expect(find.byType(DataTable), findsOneWidget);
      expect(find.text('iPhone 16 Pro Max'), findsOneWidget);
      expect(find.text('Samsung S25 Ultra'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'Samsung');
      await tester.pump();

      expect(find.text('iPhone 16 Pro Max'), findsNothing);
      expect(find.text('Samsung S25 Ultra'), findsOneWidget);
    });

    testWidgets('ProductForm bao loi khi bo trong du lieu va chua chon anh', (
      WidgetTester tester,
    ) async {
      bool submitted = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProductForm(
                submitLabel: 'Thêm sản phẩm',
                onSubmit: (_) async {
                  submitted = true;
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Thêm sản phẩm'));
      await tester.pump();

      expect(submitted, isFalse);
      expect(find.text('Tên sản phẩm không được để trống'), findsOneWidget);
      expect(find.text('Vui lòng nhập giá sản phẩm'), findsOneWidget);
      expect(find.text('Vui lòng nhập số lượng sản phẩm'), findsOneWidget);
      expect(find.text('Vui lòng chọn hình ảnh sản phẩm từ thiết bị.'), findsOneWidget);
    });

    testWidgets('ProductListScreen hien thi ProductCard tren man hinh Android hep', (
      WidgetTester tester,
    ) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const List<Product> items = [
        Product(id: '1', name: 'iPhone 16 Pro Max', price: 30000000, soluong: 10, image: ''),
      ];

      await tester.pumpWidget(
        const MaterialApp(
          home: ProductListScreen(productsOverride: items),
        ),
      );

      expect(find.byType(ProductCard), findsOneWidget);
      expect(find.byType(DataTable), findsNothing);
      expect(find.text('Số lượng: 10'), findsOneWidget);
    });

    testWidgets('EditProductScreen dien san du lieu san pham hien tai', (
      WidgetTester tester,
    ) async {
      const Product existing = Product(
        id: 'p1',
        name: 'MacBook Pro M4',
        price: 42000000,
        soluong: 3,
        image: '',
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: EditProductScreen(product: existing),
        ),
      );

      expect(find.text('MacBook Pro M4'), findsOneWidget);
      expect(find.text('42000000'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('Lưu thay đổi'), findsOneWidget);
    });
  });
}
