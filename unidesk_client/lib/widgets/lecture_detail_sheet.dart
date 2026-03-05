import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class LectureDetailSheet extends StatelessWidget {
  final Map<String, dynamic> lecture;
  final VoidCallback onNavigateToTimetable;

  const LectureDetailSheet({
    super.key,
    required this.lecture,
    required this.onNavigateToTimetable,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24.0),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Cover Image
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Image.asset(
              lecture['imagePath'] as String,
              height: 200,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 24),

          // Lecture Name
          Text(
            lecture['title'] as String,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),

          // Details
          _buildDetailRow(
            context,
            CupertinoIcons.time,
            'Time',
            lecture['time'] as String,
          ),
          _buildDetailRow(
            context,
            CupertinoIcons.location,
            'Location',
            lecture['room'] as String,
          ),
          _buildDetailRow(
            context,
            CupertinoIcons.person,
            'Lecturer',
            lecture['lecturer'] as String,
          ),
          const SizedBox(height: 32),

          // Action Button
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onNavigateToTimetable();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark
                  ? const Color(0xFF90CAF9)
                  : const Color(0xFF3B5B8E),
              foregroundColor: isDark ? Colors.black : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'View Schedule',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: theme.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: 20,
              color: isDark ? const Color(0xFF90CAF9) : theme.primaryColor,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withOpacity(0.9)
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
