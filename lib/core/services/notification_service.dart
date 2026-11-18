import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_10y.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:toolbox_everything_mobile/core/feature_flags/app_feature_flags.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _timezonesInitialized = false;
  Future<void>? _initializing;

  bool get _enabled =>
      (Platform.isAndroid || Platform.isIOS) &&
      AppFeatureFlags.localNotifications;

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

  void _ensureTimezones() {
    if (_timezonesInitialized) return;
    tz_data.initializeTimeZones();
    _timezonesInitialized = true;
  }

  Future<void> _initialize() async {
    _ensureTimezones();
    if (!_enabled) {
      _initialized = true;
      return;
    }

    try {
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
      await android?.createNotificationChannel(
        const AndroidNotificationChannel(
          'timer_channel',
          'Minuteur',
          description: 'Alertes de fin du minuteur et Pomodoro',
          importance: Importance.high,
        ),
      );
      _initialized = true;
    } catch (_) {
      // Évite de bloquer en environnement sans plugin natif.
    }
  }

  /// Demande la permission de notifications si nécessaire (Android 13+ / iOS).
  Future<bool> ensurePermission() async {
    if (!AppFeatureFlags.localNotifications) return false;
    await initialize();
    if (!_enabled) return true;
    try {
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
    } catch (_) {}
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

  NotificationDetails _timerDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'timer_channel',
        'Minuteur',
        channelDescription: 'Alertes de fin du minuteur et Pomodoro',
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
  }

  Future<void> startProgress(
    int id, {
    required String title,
    required String body,
  }) async {
    await initialize();
    if (!_enabled) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _progressDetails(),
      );
    } catch (_) {}
  }

  Future<void> updateProgress(
    int id, {
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
  }) async {
    await initialize();
    if (!_enabled) return;
    try {
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
    } catch (_) {}
  }

  Future<void> complete(int id, {required String title, String? body}) async {
    await initialize();
    if (!_enabled) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _finalDetails(success: true),
      );
    } catch (_) {}
  }

  Future<void> fail(int id, {required String title, String? body}) async {
    await initialize();
    if (!_enabled) return;
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _finalDetails(success: false),
      );
    } catch (_) {}
  }

  /// Programme une notification système même lorsque l'écran est verrouillé.
  Future<void> scheduleTimerNotification({
    int id = 100,
    required Duration delay,
    required String title,
    required String body,
  }) async {
    if (!_enabled || delay.inSeconds <= 0) return;
    try {
      final granted = await ensurePermission();
      if (!granted) return;
      _ensureTimezones();
      final scheduledDate = tz.TZDateTime.now(tz.UTC).add(delay);
      await _plugin.cancel(id: id);
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: _timerDetails(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    } catch (_) {}
  }

  Future<void> cancelTimerNotification({int id = 100}) async {
    if (!_enabled) return;
    try {
      await initialize();
      await _plugin.cancel(id: id);
    } catch (_) {}
  }

  Future<void> notifyTimerComplete({
    int id = 100,
    String title = 'Minuteur terminé !',
    required String body,
  }) async {
    if (!_enabled) return;
    try {
      final granted = await ensurePermission();
      if (!granted) return;
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: _timerDetails(),
      );
    } catch (_) {}
  }

  Future<void> cancel(int id) async {
    if (!_enabled) return;
    try {
      await initialize();
      await _plugin.cancel(id: id);
    } catch (_) {}
  }
}
