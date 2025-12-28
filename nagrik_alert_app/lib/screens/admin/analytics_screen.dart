import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../../core/theme.dart';
import '../../providers/incident_provider.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                'assets/images/logo.png',
                height: 24,
                width: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Text('Analytics'),
          ],
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF138808), Color(0xFF0D6B06)],
            ),
          ),
        ),
        foregroundColor: Colors.white,
      ),
      body: Consumer<IncidentProvider>(
        builder: (context, provider, _) {
          final stats = provider.statistics;
          final incidents = provider.incidents;

          if (stats == null || stats.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading analytics...'),
                ],
              ),
            );
          }

          final byType = (stats['by_type'] as Map<String, dynamic>?) ?? {};
          final byStatus = (stats['by_status'] as Map<String, dynamic>?) ?? {};

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary Cards
                _buildSummaryCards(stats),
                const SizedBox(height: 24),

                // Incidents by Type Pie Chart
                _buildSectionTitle('Incidents by Type'),
                const SizedBox(height: 12),
                _buildPieChart(byType),
                const SizedBox(height: 24),

                // Incidents by Status Bar Chart
                _buildSectionTitle('Incidents by Status'),
                const SizedBox(height: 12),
                _buildStatusBarChart(byStatus),
                const SizedBox(height: 24),

                // Severity Distribution
                _buildSectionTitle('Severity Distribution'),
                const SizedBox(height: 12),
                _buildSeverityChart(incidents),
                const SizedBox(height: 24),

                // Weekly Trend
                _buildSectionTitle('Weekly Trend'),
                const SizedBox(height: 12),
                _buildWeeklyTrend(incidents),
                const SizedBox(height: 24),

                // Top Incident Types
                _buildSectionTitle('Top Reported Issues'),
                const SizedBox(height: 12),
                _buildTopIssues(byType),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF000080),
      ),
    );
  }

  Widget _buildSummaryCards(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Incidents',
          '${stats['total'] ?? 0}',
          Icons.report,
          const Color(0xFF000080),
        ),
        _buildStatCard(
          'Today',
          '${stats['last_24_hours'] ?? 0}',
          Icons.today,
          const Color(0xFFFF9933),
        ),
        _buildStatCard(
          'Pending',
          '${stats['by_status']?['unverified'] ?? 0}',
          Icons.pending,
          Colors.orange,
        ),
        _buildStatCard(
          'Resolved',
          '${stats['by_status']?['resolved'] ?? 0}',
          Icons.check_circle,
          const Color(0xFF138808),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, dynamic> byType) {
    if (byType.isEmpty) {
      return const Center(child: Text('No data available'));
    }

    final colors = [
      const Color(0xFFFF9933),
      const Color(0xFF138808),
      const Color(0xFF000080),
      Colors.purple,
      Colors.teal,
      Colors.pink,
    ];

    final entries = byType.entries.toList();
    final total = entries.fold<int>(0, (sum, e) => sum + (e.value as int));

    return SizedBox(
      height: 200,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final type = entry.value.key;
                  final count = entry.value.value as int;
                  final percentage = total > 0 ? (count / total * 100) : 0;

                  return PieChartSectionData(
                    color: colors[index % colors.length],
                    value: count.toDouble(),
                    title: '${percentage.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.asMap().entries.map((entry) {
              final index = entry.key;
              final type = entry.value.key;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(type, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBarChart(Map<String, dynamic> byStatus) {
    final statuses = ['unverified', 'verified', 'resolved', 'rejected'];
    final colors = [Colors.orange, const Color(0xFF138808), Colors.blue, Colors.red];
    final labels = ['Pending', 'Verified', 'Resolved', 'Rejected'];

    return SizedBox(
      height: 200,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (byStatus.values.fold<int>(0, (max, v) => (v as int) > max ? v : max) + 5).toDouble(),
          barTouchData: BarTouchData(enabled: true),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() < labels.length) {
                    return Text(labels[value.toInt()], style: const TextStyle(fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true, reservedSize: 30),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: statuses.asMap().entries.map((entry) {
            final index = entry.key;
            final status = entry.value;
            final count = (byStatus[status] ?? 0) as int;

            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  color: colors[index],
                  width: 30,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSeverityChart(List incidents) {
    final severityCounts = <int, int>{1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var incident in incidents) {
      final sev = incident.severity;
      severityCounts[sev] = (severityCounts[sev] ?? 0) + 1;
    }

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: (severityCounts.values.fold<int>(0, (max, v) => v > max ? v : max) + 2).toDouble(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  return Text('Sev ${value.toInt()}', style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          barGroups: severityCounts.entries.map((entry) {
            final severity = entry.key;
            final count = entry.value;
            final color = severity <= 2 ? Colors.green : (severity <= 3 ? Colors.orange : Colors.red);

            return BarChartGroupData(
              x: severity,
              barRods: [
                BarChartRodData(
                  toY: count.toDouble(),
                  color: color,
                  width: 25,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildWeeklyTrend(List incidents) {
    final now = DateTime.now();
    final weekData = <int, int>{};

    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      final dayKey = date.weekday;
      weekData[dayKey] = 0;
    }

    for (var incident in incidents) {
      final timestamp = incident.timestamp;
      final diff = now.difference(timestamp).inDays;
      if (diff < 7) {
        final dayKey = timestamp.weekday;
        weekData[dayKey] = (weekData[dayKey] ?? 0) + 1;
      }
    }

    final dayNames = ['', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return SizedBox(
      height: 150,
      child: LineChart(
        LineChartData(
          gridData: const FlGridData(show: true, drawVerticalLine: false),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  if (value.toInt() > 0 && value.toInt() < dayNames.length) {
                    return Text(dayNames[value.toInt()], style: const TextStyle(fontSize: 10));
                  }
                  return const Text('');
                },
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 25)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: weekData.entries.map((e) => FlSpot(e.key.toDouble(), e.value.toDouble())).toList(),
              isCurved: true,
              color: const Color(0xFF138808),
              barWidth: 3,
              dotData: const FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: const Color(0xFF138808).withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopIssues(Map<String, dynamic> byType) {
    final sorted = byType.entries.toList()
      ..sort((a, b) => (b.value as int).compareTo(a.value as int));

    return Column(
      children: sorted.take(5).map((entry) {
        final total = byType.values.fold<int>(0, (sum, v) => sum + (v as int));
        final percentage = total > 0 ? (entry.value as int) / total : 0.0;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('${entry.value} (${(percentage * 100).toStringAsFixed(0)}%)'),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: percentage,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation(Color(0xFF138808)),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
