// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/database_helper.dart';
import 'pegawai/dashboard_pegawai.dart';
import 'admin/dashboard_admin.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _login() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      Get.snackbar('Peringatan', 'Email dan password wajib diisi',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);

    final user = await DatabaseHelper.instance.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );

    setState(() => _isLoading = false);

    if (user == null) {
      Get.snackbar('Login Gagal', 'Email atau password salah',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    // Simpan session
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('user_id', user.id!);
    await prefs.setString('user_role', user.role);
    await prefs.setString('user_nama', user.nama);

    if (user.role == 'admin') {
      Get.off(() => const DashboardAdmin());
    } else {
      Get.off(() => const DashboardPegawai());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 24),
        child: Text(
          '© 2026 SALON PRESENSI',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header teal
            Container(
              height: 260,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFF009688),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.content_cut,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Salon Presensi',
                      style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                  const Text('Masuk ke akun Anda',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                ],
              ),
            ),

            // Form login
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  const Text('Email',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'contoh@salon.com',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Password',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _passwordCtrl,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Masukkan password',
                      prefixIcon: const Icon(Icons.lock_outlined),
                      suffixIcon: IconButton(
                        icon: Icon(_obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Text('Masuk',
                            style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _lupaPassword,
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('Lupa Password?',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      TextButton(
                        onPressed: () => Get.to(() => const RegisterScreen()),
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text('Belum punya akun? Daftar',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _lupaPassword() async {
    final emailResetCtrl = TextEditingController();
    final newPasswordCtrl = TextEditingController();
    final confirmPasswordCtrl = TextEditingController();
    bool obscureNew = true;
    bool obscureConfirm = true;

    await Get.dialog(
      StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Reset Password'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Masukkan email akun Anda beserta password baru yang diinginkan.'),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailResetCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: newPasswordCtrl,
                    obscureText: obscureNew,
                    decoration: InputDecoration(
                      labelText: 'Password Baru',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setStateDialog(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: confirmPasswordCtrl,
                    obscureText: obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Konfirmasi Password Baru',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility),
                        onPressed: () => setStateDialog(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final email = emailResetCtrl.text.trim();
                  final newPass = newPasswordCtrl.text.trim();
                  final confirmPass = confirmPasswordCtrl.text.trim();

                  // Validasi
                  if (email.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                    Get.snackbar('Peringatan', 'Harap isi semua bidang',
                        backgroundColor: Colors.orange, colorText: Colors.white);
                    return;
                  }
                  if (newPass.length < 6) {
                    Get.snackbar('Peringatan', 'Password baru minimal 6 karakter',
                        backgroundColor: Colors.orange, colorText: Colors.white);
                    return;
                  }
                  if (newPass != confirmPass) {
                    Get.snackbar('Peringatan', 'Konfirmasi password tidak cocok',
                        backgroundColor: Colors.orange, colorText: Colors.white);
                    return;
                  }

                  final user = await DatabaseHelper.instance.getUserByEmail(email);
                  if (user != null) {
                    final updatedUser = user.copyWith(password: newPass);
                    await DatabaseHelper.instance.updateUser(updatedUser);
                    Get.back();
                    Get.snackbar('Berhasil', 'Password berhasil diubah. Silakan login.',
                        backgroundColor: Colors.green, colorText: Colors.white, duration: const Duration(seconds: 4));
                  } else {
                    Get.snackbar('Gagal', 'Email tidak ditemukan di sistem.',
                        backgroundColor: Colors.red, colorText: Colors.white);
                  }
                },
                child: const Text('Reset'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}
