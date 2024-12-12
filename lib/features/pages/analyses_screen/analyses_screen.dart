import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:health_controller_app/features/database/databasehelper.dart';

class AnalysesScreen extends StatefulWidget {
  const AnalysesScreen({super.key});

  @override
  State<AnalysesScreen> createState() => _AnalysesScreenState();
}

class _AnalysesScreenState extends State<AnalysesScreen> {
  String _selectedChart = "steps";
  List<BarChartGroupData> _chartDataSteps = [];
  List<BarChartGroupData> _chartDataHeartRate = [];
  List<BarChartGroupData> _chartDataSleep = [];
  List<BarChartGroupData> _chartDataWeight = [];
  List<String> _dates = [];

  @override
  void initState() {
    super.initState();
    _loadChartData();
    _loadDates();
  }

  Future<void> _loadChartData() async {
    final stepsData = await DatabaseHelper.getChartData("steps");
    final heartRateData = await DatabaseHelper.getChartData("heart_rate");
    final sleepData = await DatabaseHelper.getChartData("sleep");
    final weightData = await DatabaseHelper.getChartData("weight");

    setState(() {
      _chartDataSteps = _mapChartData(stepsData, Colors.redAccent);
      _chartDataHeartRate = _mapChartDataForDouble(heartRateData, Colors.blue);
      _chartDataSleep = _mapChartData(sleepData, Colors.green);
      _chartDataWeight = _mapChartDataForDouble(weightData, Colors.purple);
    });
  }

  Future<void> _loadDates() async {
    final dbHelper = DatabaseHelper();
    final datesData = await dbHelper.getDates();
    setState(() {
      _dates = datesData.map((date) => date['date'] as String).toList();
    });
  }

  List<BarChartGroupData> _mapChartDataForDouble(
      List<Map<String, dynamic>> data, Color color) {
    final regex = RegExp(r'\d+(\.\d+)?');

    return data.asMap().entries.map((entry) {
      int index = entry.key;
      var item = entry.value;

      String? rawValue = item['value']?.toString();
      double value = 0.0;
      if (rawValue != null) {
        final match = regex.firstMatch(rawValue);
        if (match != null) {
          value = double.tryParse(match.group(0) ?? '0.0') ?? 0.0;
        }
      }

      return BarChartGroupData(
        x: index,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: value,
            color: color,
          ),
        ],
      );
    }).toList();
  }

  List<BarChartGroupData> _mapChartData(
      List<Map<String, dynamic>> data, Color color) {
    return data.asMap().entries.map((entry) {
      int index = entry.key;
      var item = entry.value;

      var value = item['value'];

      double toY = 10.0;
      if (value is String) {
        toY = double.tryParse(value) ?? 0.0;
      } else if (value is int) {
        toY = value.toDouble();
      } else if (value is double) {
        toY = value;
      }

      return BarChartGroupData(
        x: index,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: toY,
            color: color,
          ),
        ],
      );
    }).toList();
  }

  String _getFormattedTitle(double value) {
    switch (_selectedChart) {
      case "steps":
      case "sleep":
        return value.toInt().toString();
      case "heart_rate":
      case "weight":
        return value.toStringAsFixed(1);
      default:
        return value.toString();
    }
  }

  String _getFormattedDate(int value) {
    if (_dates.isNotEmpty && value < _dates.length) {
      return _dates[value];
    }
    return 'N/A';
  }

  @override
  Widget build(BuildContext context) {
    double maxY;
    List<BarChartGroupData> chartData;

    switch (_selectedChart) {
      case "heart_rate":
        maxY = 200.0;
        chartData = _chartDataHeartRate;
        break;
      case "weight":
        maxY = 200.0;
        chartData = _chartDataWeight;
        break;
      case "steps":
        maxY = _chartDataSteps.isNotEmpty
            ? _chartDataSteps
                .map((group) => group.barRods[0].toY)
                .reduce((a, b) => a > b ? a : b)
            : 10000;
        chartData = _chartDataSteps;
        break;
      case "sleep":
        maxY = 12.0;
        chartData = _chartDataSleep;
        break;
      default:
        maxY = 100.0;
        chartData = [];
        break;
    }

    return Scaffold(
      backgroundColor: Colors.red.shade100,
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.red.shade200,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(4, 5),
                    ),
                  ],
                ),
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.35,
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: BarChart(
                    BarChartData(
                      gridData: const FlGridData(show: true),
                      borderData: FlBorderData(
                        border: const Border(
                          top: BorderSide.none,
                          right: BorderSide.none,
                          left: BorderSide(width: 1),
                          bottom: BorderSide(width: 1),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _getFormattedTitle(value),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                _getFormattedDate(value.toInt()),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: false,
                          ),
                        ),
                      ),
                      barGroups: chartData,
                      maxY: maxY,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.count(
                shrinkWrap: true,
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3,
                children: [
                  _buildChartButton("steps"),
                  _buildChartButton("heart_rate"),
                  _buildChartButton("sleep"),
                  _buildChartButton("weight"),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartButton(String chartType) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: _selectedChart == chartType
            ? Colors.redAccent
            : Colors.red.shade200,
        foregroundColor:
            _selectedChart == chartType ? Colors.white : Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        elevation: 5,
      ),
      onPressed: () {
        setState(() {
          _selectedChart = chartType;
        });
      },
      child: Text(
        chartType == "heart_rate" ? "Heart Rate" : chartType.capitalize(),
        style: const TextStyle(fontSize: 14),
      ),
    );
  }
}

extension on String {
  String capitalize() {
    return this[0].toUpperCase() + substring(1);
  }
}
