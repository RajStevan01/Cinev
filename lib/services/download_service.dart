import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:aplikasi_mobile/services/notification_service.dart'; // Tambahan import

// Enum untuk status download yang lebih jelas
enum DownloadStatus { none, downloading, paused, completed, error }

// Class untuk menampung detail setiap proses download
class DownloadTask {
  final String url;
  final String savePath;
  double progress = 0.0;
  DownloadStatus status = DownloadStatus.none;

  DownloadTask({required this.url, required this.savePath});
}

class DownloadService {
  // --- Singleton Pattern ---
  // Ini memastikan hanya ada SATU instance DownloadService di seluruh aplikasi
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() {
    return _instance;
  }
  DownloadService._internal();
  // -------------------------

  final Dio _dio = Dio();
  // Map untuk melacak semua tugas download yang sedang berjalan atau selesai
  final Map<String, DownloadTask> _tasks = {};

  // "Penyiar Radio" yang akan menyiarkan update progress ke seluruh aplikasi
  final StreamController<Map<String, DownloadTask>> _progressController =
      StreamController.broadcast();
  
  // Getter agar halaman lain bisa "mendengarkan siaran radio" ini
  Stream<Map<String, DownloadTask>> get progressStream =>
      _progressController.stream;

  // Fungsi untuk memulai download baru
  Future<void> startDownload(String taskId, String url) async {
    // Cek apakah tugas sudah ada, jika tidak buat yang baru
    if (!_tasks.containsKey(taskId) || _tasks[taskId]!.status == DownloadStatus.error) {
      final dir = await getApplicationDocumentsDirectory();
      final savePath = '${dir.path}/downloads/$taskId.mp4';
      await Directory('${dir.path}/downloads').create(recursive: true);

      _tasks[taskId] = DownloadTask(url: url, savePath: savePath);
    }
    
    // Jangan mulai download jika sudah berjalan atau sudah selesai
    if (_tasks[taskId]!.status == DownloadStatus.downloading || _tasks[taskId]!.status == DownloadStatus.completed) {
      return;
    }

    final task = _tasks[taskId]!;
    task.status = DownloadStatus.downloading;
    _broadcastUpdate(); // Siarkan status baru

    try {
      await _dio.download(
        task.url,
        task.savePath,
        onReceiveProgress: (rec, total) {
          if (total != -1) {
            task.progress = rec / total;
            _broadcastUpdate(); // Siarkan update progress
          }
        },
      );
      task.status = DownloadStatus.completed;
      
      // Kirim notifikasi ke lonceng saat Dio selesai mengunduh
      await NotificationService().simpanNotifKeLonceng(
        kategori: 'download',
        judul: 'Unduhan Selesai',
        pesan: 'Film kamu sudah berhasil diunduh dan siap ditonton offline!',
      );
      
    } catch (e) {
      task.status = DownloadStatus.error;
      // TAMBAHKAN BARIS INI BIAR KITA TAHU PENYAKITNYA
      print("🚨 ERROR DOWNLOAD GAGAL: $e");
    } finally {
      _broadcastUpdate(); // Siarkan status akhir (selesai atau error)
    }
  }
  
  // Helper untuk menyiarkan update
  void _broadcastUpdate() {
    _progressController.add(Map.from(_tasks));
  }

  // Fungsi untuk mendapatkan status download saat ini
  DownloadTask? getTask(String taskId) {
    return _tasks[taskId];
  }
  
  // Jangan lupa panggil ini saat aplikasi ditutup (opsional untuk sekarang)
  void dispose() {
    _progressController.close();
  }
}