// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/database_helper.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _namaCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _hpCtrl = TextEditingController();
  final _jabatanCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  Future<void> _register() async {
    if (_namaCtrl.text.isEmpty ||
        _emailCtrl.text.isEmpty ||
        _passwordCtrl.text.isEmpty ||
        _jabatanCtrl.text.isEmpty) {
      Get.snackbar('Peringatan', 'Harap isi semua field yang wajib',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    setState(() => _isLoading = true);

    try {
      final newUser = UserModel(
        nama: _namaCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        role: 'pegawai',
        jabatan: _jabatanCtrl.text.trim(),
        noHp: _hpCtrl.text.trim(),
      );

      await DatabaseHelper.instance.insertUser(newUser);

      Get.snackbar('Sukses', 'Registrasi berhasil. Silakan login.',
          backgroundColor: Colors.green, colorText: Colors.white);
      Get.back(); // Kembali ke halaman login
    } catch (e) {
      Get.snackbar('Error', 'Gagal mendaftar. Email mungkin sudah digunakan.',
          backgroundColor: Colors.red, colorText: Colors.white);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black87,
        title: const Text('Daftar Akun Baru'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Lengkapi Profil',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text('Bergabunglah dengan presensi salon kami',
                  style: TextStyle(color: Colors.black54)),
              const SizedBox(height: 32),

              // Form field
              _buildLabel('Nama Lengkap *'),
              _buildTextField(_namaCtrl, 'Contoh: Rina Melati', Icons.person),
              
              const SizedBox(height: 16),
              _buildLabel('Email *'),
              _buildTextField(_emailCtrl, 'Contoh: rina@salon.com', Icons.email,
                  type: TextInputType.emailAddress),
              
              const SizedBox(height: 16),
              _buildLabel('Password *'),
              TextField(
                controller: _passwordCtrl,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: 'Minimal 6 karakter',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              _buildLabel('Jabatan *'),
              _buildTextField(_jabatanCtrl, 'Contoh: Stylist, Kasir', Icons.work),
              
              const SizedBox(height: 16),
              _buildLabel('Nomor HP (Opsional)'),
              _buildTextField(_hpCtrl, 'Contoh: 0812...', Icons.phone,
                  type: TextInputType.phone),

              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _register,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Daftar Sekarang',
                        style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      keyboardType: type,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
      ),
    );
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _jabatanCtrl.dispose();
    _hpCtrl.dispose();
    super.dispose();
  }
}
