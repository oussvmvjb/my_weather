import 'dart:convert';
import 'package:http/http.dart' as http;

class WeatherService {
  // استخدم API Key مباشرة (للاختبار فقط)
  static const String apiKey = '473673230f6f10dd5af735e56eb861d6';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // جلب الطقس الحالي
  static Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather?q=$city&appid=$apiKey&units=metric&lang=ar'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 404) {
        throw Exception('المدينة غير موجودة');
      } else if (response.statusCode == 401) {
        throw Exception('API Key غير صالح');
      } else {
        throw Exception('فشل في جلب البيانات: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // جلب توقعات 5 أيام
  static Future<Map<String, dynamic>> getWeatherForecast(String city) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/forecast?q=$city&appid=$apiKey&units=metric&lang=ar'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('فشل في جلب التوقعات: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }

  // الحصول على الطقس حسب الموقع الجغرافي
  static Future<Map<String, dynamic>> getWeatherByLocation(double lat, double lon) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=ar'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('فشل في جلب البيانات');
      }
    } catch (e) {
      throw Exception('خطأ في الاتصال: $e');
    }
  }
}