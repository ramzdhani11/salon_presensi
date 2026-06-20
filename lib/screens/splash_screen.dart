// lib/screens/splash_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';
import 'pegawai/dashboard_pegawai.dart';
import 'admin/dashboard_admin.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Gunakan post frame callback agar timer 2 detik baru dimulai
    // SETELAH layar splash screen benar-benar selesai digambar (render) di layar HP.
    // Ini mencegah masalah di HP yang agak lambat (di mana proses render pertama makan waktu > 2 detik)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cekSession();
    });
  }

  Future<void> _cekSession() async {
    // Tampilkan splash minimal 2 detik
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getInt('user_id');
    final role = prefs.getString('user_role');

    if (!mounted) return;

    if (userId != null && role != null) {
      if (role == 'admin') {
        Get.off(() => const DashboardAdmin());
      } else {
        Get.off(() => const DashboardPegawai());
      }
    } else {
      Get.offNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF009688), // Tema utama salon (Teal)
      bottomNavigationBar: const Padding(
        padding: EdgeInsets.only(bottom: 24),
        child: Text(
          '© 2026 SALON PRESENSI',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white38, // Efek cahaya (glow)
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.content_cut,
                    size: 50,
                    color: Color(0xFF009688), // Ikon gunting teal jika gambar gagal
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Salon Presensi',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              width: 50,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.white, // Garis bawah diubah putih agar kontras
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Aplikasi Absensi Pegawai Salon',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 80),
            const CircularProgressIndicator(
              color: Colors.white, // Indikator diubah putih
              strokeWidth: 2,
            ),
          ],
        ),
      ),
    );
  }
}
