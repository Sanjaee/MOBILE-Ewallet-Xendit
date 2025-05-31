import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';
import '../../utils/helpers.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final NotificationService _notificationService =
      NotificationService._internal();

  factory NotificationService() {
    return _notificationService;
  }

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestSoundPermission: true,
      requestBadgePermission: true,
      requestAlertPermission: true,
    );

    final InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.requestNotificationsPermission();

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: onDidReceiveNotificationResponse,
    );
  }

  void onDidReceiveLocalNotification(
      int id, String? title, String? body, String? payload) async {
    // Handle notification received while app is in foreground (iOS < 10)
  }

  void onDidReceiveNotificationResponse(
      NotificationResponse notificationResponse) async {
    // Handle user tapping on notification
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id_transactions',
      'Transaksi',
      channelDescription: 'Notifikasi terkait transaksi',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
      color: Color(0xFFFFFFFF),
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> showTransactionNotification({
    required String type, // 'topup', 'transfer', 'withdraw'
    required double amount,
    required bool isSuccess,
  }) async {
    String title = isSuccess ? 'Transaksi Berhasil' : 'Transaksi Gagal';
    String body = '';

    switch (type.toLowerCase()) {
      case 'topup':
        body = isSuccess
            ? 'Top Up sebesar ${Helpers.formatCurrency(amount)} berhasil ditambahkan ke saldo Anda'
            : 'Top Up sebesar ${Helpers.formatCurrency(amount)} gagal diproses';
        break;
      case 'transfer':
        body = isSuccess
            ? 'Transfer sebesar ${Helpers.formatCurrency(amount)} berhasil dikirim'
            : 'Transfer sebesar ${Helpers.formatCurrency(amount)} gagal diproses';
        break;
      case 'withdraw':
        body = isSuccess
            ? 'Withdraw sebesar ${Helpers.formatCurrency(amount)} berhasil diproses'
            : 'Withdraw sebesar ${Helpers.formatCurrency(amount)} gagal diproses';
        break;
    }

    await showNotification(
      id: DateTime.now().millisecondsSinceEpoch.remainder(100000),
      title: title,
      body: body,
      payload: jsonEncode({
        'type': type,
        'amount': amount,
        'status': isSuccess ? 'success' : 'failed',
        'timestamp': DateTime.now().toIso8601String(),
      }),
    );
  }
}
