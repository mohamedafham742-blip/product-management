import 'dart:async';
import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'product_form_screen.dart';
import 'products_screen.dart';
import 'recycle_bin_screen.dart';

class DashboardScreen extends StatefulWidget {
  final bool isTab;
  final Function(int)? onNavigateTab;

  const DashboardScreen({
    super.key,
    this.isTab = false,
    this.onNavigateTab,
  });

  @override
  State<DashboardScreen> createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  UserModel? _user;
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    // Real-time auto-sync: keep dashboard KPI metrics synchronized in background
    _autoSyncTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (mounted) {
        _loadDashboardData(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }

  void reloadDashboard({bool silent = false}) {
    _loadDashboardData(silent: silent);
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
      final user = await ApiService().getUserProfile();
      if (mounted && user != null) {
        _user = user;
      }
    }

    // Load Stats from Products Endpoint
    final productsRes = await ApiService().getProducts();

    if (!mounted) return;

    setState(() {
      _user ??= ApiService().currentUser;
      if (productsRes['success'] == true) {
        _stats = productsRes['stats'] ?? {};
      }
      _isLoading = false;
    });
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2B2623))),
        content: const Text('Are you sure you want to sign out from this account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF7D716A))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFA33B2E),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await ApiService().logout();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  String _getUserInitials(String name) {
    if (name.trim().isEmpty) return 'U';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final user = _user ?? ApiService().currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isTab,
        backgroundColor: Colors.white.withValues(alpha: 0.95),
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF3D3835),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.inventory_2_outlined, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PRODUCT SYSTEM',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, letterSpacing: 1, color: Color(0xFF2B2623)),
                ),
                Text(
                  'Dashboard',
                  style: TextStyle(fontSize: 11, color: Color(0xFF8C7F77)),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Color(0xFFA33B2E), size: 20),
            tooltip: 'Sign Out',
            onPressed: _handleLogout,
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: const Color(0xFF3D3835),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // User Profile Details Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5D8CF)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFE5D8CF).withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // Avatar Circle
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF3D3835), Color(0xFF5A4F48)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Text(
                              _getUserInitials(user?.name ?? 'Admin'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Name & Email
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      user?.name ?? 'Administrator',
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2B2623),
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEAF5ED),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: const Color(0xFFCDE5D4)),
                                    ),
                                    child: const Text(
                                      'Active',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2C6E3D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                user?.email ?? 'admin@example.com',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF7D7068),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: Color(0xFFF0E6DE)),
                    const SizedBox(height: 12),

                    // User ID & API Server Connection status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_user_outlined, size: 14, color: Color(0xFF8C7F77)),
                            const SizedBox(width: 4),
                            Text(
                              'Account ID: #${user?.id ?? 1}',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF8C7F77)),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: Color(0xFF2C6E3D),
                              ),
                            ),
                            const SizedBox(width: 5),
                            const Text(
                              'Sanctum Token Active',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF2C6E3D),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // KPI Stats Section Header
              const Text(
                'INVENTORY OVERVIEW',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF7D7068),
                ),
              ),
              const SizedBox(height: 12),

              // 2x2 Metric Cards Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'TOTAL PRODUCTS',
                      value: '${_stats['total_products'] ?? 0}',
                      icon: Icons.inventory_2_outlined,
                      accentColor: const Color(0xFF3D3835),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'ACTIVE ITEMS',
                      value: '${_stats['active_products'] ?? 0}',
                      icon: Icons.check_circle_outline,
                      accentColor: const Color(0xFF2C6E3D),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      title: 'INACTIVE ITEMS',
                      value: '${_stats['inactive_products'] ?? 0}',
                      icon: Icons.pause_circle_outline,
                      accentColor: const Color(0xFF8C7D75),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildMetricCard(
                      title: 'TOTAL STOCK',
                      value: '${_stats['total_stock'] ?? 0}',
                      icon: Icons.layers_outlined,
                      accentColor: const Color(0xFF9E6517),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Quick Actions Section Header
              const Text(
                'QUICK ACTIONS & NAVIGATION',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: Color(0xFF7D7068),
                ),
              ),
              const SizedBox(height: 12),

              // Action Card 1: View Products Catalog
              _buildActionCard(
                icon: Icons.format_list_bulleted,
                title: 'Products Catalog',
                subtitle: 'Browse, search, filter, and inspect product details',
                badgeText: '${_stats['total_products'] ?? 0} Items',
                onTap: () async {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(1);
                  } else {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ProductsScreen()),
                    );
                    _loadDashboardData();
                  }
                },
              ),
              const SizedBox(height: 10),

              // Action Card 2: Create New Product
              _buildActionCard(
                icon: Icons.add_box_outlined,
                title: 'Add New Product',
                subtitle: 'Register a new product with SKU, pricing, and stock',
                badgeText: 'New',
                badgeColor: const Color(0xFFFAF5F0),
                onTap: () async {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(2);
                  } else {
                    final created = await Navigator.of(context).push<bool>(
                      MaterialPageRoute(builder: (_) => const ProductFormScreen()),
                    );
                    if (created == true) _loadDashboardData();
                  }
                },
              ),
              const SizedBox(height: 10),

              // Action Card 3: Recycle Bin
              _buildActionCard(
                icon: Icons.delete_sweep_outlined,
                title: 'Recycle Bin',
                subtitle: 'View, restore, or permanently remove deleted products',
                badgeText: 'Trash',
                badgeColor: const Color(0xFFFAF0EE),
                onTap: () async {
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(3);
                  } else {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RecycleBinScreen()),
                    );
                    _loadDashboardData();
                  }
                },
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5D8CF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5D8CF).withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: Color(0xFF8A7C73),
                ),
              ),
              Icon(icon, size: 18, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          _isLoading
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF3D3835)),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: accentColor,
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required String badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5D8CF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5D8CF).withValues(alpha: 0.25),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAF5F0),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE5D8CF)),
                  ),
                  child: Icon(icon, color: const Color(0xFF3D3835), size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF2B2623),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: badgeColor ?? const Color(0xFFFAF5F0),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: const Color(0xFFE5D8CF)),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF5C5049),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF8A7C73),
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Color(0xFFC4B5AA)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
