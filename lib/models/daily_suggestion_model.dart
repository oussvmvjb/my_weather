import 'package:my_weather/models/weather_model.dart';

class DailySuggestion {
  final DateTime startTime;
  final DateTime endTime;
  final String suggestion;
  final List<String> options;
  final String icon;
  final double? temperature;
  final String? weatherConditions;

  DailySuggestion({
    required this.startTime,
    required this.endTime,
    required this.suggestion,
    required this.options,
    this.icon = '☀️',
    this.temperature,
    this.weatherConditions,
  });
}

// دالة توليد الاقتراحات المعدلة
List<DailySuggestion> generateDailySuggestions(List<Weather> forecasts) {
  List<DailySuggestion> suggestions = [];

  for (var forecast in forecasts) {
    DateTime date = forecast.date;
    String desc = forecast.description.toLowerCase();
    double temp = forecast.temperature;
    double wind = forecast.windSpeed;
    int humidity = forecast.humidity;

    String weatherConditions = 'Temp: ${temp.toStringAsFixed(1)}°C';
    if (wind > 10) weatherConditions += ', Wind: ${wind.toStringAsFixed(1)} m/s';
    if (humidity > 70) weatherConditions += ', Humidity: $humidity%';

    // 1. Morning 6–9
    if (date.hour >= 6 && date.hour < 9) {
      if (desc.contains('rain')) {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'Rain expected this morning. Stay indoors or leave early.',
          options: ['Leave early', 'Stay inside', 'Take an umbrella'],
          icon: '🌧️',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      } else if (temp < 12) {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'It creates a chilly morning. Wear a warm coat if you go out.',
          options: ['Go out', 'Stay inside'],
          icon: '🧥',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      } else {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'Sunny morning! Great for outdoor activities.',
          options: ['Go for a walk', 'Coffee at home'],
          icon: '☀️',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      }
    }

    // 2. Mid-Morning 9–12
    if (date.hour >= 9 && date.hour < 12) {
      if (desc.contains('rain')) {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'Continuous rain. Keep dry indoors or use an umbrella.',
          options: ['Stay inside', 'Take an umbrella'],
          icon: '☔',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      } else if (temp > 25) {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'High heat. Avoid strenuous outdoor activities.',
          options: ['Stay inside', 'Go to the pool'],
          icon: '🌞',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      } else {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'Mild weather. Good for a short walk or shopping.',
          options: ['Go shopping', 'Walk in the park'],
          icon: '🌤️',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      }
    }

    // 3. Afternoon 12–16
    if (date.hour >= 12 && date.hour < 16) {
      if (wind > 15) {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'Strong winds. Be careful if you go out.',
          options: ['Stay inside', 'Go carefully'],
          icon: '💨',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      } else if (desc.contains('clear')) {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'Sunny afternoon! Perfect for sports or cycling.',
          options: ['Do sports', 'Go for a walk'],
          icon: '🚴',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      } else {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'Cloudy patches. Good time for indoor activities.',
          options: ['Read a book', 'Work on a project'],
          icon: '📚',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      }
    }

    // 4. Late Afternoon 16–20
    if (date.hour >= 16 && date.hour < 20) {
      if (desc.contains('rain')) {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'Scattered showers. Stay indoors or take an umbrella.',
          options: ['Stay inside', 'Take an umbrella'],
          icon: '🌧️',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      } else if (temp < 15) {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'Chilly weather. Nice for a warm drink or a movie.',
          options: ['Stay inside', 'Go to a cafe'],
          icon: '☕',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      } else {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'Pleasant afternoon. You could visit a friend.',
          options: ['Go for a walk', 'Visit a friend'],
          icon: '🌆',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      }
    }

    // 5. Evening 20–24
    if (date.hour >= 20 && date.hour < 24) {
      if (desc.contains('clear')) {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'Clear evening. Stargazing or a light walk is possible.',
          options: ['Go for a walk', 'Stay inside'],
          icon: '🌙',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      } else {
        suggestions.add(DailySuggestion(
          startTime: date,
          endTime: date.add(const Duration(hours: 2)),
          suggestion: 'Weather not ideal for going out. Enjoy your home.',
          options: ['Stay inside', 'Read a book'],
          icon: '🏠',
          temperature: temp,
          weatherConditions: weatherConditions,
        ));
      }
    }
  }

  // أخذ أول 20 اقتراح وتنظيمها حسب الوقت
  suggestions.sort((a, b) => a.startTime.compareTo(b.startTime));
  return suggestions.take(20).toList();
}