import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  Future<void>? _initializing;

  Future<void> initialize() async {
    if (_initialized) return;
    if (_initializing != null) return _initializing!;

    _initializing = _initialize();
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _initialize() async {
    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('ic_notification');
    const DarwinInitializationSettings darwinInitSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
      iOS: darwinInitSettings,
    );

    await _plugin.initialize(settings: initSettings);
    // Création explicite du canal de notifications pour assurer la compatibilité
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        'downloads_channel',
        'Téléchargements',
        description: 'Progression des téléchargements',
        importance: Importance.low,
      ),
    );
    _initialized = true;
  }

  /// Demande la permission de notifications si nécessaire (Android 13+).
  Future<bool> ensurePermission() async {
    await initialize();
    if (Platform.isAndroid) {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (android != null) {
        final granted = await android.requestNotificationsPermission();
        return granted ?? true;
      }
    }
    if (Platform.isIOS) {
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      return await ios?.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          true;
    }
    return true;
  }

  NotificationDetails _progressDetails() {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'downloads_channel',
          'Téléchargements',
          channelDescription: 'Progression des téléchargements',
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          showProgress: true,
          indeterminate: false,
          ongoing: true,
          playSound: false,
          icon: 'ic_notification',
        );
    return const NotificationDetails(android: androidDetails);
  }

  NotificationDetails _finalDetails({bool success = true}) {
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'downloads_channel',
          'Téléchargements',
          channelDescription: 'Progression des téléchargements',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          onlyAlertOnce: true,
          ongoing: false,
          playSound: success,
          icon: 'ic_notification',
        );
    return NotificationDetails(android: androidDetails);
  }

  Future<void> startProgress(
    int id, {
    required String title,
    required String body,
  }) async {
    await initialize();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _progressDetails(),
    );
  }

  Future<void> updateProgress(
    int id, {
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
  }) async {
    await initialize();
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'downloads_channel',
          'Téléchargements',
          channelDescription: 'Progression des téléchargements',
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          showProgress: true,
          indeterminate: false,
          ongoing: true,
          playSound: false,
          maxProgress: maxProgress,
          progress: progress,
          icon: 'ic_notification',
        );
    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> complete(int id, {required String title, String? body}) async {
    await initialize();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _finalDetails(success: true),
    );
  }

  Future<void> fail(int id, {required String title, String? body}) async {
    await initialize();
    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: _finalDetails(success: false),
    );
  }

  Future<void> notifyTimerComplete({required String body}) async {
    final granted = await ensurePermission();
    if (!granted) return;

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        'timer_channel',
        'Minuteur',
        channelDescription: 'Alertes de fin du minuteur',
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
    await _plugin.show(
      id: 0,
      title: 'Minuteur terminé !',
      body: body,
      notificationDetails: details,
    );
  }

  Future<void> cancel(int id) async {
    await initialize();
    await _plugin.cancel(id: id);
  }
}
