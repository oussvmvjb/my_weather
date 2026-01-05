import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'screens/home_screen.dart';
import 'services/weather_service.dart'; // خدمة الطقس لديك

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

// ⚡ دالة WorkManager التي تعمل في الخلفية
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // جلب الطقس لمدينة معينة (مثال: Tunis)
      final weatherData = await WeatherService.getCurrentWeather('Tunis');
      final double temp = weatherData['main']['temp'];

      String message = 'درجة الحرارة الآن: ${temp.toStringAsFixed(1)}°C';

      // شرط للإشعار: حرارة مرتفعة أو منخفضة
      if (temp > 30) {
        message += ' 🔥 الجو حار!';
      } else if (temp < 10) {
        message += ' ❄️ الجو بارد!';
      }

      // إرسال Notification
      const AndroidNotificationDetails androidDetails =
          AndroidNotificationDetails(
        'weather_channel',
        'Weather Alerts',
        channelDescription: 'Notifications for temperature alerts',
        importance: Importance.high,
        priority: Priority.high,
        playSound: true,
      );

      const NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      await flutterLocalNotificationsPlugin.show(
        0,
        'Weather Update',
        message,
        platformDetails,
      );
    } catch (e) {
      print("Error fetching weather in background: $e");
    }

    return Future.value(true);
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp();

  // طلب صلاحيات الإشعارات (Android يحتاجها أحيانًا)
  await FirebaseMessaging.instance.requestPermission();

  // الحصول على FCM Token
  String? token = await FirebaseMessaging.instance.getToken();
  print("FCM Token: $token");

  // تهيئة notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
      InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(initializationSettings);

  // تهيئة Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: true, // اجعل false عند الإطلاق
  );

  // تسجيل المهمة لتعمل كل 3 ساعات
  await Workmanager().registerPeriodicTask(
    "weatherTask",
    "fetchWeatherAndNotify",
    frequency: const Duration(hours: 3),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'My Weather',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        fontFamily: 'Ethnocentric',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontSize: 72, fontWeight: FontWeight.w300),
          displayMedium: TextStyle(fontSize: 48, fontWeight: FontWeight.w300),
          displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w400),
          headlineMedium: TextStyle(fontSize: 24, fontWeight: FontWeight.w400),
          headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w400),
          titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
          bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
          bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
