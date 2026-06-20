// lib/screens/pegawai/histori_presensi.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_helper.dart';
import '../../models/presensi_model.dart';

class HistoriPresensi extends StatefulWidget {
  final int userId;
  const HistoriPresensi({super.key, required this.userId});

  @override
  State<HistoriPresensi> createState() => _HistoriPresensiState();
}

class _HistoriPresensiState extends State<HistoriPresensi> {
  List<PresensiModel> _data = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHistori();
  }

  Future<void> _loadHistori() async {
    setState(() => _isLoading = true);
    final data = await DatabaseHelper.instance
        .getHistoriPresensi(widget.userId, limit: 60);
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalHadir = _data.where((p) => p.status == 'hadir').length;
    final totalTerlambat = _data.where((p) => p.status == 'terlambat').length;

    return Scaffold(
      appBar: AppBar(title: const Text('Histori Presensi')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Ringkasan statistik
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Colors.teal[50],
                  child: Row(
                    children: [
                      _buildStatCard('Total', _data.length.toString(),
                          Colors.purple),
                      _buildStatCard(
                          'Hadir', totalHadir.toString(), Colors.green),
                      _buildStatCard('Terlambat', totalTerlambat.toString(),
                          Colors.orange),
                    ],
                  ),
                ),
                // List histori
                Expanded(
                  child: _data.isEmpty
                      ? const Center(
                          child: Text('Belum ada data presensi'))
                      : RefreshIndicator(
                          onRefresh: _loadHistori,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: _data.length,
                            itemBuilder: (context, i) =>
                                _buildItem(_data[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(PresensiModel p) {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.remove_circle_outline;
    if (p.status == 'hadir') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle_outline;
    }
    if (p.status == 'terlambat') {
      statusColor = Colors.orange;
      statusIcon = Icons.warning_amber_outlined;
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(statusIcon, color: statusColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.tanggal,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.login, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(p.jamMasuk ?? '--:--',
                          style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 16),
                      const Icon(Icons.logout, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(p.jamKeluar ?? '--:--',
                          style: const TextStyle(fontSize: 13)),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text('Total: ${p.totalJamKerja}',
                      style: TextStyle(
                          fontSize: 12, color: Colors.grey[600])),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
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
          ],
        ),
      ),
    );
  }
}
