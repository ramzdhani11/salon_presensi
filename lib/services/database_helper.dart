// lib/services/database_helper.dart

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/presensi_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('salon_presensi_v2.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future _createDB(Database db, int version) async {
    // Tabel users
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama TEXT NOT NULL,
        email TEXT UNIQUE NOT NULL,
        password TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'pegawai',
        no_hp TEXT,
        foto_profil TEXT,
        jabatan TEXT
      )
    ''');

    // Tabel presensi
    await db.execute('''
      CREATE TABLE presensi (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        tanggal TEXT NOT NULL,
        jam_masuk TEXT,
        jam_keluar TEXT,
        lat_masuk REAL,
        lng_masuk REAL,
        status TEXT DEFAULT 'belum_absen',
        keterangan TEXT,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // Tabel pengaturan lokasi salon
    await db.execute('''
      CREATE TABLE lokasi_salon (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        nama_salon TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        radius_meter REAL NOT NULL DEFAULT 100.0
      )
    ''');

    // Seed data: akun admin default
    await db.insert('users', {
      'nama': 'Pemilik Salon',
      'email': 'admin@salon.com',
      'password': 'admin123',
      'role': 'admin',
      'jabatan': 'Pemilik',
    });

    // Data pegawai dummy telah dihapus. Anda bisa menambahkan pegawai baru melalui menu Kelola Pegawai.

    // Seed lokasi salon default
    await db.insert('lokasi_salon', {
      'nama_salon': 'Salon Cantik',
      'latitude': -8.1726,
      'longitude': 113.7028,
      'radius_meter': 100.0,
    });
  }

  // ===== USER METHODS =====

  Future<UserModel?> login(String email, String password) async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [email, password],
    );
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<List<UserModel>> getAllPegawai() async {
    final db = await database;
    final result = await db.query(
      'users',
      where: 'role = ?',
      whereArgs: ['pegawai'],
      orderBy: 'nama ASC',
    );
    return result.map((e) => UserModel.fromMap(e)).toList();
  }

  Future<UserModel?> getUserById(int id) async {
    final db = await database;
    final result = await db.query('users', where: 'id = ?', whereArgs: [id]);
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<UserModel?> getUserByEmail(String email) async {
    final db = await database;
    final result = await db.query('users', where: 'email = ?', whereArgs: [email]);
    if (result.isEmpty) return null;
    return UserModel.fromMap(result.first);
  }

  Future<int> insertUser(UserModel user) async {
    final db = await database;
    return await db.insert('users', user.toMap());
  }

  Future<int> updateUser(UserModel user) async {
    final db = await database;
    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    return await db.delete('users', where: 'id = ?', whereArgs: [id]);
  }

  // ===== PRESENSI METHODS =====

  Future<PresensiModel?> getPresensiHariIni(int userId) async {
    final db = await database;
    final today = DateTime.now().toString().substring(0, 10);
    final result = await db.query(
      'presensi',
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, today],
    );
    if (result.isEmpty) return null;
    return PresensiModel.fromMap(result.first);
  }

  Future<int> checkIn(int userId, double lat, double lng) async {
    final db = await database;
    final now = DateTime.now();
    final today = now.toString().substring(0, 10);
    final jamSekarang = now.toString().substring(11, 16);

    // Cek sudah absen hari ini
    final existing = await getPresensiHariIni(userId);
    if (existing != null && existing.jamMasuk != null) return -1;

    // Tentukan status: terlambat jika setelah 08:30
    final status = jamSekarang.compareTo('08:30') > 0 ? 'terlambat' : 'hadir';

    if (existing != null) {
      return await db.update(
        'presensi',
        {
          'jam_masuk': jamSekarang,
          'lat_masuk': lat,
          'lng_masuk': lng,
          'status': status,
        },
        where: 'id = ?',
        whereArgs: [existing.id],
      );
    }

    return await db.insert('presensi', {
      'user_id': userId,
      'tanggal': today,
      'jam_masuk': jamSekarang,
      'lat_masuk': lat,
      'lng_masuk': lng,
      'status': status,
    });
  }

  Future<int> checkOut(int userId) async {
    final db = await database;
    final today = DateTime.now().toString().substring(0, 10);
    final jamSekarang = DateTime.now().toString().substring(11, 16);
    return await db.update(
      'presensi',
      {'jam_keluar': jamSekarang},
      where: 'user_id = ? AND tanggal = ?',
      whereArgs: [userId, today],
    );
  }

  Future<List<PresensiModel>> getHistoriPresensi(int userId, {int limit = 30}) async {
    final db = await database;
    final result = await db.query(
      'presensi',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'tanggal DESC',
      limit: limit,
    );
    return result.map((e) => PresensiModel.fromMap(e)).toList();
  }

  Future<List<Map<String, dynamic>>> getPresensiSemuaPegawai(String tanggal) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT u.nama, u.jabatan, p.id as presensi_id, p.jam_masuk, p.jam_keluar, p.status
      FROM users u
      LEFT JOIN presensi p ON u.id = p.user_id AND p.tanggal = ?
      WHERE u.role = 'pegawai'
      ORDER BY u.nama ASC
    ''', [tanggal]);
  }

  Future<int> updatePresensiAdmin(int presensiId, String jamMasuk, String? jamKeluar, String status) async {
    final db = await database;
    return await db.update(
      'presensi',
      {
        'jam_masuk': jamMasuk,
        'jam_keluar': jamKeluar,
        'status': status,
      },
      where: 'id = ?',
      whereArgs: [presensiId],
    );
  }

  Future<int> deletePresensiAdmin(int presensiId) async {
    final db = await database;
    return await db.delete('presensi', where: 'id = ?', whereArgs: [presensiId]);
  }

  // ===== LOKASI SALON =====

  Future<Map<String, dynamic>?> getLokasiSalon() async {
    final db = await database;
    final result = await db.query('lokasi_salon', limit: 1);
    if (result.isEmpty) return null;
    return result.first;
  }

  Future<int> updateLokasiSalon(
      double lat, double lng, double radius, String nama) async {
    final db = await database;
    return await db.update('lokasi_salon', {
      'latitude': lat,
      'longitude': lng,
      'radius_meter': radius,
      'nama_salon': nama,
    }, where: 'id = 1');
  }
}
