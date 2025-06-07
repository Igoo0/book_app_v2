import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:math';

class NotificationService {
  static final NotificationService instance = NotificationService._internal();
  factory NotificationService() => instance;
  NotificationService._internal();

  late FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;

    _flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization  
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    _isInitialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
    // Handle notification tap based on payload
    // You can navigate to specific screens here
  }

  Future<void> requestPermissions() async {
    try {
      // Request permissions for Android
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      if (androidImplementation != null) {
        await androidImplementation.requestNotificationsPermission();
      }

      // Request permissions for iOS
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();

      if (iosImplementation != null) {
        await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
    int? id,
  }) async {
    if (!_isInitialized) await initialize();

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'bookverse_channel',
      'BookVerse Notifications',
      channelDescription: 'Notifications for BookVerse app',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iosPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id ?? Random().nextInt(100000),
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  Future<void> showBookRecommendationNotification({
    required String bookTitle,
    required String author,
    required String bookId,
  }) async {
    await showNotification(
      title: 'New Book Recommendation',
      body: 'Check out "$bookTitle" by $author',
      payload: 'book_recommendation:$bookId',
    );
  }

  Future<void> showNewBookAlert({
    required String bookTitle,
    required String category,
    required String bookId,
  }) async {
    await showNotification(
      title: 'New Release in $category',
      body: '"$bookTitle" is now available!',
      payload: 'new_book:$bookId',
    );
  }

  Future<void> showSearchResultNotification({
    required int resultCount,
    required String query,
  }) async {
    await showNotification(
      title: 'Search Complete',
      body: 'Found $resultCount books for "$query"',
      payload: 'search_complete:$query',
    );
  }

  Future<void> showFavoriteAddedNotification({
    required String bookTitle,
  }) async {
    await showNotification(
      title: 'Added to Favorites',
      body: '"$bookTitle" has been added to your favorites',
      payload: 'favorite_added',
    );
  }

  Future<void> showWelcomeNotification({
    required String username,
  }) async {
    await showNotification(
      title: 'Welcome to BookVerse!',
      body: 'Hello $username! Start exploring your digital library.',
      payload: 'welcome',
    );
  }

  Future<void> showDailyReadingReminder() async {
    await showNotification(
      title: 'Daily Reading Reminder',
      body: 'Don\'t forget to read today! Check out new recommendations.',
      payload: 'daily_reminder',
    );
  }

  Future<void> showCurrencyUpdateNotification() async {
    await showNotification(
      title: 'Currency Rates Updated',
      body: 'Latest exchange rates are now available.',
      payload: 'currency_update',
    );
  }

  Future<void> showShakeDetectedNotification() async {
    await showNotification(
      title: 'Shake Detected!',
      body: 'You shook your device! Here are some random book suggestions.',
      payload: 'shake_detected',
    );
  }

  Future<void> scheduleWeeklyRecommendation() async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'weekly_channel',
      'Weekly Recommendations',
      channelDescription: 'Weekly book recommendations',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.periodicallyShow(
      1,
      'Weekly Book Recommendations',
      'Discover new books tailored just for you!',
      RepeatInterval.weekly,
      platformChannelSpecifics,
      payload: 'weekly_recommendation',
    );
  }

  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  Future<void> showProgressNotification({
    required String title,
    required String body,
    required int progress,
    required int maxProgress,
    int? id,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
      AndroidNotificationDetails(
      'progress_channel',
      'Progress Notifications',
      channelDescription: 'Progress notifications for downloads',
      importance: Importance.low,
      priority: Priority.low,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      maxProgress: maxProgress,
      progress: progress,
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      id ?? 999,
      title,
      body,
      platformChannelSpecifics,
    );
  }

  Future<void> showBigTextNotification({
    required String title,
    required String shortBody,
    required String longBody,
    String? payload,
  }) async {
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'big_text_channel',
      'Big Text Notifications',
      channelDescription: 'Notifications with expanded text',
      importance: Importance.max,
      priority: Priority.high,
      styleInformation: BigTextStyleInformation(
        longBody,
        htmlFormatBigText: true,
        contentTitle: title,
        htmlFormatContentTitle: true,
        summaryText: 'BookVerse',
        htmlFormatSummaryText: true,
      ),
    );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      Random().nextInt(100000),
      title,
      shortBody,
      platformChannelSpecifics,
      payload: payload,
    );
  }
}