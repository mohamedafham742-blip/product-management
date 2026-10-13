import 'package:flutter/material.dart';
import 'dashboard_screen.dart';
import 'product_form_screen.dart';
import 'products_screen.dart';
import 'recycle_bin_screen.dart';
import 'settings_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final int initialIndex;
  const MainNavigationScreen({super.key, this.initialIndex = 0});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late int _currentIndex;
  final GlobalKey<DashboardScreenState> _dashboardKey = GlobalKey<DashboardScreenState>();
  final GlobalKey<ProductsScreenState> _productsKey = GlobalKey<ProductsScreenState>();
  final GlobalKey<RecycleBinScreenState> _recycleBinKey = GlobalKey<RecycleBinScreenState>();

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    // Automatically sync target screen when navigated to
    if (index == 0) {
      _dashboardKey.currentState?.reloadDashboard(silent: true);
    } else if (index == 1) {
      _productsKey.currentState?.reloadProducts(silent: true);
    } else if (index == 3) {
      _recycleBinKey.currentState?.reloadTrash(silent: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardScreen(
        key: _dashboardKey,
        isTab: true,
        onNavigateTab: _onTabTapped,
      ),
      ProductsScreen(
        key: _productsKey,
        isTab: true,
        onAddTap: () => _onTabTapped(2),
        onTrashTap: () => _onTabTapped(3),
      ),
      ProductFormScreen(
        isTab: true,
        onProductCreated: (newProduct) {
          // Immediately inject the product into ProductsScreen list without waiting!
          _productsKey.currentState?.addProductInstantly(newProduct);
          // And refresh dashboard stats in background
          _dashboardKey.currentState?.reloadDashboard(silent: true);
        },
        onSaved: () => _onTabTapped(1),
      ),
      RecycleBinScreen(
        key: _recycleBinKey,
        isTab: true,
        onRestored: () {
          // Auto-sync products catalog and dashboard when items are restored
          _productsKey.currentState?.reloadProducts(silent: true);
          _dashboardKey.currentState?.reloadDashboard(silent: true);
        },
      ),
      const SettingsScreen(
        isTab: true,
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: _buildFixedFooterNavBar(),
    );
  }

  Widget _buildFixedFooterNavBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          top: BorderSide(color: Color(0xFFE5D8CF), width: 1.0),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3D3835).withValues(alpha: 0.08),
            blurRadius: 16,
            spreadRadius: 1,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Dashboard',
                activeIcon: Icons.grid_view_rounded,
                inactiveIcon: Icons.grid_view_outlined,
              ),
              _buildNavItem(
                index: 1,
                label: 'Products',
                activeIcon: Icons.inventory_2_rounded,
                inactiveIcon: Icons.inventory_2_outlined,
              ),
              _buildCenterAddItem(
                index: 2,
              ),
              _buildNavItem(
                index: 3,
                label: 'Trash',
                activeIcon: Icons.delete_sweep_rounded,
                inactiveIcon: Icons.delete_sweep_outlined,
              ),
              _buildNavItem(
                index: 4,
                label: 'Settings',
                activeIcon: Icons.tune_rounded,
                inactiveIcon: Icons.tune_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    final isSelected = _currentIndex == index;
    const activeColor = Color(0xFF3D3835);
    const inactiveColor = Color(0xFF8C7F77);

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor: const Color(0xFFFAF5F0),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF3ECE4) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                size: 22,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterAddItem({required int index}) {
    final isSelected = _currentIndex == index;

    return Expanded(
      child: InkWell(
        onTap: () => _onTabTapped(index),
        splashColor: const Color(0xFFFAF5F0),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2C6E3D) : const Color(0xFF3D3835),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? const Color(0xFF2C6E3D) : const Color(0xFF3D3835))
                        .withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(
                Icons.add_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Add Item',
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? const Color(0xFF2C6E3D) : const Color(0xFF3D3835),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
