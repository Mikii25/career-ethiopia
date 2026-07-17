import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/weather_model.dart';
import '../services/weather_service.dart';

class WeatherDashboard extends StatefulWidget {
  const WeatherDashboard({Key? key}) : super(key: key);

  @override
  State<WeatherDashboard> createState() => _WeatherDashboardState();
}

class _WeatherDashboardState extends State<WeatherDashboard> {
  late Future<Weather> _weatherFuture;
  late Future<List<ForecastDay>> _forecastFuture;
  final TextEditingController _cityController = TextEditingController();
  String _currentCity = 'Addis Ababa';

  @override
  void initState() {
    super.initState();
    _loadWeather();
  }

  void _loadWeather() {
    setState(() {
      _weatherFuture = WeatherService.getCurrentWeather(_currentCity);
      _forecastFuture = WeatherService.getForecast(_currentCity);
    });
  }

  void _searchCity(String city) {
    if (city.isNotEmpty) {
      setState(() {
        _currentCity = city;
        _loadWeather();
      });
      _cityController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Dashboard'),
        elevation: 0,
        backgroundColor: Colors.blue.shade400,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search Bar
            Container(
              color: Colors.blue.shade400,
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityController,
                      decoration: InputDecoration(
                        hintText: 'Search city...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: _searchCity,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () => _searchCity(_cityController.text),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.blue.shade400,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Search'),
                  ),
                ],
              ),
            ),
            // Current Weather
            FutureBuilder<Weather>(
              future: _weatherFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  );
                } else if (snapshot.hasError) {
                  return Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'Error: ${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                } else if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No data'),
                  );
                }

                final weather = snapshot.data!;
                return Container(
                  color: Colors.blue.shade50,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Text(
                        '${weather.city}, ${weather.country}',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Image.network(
                        WeatherService.getWeatherIconUrl(weather.icon),
                        width: 120,
                        height: 120,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${weather.temperature.toStringAsFixed(1)}°C',
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        weather.description,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        'Feels like ${weather.feelsLike.toStringAsFixed(1)}°C',
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 24),
                      // Weather Details Grid
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.5,
                        children: [
                          _buildWeatherCard(
                            'Humidity',
                            '${weather.humidity}%',
                            Icons.opacity,
                          ),
                          _buildWeatherCard(
                            'Wind Speed',
                            '${weather.windSpeed.toStringAsFixed(1)} m/s',
                            Icons.air,
                          ),
                          _buildWeatherCard(
                            'Pressure',
                            '${weather.pressure.toStringAsFixed(0)} hPa',
                            Icons.compress,
                          ),
                          _buildWeatherCard(
                            'Visibility',
                            '${(weather.visibility / 1000).toStringAsFixed(1)} km',
                            Icons.visibility,
                          ),
                          _buildWeatherCard(
                            'Cloudiness',
                            '${weather.cloudiness}%',
                            Icons.cloud,
                          ),
                          _buildWeatherCard(
                            'UV Index',
                            'N/A',
                            Icons.sunny,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Sunrise/Sunset
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildSunCard(
                            'Sunrise',
                            DateFormat('HH:mm').format(weather.sunrise),
                            Icons.sunrise,
                          ),
                          _buildSunCard(
                            'Sunset',
                            DateFormat('HH:mm').format(weather.sunset),
                            Icons.sunset,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
            // 5-Day Forecast
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '5-Day Forecast',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  FutureBuilder<List<ForecastDay>>(
                    future: _forecastFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircularProgressIndicator();
                      } else if (snapshot.hasError) {
                        return Text('Error: ${snapshot.error}');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No forecast data');
                      }

                      final forecasts = snapshot.data!;
                      // Get unique days (one forecast per day)
                      final uniqueForecasts = <String, ForecastDay>{};
                      for (var forecast in forecasts) {
                        final dateKey =
                            DateFormat('yyyy-MM-dd').format(forecast.dateTime);
                        if (!uniqueForecasts.containsKey(dateKey)) {
                          uniqueForecasts[dateKey] = forecast;
                        }
                      }

                      return SizedBox(
                        height: 150,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: uniqueForecasts.entries
                              .take(5)
                              .map(
                                (entry) => _buildForecastCard(entry.value),
                              )
                              .toList(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Colors.blue),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSunCard(String title, String time, IconData icon) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, size: 32, color: Colors.orange),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForecastCard(ForecastDay forecast) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              DateFormat('MMM d').format(forecast.dateTime),
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Image.network(
              WeatherService.getWeatherIconUrl(forecast.icon),
              width: 40,
              height: 40,
            ),
            const SizedBox(height: 8),
            Text(
              '${forecast.tempMax.toStringAsFixed(0)}°',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${forecast.tempMin.toStringAsFixed(0)}°',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
