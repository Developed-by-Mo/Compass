// Player Stats Tab

import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:developer' as developer;
import '../services/player_services.dart';
import '../utils/theme_utils.dart';

class StatsTab extends StatefulWidget {
  final String accountId;
  final bool isDarkMode;

  const StatsTab({
    super.key,
    required this.accountId,
    required this.isDarkMode,
  });

  @override
  State<StatsTab> createState() => _StatsTabState();
}

class _StatsTabState extends State<StatsTab> {
  Map<String, dynamic> _playerStats = {};
  bool _isLoading = true;
  String _errorMessage = '';
  int _touchedIndex = -1;
  List<Map<String, dynamic>> _winrateHistory = [];
  bool _isWinrateLoading = true;
  String _winrateErrorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchPlayerStats();
    _fetchWinrateHistory();
  }

  Future<void> _fetchWinrateHistory() async {
    try {
      developer.log('Fetching winrate history for account: ${widget.accountId}');
      final history = await PlayerService.fetchWinrateHistory(widget.accountId);

      developer.log('Received winrate history: $history');

      setState(() {
        _winrateHistory = history;
        _isWinrateLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching winrate history', error: e);
      setState(() {
        _winrateErrorMessage = 'Failed to fetch winrate history: $e';
        _isWinrateLoading = false;
      });
    }
  }

  List<FlSpot> _generateWinrateSpots() {
    return _winrateHistory.asMap().entries.map((entry) {
      final index = entry.key;
      final data = entry.value;
      return FlSpot(
          (data['matchCount'] as int).toDouble(),
          double.parse(data['winrate'].toString())
      );
    }).toList();
  }

  Future<void> _fetchPlayerStats() async {
    try {
      developer.log('Fetching stats for account: ${widget.accountId}');
      final stats = await PlayerService.fetchPlayerStats(widget.accountId);

      developer.log('Received stats: $stats');

      setState(() {
        _playerStats = stats ?? {}; // Ensure stats is not null
        _isLoading = false;
      });
    } catch (e) {
      developer.log('Error fetching stats', error: e);
      setState(() {
        _errorMessage = 'Failed to fetch player statistics: $e';
        _isLoading = false;
      });
    }
  }

  List<PieChartSectionData> _generateWinrateSections() {
    final wins = _playerStats['winCount'] ?? 0;
    final totalMatches = _playerStats['matchCount'] ?? 0;
    final losses = totalMatches - wins;

    return List.generate(2, (i) {
      final isTouched = i == _touchedIndex;
      final fontSize = isTouched ? 25.0 : 16.0;
      final radius = isTouched ? 60.0 : 50.0;
      const shadows = [Shadow(color: Colors.black, blurRadius: 2)];

      if (i == 0) {
        return PieChartSectionData(
          color: Colors.green[400],
          value: wins.toDouble(),
          title: 'Wins\n$wins',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: shadows,
          ),
        );
      } else {
        return PieChartSectionData(
          color: Colors.red[400],
          value: losses.toDouble(),
          title: 'Losses\n$losses',
          radius: radius,
          titleStyle: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: shadows,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            widget.isDarkMode ? Colors.white : Colors.grey[800]!,
          ),
          strokeWidth: 3,
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    // If no stats are available, show a message
    if (_playerStats.isEmpty) {
      return Center(
        child: Text(
          'No player statistics available',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black,
            fontSize: 18,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card-style container for player overview
            Container(
              decoration: BoxDecoration(
                color: widget.isDarkMode ? Colors.grey[900] : Colors.grey[200],
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Player Statistics',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _buildStatRow(
                    'First Match',
                    _formatFirstMatchDate(_playerStats['firstMatchDate']),
                  ),
                  _buildStatRow(
                    'Total Matches',
                    '${_playerStats['matchCount']}',
                  ),
                  _buildStatRow(
                    'Lifetime Winrate',
                    '${_calculateWinrate()}%',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (!_isWinrateLoading && _winrateHistory.isNotEmpty) ...[
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Colors.grey[900] : Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      spreadRadius: 2,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Winrate History',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: widget.isDarkMode ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    AspectRatio(
                      aspectRatio: 1.5,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: true,
                            horizontalInterval: 10,
                            verticalInterval: 10,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: widget.isDarkMode
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                              strokeWidth: 1,
                            ),
                            getDrawingVerticalLine: (value) => FlLine(
                              color: widget.isDarkMode
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            show: true,
                            rightTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            topTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 30,
                                interval: 10,
                                getTitlesWidget: (value, meta) => Text(
                                  value.toInt().toString(),
                                  style: TextStyle(
                                    color: widget.isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 10,
                                getTitlesWidget: (value, meta) => Text(
                                  '${value.toInt()}%',
                                  style: TextStyle(
                                    color: widget.isDarkMode
                                        ? Colors.white70
                                        : Colors.black54,
                                    fontSize: 12,
                                  ),
                                ),
                                reservedSize: 40,
                              ),
                            ),
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: Border.all(
                              color: widget.isDarkMode
                                  ? Colors.white24
                                  : Colors.grey.shade300,
                            ),
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: _generateWinrateSpots(),
                              isCurved: true,
                              color: Colors.blue.shade400,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, barData, index) =>
                                    FlDotCirclePainter(
                                      radius: 4,
                                      color: Colors.blue.shade600,
                                      strokeWidth: 2,
                                      strokeColor: widget.isDarkMode
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.blue.shade400.withOpacity(0.5),
                                    Colors.blue.shade400.withOpacity(0.1),
                                  ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                              ),
                            ),
                          ],
                          minX: 0,
                          maxX: _winrateHistory.last['matchCount'].toDouble(),
                          minY: 0,
                          maxY: 100,
                        ),
                      ),
                    ),
                    Center(
                      child: Text("Match Count",             style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.white70 : Colors.black87,
                      ),),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 100),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              color: widget.isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFirstMatchDate(int? timestamp) {
    if (timestamp == null) return 'Unknown';
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return '${date.day}/${date.month}/${date.year}';
  }

  double _calculateWinrate() {
    final wins = _playerStats['winCount'] ?? 0;
    final totalMatches = _playerStats['matchCount'] ?? 0;

    if (totalMatches == 0) return 0.0;

    return double.parse(((wins / totalMatches) * 100).toStringAsFixed(2));
  }
}