import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'recycle_bin_screen.dart';

class SettingsScreen extends StatefulWidget {
  final bool isTab;
  const SettingsScreen({super.key, this.isTab = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserModel? _user;
  late TextEditingController _urlController;
  bool _isTesting = false;
  String? _testResult;
  bool? _testSuccess;

  @override
  void initState() {
    super.initState();
    _user = ApiService().currentUser;
    _urlController = TextEditingController(text: ApiService().baseUrl);
    _loadProfile();
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = await ApiService().getUserProfile();
    if (mounted && user != null) {
      setState(() => _user = user);
    }
  }

  Future<void> _handleTestAndSaveUrl() async {
    setState(() {
      _isTesting = true;
      _testResult = null;
      _testSuccess = null;
    });

    final targetUrl = _urlController.text.trim();
    final result = await ApiService().testConnection(targetUrl);

    if (!mounted) return;

    if (result['success'] == true) {
      await ApiService().setBaseUrl(targetUrl);
      if (!mounted) return;
      setState(() {
        _isTesting = false;
        _testSuccess = true;
        _testResult = 'Success: ${result['message']}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Server URL verified & saved successfully!'),
          backgroundColor: Color(0xFF2C6E3D),
        ),
      );
    } else {
      setState(() {
        _isTesting = false;
        _testSuccess = false;
        _testResult = result['message'] ?? 'Connection failed';
      });
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Sign Out',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2B2623)),
        ),
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
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
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
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings & Profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF2B2623)),
            ),
            Text(
              'Account & API server configuration',
              style: TextStyle(fontSize: 11, color: Color(0xFF8C7F77)),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Card
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
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
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
                          style: const TextStyle(fontSize: 12, color: Color(0xFF7D7068)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(Icons.verified_user_outlined, size: 13, color: Color(0xFF8C7F77)),
                            const SizedBox(width: 4),
                            Text(
                              'User ID: #${user?.id ?? 1}  •  Sanctum Session',
                              style: const TextStyle(fontSize: 11, color: Color(0xFF8C7F77)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Recycle Bin Navigation Card
            InkWell(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RecycleBinScreen()),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF1EF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.delete_sweep_outlined, color: Color(0xFFA33B2E), size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Recycle Bin',
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF2B2623)),
                          ),
                          Text(
                            'Restore or permanently erase deleted items',
                            style: TextStyle(fontSize: 11, color: Color(0xFF7D7068)),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Color(0xFF8C7F77), size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Server Connection Settings Section
            const Text(
              'API SERVER CONFIGURATION',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF7D7068),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
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
                  const Text(
                    'Quick Presets (Tap to apply):',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3D3835)),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ActionChip(
                        avatar: const Icon(Icons.wifi, size: 14, color: Color(0xFF3D3835)),
                        label: const Text('Wi-Fi (192.168.1.10)', style: TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFFFAF5F0),
                        side: const BorderSide(color: Color(0xFFE5D8CF)),
                        onPressed: () {
                          _urlController.text = 'http://192.168.1.10:8000/api';
                          _handleTestAndSaveUrl();
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.cable, size: 14, color: Color(0xFF3D3835)),
                        label: const Text('USB (127.0.0.1)', style: TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFFFAF5F0),
                        side: const BorderSide(color: Color(0xFFE5D8CF)),
                        onPressed: () {
                          _urlController.text = 'http://127.0.0.1:8000/api';
                          _handleTestAndSaveUrl();
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.phone_android, size: 14, color: Color(0xFF3D3835)),
                        label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFFFAF5F0),
                        side: const BorderSide(color: Color(0xFFE5D8CF)),
                        onPressed: () {
                          _urlController.text = 'http://10.0.2.2:8000/api';
                          _handleTestAndSaveUrl();
                        },
                      ),
                      ActionChip(
                        avatar: const Icon(Icons.wifi, size: 14, color: Color(0xFF3D3835)),
                        label: const Text('Wi-Fi (192.168.1.8)', style: TextStyle(fontSize: 11)),
                        backgroundColor: const Color(0xFFFAF5F0),
                        side: const BorderSide(color: Color(0xFFE5D8CF)),
                        onPressed: () {
                          _urlController.text = 'http://192.168.1.8:8000/api';
                          _handleTestAndSaveUrl();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Text(
                    'Target Backend API URL:',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF3D3835)),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'http://192.168.1.8:8000/api',
                      filled: true,
                      fillColor: const Color(0xFFFAF7F4),
                      prefixIcon: const Icon(Icons.link, color: Color(0xFF8C7F77), size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5D8CF)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE5D8CF)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF3D3835), width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 12),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isTesting ? null : _handleTestAndSaveUrl,
                      icon: _isTesting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline, size: 18),
                      label: Text(_isTesting ? 'Testing Connection...' : 'Save & Verify Connection'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D3835),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),

                  if (_testResult != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _testSuccess == true ? const Color(0xFFEAF5ED) : const Color(0xFFFBEBE8),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _testSuccess == true ? const Color(0xFFCDE5D4) : const Color(0xFFF4C5BD),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            _testSuccess == true ? Icons.check_circle : Icons.error_outline,
                            size: 18,
                            color: _testSuccess == true ? const Color(0xFF2C6E3D) : const Color(0xFFA33B2E),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _testResult!,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: _testSuccess == true ? const Color(0xFF2C6E3D) : const Color(0xFFA33B2E),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // System & Architecture Information
            const Text(
              'APPLICATION & STACK INFO',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Color(0xFF7D7068),
              ),
            ),
            const SizedBox(height: 10),

            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE5D8CF)),
              ),
              child: const Column(
                children: [
                  _InfoRow(label: 'Mobile Framework', value: 'Flutter 3.47 (Dart)'),
                  Divider(height: 16, color: Color(0xFFF0E6DE)),
                  _InfoRow(label: 'Backend REST API', value: 'Laravel 12 (PHP 8.4)'),
                  Divider(height: 16, color: Color(0xFFF0E6DE)),
                  _InfoRow(label: 'Web Client', value: 'Svelte 5 + Inertia.js 2'),
                  Divider(height: 16, color: Color(0xFFF0E6DE)),
                  _InfoRow(label: 'Database Engine', value: 'MySQL (Port 3306)'),
                  Divider(height: 16, color: Color(0xFFF0E6DE)),
                  _InfoRow(label: 'App Build Version', value: '1.0.0+1 (Stable)'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout, size: 18, color: Color(0xFFA33B2E)),
                label: const Text(
                  'Sign Out of Account',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFFA33B2E)),
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: const BorderSide(color: Color(0xFFF4C5BD)),
                  backgroundColor: const Color(0xFFFFF9F8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF7D7068)),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF2B2623)),
        ),
      ],
    );
  }
}
