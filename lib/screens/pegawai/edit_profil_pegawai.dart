// lib/screens/pegawai/edit_profil_pegawai.dart

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/database_helper.dart';
import '../../models/user_model.dart';

class EditProfilPegawai extends StatefulWidget {
  final int userId;
  const EditProfilPegawai({super.key, required this.userId});

  @override
  State<EditProfilPegawai> createState() => _EditProfilPegawaiState();
}

class _EditProfilPegawaiState extends State<EditProfilPegawai> {
  final _namaCtrl = TextEditingController();
  final _noHpCtrl = TextEditingController();
  final _jabatanCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  UserModel? _user;
  bool _isLoading = false;
  String? _fotoProfilPath;

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = widget.userId;
    final db = DatabaseHelper.instance;
    final user = await db.getUserById(userId);
    
    if (user != null) {
      setState(() {
        _user = user;
        _namaCtrl.text = user.nama;
        _noHpCtrl.text = user.noHp ?? '';
        _jabatanCtrl.text = user.jabatan ?? '';
        _fotoProfilPath = user.fotoProfil;
      });
    } else {
      _namaCtrl.text = prefs.getString('user_nama') ?? '';
    }
  }

  Future<void> _pilihFoto() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _fotoProfilPath = pickedFile.path;
      });
    }
  }

  Future<void> _simpan() async {
    if (_namaCtrl.text.trim().isEmpty) {
      Get.snackbar('Peringatan', 'Nama tidak boleh kosong',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    
    if (_passwordCtrl.text.isNotEmpty && _passwordCtrl.text.length < 6) {
      Get.snackbar('Peringatan', 'Password baru minimal 6 karakter',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }

    if (_user == null) return;

    setState(() => _isLoading = true);

    final updatedUser = UserModel(
      id: _user!.id,
      nama: _namaCtrl.text.trim(),
      email: _user!.email,
      password: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : _user!.password,
      role: _user!.role,
      noHp: _noHpCtrl.text.trim(),
      jabatan: _jabatanCtrl.text.trim(),
      fotoProfil: _fotoProfilPath,
    );

    await DatabaseHelper.instance.updateUser(updatedUser);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_nama', updatedUser.nama);

    setState(() => _isLoading = false);
    Get.snackbar('Berhasil', 'Profil berhasil diperbarui',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Avatar
            Center(
              child: GestureDetector(
                onTap: _pilihFoto,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 52,
                      backgroundColor: const Color(0xFF009688),
                      backgroundImage: _fotoProfilPath != null && _fotoProfilPath!.isNotEmpty
                          ? FileImage(File(_fotoProfilPath!))
                          : null,
                      child: _fotoProfilPath == null || _fotoProfilPath!.isEmpty
                          ? Text(
                              _namaCtrl.text.isNotEmpty
                                  ? _namaCtrl.text[0].toUpperCase()
                                  : 'P',
                              style: const TextStyle(
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF009688), width: 2),
                        ),
                        child: const Icon(Icons.camera_alt,
                            color: Color(0xFF009688), size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Form
            _buildField('Nama Lengkap', _namaCtrl, Icons.person_outline),
            const SizedBox(height: 16),
            _buildField('Nomor HP', _noHpCtrl, Icons.phone_outlined,
                type: TextInputType.phone),
            const SizedBox(height: 16),
            _buildField('Jabatan', _jabatanCtrl, Icons.work_outline),
            const SizedBox(height: 16),
            _buildField('Password Baru', _passwordCtrl, Icons.lock_outline,
                obscure: true, hint: 'Kosongkan jika tidak ingin ganti'),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _simpan,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.save),
              label: const Text('Simpan Perubahan',
                  style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType type = TextInputType.text,
    bool obscure = false,
    String? hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          keyboardType: type,
          obscureText: obscure,
          decoration: InputDecoration(
            prefixIcon: Icon(icon),
            hintText: hint ?? 'Masukkan $label',
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _noHpCtrl.dispose();
    _jabatanCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }
}
