// lib/models/user_model.dart

class UserModel {
  final int? id;
  final String nama;
  final String email;
  final String password;
  final String role; // 'admin' atau 'pegawai'
  final String? noHp;
  final String? fotoProfil;
  final String? jabatan;

  UserModel({
    this.id,
    required this.nama,
    required this.email,
    required this.password,
    required this.role,
    this.noHp,
    this.fotoProfil,
    this.jabatan,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': nama,
      'email': email,
      'password': password,
      'role': role,
      'no_hp': noHp,
      'foto_profil': fotoProfil,
      'jabatan': jabatan,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      nama: map['nama'],
      email: map['email'],
      password: map['password'],
      role: map['role'],
      noHp: map['no_hp'],
      fotoProfil: map['foto_profil'],
      jabatan: map['jabatan'],
    );
  }

  UserModel copyWith({
    int? id,
    String? nama,
    String? email,
    String? password,
    String? role,
    String? noHp,
    String? fotoProfil,
    String? jabatan,
  }) {
    return UserModel(
      id: id ?? this.id,
      nama: nama ?? this.nama,
      email: email ?? this.email,
      password: password ?? this.password,
      role: role ?? this.role,
      noHp: noHp ?? this.noHp,
      fotoProfil: fotoProfil ?? this.fotoProfil,
      jabatan: jabatan ?? this.jabatan,
    );
  }
}
