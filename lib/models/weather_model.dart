class Weather {
  final String cityName;
  final String description;
  final double temperature;
  final double feelsLike;
  final int humidity;
  final double windSpeed;
  final String icon;
  final DateTime date;
  final double? minTemp;
  final double? maxTemp;

  Weather({
    required this.cityName,
    required this.description,
    required this.temperature,
    required this.feelsLike,
    required this.humidity,
    required this.windSpeed,
    required this.icon,
    required this.date,
    this.minTemp,
    this.maxTemp,
  });

  factory Weather.fromJson(Map<String, dynamic> json) {
    return Weather(
      cityName: json['name'],
      description: json['weather'][0]['description'],
      temperature: json['main']['temp'].toDouble(),
      feelsLike: json['main']['feels_like'].toDouble(),
      humidity: json['main']['humidity'],
      windSpeed: json['wind']['speed'].toDouble(),
      icon: json['weather'][0]['icon'],
      date: DateTime.fromMillisecondsSinceEpoch(json['dt'] * 1000),
      minTemp: json['main']['temp_min']?.toDouble(),
      maxTemp: json['main']['temp_max']?.toDouble(),
    );
  }

  String get iconUrl => 'https://openweathermap.org/img/wn/$icon@2x.png';
}