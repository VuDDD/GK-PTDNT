import 'package:flutter/material.dart';

import '../models/product.dart';
import '../services/auth_service.dart';
import '../services/product_service.dart';
import '../services/storage_service.dart';
import 'add_product_screen.dart';
import 'product_list_screen.dart';

/// Màn hình Dashboard chính cho Admin với Sidebar điều hướng (Web)
/// hoặc Drawer/FAB (Android), khu vực thống kê và quản lý sản phẩm.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    this.useEmulator = false,
    this.authService,
    this.productService,
    this.storageService,
  });

  final bool useEmulator;
  final AuthService? authService;
  final ProductService? productService;
  final StorageService? storageService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final AuthService _authService;
  late final ProductService _productService;
  late final StorageService _storageService;

  int _selectedSection = 0;

  @override
  void initState() {
    super.initState();
    _authService = widget.authService ?? AuthService();
    _productService = widget.productService ?? ProductService();
    _storageService = widget.storageService ?? StorageService();
  }

  Future<void> _confirmSignOut() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có muốn đăng xuất khỏi tài khoản Admin?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _authService.signOut();
    }
  }

  void _openAddProductScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddProductScreen(
          productService: _productService,
          storageService: _storageService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String adminEmail =
        _authService.currentUser?.email ?? 'Admin';

    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isDesktop = constraints.maxWidth >= 920;

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          drawer: isDesktop
              ? null
              : Drawer(
                  child: _AdminSidebar(
                    adminEmail: adminEmail,
                    selectedIndex: _selectedSection,
                    useEmulator: widget.useEmulator,
                    onSelectIndex: (index) {
                      Navigator.of(context).pop();
                      setState(() => _selectedSection = index);
                    },
                    onAddProduct: () {
                      Navigator.of(context).pop();
                      _openAddProductScreen();
                    },
                    onSignOut: () {
                      Navigator.of(context).pop();
                      _confirmSignOut();
                    },
                  ),
                ),
          floatingActionButton: isDesktop
              ? null
              : FloatingActionButton.extended(
                  onPressed: _openAddProductScreen,
                  icon: const Icon(Icons.add),
                  label: const Text('Thêm sản phẩm'),
                ),
          body: Row(
            children: [
              if (isDesktop)
                SizedBox(
                  width: 260,
                  child: _AdminSidebar(
                    adminEmail: adminEmail,
                    selectedIndex: _selectedSection,
                    useEmulator: widget.useEmulator,
                    onSelectIndex: (index) {
                      setState(() => _selectedSection = index);
                    },
                    onAddProduct: _openAddProductScreen,
                    onSignOut: _confirmSignOut,
                  ),
                ),
              Expanded(
                child: Column(
                  children: [
                    _AdminTopHeader(
                      isDesktop: isDesktop,
                      adminEmail: adminEmail,
                      useEmulator: widget.useEmulator,
                      title: _selectedSection == 0
                          ? 'Dashboard Quản Lý Sản Phẩm'
                          : 'Danh Sách Sản Phẩm',
                      onSignOut: _confirmSignOut,
                    ),
                    Expanded(
                      child: StreamBuilder<List<Product>>(
                        stream: _productService.watchProducts(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return SingleChildScrollView(
                              padding: const EdgeInsets.all(20),
                              child: _DashboardErrorBanner(
                                error: snapshot.error.toString(),
                              ),
                            );
                          }

                          if (snapshot.connectionState ==
                                  ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final List<Product> products =
                              snapshot.data ?? const <Product>[];

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (_selectedSection == 0) ...[
                                  _StatsGrid(products: products),
                                  const SizedBox(height: 20),
                                ],
                                ProductListScreen(
                                  embedded: true,
                                  productsOverride: products,
                                  productService: _productService,
                                  storageService: _storageService,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  const _AdminSidebar({
    required this.adminEmail,
    required this.selectedIndex,
    required this.useEmulator,
    required this.onSelectIndex,
    required this.onAddProduct,
    required this.onSignOut,
  });

  final String adminEmail;
  final int selectedIndex;
  final bool useEmulator;
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onAddProduct;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          right: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Product Admin',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          useEmulator ? 'Firebase Emulator' : 'Firebase Cloud',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const SizedBox(height: 12),
            _SidebarItem(
              icon: Icons.dashboard_outlined,
              selectedIcon: Icons.dashboard,
              label: 'Tổng quan Dashboard',
              selected: selectedIndex == 0,
              onTap: () => onSelectIndex(0),
            ),
            _SidebarItem(
              icon: Icons.list_alt_outlined,
              selectedIcon: Icons.list_alt,
              label: 'Danh sách sản phẩm',
              selected: selectedIndex == 1,
              onTap: () => onSelectIndex(1),
            ),
            _SidebarItem(
              icon: Icons.add_box_outlined,
              selectedIcon: Icons.add_box,
              label: 'Thêm sản phẩm mới',
              selected: false,
              onTap: onAddProduct,
            ),
            const Spacer(),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: colorScheme.primaryContainer,
                        child: Icon(
                          Icons.person_outline,
                          size: 20,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Quản trị viên',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            Text(
                              adminEmail,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: onSignOut,
                    icon: const Icon(Icons.logout, size: 18),
                    label: const Text('Đăng xuất'),
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

class _SidebarItem extends StatelessWidget {
  const _SidebarItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: ListTile(
        selected: selected,
        selectedTileColor: colorScheme.primaryContainer.withValues(alpha: 0.65),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(
          selected ? selectedIcon : icon,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
        ),
        title: Text(
          label,
          style: TextStyle(
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
            color: selected ? colorScheme.primary : colorScheme.onSurface,
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}

class _AdminTopHeader extends StatelessWidget {
  const _AdminTopHeader({
    required this.isDesktop,
    required this.adminEmail,
    required this.useEmulator,
    required this.title,
    required this.onSignOut,
  });

  final bool isDesktop;
  final String adminEmail;
  final bool useEmulator;
  final String title;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surface,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              if (!isDesktop)
                Builder(
                  builder: (ctx) => IconButton(
                    tooltip: 'Mở menu',
                    onPressed: () => Scaffold.of(ctx).openDrawer(),
                    icon: const Icon(Icons.menu),
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (isDesktop)
                      Text(
                        'Xin chào, $adminEmail',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (isDesktop)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: useEmulator
                        ? colorScheme.tertiaryContainer
                        : colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    useEmulator ? 'Emulator Mode' : 'Cloud Mode',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: useEmulator
                          ? colorScheme.onTertiaryContainer
                          : colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
              IconButton(
                tooltip: 'Đăng xuất',
                onPressed: onSignOut,
                icon: const Icon(Icons.logout),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.products});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    final int totalProducts = products.length;
    final int totalQuantity = products.fold<int>(
      0,
      (sum, product) => sum + product.soluong,
    );
    final int lowOrOutOfStock = products.where((p) => p.soluong <= 5).length;
    final double totalInventoryValue = products.fold<double>(
      0,
      (sum, product) => sum + (product.price * product.soluong),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final int crossAxisCount = width >= 980
            ? 4
            : width >= 560
                ? 2
                : 1;
        final double itemWidth =
            (width - (12 * (crossAxisCount - 1))) / crossAxisCount;

        final List<_StatCardData> stats = [
          _StatCardData(
            title: 'Tổng sản phẩm',
            value: '$totalProducts',
            subtitle: 'Mặt hàng trên Firestore',
            icon: Icons.inventory_2_outlined,
            accentColor: const Color(0xFF1D4ED8),
          ),
          _StatCardData(
            title: 'Tổng số lượng tồn',
            value: '$totalQuantity',
            subtitle: 'Tổng đơn vị trong kho',
            icon: Icons.layers_outlined,
            accentColor: const Color(0xFF0F766E),
          ),
          _StatCardData(
            title: 'Sắp hết / Hết hàng',
            value: '$lowOrOutOfStock',
            subtitle: 'Số lượng <= 5',
            icon: Icons.warning_amber_rounded,
            accentColor: const Color(0xFFB45309),
          ),
          _StatCardData(
            title: 'Tổng giá trị kho',
            value: Product.formatVnd(totalInventoryValue),
            subtitle: 'Tính từ dữ liệu hiện có',
            icon: Icons.payments_outlined,
            accentColor: const Color(0xFF6D28D9),
          ),
        ];

        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: stats
              .map(
                (item) => SizedBox(
                  width: itemWidth,
                  child: _StatCard(data: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _StatCardData {
  const _StatCardData({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.data});

  final _StatCardData data;

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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: data.accentColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.accentColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.title,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
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

class _DashboardErrorBanner extends StatelessWidget {
  const _DashboardErrorBanner({required this.error});

  final String error;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    return Card(
      elevation: 0,
      color: colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          'Lỗi kết nối Firestore: $error\n\n'
          'Hãy kiểm tra lại tài khoản Admin trong Security Rules hoặc kết nối Firebase Emulator.',
          style: TextStyle(color: colorScheme.onErrorContainer),
        ),
      ),
    );
  }
}
