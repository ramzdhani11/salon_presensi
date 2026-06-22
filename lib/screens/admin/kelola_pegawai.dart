// lib/screens/admin/kelola_pegawai.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../services/database_helper.dart';
import '../../models/user_model.dart';

class KelolaPegawai extends StatefulWidget {
  const KelolaPegawai({super.key});

  @override
  State<KelolaPegawai> createState() => _KelolaPegawaiState();
}

class _KelolaPegawaiState extends State<KelolaPegawai> {
  List<UserModel> _pegawai = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await DatabaseHelper.instance.getAllPegawai();
    setState(() => _pegawai = data);
  }

  void _showFormPegawai({UserModel? user}) {
    final namaCtrl = TextEditingController(text: user?.nama);
    final emailCtrl = TextEditingController(text: user?.email);
    final passwordCtrl = TextEditingController(text: user?.password);
    final noHpCtrl = TextEditingController(text: user?.noHp);
    
    final listJabatan = ['Hair Stylist', 'Makeup Artist', 'Nail Artist', 'Kasir', 'Resepsionis', 'Manajer', 'Terapis', 'Asisten Salon'];
    String? selectedJabatan = listJabatan.contains(user?.jabatan) ? user?.jabatan : null;

    Get.bottomSheet(
      StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
              Text(user == null ? 'Tambah Pegawai' : 'Edit Pegawai',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: namaCtrl,
                decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    prefixIcon: Icon(Icons.person_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: passwordCtrl,
                decoration: const InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock_outline)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noHpCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'No. HP',
                    prefixIcon: Icon(Icons.phone_outlined)),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedJabatan,
                items: listJabatan
                    .map((jabatan) => DropdownMenuItem(value: jabatan, child: Text(jabatan)))
                    .toList(),
                onChanged: (val) {
                  setModalState(() {
                    selectedJabatan = val;
                  });
                },
                decoration: const InputDecoration(
                  labelText: 'Jabatan',
                  prefixIcon: Icon(Icons.work_outline),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (namaCtrl.text.isEmpty || emailCtrl.text.isEmpty) {
                    Get.snackbar('Peringatan', 'Nama dan email wajib diisi',
                        backgroundColor: Colors.orange,
                        colorText: Colors.white);
                    return;
                  }
                  final newUser = UserModel(
                    id: user?.id,
                    nama: namaCtrl.text.trim(),
                    email: emailCtrl.text.trim(),
                    password: passwordCtrl.text.isEmpty
                        ? (user?.password ?? 'pegawai123')
                        : passwordCtrl.text.trim(),
                    role: 'pegawai',
                    noHp: noHpCtrl.text.trim(),
                    jabatan: selectedJabatan ?? '',
                  );
                  if (user == null) {
                    await DatabaseHelper.instance.insertUser(newUser);
                  } else {
                    await DatabaseHelper.instance.updateUser(newUser);
                  }
                  Get.back();
                  await _loadData();
                  Get.snackbar('Berhasil',
                      user == null ? 'Pegawai ditambahkan' : 'Data diperbarui',
                      backgroundColor: Colors.green, colorText: Colors.white);
                },
                child: Text(user == null ? 'Tambah' : 'Simpan'),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
        }),
      isScrollControlled: true,
    );
  }

  Future<void> _hapusPegawai(UserModel user) async {
    final konfirmasi = await Get.dialog<bool>(
      AlertDialog(
        title: const Text('Hapus Pegawai'),
        content: Text('Hapus ${user.nama}?'),
        actions: [
          TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('Batal')),
          ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Get.back(result: true),
              child: const Text('Hapus')),
        ],
      ),
    );
    if (konfirmasi == true) {
      await DatabaseHelper.instance.deleteUser(user.id!);
      await _loadData();
      Get.snackbar('Berhasil', '${user.nama} dihapus',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kelola Pegawai')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormPegawai(),
        backgroundColor: const Color(0xFF009688),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Pegawai',
            style: TextStyle(color: Colors.white)),
      ),
      body: _pegawai.isEmpty
          ? const Center(child: Text('Belum ada pegawai'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _pegawai.length,
              itemBuilder: (context, i) {
                final p = _pegawai[i];
                return Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          const Color(0xFF009688).withOpacity(0.15),
                      child: Text(p.nama[0].toUpperCase(),
                          style: const TextStyle(
                              color: Color(0xFF009688),
                              fontWeight: FontWeight.bold)),
                    ),
                    title: Text(p.nama,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('${p.jabatan ?? '-'} • ${p.email}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              color: Colors.blue),
                          onPressed: () => _showFormPegawai(user: p),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              color: Colors.red),
                          onPressed: () => _hapusPegawai(p),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
