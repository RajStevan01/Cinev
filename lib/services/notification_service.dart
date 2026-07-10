import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:aplikasi_mobile/services/database_helper.dart'; // Tambahan import database
import 'package:firebase_messaging/firebase_messaging.dart'; // Import penangkap Firebase
import 'package:flutter/foundation.dart'; // Tambahan import untuk kIsWeb

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin = FlutterLocalNotificationsPlugin();

  Future<void> initNotification() async {
    // Pengaturan icon untuk Android (mengarah ke folder drawable native)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@drawable/logo_notif'); // Tanpa .png

    // Pengaturan untuk iOS
    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    // Inisialisasi plugin
    await notificationsPlugin.initialize(initializationSettings);

    // Minta izin notifikasi khusus untuk Android 13 ke atas
    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        notificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    
    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
    }
  }

  Future<void> tampilkanNotifikasiWelcome({required String username}) async {
    // Detail tampilan notifikasi untuk Android
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'channel_cinev_1', // ID Channel
      'Notifikasi Sistem', // Nama Channel
      channelDescription: 'Channel untuk notifikasi otomatis',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/logo_notif', // Tanpa .png
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    // Perintah untuk memunculkan notifikasi
    await notificationsPlugin.show(
      0, // ID Notifikasi (bebas)
      'Selamat Datang! 🍿', // Judul Notifikasi
      'Halo $username, yuk tonton deretan film terlaris minggu ini di Cinev App!', // Isi Pesan
      notificationDetails,
    );
  }

  // --- FUNGSI Notifikasi Download ---
  Future<void> tampilkanNotifikasiDownload({required String namaFilm}) async {
    const AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'channel_cinev_download', // ID Channel dibedakan dari notif welcome
      'Notifikasi Download',
      channelDescription: 'Channel untuk notifikasi unduhan selesai',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@drawable/logo_notif', // Menggunakan logo TV putih andalan
    );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: DarwinNotificationDetails(),
    );

    // Perintah untuk memunculkan notifikasi
    await notificationsPlugin.show(
      1, // ID Notifikasi (pakai angka 1 agar tidak menimpa notif welcome yang ber-ID 0)
      'Download Selesai! ✅', 
      'Film $namaFilm berhasil diunduh dan siap ditonton offline.', 
      notificationDetails,
    );
  }

  // --- FUNGSI BARU: Simpan riwayat ke Lonceng (SQLite) ---
  Future<void> simpanNotifKeLonceng({
    required String kategori,
    required String judul,
    required String pesan,
  }) async {
    await DatabaseHelper.instance.tambahNotifikasi({
      'kategori': kategori,
      'judul': judul,
      'pesan': pesan,
      'waktu': DateTime.now().toString().split('.')[0], // Format: YYYY-MM-DD HH:MM:SS
      'dibaca': 0,
    });
  }

  // --- FUNGSI BARU: Inisialisasi Antena Firebase (FCM) ---
  Future<void> initFCM() async {
    if (kIsWeb) {
      print("FCM dinonaktifkan di Web untuk mencegah crash.");
      return;
    }
    
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    // Pastikan izin notif sudah aktif
    await messaging.requestPermission();

    // --- TAMBAHKAN 4 BARIS INI UNTUK MENGAMBIL TOKEN ---
    String? fcmToken = await messaging.getToken();
    print("====== INI FCM TOKEN HP TEMANMU ======");
    print(fcmToken);
    print("======================================");

    // Subscribe ke topic all_users agar mendapat broadcast notifikasi admin (Hanya untuk Mobile)
    if (!kIsWeb) {
      await messaging.subscribeToTopic('all_users');
    }

    // Skenario 1: Aplikasi sedang DIBUKA (Foreground)
    // Firebase tidak memunculkan notif secara otomatis jika aplikasi sedang dibuka.
    // Jadi kita harus tangkap pesannya dan munculkan manual pakai Local Notification.
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      if (message.notification != null) {
        String judul = message.notification!.title ?? 'Pengumuman Baru';
        String pesan = message.notification!.body ?? '';

        // 1. Munculkan pop-up dari atas layar
        await tampilkanNotifikasiWelcome(username: 'Cinev User'); // Kita pinjam UI notif welcome
        // (Opsional: kamu bisa buat fungsi tampilkanNotifikasi khusus FCM nanti)
        
        // 2. Simpan sejarahnya ke Lonceng
        await simpanNotifKeLonceng(
          kategori: 'fcm',
          judul: judul,
          pesan: pesan,
        );
      }
    });
  }
}