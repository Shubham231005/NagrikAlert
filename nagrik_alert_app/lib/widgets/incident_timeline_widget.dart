import 'package:flutter/material.dart';
import '../models/incident_model.dart';

class IncidentTimelineWidget extends StatelessWidget {
  final IncidentModel incident;
  final List<Map<String, dynamic>>? statusHistory;

  const IncidentTimelineWidget({
    super.key,
    required this.incident,
    this.statusHistory,
  });

  @override
  Widget build(BuildContext context) {
    // Create timeline from status history or generate default
    final timeline = _buildTimeline();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timeline, color: Color(0xFF000080)),
              const SizedBox(width: 8),
              const Text(
                'Incident Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF000080),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(incident.status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  incident.status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _getStatusColor(incident.status),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...timeline.map((step) => _buildTimelineStep(
                step['title']!,
                step['subtitle']!,
                step['time']!,
                step['completed']!,
                step['isLast'] ?? false,
                step['icon'] as IconData,
              )),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> _buildTimeline() {
    final List<Map<String, dynamic>> timeline = [];

    // Step 1: Reported
    timeline.add({
      'title': 'Incident Reported',
      'subtitle': 'Report submitted by citizen',
      'time': _formatTime(incident.timestamp),
      'completed': true,
      'icon': Icons.report_outlined,
    });

    // Step 2: Under Review
    timeline.add({
      'title': 'Under Review',
      'subtitle': 'Admin reviewing the report',
      'time': incident.status != 'Unverified' ? 'Reviewed' : 'Pending',
      'completed': incident.status != 'Unverified',
      'icon': Icons.pending_actions,
    });

    // Step 3: Verified/Rejected
    if (incident.status == 'Rejected') {
      timeline.add({
        'title': 'Rejected',
        'subtitle': 'Report was not valid',
        'time': 'Closed',
        'completed': true,
        'isLast': true,
        'icon': Icons.cancel,
      });
    } else {
      timeline.add({
        'title': 'Verified',
        'subtitle': 'Incident confirmed by admin',
        'time': incident.status == 'Verified' || incident.status == 'Resolved' ? 'Verified' : 'Pending',
        'completed': incident.status == 'Verified' || incident.status == 'Resolved',
        'icon': Icons.verified,
      });

      // Step 4: Action Taken (if resolved)
      timeline.add({
        'title': 'Action Taken',
        'subtitle': 'Authorities notified',
        'time': incident.status == 'Resolved' ? 'Done' : 'Pending',
        'completed': incident.status == 'Resolved',
        'icon': Icons.local_police,
      });

      // Step 5: Resolved
      timeline.add({
        'title': 'Resolved',
        'subtitle': 'Incident has been addressed',
        'time': incident.status == 'Resolved' ? 'Completed' : 'Pending',
        'completed': incident.status == 'Resolved',
        'isLast': true,
        'icon': Icons.check_circle,
      });
    }

    return timeline;
  }

  Widget _buildTimelineStep(
    String title,
    String subtitle,
    String time,
    bool completed,
    bool isLast,
    IconData icon,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline indicator
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: completed ? const Color(0xFF138808) : Colors.grey.shade300,
                shape: BoxShape.circle,
                boxShadow: completed
                    ? [
                        BoxShadow(
                          color: const Color(0xFF138808).withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                icon,
                color: completed ? Colors.white : Colors.grey.shade500,
                size: 20,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 50,
                color: completed ? const Color(0xFF138808) : Colors.grey.shade300,
              ),
          ],
        ),
        const SizedBox(width: 16),
        // Content
        Expanded(
          child: Container(
            margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: completed ? const Color(0xFF000080) : Colors.grey,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: completed ? const Color(0xFF138808) : Colors.grey,
                        fontWeight: completed ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'verified':
        return const Color(0xFF138808);
      case 'resolved':
        return Colors.blue;
      case 'rejected':
        return Colors.red;
      default:
        return const Color(0xFFFF9933);
    }
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
