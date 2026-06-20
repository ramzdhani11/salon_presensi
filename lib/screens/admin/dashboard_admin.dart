// lib/screens/admin/dashboard_admin.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/database_helper.dart';
import '../login_screen.dart';
import 'kelola_pegawai.dart';
import 'atur_lokasi.dart';
import 'laporan_presensi.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  String _nama = '';
  List<Map<String, dynamic>> _presensiHariIni = [];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _nama = prefs.getString('user_nama') ?? 'Admin';
    final today = DateTime.now().toString().substring(0, 10);
    final data =
        await DatabaseHelper.instance.getPresensiSemuaPegawai(today);
    setState(() => _presensiHariIni = data);
  }

  Future<void> _logout() async {
    final konfirmasi = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Batal')),
          ElevatedButton(
              onPressed: () => Get.back(result: true),
              child: const Text('Logout')),
        ],
      ),
    );
    if (konfirmasi == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      Get.offAll(() => const LoginScreen());
    }
  }

  Widget _buildHomePage() {
    final today = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(DateTime.now());
    final totalHadir = _presensiHariIni.where((p) => p['status'] == 'hadir').length;
    final totalTerlambat = _presensiHariIni.where((p) => p['status'] == 'terlambat').length;
    final totalPegawai = _presensiHariIni.length;
    final totalBelumAbsen = totalPegawai - (totalHadir + totalTerlambat);

    return RefreshIndicator(
      onRefresh: _loadData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Card(
              elevation: 0,
              color: const Color(0xFF009688),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(today,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Halo, $_nama!',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _buildStatCard2('Total\nPegawai',
                            totalPegawai.toString(), Colors.white),
                        const SizedBox(width: 12),
                        _buildStatCard2('Sudah\nHadir',
                            totalHadir.toString(), Colors.greenAccent),
                        const SizedBox(width: 12),
                        _buildStatCard2(
                            'Belum\nAbsen',
                            totalBelumAbsen.toString(),
                            Colors.orangeAccent),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Menu cepat
            const Text('Menu',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildMenuCard(Icons.people, 'Kelola\nPegawai',
                    Colors.purple, () => Get.to(() => const KelolaPegawai())),
                const SizedBox(width: 12),
                _buildMenuCard(Icons.location_on, 'Atur\nLokasi',
                    Colors.teal, () => Get.to(() => const AturLokasi())),
                const SizedBox(width: 12),
                _buildMenuCard(Icons.bar_chart, 'Laporan\nPresensi',
                    Colors.orange,
                    () => Get.to(() => const LaporanPresensi())),
              ],
            ),
            const SizedBox(height: 24),

            // Presensi hari ini
            const Text('Kehadiran Hari Ini',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_presensiHariIni.isEmpty)
              const Center(child: Text('Belum ada data pegawai'))
            else
              ...(_presensiHariIni.map((p) => _buildPegawaiCard(p))),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard2(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 11),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      IconData icon, String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey[200]!),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 8),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: color.withOpacity(0.15),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(height: 8),
                Text(label,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPegawaiCard(Map<String, dynamic> p) {
    final sudahHadir = p['jam_masuk'] != null;
    final status = p['status'] ?? 'belum_absen';
    Color statusColor = sudahHadir
        ? (status == 'terlambat' ? Colors.orange : Colors.green)
        : Colors.grey;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF009688).withOpacity(0.15),
          child: Text(
            (p['nama'] as String).isNotEmpty
                ? (p['nama'] as String)[0].toUpperCase()
                : '?',
            style: const TextStyle(
                color: Color(0xFF009688), fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(p['nama'] ?? '-',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(p['jabatan'] ?? '-'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(p['jam_masuk'] ?? '--:--',
                style: const TextStyle(fontWeight: FontWeight.bold)),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                sudahHadir
                    ? status.replaceAll('_', ' ').toUpperCase()
                    : 'BELUM',
                style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomePage(),
      const LaporanPresensi(),
      const KelolaPegawai(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard Admin'),
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: 'Dashboard'),
          NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Laporan'),
          NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Pegawai'),
        ],
      ),
    );
  }
}
