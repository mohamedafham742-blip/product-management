import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'main_navigation_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'admin@example.com');
  final _passwordController = TextEditingController(text: 'password123');
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await ApiService().login(
      _emailController.text,
      _passwordController.text,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else {
      setState(() {
        _errorMessage = result['message'] ?? 'Authentication failed.';
      });
    }
  }

  void _showServerConfigDialog() {
    final urlController = TextEditingController(text: ApiService().baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'API Server URL',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF2E2825)),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select a preset or enter your backend server address:',
                style: TextStyle(fontSize: 12, color: Color(0xFF7D716A)),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  ActionChip(
                    label: const Text('Wi-Fi (192.168.1.10)', style: TextStyle(fontSize: 10)),
                    backgroundColor: const Color(0xFFFAF5F0),
                    onPressed: () {
                      urlController.text = 'http://192.168.1.10:8000/api';
                    },
                  ),
                  ActionChip(
                    label: const Text('USB Cable (127.0.0.1)', style: TextStyle(fontSize: 10)),
                    backgroundColor: const Color(0xFFFAF5F0),
                    onPressed: () {
                      urlController.text = 'http://127.0.0.1:8000/api';
                    },
                  ),
                  ActionChip(
                    label: const Text('Emulator (10.0.2.2)', style: TextStyle(fontSize: 10)),
                    backgroundColor: const Color(0xFFFAF5F0),
                    onPressed: () {
                      urlController.text = 'http://10.0.2.2:8000/api';
                    },
                  ),
                  ActionChip(
                    label: const Text('Wi-Fi (192.168.1.8)', style: TextStyle(fontSize: 10)),
                    backgroundColor: const Color(0xFFFAF5F0),
                    onPressed: () {
                      urlController.text = 'http://192.168.1.8:8000/api';
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: urlController,
                decoration: InputDecoration(
                  hintText: 'http://192.168.1.3:8000/api',
                  filled: true,
                  fillColor: const Color(0xFFFAF7F4),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5D8CF)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                style: const TextStyle(fontSize: 13, fontFamily: 'monospace'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF7D716A))),
            ),
            ElevatedButton(
              onPressed: () async {
                await ApiService().setBaseUrl(urlController.text.trim());
                if (ctx.mounted) Navigator.pop(ctx);
                setState(() {});
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3D3835),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save URL'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F4),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF7D716A), size: 20),
            tooltip: 'Server Settings',
            onPressed: _showServerConfigDialog,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brand Logo Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFF3D3835),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3D3835).withValues(alpha: 0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 16),

                // Title
                const Text(
                  'PRODUCT SYSTEM',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2,
                    color: Color(0xFF2E2825),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mobile Client',
                  style: TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    color: Color(0xFF8C7F77),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 32),

                // Card Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: const Color(0xFFE5D8CF)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD7C4BA).withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Error message banner
                        if (_errorMessage != null) ...[
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFAF0EE),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: const Color(0xFFEBCAC4)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline, color: Color(0xFFA63628), size: 18),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _errorMessage!,
                                    style: const TextStyle(fontSize: 12, color: Color(0xFFA63628)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Email Field
                        const Text(
                          'EMAIL ADDRESS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Color(0xFF5A4F48),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.mail_outline, size: 18, color: Color(0xFF9E9087)),
                            hintText: 'name@company.com',
                            filled: true,
                            fillColor: const Color(0xFFFAF7F4),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Email is required';
                            if (!val.contains('@')) return 'Invalid email format';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Password Field
                        const Text(
                          'PASSWORD',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: Color(0xFF5A4F48),
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.lock_outline, size: 18, color: Color(0xFF9E9087)),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                size: 18,
                                color: const Color(0xFF9E9087),
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            hintText: '••••••••',
                            filled: true,
                            fillColor: const Color(0xFFFAF7F4),
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
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Password is required';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3D3835),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                    ),
                                  )
                                : const Text(
                                    'SIGN IN',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Server Target Link
                        InkWell(
                          onTap: _showServerConfigDialog,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.link, size: 14, color: Color(0xFF8C7F77)),
                                const SizedBox(width: 4),
                                Text(
                                  ApiService().baseUrl,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF8C7F77),
                                    fontFamily: 'monospace',
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
