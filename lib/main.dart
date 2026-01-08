import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:workmanager/workmanager.dart';
import 'package:geolocator/geolocator.dart'; // أضف هذه
import 'screens/home_screen.dart';
import 'services/weather_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    print("🎯 Background task started: $task");
    WidgetsFlutterBinding.ensureInitialized();

    // 0️⃣ تهيئة الإشعارات داخل المعزولة (Isolate) الخلفية
    final FlutterLocalNotificationsPlugin backgroundNotificationsPlugin =
        FlutterLocalNotificationsPlugin();
    
    // تهيئة الإعدادات لنظام أندرويد
    const AndroidInitializationSettings androidInit = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = 
        InitializationSettings(android: androidInit);
    
    await backgroundNotificationsPlugin.initialize(initSettings);

    try {
      // 1️⃣ الحصول على الموقع الحالي في الخلفية
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission != LocationPermission.whileInUse && 
            permission != LocationPermission.always) {
          print("❌ Location permission denied in background");
          // استخدم المدينة المخزنة كبديل
          await _notifyWithSavedCity(backgroundNotificationsPlugin);
          return Future.value(true); // ✅ هنا نقوم بالإرجاع
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print("❌ Location permission permanently denied");
        await _notifyWithSavedCity(backgroundNotificationsPlugin); // ✅ ننتظر اكتمال الدالة
        return Future.value(true);
      }

      // 2️⃣ الحصول على الإحداثيات
      Position position;
      try {
        position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.medium,
        );
        print("📍 Background location: ${position.latitude}, ${position.longitude}");
      } catch (e) {
        print("❌ Failed to get position: $e");
        await _notifyWithSavedCity(backgroundNotificationsPlugin); // ✅ ننتظر اكتمال الدالة
        return Future.value(true);
      }

      // 3️⃣ الحصول على الطقس بالإحداثيات
      final weatherData = await WeatherService.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      final city = weatherData['name'] ?? 'Unknown City';
      final double temp = (weatherData['main']['temp'] as num).toDouble();
      
      // 4️⃣ حفظ المدينة الجديدة
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('city', city);

      // 5️⃣ إرسال الإشعار
      await _sendWeatherNotification(city, temp, backgroundNotificationsPlugin);

    } catch (e) {
      print('❌ Background error: $e');
      // حاول باستخدام المدينة المخزنة
      await _notifyWithSavedCity(backgroundNotificationsPlugin); // ✅ ننتظر اكتمال الدالة
    }

    return Future.value(true); // ✅ إرجاع القيمة المطلوبة
  });
}

// دالة مساعدة للإشعار بالمدينة المخزنة
Future<bool> _notifyWithSavedCity(FlutterLocalNotificationsPlugin notificationsPlugin) async { // ✅ تغيير نوع الإرجاع إلى Future<bool>
  try {
    final prefs = await SharedPreferences.getInstance();
    final city = prefs.getString('city') ?? 'Tunis';
    
    final weatherData = await WeatherService.getCurrentWeather(city);
    final double temp = (weatherData['main']['temp'] as num).toDouble();
    
    await _sendWeatherNotification(city, temp, notificationsPlugin);
    return true; // ✅ إرجاع true
  } catch (e) {
    print("❌ Failed to notify with saved city: $e");
    return false; // ✅ إرجاع false في حالة الخطأ
  }
}

// دالة مساعدة لإرسال الإشعار
Future<bool> _sendWeatherNotification(String city, double temp, FlutterLocalNotificationsPlugin notificationsPlugin) async { // ✅ تغيير إلى Future<bool>
  try {
    String message = 'درجة الحرارة في $city: ${temp.toStringAsFixed(1)}°C';

    if (temp > 30) {
      message += ' 🔥 الجو حار';
    } else if (temp < 10) {
      message += ' ❄️ الجو بارد';
    }

    const androidDetails = AndroidNotificationDetails(
      'weather_channel',
      'Weather Alerts',
      channelDescription: 'Weather background alerts',
      importance: Importance.high,
      priority: Priority.high,
      enableVibration: true,
      playSound: true,
    );

    const notificationDetails = NotificationDetails(android: androidDetails);

    await notificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      'تحديث الطقس',
      message,
      notificationDetails,
    );
    
    print("✅ Notification sent for $city: $temp°C");
    return true; // ✅ إرجاع true
  } catch (e) {
    print("❌ Failed to send notification: $e");
    return false; // ✅ إرجاع false في حالة الخطأ
  }
}





Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // تهيئة Firebase
  await Firebase.initializeApp();

  // طلب إذن الإشعارات
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  // تهيئة الإشعارات المحلية
  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  const initSettings = InitializationSettings(android: androidInit);
  await flutterLocalNotificationsPlugin.initialize(initSettings);

  // ✅ تأكد من إعداد قناة الإشعارات
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
    'weather_channel',
    'Weather Alerts',
    importance: Importance.high,
  ));

  // تهيئة Workmanager
  await Workmanager().initialize(
    callbackDispatcher,
    isInDebugMode: false, // ⚠️ ضع true للتجربة فقط
  );

  // تنظيف المهام القديمة
  await Workmanager().cancelAll();

  // تسجيل المهام الدورية
  await Workmanager().registerPeriodicTask(
    "weatherPeriodicTask",
    "fetchWeatherAndNotify",
    frequency: const Duration(hours: 1), // كل ساعة
    initialDelay: const Duration(seconds: 10),
    constraints: Constraints(
      networkType: NetworkType.connected,
    ),
  );

  print("🚀 App initialized with background tasks");

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