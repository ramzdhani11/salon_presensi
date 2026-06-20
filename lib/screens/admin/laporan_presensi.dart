// lib/screens/admin/laporan_presensi.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/database_helper.dart';

class LaporanPresensi extends StatefulWidget {
  const LaporanPresensi({super.key});

  @override
  State<LaporanPresensi> createState() => _LaporanPresensiState();
}

class _LaporanPresensiState extends State<LaporanPresensi> {
  DateTime _tanggalDipilih = DateTime.now();
  List<Map<String, dynamic>> _data = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final tanggal = _tanggalDipilih.toString().substring(0, 10);
    final data =
        await DatabaseHelper.instance.getPresensiSemuaPegawai(tanggal);
    setState(() {
      _data = data;
      _isLoading = false;
    });
  }

  Future<void> _pilihTanggal() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tanggalDipilih,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF009688),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _tanggalDipilih = picked);
      await _loadData();
    }
  }

  Future<void> _editPresensiDialog(Map<String, dynamic> p) async {
    if (p['presensi_id'] == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pegawai belum melakukan presensi hari ini.')));
      return;
    }

    final jamMasukCtrl = TextEditingController(text: p['jam_masuk'] ?? '');
    final jamKeluarCtrl = TextEditingController(text: p['jam_keluar'] ?? '');
    String status = p['status'] ?? 'hadir';

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: Text('Edit Presensi ${p['nama']}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: jamMasukCtrl,
                decoration: const InputDecoration(labelText: 'Jam Masuk (HH:mm)'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: jamKeluarCtrl,
                decoration: const InputDecoration(labelText: 'Jam Keluar (HH:mm)'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: status,
                decoration: const InputDecoration(labelText: 'Status'),
                items: const [
                  DropdownMenuItem(value: 'hadir', child: Text('Hadir')),
                  DropdownMenuItem(value: 'terlambat', child: Text('Terlambat')),
                  DropdownMenuItem(value: 'izin', child: Text('Izin')),
                  DropdownMenuItem(value: 'sakit', child: Text('Sakit')),
                  DropdownMenuItem(value: 'belum_absen', child: Text('Belum Absen')),
                ],
                onChanged: (v) => setStateDialog(() => status = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () async {
                await DatabaseHelper.instance.updatePresensiAdmin(
                  p['presensi_id'],
                  jamMasukCtrl.text,
                  jamKeluarCtrl.text.isEmpty ? null : jamKeluarCtrl.text,
                  status,
                );
                if (mounted) Navigator.pop(context);
                _loadData();
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _hapusPresensi(int presensiId) async {
    final konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Presensi'),
        content: const Text('Yakin ingin menghapus data presensi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (konfirmasi == true) {
      await DatabaseHelper.instance.deletePresensiAdmin(presensiId);
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tanggalLabel = DateFormat('d MMMM yyyy', 'id_ID').format(_tanggalDipilih);
    final totalHadir = _data.where((p) => p['status'] == 'hadir').length;
    final totalTerlambat = _data.where((p) => p['status'] == 'terlambat').length;
    final totalBelumAbsen = _data.length - (totalHadir + totalTerlambat);

    return Scaffold(
      appBar: AppBar(title: const Text('Laporan Presensi')),
      body: Column(
        children: [
          // Filter tanggal
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.teal[50],
            child: Row(
              children: [
                const Icon(Icons.calendar_today,
                    color: Color(0xFF009688), size: 20),
                const SizedBox(width: 8),
                Text(tanggalLabel,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                ElevatedButton(
                  onPressed: _pilihTanggal,
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size.zero,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  child: const Text('Ganti Tanggal'),
                ),
              ],
            ),
          ),

          // Statistik
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildStat('Total', _data.length, Colors.purple),
                _buildStat('Hadir', totalHadir, Colors.green),
                _buildStat('Terlambat', totalTerlambat, Colors.orange),
                _buildStat('Belum Absen', totalBelumAbsen, Colors.red),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _data.isEmpty
                    ? const Center(child: Text('Tidak ada data'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: _data.length,
                        itemBuilder: (context, i) =>
                            _buildItem(_data[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String label, int value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text('$value',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(label,
                style: TextStyle(fontSize: 11, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(Map<String, dynamic> p) {
    final sudahHadir = p['jam_masuk'] != null;
    final status = p['status'] as String? ?? 'belum_absen';
    Color color = sudahHadir
        ? (status == 'terlambat' ? Colors.orange : Colors.green)
        : Colors.grey;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: InkWell(
        onTap: () => _editPresensiDialog(p),
        onLongPress: () {
          if (p['presensi_id'] != null) {
            _hapusPresensi(p['presensi_id']);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor:
                    const Color(0xFF009688).withOpacity(0.1),
                child: Text(
                  (p['nama'] as String)[0].toUpperCase(),
                  style: const TextStyle(
                      color: Color(0xFF009688),
                      fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['nama'] ?? '-',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    Text(p['jabatan'] ?? '-',
                        style: TextStyle(
                            color: Colors.grey[500], fontSize: 12)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        '${p['jam_masuk'] ?? '--:--'} - ${p['jam_keluar'] ?? '--:--'}',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      if (p['presensi_id'] != null) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.edit, size: 14, color: Colors.grey),
                      ]
                    ],
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sudahHadir
                          ? status.replaceAll('_', ' ').toUpperCase()
                          : 'BELUM ABSEN',
                      style: TextStyle(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
