// lib/screens/admin/atur_lokasi.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/database_helper.dart';
import '../../services/location_service.dart';

class AturLokasi extends StatefulWidget {
  const AturLokasi({super.key});

  @override
  State<AturLokasi> createState() => _AturLokasiState();
}

class _AturLokasiState extends State<AturLokasi> {
  final _namaSalonCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  double _radius = 100;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadLokasi();
  }

  Future<void> _loadLokasi() async {
    final lokasi = await DatabaseHelper.instance.getLokasiSalon();
    if (lokasi != null) {
      _namaSalonCtrl.text = lokasi['nama_salon'] ?? '';
      _latCtrl.text = lokasi['latitude'].toString();
      _lngCtrl.text = lokasi['longitude'].toString();
      setState(() => _radius = (lokasi['radius_meter'] as num).toDouble());
    }
  }

  Future<void> _gunakanLokasiSekarang() async {
    setState(() => _isLoading = true);
    final pos = await LocationService.getCurrentPosition();
    if (pos != null) {
      setState(() {
        _latCtrl.text = pos.latitude.toStringAsFixed(6);
        _lngCtrl.text = pos.longitude.toStringAsFixed(6);
      });
      Get.snackbar('Berhasil', 'Lokasi saat ini digunakan',
          backgroundColor: Colors.green, colorText: Colors.white);
    } else {
      Get.snackbar('Error', 'Gagal mendapatkan lokasi. Aktifkan GPS.',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
    setState(() => _isLoading = false);
  }

  Future<void> _simpan() async {
    if (_namaSalonCtrl.text.isEmpty ||
        _latCtrl.text.isEmpty ||
        _lngCtrl.text.isEmpty) {
      Get.snackbar('Peringatan', 'Semua field wajib diisi',
          backgroundColor: Colors.orange, colorText: Colors.white);
      return;
    }
    await DatabaseHelper.instance.updateLokasiSalon(
      double.parse(_latCtrl.text),
      double.parse(_lngCtrl.text),
      _radius,
      _namaSalonCtrl.text,
    );
    Get.snackbar('Berhasil', 'Lokasi salon berhasil disimpan',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Atur Lokasi Salon')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Card(
              elevation: 0,
              color: Colors.teal[50],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.teal[100]!),
              ),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.teal),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Atur koordinat GPS salon dan radius area. Pegawai hanya bisa absen jika berada dalam radius ini.',
                        style: TextStyle(fontSize: 13, color: Colors.teal),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Nama Salon',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              controller: _namaSalonCtrl,
              decoration: const InputDecoration(
                hintText: 'Contoh: Salon Cantik',
                prefixIcon: Icon(Icons.store_outlined),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Koordinat GPS Salon',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                        labelText: 'Latitude',
                        prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _lngCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                        labelText: 'Longitude',
                        prefixIcon: Icon(Icons.location_on_outlined)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _gunakanLokasiSekarang,
              icon: _isLoading
                  ? const SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.my_location),
              label: const Text('Gunakan Lokasi Saat Ini'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                foregroundColor: const Color(0xFF009688),
                side: const BorderSide(color: Color(0xFF009688)),
              ),
            ),
            const SizedBox(height: 24),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Radius Area',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text('${_radius.toInt()} meter',
                    style: const TextStyle(
                        color: Color(0xFF009688),
                        fontWeight: FontWeight.bold)),
              ],
            ),
            Slider(
              value: _radius,
              min: 10,
              max: 500,
              divisions: 49,
              activeColor: const Color(0xFF009688),
              onChanged: (v) => setState(() => _radius = v),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('10m', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                Text('500m', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ),
            const SizedBox(height: 32),

            ElevatedButton.icon(
              onPressed: _simpan,
              icon: const Icon(Icons.save),
              label: const Text('Simpan Lokasi', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _namaSalonCtrl.dispose();
    _latCtrl.dispose();
    _lngCtrl.dispose();
    super.dispose();
  }
}
