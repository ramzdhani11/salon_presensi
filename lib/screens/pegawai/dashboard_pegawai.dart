// lib/screens/pegawai/dashboard_pegawai.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../../services/database_helper.dart';
import '../../services/location_service.dart';
import '../../models/presensi_model.dart';
import '../login_screen.dart';
import 'histori_presensi.dart';
import 'edit_profil_pegawai.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class DashboardPegawai extends StatefulWidget {
  const DashboardPegawai({super.key});

  @override
  State<DashboardPegawai> createState() => _DashboardPegawaiState();
}

class _DashboardPegawaiState extends State<DashboardPegawai> {
  String _nama = '';
  int _userId = 0;
  PresensiModel? _presensiHariIni;
  bool _isLoadingAbsen = false;
  int _currentIndex = 0;
  
  LatLng? _userLocation;
  Map<String, dynamic>? _salonLokasi;
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id') ?? 0;
    _nama = prefs.getString('user_nama') ?? '';
    final presensi =
        await DatabaseHelper.instance.getPresensiHariIni(_userId);
    final lokasi = await DatabaseHelper.instance.getLokasiSalon();
    setState(() {
      _presensiHariIni = presensi;
      _salonLokasi = lokasi;
    });

    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      setState(() {
        _userLocation = LatLng(position.latitude, position.longitude);
      });
      // _mapController.move tidak diperlukan di sini karena MapOptions sudah menggunakan
      // initialCenter: _userLocation! yang otomatis memposisikan peta saat pertama kali dirender.
    }
  }

  Future<void> _checkIn() async {
    setState(() => _isLoadingAbsen = true);

    // Dapatkan posisi GPS
    final position = await LocationService.getCurrentPosition();
    if (position == null) {
      Get.snackbar('GPS Error', 'Aktifkan GPS dan izinkan akses lokasi',
          backgroundColor: Colors.orange, colorText: Colors.white);
      setState(() => _isLoadingAbsen = false);
      return;
    }

    // Dapatkan lokasi salon
    final lokasiSalon = await DatabaseHelper.instance.getLokasiSalon();
    if (lokasiSalon == null) {
      Get.snackbar('Error', 'Lokasi salon belum diatur oleh admin',
          backgroundColor: Colors.red, colorText: Colors.white);
      setState(() => _isLoadingAbsen = false);
      return;
    }

    // Validasi radius
    final dalamRadius = LocationService.dalamRadius(
      userLat: position.latitude,
      userLng: position.longitude,
      salonLat: lokasiSalon['latitude'],
      salonLng: lokasiSalon['longitude'],
      radiusMeter: lokasiSalon['radius_meter'],
    );

    if (!dalamRadius) {
      final jarak = LocationService.hitungJarak(
        position.latitude, position.longitude,
        lokasiSalon['latitude'], lokasiSalon['longitude'],
      ).toStringAsFixed(0);
      Get.snackbar(
        'Lokasi Di Luar Area',
        'Anda berada ${jarak}m dari salon. Maksimal ${lokasiSalon['radius_meter'].toInt()}m.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
      );
      setState(() => _isLoadingAbsen = false);
      return;
    }

    await DatabaseHelper.instance
        .checkIn(_userId, position.latitude, position.longitude);
    await _loadData();
    setState(() => _isLoadingAbsen = false);

    Get.snackbar('Check-In Berhasil', 'Selamat bekerja, $_nama!',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  Future<void> _checkOut() async {
    setState(() => _isLoadingAbsen = true);
    await DatabaseHelper.instance.checkOut(_userId);
    await _loadData();
    setState(() => _isLoadingAbsen = false);
    Get.snackbar('Check-Out Berhasil', 'Sampai jumpa, $_nama!',
        backgroundColor: Colors.blue, colorText: Colors.white);
  }

  Future<void> _logout() async {
    final konfirmasi = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Logout'),
        content: const Text('Yakin ingin keluar?'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false),
              child: const Text('Batal')),
          ElevatedButton(onPressed: () => Get.back(result: true),
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

  Widget _buildStatusCard() {
    final now = DateTime.now();
    final tanggal = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    final sudahMasuk = _presensiHariIni?.jamMasuk != null;
    final sudahKeluar = _presensiHariIni?.jamKeluar != null;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: const Color(0xFF009688),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(tanggal,
                style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 4),
            Text('Halo, $_nama!',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoChip(
                    Icons.login, 'Masuk',
                    _presensiHariIni?.jamMasuk ?? '--:--'),
                const SizedBox(width: 12),
                _buildInfoChip(
                    Icons.logout, 'Keluar',
                    _presensiHariIni?.jamKeluar ?? '--:--'),
                const SizedBox(width: 12),
                _buildInfoChip(
                    Icons.timer, 'Total',
                    _presensiHariIni?.totalJamKerja ?? '-'),
              ],
            ),
            const SizedBox(height: 16),
            // Status badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusLabel(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor() {
    if (_presensiHariIni?.jamKeluar != null) return Colors.blue;
    if (_presensiHariIni?.status == 'terlambat') return Colors.orange;
    if (_presensiHariIni?.status == 'hadir') return Colors.green;
    return Colors.white24;
  }

  String _getStatusLabel() {
    if (_presensiHariIni?.jamKeluar != null) return 'Sudah Check-Out';
    if (_presensiHariIni?.status == 'terlambat') return 'Terlambat';
    if (_presensiHariIni?.status == 'hadir') return 'Hadir';
    return 'Belum Absen';
  }

  Widget _buildInfoChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTombolAbsen() {
    final sudahMasuk = _presensiHariIni?.jamMasuk != null;
    final sudahKeluar = _presensiHariIni?.jamKeluar != null;

    if (sudahKeluar) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.blue),
            SizedBox(width: 8),
            Text('Presensi hari ini selesai',
                style: TextStyle(
                    color: Colors.blue, fontWeight: FontWeight.w600)),
          ],
        ),
      );
    }

    return Column(
      children: [
        if (!sudahMasuk)
          ElevatedButton.icon(
            onPressed: _isLoadingAbsen ? null : _checkIn,
            icon: _isLoadingAbsen
                ? const SizedBox(
                    width: 18, height: 18,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.location_on),
            label: const Text('Check-In Sekarang', style: TextStyle(fontSize: 16)),
          ),
        if (sudahMasuk && !sudahKeluar) ...[
          ElevatedButton.icon(
            onPressed: _isLoadingAbsen ? null : _checkOut,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              minimumSize: const Size(double.infinity, 52),
            ),
            icon: const Icon(Icons.logout),
            label: const Text('Check-Out Sekarang',
                style: TextStyle(fontSize: 16)),
          ),
        ],
      ],
    );
  }

  Widget _buildMap() {
    if (_salonLokasi == null || _userLocation == null) {
      return const SizedBox(
        height: 250,
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Mencari lokasi Anda...')
          ],
        )),
      );
    }

    final salonLatLng = LatLng(
      _salonLokasi!['latitude'],
      _salonLokasi!['longitude'],
    );
    final radius = _salonLokasi!['radius_meter'] as num;

    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 5))
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _userLocation!,
              initialZoom: 17.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.salon_presensi',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: salonLatLng,
                    color: Colors.blue.withOpacity(0.2),
                    borderColor: Colors.blue,
                    borderStrokeWidth: 2,
                    useRadiusInMeter: true,
                    radius: radius.toDouble(),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Marker Salon
                  Marker(
                    point: salonLatLng,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.store, color: Colors.blue, size: 40),
                  ),
                  // Marker Pegawai
                  Marker(
                    point: _userLocation!,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.person_pin_circle,
                        color: Color(0xFF009688), size: 40),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: _buildTombolAbsen(),
          ),
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              backgroundColor: Colors.white,
              child: const Icon(Icons.my_location, color: Colors.blue),
              onPressed: () {
                if (_userLocation != null) {
                  _mapController.move(_userLocation!, 17.0);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      // Home
      RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatusCard(),
              const SizedBox(height: 20),
              const Text('Lokasi Saat Ini',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildMap(),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text('Histori Terbaru',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Spacer(),
                  TextButton(
                    onPressed: () =>
                        Get.to(() => HistoriPresensi(userId: _userId)),
                    child: const Text('Lihat Semua'),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FutureBuilder(
                future: DatabaseHelper.instance
                    .getHistoriPresensi(_userId, limit: 5),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  final data = snapshot.data!;
                  if (data.isEmpty) {
                    return const Center(
                        child: Text('Belum ada histori presensi'));
                  }
                  return Column(
                    children: data
                        .map((p) => _buildHistoriItem(p))
                        .toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
      // Histori
      HistoriPresensi(userId: _userId),
      // Edit Profil
      EditProfilPegawai(userId: _userId),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Salon'),
        actions: [
          IconButton(
              icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda'),
          NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: 'Histori'),
          NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil'),
        ],
      ),
    );
  }

  Widget _buildHistoriItem(PresensiModel p) {
    Color statusColor = Colors.grey;
    if (p.status == 'hadir') statusColor = Colors.green;
    if (p.status == 'terlambat') statusColor = Colors.orange;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.15),
          child: Icon(Icons.calendar_today, color: statusColor, size: 18),
        ),
        title: Text(p.tanggal,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(
            '${p.jamMasuk ?? '--:--'} - ${p.jamKeluar ?? '--:--'} | ${p.totalJamKerja}'),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            p.status.replaceAll('_', ' ').toUpperCase(),
            style: TextStyle(
                color: statusColor,
                fontSize: 10,
                fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }
}
