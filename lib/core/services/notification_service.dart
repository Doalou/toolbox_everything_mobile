import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._internal();
  static final NotificationService instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInitSettings =
        AndroidInitializationSettings('ic_launcher');

    const InitializationSettings initSettings = InitializationSettings(
      android: androidInitSettings,
    );

    await _plugin.initialize(initSettings);
    // Android 13+ nécessite une permission runtime pour les notifications
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await androidImpl?.requestNotificationsPermission();
    _initialized = true;
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
        );
    return NotificationDetails(android: androidDetails);
  }

  Future<void> startProgress(
    int id, {
    required String title,
    required String body,
  }) async {
    await _plugin.show(id, title, body, _progressDetails());
  }

  Future<void> updateProgress(
    int id, {
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
  }) async {
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
        );
    final details = NotificationDetails(android: androidDetails);
    await _plugin.show(id, title, body, details);
  }

  Future<void> complete(int id, {required String title, String? body}) async {
    await _plugin.show(id, title, body, _finalDetails(success: true));
  }

  Future<void> fail(int id, {required String title, String? body}) async {
    await _plugin.show(id, title, body, _finalDetails(success: false));
  }

  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }
}
