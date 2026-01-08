import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import '../services/weather_service.dart';
import '../models/weather_model.dart';

class ForecastScreen extends StatefulWidget {
  final String city;

  const ForecastScreen({super.key, required this.city});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> with SingleTickerProviderStateMixin {
  List<Weather> _forecasts = [];
  bool _isLoading = false;
  String _errorMessage = '';
  
  // Animation
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Timer _bgTimer;
  int _bgIndex = 0;
  final List<Color> _bgColors = [
    Colors.deepPurple.shade900,
    Colors.blue.shade900,
    Colors.teal.shade900,
    Colors.indigo.shade900,
    Colors.purple.shade900,
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 15),
    )..repeat(reverse: true);
    
    _animation = Tween<double>(begin: -0.05, end: 0.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    // Background color animation
    _bgTimer = Timer.periodic(const Duration(seconds: 8), (timer) {
      setState(() {
        _bgIndex = (_bgIndex + 1) % _bgColors.length;
      });
    });
    
    _loadForecast();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bgTimer.cancel();
    super.dispose();
  }

  Future<void> _loadForecast() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final forecastData = await WeatherService.getWeatherForecast(widget.city);
      final List<dynamic> list = forecastData['list'];
      
      // Group forecasts by day
      final Map<String, dynamic> dailyForecasts = {};
      
      for (var item in list) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(item['dt'] * 1000);
        final dateKey = DateFormat('yyyy-MM-dd').format(dateTime);
        
        // Get forecast closest to 12:00
        if (!dailyForecasts.containsKey(dateKey) ||
            (item['dt'] * 1000 - DateTime(dateTime.year, dateTime.month, dateTime.day, 12).millisecondsSinceEpoch).abs() <
            (dailyForecasts[dateKey]['dt'] * 1000 - DateTime(dateTime.year, dateTime.month, dateTime.day, 12).millisecondsSinceEpoch).abs()) {
          dailyForecasts[dateKey] = {
            ...item,
            'hour': dateTime.hour,
            'dateTime': dateTime,
          };
        }
      }
      
      // Get next 5 days
      final today = DateTime.now();
      final weatherList = dailyForecasts.values
          .where((item) => item['dateTime'].isAfter(today))
          .take(5)
          .map((item) {
            return Weather.fromJson({
              ...item,
              'name': widget.city,
            });
          })
          .toList();

      setState(() {
        _forecasts = weatherList;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'FORECAST DATA UNAVAILABLE';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _getDayName(DateTime date) {
    final today = DateTime.now();
    final tomorrow = today.add(const Duration(days: 1));
    
    if (date.year == today.year && date.month == today.month && date.day == today.day) {
      return 'TODAY';
    } else if (date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day) {
      return 'TOMORROW';
    } else {
      return DateFormat('EEEE').format(date).toUpperCase();
    }
  }

  Color _getTempColor(double temp) {
    if (temp < 10) return Colors.cyan;
    if (temp < 20) return Colors.blue;
    if (temp < 30) return Colors.orange;
    return Colors.red;
  }

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Stack(
          children: [
            // Animated gradient background
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
            
            // Animated grid lines
            CustomPaint(
              painter: GridPainter(animationValue: _animation.value),
            ),
            
            // Floating particles
            for (int i = 0; i < 15; i++)
              Positioned(
                left: (MediaQuery.of(context).size.width * 0.9) * (i / 15),
                top: 50 + 30 * (i % 5) + 80 * _animation.value * (i % 3 == 0 ? 1 : -1),
                child: Container(
                  width: 1.5,
                  height: 1.5,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildForecastCard(Weather forecast, int index) {
    final dayName = _getDayName(forecast.date);
    final formattedDate = DateFormat('MMM d').format(forecast.date).toUpperCase();
    final tempColor = _getTempColor(forecast.temperature);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: const ColorFilter.mode(Colors.black, BlendMode.srcOver),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Day and date - Left side
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dayName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 2,
                          fontFamily: 'Ethnocentric',
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        formattedDate,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                          letterSpacing: 1.5,
                          fontFamily: 'Ethnocentric',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: tempColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: tempColor.withOpacity(0.4)),
                        ),
                        child: Text(
                          forecast.date.hour.toString().padLeft(2, '0') + ':00',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'Ethnocentric',
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Weather icon - Center
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 15),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Image.network(
                    forecast.iconUrl,
                    width: 50,
                    height: 50,
                    color: Colors.white,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.cloud,
                        size: 40,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
                
                // Temperature and details - Right side
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      // Main temperature
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            forecast.temperature.toStringAsFixed(0),
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              fontFamily: 'Ethnocentric',
                              height: 0.9,
                            ),
                          ),
                          const Text(
                            '°C',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w300,
                              color: Colors.white,
                              fontFamily: 'Ethnocentric',
                            ),
                          ),
                        ],
                      ),
                      
                      // Weather description
                      Text(
                        forecast.description.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Ethnocentric',
                        ),
                        textAlign: TextAlign.right,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      
                      const SizedBox(height: 15),
                      
                      // Weather details in horizontal row
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildDetailItem(
                              Icons.thermostat,
                              'FEELS',
                              '${forecast.feelsLike.toStringAsFixed(0)}°',
                              Colors.orange,
                            ),
                            _buildDetailItem(
                              Icons.water_drop,
                              'HUM',
                              '${forecast.humidity}%',
                              Colors.blue,
                            ),
                            _buildDetailItem(
                              Icons.air,
                              'WIND',
                              '${forecast.windSpeed.toStringAsFixed(1)}',
                              Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailItem(IconData icon, String title, String value, Color color) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 5),
        Text(
          title,
          style: TextStyle(
            fontSize: 10,
            color: Colors.white.withOpacity(0.7),
            letterSpacing: 1,
            fontFamily: 'Ethnocentric',
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Ethnocentric',
          ),
        ),
      ],
    );
  }

  Widget _buildHourlySection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: Colors.white.withOpacity(0.8), size: 22),
              const SizedBox(width: 10),
              Text(
                'HOURLY OUTLOOK',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  fontFamily: 'Ethnocentric',
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 8,
              itemBuilder: (context, index) {
                final hour = (DateTime.now().hour + index * 3) % 24;
                final isCurrentHour = index == 0;
                
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: isCurrentHour ? Colors.blue.withOpacity(0.3) : Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isCurrentHour ? Colors.blue : Colors.white.withOpacity(0.2),
                      width: isCurrentHour ? 2 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '${hour.toString().padLeft(2, '0')}:00',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Ethnocentric',
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Icon(
                        Icons.cloud,
                        size: 30,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        '${24 + index * 2}°',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          fontFamily: 'Ethnocentric',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
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
            child: Column(
              children: [
                // App bar
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'FORECAST MODULE',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.white.withOpacity(0.7),
                                letterSpacing: 3,
                                fontFamily: 'Ethnocentric',
                              ),
                            ),
                            Text(
                              widget.city.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 2,
                                fontFamily: 'Ethnocentric',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.blue, Colors.purple],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '5-DAY',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 2,
                            fontFamily: 'Ethnocentric',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                if (_isLoading)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'ANALYZING WEATHER DATA',
                            style: TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              letterSpacing: 2,
                              fontFamily: 'Ethnocentric',
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Please wait...',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.7),
                              fontFamily: 'Ethnocentric',
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else if (_errorMessage.isNotEmpty)
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 80,
                            color: Colors.red.withOpacity(0.8),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _errorMessage,
                            style: TextStyle(
                              fontSize: 20,
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              fontFamily: 'Ethnocentric',
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.blue, Colors.purple],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: ElevatedButton(
                              onPressed: _loadForecast,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              child: Text(
                                'RETRY ANALYSIS',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: 2,
                                  fontFamily: 'Ethnocentric',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: RefreshIndicator(
                      color: Colors.white,
                      backgroundColor: Colors.transparent,
                      onRefresh: _loadForecast,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Hourly forecast section
                            // _buildHourlySection(),
                            // const SizedBox(height: 10),
                            
                            // Daily forecast title
                            Padding(
                              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                              child: Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.8), size: 22),
                                  const SizedBox(width: 10),
                                  Text(
                                    'DAILY FORECAST',
                                    style: TextStyle(
                                      fontSize: 20,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2,
                                      fontFamily: 'Ethnocentric',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Forecast list
                            if (_forecasts.isEmpty)
                              Padding(
                                padding: const EdgeInsets.all(40),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.cloud_off,
                                      size: 80,
                                      color: Colors.white.withOpacity(0.5),
                                    ),
                                    const SizedBox(height: 20),
                                    Text(
                                      'NO FORECAST DATA',
                                      style: TextStyle(
                                        fontSize: 20,
                                        color: Colors.white,
                                        letterSpacing: 2,
                                        fontFamily: 'Ethnocentric',
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      'Try another city',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.white.withOpacity(0.7),
                                        fontFamily: 'Ethnocentric',
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              Column(
                                children: _forecasts.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final forecast = entry.value;
                                  return _buildForecastCard(forecast, index);
                                }).toList(),
                              ),
                            
                            // Footer info
                            Container(
                              margin: const EdgeInsets.all(20),
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: Colors.white.withOpacity(0.1)),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info,
                                    color: Colors.blue.withOpacity(0.8),
                                    size: 22,
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Text(
                                      'FORECAST UPDATES EVERY 3 HOURS • DATA SOURCE: OPENWEATHER API',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withOpacity(0.7),
                                        fontFamily: 'Ethnocentric',
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Floating action button
          if (_forecasts.isNotEmpty)
            Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue, Colors.purple],
                  ),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(0.5),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: FloatingActionButton.extended(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'SHARE FEATURE ACTIVATED',
                          style: TextStyle(
                            fontFamily: 'Ethnocentric',
                            letterSpacing: 1,
                          ),
                        ),
                        backgroundColor: Colors.blue,
                      ),
                    );
                  },
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  icon: const Icon(Icons.share),
                  label: Text(
                    'SHARE',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontFamily: 'Ethnocentric',
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Custom painter for grid lines
class GridPainter extends CustomPainter {
  final double animationValue;
  
  GridPainter({required this.animationValue});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    // Draw vertical lines
    for (double x = 0; x < size.width; x += 50) {
      canvas.drawLine(
        Offset(x + animationValue * 10, 0),
        Offset(x + animationValue * 10, size.height),
        paint,
      );
    }
    
    // Draw horizontal lines
    for (double y = 0; y < size.height; y += 50) {
      canvas.drawLine(
        Offset(0, y - animationValue * 10),
        Offset(size.width, y - animationValue * 10),
        paint,
      );
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}