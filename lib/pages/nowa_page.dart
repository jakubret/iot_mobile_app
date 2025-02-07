import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_new_project/config.dart';
import 'package:my_new_project/pages/alert_page.dart';
import 'package:my_new_project/pages/configuration.dart';
import 'package:my_new_project/services/session.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Environment Monitor',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
        textTheme: GoogleFonts.poppinsTextTheme(
            Theme.of(context).textTheme), // Using Poppins as a modern font
      ),
      home: HomePageTemperature(topic: 'Environmental Data', sensorId: 10),
    );
  }
}

class HomePageTemperature extends StatefulWidget {
  final String topic;
  final int sensorId; // Accept sensorId as a parameter

  const HomePageTemperature({required this.topic, required this.sensorId});

  @override
  _HomePageTemperatureState createState() => _HomePageTemperatureState();
}

class _HomePageTemperatureState extends State<HomePageTemperature> {
  List<MeasurementData> measurements = [];
  bool isLoading = true;
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    fetchDataFromApi();
    WidgetsBinding.instance.addPostFrameCallback((_) => updateAlertStatus());
  }

  void updateAlertStatus() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> fetchDataFromApi(
      {DateTime? startTime, DateTime? endTime}) async {
    final userId = await SessionService.getUserID();
    if (userId == null) {
      throw Exception("User ID not found.");
    }

    try {
      String apiUrl =
          'http://${Config.apiURL}/api/sensors/${widget.sensorId}/readings';

      if (startTime != null && endTime != null) {
        apiUrl +=
            '?startTime=${startTime.toIso8601String()}&endTime=${endTime.toIso8601String()}';
      }

      final token = await SessionService.getToken();
      if (token == null) {
        throw Exception("Token not found. Please log in again.");
      }

      final response = await http.get(Uri.parse(apiUrl), headers: {
        'Authorization': 'Bearer $token',
      });
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          measurements = data.map((entry) {
            return MeasurementData(
              timestamp: DateTime.parse(entry['timestamp']),
              temperature: entry['temperature'] != null
                  ? entry['temperature'].toDouble()
                  : 0.0,
              humidity: entry['humidity'] != null
                  ? entry['humidity'].toDouble()
                  : 0.0,
              pressure: entry['pressure'] != null
                  ? entry['pressure'].toDouble()
                  : 0.0,
              lightIntensity: entry['lightIntensity'] != null
                  ? entry['lightIntensity'].toDouble()
                  : 0.0,
              soilMoisture: entry['soilMoisture'] != null
                  ? entry['soilMoisture'].toDouble()
                  : 0.0,
            );
          }).toList();
          isLoading = false;
        });
      } else {
        throw Exception(
            'Failed to fetch data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  DateTime? _startTime;
  DateTime? _endTime;

  Widget _buildDateTimePicker() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ElevatedButton(
          onPressed: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (pickedTime != null) {
                setState(() {
                  _startTime = DateTime(pickedDate.year, pickedDate.month,
                      pickedDate.day, pickedTime.hour, pickedTime.minute);
                });
              }
            }
          },
          child: Text(
            _startTime == null
                ? 'Start Time'
                : '${DateFormat('yyyy-MM-dd HH:mm').format(_startTime!)}',
          ),
        ),
        ElevatedButton(
          onPressed: () async {
            final DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (pickedDate != null) {
              final TimeOfDay? pickedTime = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.now(),
              );
              if (pickedTime != null) {
                setState(() {
                  _endTime = DateTime(pickedDate.year, pickedDate.month,
                      pickedDate.day, pickedTime.hour, pickedTime.minute);
                });
              }
            }
          },
          child: Text(
            _endTime == null
                ? 'End Time'
                : '${DateFormat('yyyy-MM-dd HH:mm').format(_endTime!)}',
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todayData =
        measurements.where((data) => data.timestamp.day == today.day).toList();
    final averageData = todayData.isNotEmpty
        ? todayData.reduce((a, b) => MeasurementData(
              timestamp: today,
              temperature: (a.temperature + b.temperature) / todayData.length,
              humidity: (a.humidity + b.humidity) / todayData.length,
              pressure: (a.pressure + b.pressure) / todayData.length,
              lightIntensity:
                  (a.lightIntensity + b.lightIntensity) / todayData.length,
              soilMoisture:
                  (a.soilMoisture + b.soilMoisture) / todayData.length,
            ))
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text('Environment Monitor', style: GoogleFonts.questrial()),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications,
              color: SessionService.hasPendingAlerts ? Colors.red : null,
            ),
            tooltip: 'Alerts',
            onPressed: () async {
              final userId = await SessionService.getUserID();
              if (userId != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AlertsScreen(userId: userId),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('User ID not found')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Configuration',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FormScreen(sensorId: widget.sensorId),
                ),
              );
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : errorMessage.isNotEmpty
              ? Center(child: Text(errorMessage))
              : SingleChildScrollView(
                  child: Column(
                    children: [
                      _buildDateTimePicker(),
                      ElevatedButton(
                        onPressed: () {
                          if (_startTime != null && _endTime != null) {
                            fetchDataFromApi(
                                startTime: _startTime, endTime: _endTime);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'Please select both start and end times.')),
                            );
                          }
                        },
                        child: Text('wczytaj dane'),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildCurrentDataSection(todayData),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildCurrentMeasurements(
                            todayData.isNotEmpty ? todayData.last : null),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: _buildVisualRepresentation(averageData),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: _buildWeeklyDataTable(measurements),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildNonPressureChart(measurements),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: _buildVisalPressureChart(measurements),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _buildCurrentDataSection(List<MeasurementData> todayData) {
    return Container(
      height: 150,
      child: ListView.builder(
        itemCount: todayData.length,
        itemBuilder: (context, index) => ListTile(
          title: Text(
              '${DateFormat('yyyy-MM-dd HH:mm').format(todayData[index].timestamp)} - Temp: ${todayData[index].temperature}°C',
              style: GoogleFonts.questrial()),
          subtitle: Text('Humidity: ${todayData[index].humidity}%',
              style: GoogleFonts.questrial()),
          trailing: Icon(Icons.thermostat_rounded),
        ),
      ),
    );
  }

  Widget _buildWeeklyDataTable(List<MeasurementData> data) {
    List<MeasurementData> filteredData = data;
    if (_startTime != null && _endTime != null) {
      filteredData = data
          .where((data) =>
              data.timestamp.isAfter(_startTime!) &&
              data.timestamp.isBefore(_endTime!))
          .toList();
    }

    return Container(
      height: 200, // You might need to adjust this for better visibility
      constraints: BoxConstraints(minHeight: 200, maxHeight: 300),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Scrollbar(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Timestamp')),
                DataColumn(label: Text('Temperature')),
                DataColumn(label: Text('Humidity')),
                DataColumn(label: Text('Pressure')),
                DataColumn(label: Text('Light Intensity')),
                DataColumn(label: Text('Soil Moisture')),
              ],
              rows: filteredData
                  .map((data) => DataRow(
                        cells: [
                          DataCell(Text(
                              '${DateFormat('yyyy-MM-dd HH:mm').format(data.timestamp)}')),
                          DataCell(
                              Text('${data.temperature.toStringAsFixed(1)}°C')),
                          DataCell(
                              Text('${data.humidity.toStringAsFixed(1)}%')),
                          DataCell(
                              Text('${data.pressure.toStringAsFixed(1)} hPa')),
                          DataCell(Text(
                              '${data.lightIntensity.toStringAsFixed(1)} lux')),
                          DataCell(
                              Text('${data.soilMoisture.toStringAsFixed(1)}%')),
                        ],
                      ))
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoricalLineChart(List<MeasurementData> data) {
    return Container(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat('MM/dd'),
          intervalType: DateTimeIntervalType.days,
          interval: 1,
          title: AxisTitle(text: 'Date'),
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'Values'),
        ),
        series: <LineSeries<MeasurementData, DateTime>>[
          LineSeries<MeasurementData, DateTime>(
            dataSource: data,
            xValueMapper: (MeasurementData data, _) => data.timestamp,
            yValueMapper: (MeasurementData data, _) => data.temperature,
            name: 'Temperature',
          ),
          LineSeries<MeasurementData, DateTime>(
            dataSource: data,
            xValueMapper: (MeasurementData data, _) => data.timestamp,
            yValueMapper: (MeasurementData data, _) => data.humidity,
            name: 'Humidity',
          ),
          LineSeries<MeasurementData, DateTime>(
            dataSource: data,
            xValueMapper: (MeasurementData data, _) => data.timestamp,
            yValueMapper: (MeasurementData data, _) => data.pressure,
            name: 'Pressure',
          ),
        ],
      ),
    );
  }

  Widget _buildNonPressureChart(List<MeasurementData> data) {
    return Container(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat('MM/dd'),
          intervalType: DateTimeIntervalType.days,
          interval: 1,
          title: AxisTitle(text: 'Date'),
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'Values'),
        ),
        legend: Legend(isVisible: true),
        series: <LineSeries<MeasurementData, DateTime>>[
          LineSeries<MeasurementData, DateTime>(
            dataSource: data,
            xValueMapper: (MeasurementData data, _) => data.timestamp,
            yValueMapper: (MeasurementData data, _) => data.temperature,
            name: 'Temperatura [°C]',
          ),
          LineSeries<MeasurementData, DateTime>(
            dataSource: data,
            xValueMapper: (MeasurementData data, _) => data.timestamp,
            yValueMapper: (MeasurementData data, _) => data.humidity,
            name: 'wilgotność [%]',
          ),
        ],
      ),
    );
  }

  Widget _buildVisalPressureChart(List<MeasurementData> data) {
    return Container(
      height: 300,
      child: SfCartesianChart(
        primaryXAxis: DateTimeAxis(
          dateFormat: DateFormat('MM/dd'),
          intervalType: DateTimeIntervalType.days,
          interval: 1,
          title: AxisTitle(text: 'Date'),
        ),
        primaryYAxis: NumericAxis(
          title: AxisTitle(text: 'Values'),
        ),
        legend: Legend(isVisible: true),
        series: <LineSeries<MeasurementData, DateTime>>[
          LineSeries<MeasurementData, DateTime>(
            dataSource: data,
            xValueMapper: (MeasurementData data, _) => data.timestamp,
            yValueMapper: (MeasurementData data, _) => data.pressure,
            name: 'Ciśnienie  [hPa]',
          ),
        ],
      ),
    );
  }

  Widget _buildVisualRepresentation(MeasurementData? data) {
    return data == null
        ? Container(
            height: 100,
            alignment: Alignment.center,
            child: Text("No data available for today.",
                style: GoogleFonts.questrial()),
          )
        : Container(
            height: 150,
            alignment: Alignment.center,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.spa, size: 50, color: Colors.green),
                Text(
                    'Średnia Temperatura: ${data.temperature.toStringAsFixed(2)}°C',
                    style: GoogleFonts.questrial()),
                Text('Średnia Wilgotność: ${data.humidity.toStringAsFixed(2)}%',
                    style: GoogleFonts.questrial()),
                Text(
                    'Średnie Ciśnienie: ${data.pressure.toStringAsFixed(2)} hPa',
                    style: GoogleFonts.questrial()),
                Text(
                    'Średnia intensywność światła: ${data.lightIntensity.toStringAsFixed(2)} lux',
                    style: GoogleFonts.questrial()),
                Text(
                    'Średnia wilgotność gleby: ${data.soilMoisture.toStringAsFixed(2)}%',
                    style: GoogleFonts.questrial()),
              ],
            ),
          );
  }

  Widget _buildCurrentMeasurements(MeasurementData? currentData) {
    if (currentData == null) {
      return Center(
        child: Text(
          'No current measurements available.',
          style: GoogleFonts.questrial(fontSize: 16),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Current Measurements',
            style: GoogleFonts.questrial(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blue[800]),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.thermostat, color: Colors.red, size: 30),
              const SizedBox(width: 10),
              Text(
                'Temperature: ${currentData.temperature.toStringAsFixed(1)}°C',
                style: GoogleFonts.questrial(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.water_drop, color: Colors.blue, size: 30),
              const SizedBox(width: 10),
              Text(
                'Humidity: ${currentData.humidity.toStringAsFixed(1)}%',
                style: GoogleFonts.questrial(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.compress, color: Colors.purple, size: 30),
              const SizedBox(width: 10),
              Text(
                'Pressure: ${currentData.pressure.toStringAsFixed(1)} hPa',
                style: GoogleFonts.questrial(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.light_mode, color: Colors.orange, size: 30),
              const SizedBox(width: 10),
              Text(
                'Light Intensity: ${currentData.lightIntensity.toStringAsFixed(1)} lux',
                style: GoogleFonts.questrial(fontSize: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.grass, color: Colors.green, size: 30),
              const SizedBox(width: 10),
              Text(
                'Soil Moisture: ${currentData.soilMoisture.toStringAsFixed(1)}%',
                style: GoogleFonts.questrial(fontSize: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class MeasurementData {
  final DateTime timestamp;
  final double temperature;
  final double humidity;
  final double pressure;
  final double lightIntensity;
  final double soilMoisture;

  MeasurementData({
    required this.timestamp,
    this.temperature = 0.0, // Domyślna wartość dla null
    this.humidity = 0.0,
    this.pressure = 0.0,
    this.lightIntensity = 0.0,
    this.soilMoisture = 0.0,
  });
}

List<MeasurementData> prepareChartData(
    List<MeasurementData> allData, DateTime? startTime, DateTime? endTime) {
  List<MeasurementData> filteredData = allData
      .where((data) =>
          data.timestamp.isAfter(startTime!) &&
          data.timestamp.isBefore(endTime!))
      .toList();

  if (filteredData.isEmpty && allData.isNotEmpty) {
    MeasurementData lastMeasurement = allData.last;
    MeasurementData extendedMeasurement = MeasurementData(
      timestamp: endTime ?? DateTime.now(),
      temperature: lastMeasurement.temperature,
      humidity: lastMeasurement.humidity,
      pressure: lastMeasurement.pressure,
      lightIntensity: lastMeasurement.lightIntensity,
      soilMoisture: lastMeasurement.soilMoisture,
    );
    filteredData = [lastMeasurement, extendedMeasurement];
  }

  return filteredData;
}
