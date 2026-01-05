import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:async';
import '../services/weather_service.dart';
import '../models/weather_model.dart';
import 'forecast_screen.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  Weather? _currentWeather;
  bool _isLoading = false;
  String _errorMessage = '';
  final TextEditingController _cityController = TextEditingController();
  final List<String> _popularCities = [
  'Beja',
  'Tunis',
  'Bizerte',
  'Sfax',
  'Sousse',
  'Gabes',
  'Kairouan',
  'Nabeul'
];
  
  // Animation controllers
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Timer _bgTimer;
  int _bgIndex = 0;
  final List<Color> _bgColors = [
    Colors.blue.shade900,
    Colors.purple.shade900,
    Colors.teal.shade900,
    Colors.indigo.shade900,
    Colors.deepOrange.shade900,
  ];
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
  FlutterLocalNotificationsPlugin();
  @override
void initState() {
  super.initState();

  // Initialize notifications
  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  final InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  flutterLocalNotificationsPlugin.initialize(initializationSettings);
  // Initialize animation controller
  _animationController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 20),
  )..repeat(reverse: true);
  
  _animation = Tween<double>(begin: -0.1, end: 0.1).animate(
    CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
  );
  
  // Background color changer
  _bgTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
    setState(() {
      _bgIndex = (_bgIndex + 1) % _bgColors.length;
    });
  });
  
  // Load weather
  _loadCurrentLocationWeather();

  // --- Firebase Messaging listener ---
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    // يمكنك هنا عرض إشعار داخل التطبيق إذا أحببت
    print("Notification received:");
    print("Title: ${message.notification?.title}");
    print("Body: ${message.notification?.body}");
  });

  // (اختياري) استخراج FCM Token الآن
  FirebaseMessaging.instance.getToken().then((token) {
    print("FCM Token: $token"); // احتفظ بهذا لاستخدامه في n8n
  });
}


  @override
  void dispose() {
    _animationController.dispose();
    _bgTimer.cancel();
    super.dispose();
  }

  Future<void> _loadCurrentLocationWeather() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _errorMessage = 'Location permissions are denied';
          });
          _searchWeather('beja');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage = 'Location permissions are permanently denied';
        });
        _searchWeather('beja');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      final weatherData = await WeatherService.getWeatherByLocation(
        position.latitude,
        position.longitude,
      );

      setState(() {
        _currentWeather = Weather.fromJson(weatherData);
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: $e';
        _searchWeather('beja');
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  Future<void> _showTestNotification() async {
  try {
    // جلب الطقس لمدينة معينة، مثال: Tunis
    final weatherData = await WeatherService.getCurrentWeather('beja');
    final double temp = weatherData['main']['temp'];

    // نص الإشعار الأساسي
    String message = 'درجة الحرارة الآن: ${temp.toStringAsFixed(1)}°C';

    // شرط للإشعار: حرارة مرتفعة أو منخفضة
    if (temp > 30) {
      message += ' 🔥 الجو حار!';
    } else if (temp < 10) {
      message += ' ❄️ الجو بارد!';
    }

    // إعداد Notification
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'weather_channel',
      'Weather Alerts',
      channelDescription: 'Notifications for temperature alerts',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);

    // عرض الإشعار
    await flutterLocalNotificationsPlugin.show(
      0,
      'Weather Update',
      message,
      platformDetails,
      payload: 'Weather Payload',
    );
  } catch (e) {
    print("Error showing test notification: $e");
  }
}


  Future<void> _searchWeather(String city) async {
    if (city.isEmpty) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
      FocusScope.of(context).unfocus();
    });

    try {
      final weatherData = await WeatherService.getCurrentWeather(city);
      setState(() {
        _currentWeather = Weather.fromJson(weatherData);
        _cityController.clear();
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'City not found or connection issue';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Animated background with particles
  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Gradient background
            AnimatedContainer(
              duration: const Duration(seconds: 2),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _bgColors[_bgIndex],
                    _bgColors[(_bgIndex + 1) % _bgColors.length],
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            
            // Animated particles
            for (int i = 0; i < 20; i++)
              Positioned(
                left: (MediaQuery.of(context).size.width * 0.8) * (i / 20),
                top: 100 + 50 * (i % 3) + 100 * _animation.value * (i % 2 == 0 ? 1 : -1),
                child: Container(
                  width: 2,
                  height: 2,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildWeatherCard() {
    if (_currentWeather == null) return Container();

    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: const ColorFilter.mode(Colors.black, BlendMode.srcOver),
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              children: [
                // Header with city name
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentWeather!.cityName.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                            fontFamily: 'Ethnocentric',
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _currentWeather!.date.toString().split(' ')[0],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                
                // Main temperature display
                Center(
                  child: Column(
                    children: [
                      Image.network(
                        _currentWeather!.iconUrl,
                        width: 150,
                        height: 150,
                        color: Colors.white,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.wb_sunny,
                            size: 120,
                            color: Colors.white,
                          );
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _currentWeather!.temperature.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 100,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Ethnocentric',
                              height: 0.9,
                            ),
                          ),
                          const Text(
                            '°C',
                            style: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        _currentWeather!.description.toUpperCase(),
                        style: TextStyle(
                          fontSize: 20,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 2,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Ethnocentric',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                
                // Weather details in futuristic style
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildDetailItem(
                        Icons.thermostat,
                        'FEELS',
                        '${_currentWeather!.feelsLike.toStringAsFixed(0)}°',
                      ),
                      _buildDetailItem(
                        Icons.water_drop,
                        'HUMIDITY',
                        '${_currentWeather!.humidity}%',
                      ),
                      _buildDetailItem(
                        Icons.air,
                        'WIND',
                        '${_currentWeather!.windSpeed.toStringAsFixed(1)} m/s',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                
                // Forecast button with neon effect
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      colors: [
                        Colors.blue.withOpacity(0.8),
                        Colors.purple.withOpacity(0.8),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 20,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ForecastScreen(city: _currentWeather!.cityName),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timeline, color: Colors.white),
                        const SizedBox(width: 10),
                        Text(
                          'VIEW FORECAST',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                            fontFamily: 'Ethnocentric',
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 1,
            fontFamily: 'Ethnocentric',
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Ethnocentric',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Animated background
          _buildAnimatedBackground(),
          
          // Main content
          SafeArea(
            child: _isLoading
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2,
                        ),
                    
                        const SizedBox(height: 20),
                        const Text(
                          'LOADING WEATHER DATA',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            letterSpacing: 2,
                            fontFamily: 'Ethnocentric',
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      // App bar
                      // App bar - تم تعديل هذا الجزء
Padding(
  padding: const EdgeInsets.all(20),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      // القائمة مع زر الاختبار
      PopupMenuButton<String>(
        icon: const Icon(Icons.menu, color: Colors.white),
        onSelected: (value) {
          if (value == 'test_notification') {
            _showTestNotification();
          }
        },
        itemBuilder: (context) => [
          const PopupMenuItem<String>(
            value: 'test_notification',
            child: Row(
              children: [
                Icon(Icons.notifications, color: Colors.orange),
                SizedBox(width: 10),
                Text('Test Notification'),
              ],
            ),
          ),
        ],
        color: Colors.grey[900],
      ),
      
      const Text(
        'MY WEATHER',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: Colors.white,
          letterSpacing: 3,
          fontFamily: 'Ethnocentric',
        ),
      ),
      
      IconButton(
        icon: const Icon(Icons.refresh, color: Colors.white),
        onPressed: _loadCurrentLocationWeather,
      ),
    ],
  ),
),
                      
                      // Search bar
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: Colors.white.withOpacity(0.2)),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _cityController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'SEARCH CITY...',
                                    hintStyle: TextStyle(
                                      color: Colors.white.withOpacity(0.5),
                                      fontFamily: 'Ethnocentric',
                                      letterSpacing: 1,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 15,
                                    ),
                                    prefixIcon: Icon(
                                      Icons.search,
                                      color: Colors.white.withOpacity(0.7),
                                    ),
                                  ),
                                  onSubmitted: _searchWeather,
                                ),
                              ),
                              Container(
                                margin: const EdgeInsets.only(right: 10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Colors.blue,
                                      Colors.purple,
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.search, color: Colors.white),
                                  onPressed: () => _searchWeather(_cityController.text),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Quick cities
                      SizedBox(
                        height: 40,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _popularCities.length,
                          itemBuilder: (context, index) {
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              child: ActionChip(
                                label: Text(
                                  _popularCities[index],
                                  style: const TextStyle(
                                    color: Color.fromARGB(255, 0, 0, 0),
                                    fontFamily: 'Ethnocentric',
                                    letterSpacing: 1,
                                  ),
                                ),
                                onPressed: () => _searchWeather(_popularCities[index]),
                                backgroundColor: Colors.white.withOpacity(0.1),
                                side: BorderSide(color: Colors.white.withOpacity(0.2)),
                              ),
                            );
                          },
                        ),
                      ),
                      
                      // Error message
                      if (_errorMessage.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.all(20),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(15),
                            border: Border.all(color: Colors.red.withOpacity(0.5)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error, color: Colors.red.shade300),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _errorMessage,
                                  style: TextStyle(
                                    color: Colors.red.shade200,
                                    fontFamily: 'Ethnocentric',
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      
                      // Weather card
                      Expanded(
                        child: SingleChildScrollView(
                          child: _currentWeather == null
                              ? SizedBox(
                                  height: 300,
                                  child: Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.cloud_off,
                                          size: 80,
                                          color: Colors.white.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 20),
                                        const Text(
                                          'NO WEATHER DATA',
                                          style: TextStyle(
                                            fontSize: 18,
                                            color: Colors.white,
                                            letterSpacing: 2,
                                            fontFamily: 'Ethnocentric',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : _buildWeatherCard(),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
      
      // Floating action button
      floatingActionButton: FloatingActionButton(
        onPressed: _loadCurrentLocationWeather,
        backgroundColor: Colors.white.withOpacity(0.2),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        child: const Icon(Icons.gps_fixed),
      ),
    );
  }
}