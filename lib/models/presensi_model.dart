// lib/models/presensi_model.dart

class PresensiModel {
  final int? id;
  final int userId;
  final String tanggal;
  final String? jamMasuk;
  final String? jamKeluar;
  final double? latMasuk;
  final double? lngMasuk;
  final String status; // 'hadir', 'terlambat', 'belum_absen'
  final String? keterangan;

  PresensiModel({
    this.id,
    required this.userId,
    required this.tanggal,
    this.jamMasuk,
    this.jamKeluar,
    this.latMasuk,
    this.lngMasuk,
    this.status = 'belum_absen',
    this.keterangan,
  });

  // Hitung total jam kerja
  String get totalJamKerja {
    if (jamMasuk == null || jamKeluar == null) return '-';
    try {
      final masuk = DateTime.parse('2000-01-01 $jamMasuk');
      final keluar = DateTime.parse('2000-01-01 $jamKeluar');
      final diff = keluar.difference(masuk);
      final jam = diff.inHours;
      final menit = diff.inMinutes % 60;
      return '${jam}j ${menit}m';
    } catch (e) {
      return '-';
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'tanggal': tanggal,
      'jam_masuk': jamMasuk,
      'jam_keluar': jamKeluar,
      'lat_masuk': latMasuk,
      'lng_masuk': lngMasuk,
      'status': status,
      'keterangan': keterangan,
    };
  }

  factory PresensiModel.fromMap(Map<String, dynamic> map) {
    return PresensiModel(
      id: map['id'],
      userId: map['user_id'],
      tanggal: map['tanggal'],
      jamMasuk: map['jam_masuk'],
      jamKeluar: map['jam_keluar'],
      latMasuk: map['lat_masuk'],
      lngMasuk: map['lng_masuk'],
      status: map['status'] ?? 'belum_absen',
      keterangan: map['keterangan'],
    );
  }
}
