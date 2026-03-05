import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import 'laptop_request_screen.dart';
import 'broken_pc_report_screen.dart';
import 'missing_item_report_screen.dart';
import 'appointment_booking_screen.dart';
import 'contact_staff_screen.dart';

class ServicesScreen extends StatelessWidget {
  final VoidCallback? onBackPressed;
  const ServicesScreen({super.key, this.onBackPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 20,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        children: [
          const SizedBox(height: 8),
          Text(
            'What do you\nneed help\nwith?',
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.w900,
              height: 1.1,
              letterSpacing: -1.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                _buildServiceItem(
                  context,
                  title: 'Request Laptop',
                  subtitle: 'Borrow for university use',
                  icon: Icons.laptop_mac_rounded,
                  iconColor: Colors.blue,
                  destinationScreen: const LaptopRequestScreen(),
                ),
                _buildDivider(),
                _buildServiceItem(
                  context,
                  title: 'Report Broken Computer',
                  subtitle: 'Lab PC or hardware issues',
                  icon: Icons.computer_rounded,
                  iconColor: Colors.orange,
                  destinationScreen: const BrokenPcReportScreen(),
                ),
                _buildDivider(),
                _buildServiceItem(
                  context,
                  title: 'Report Missing Item',
                  subtitle: 'Lost and found registry',
                  icon: Icons.search_rounded,
                  iconColor: Colors.amber,
                  destinationScreen: const MissingItemReportScreen(),
                ),
                _buildDivider(),
                _buildServiceItem(
                  context,
                  title: 'Book Appointment',
                  subtitle: 'Meet with your lecturer',
                  icon: Icons.event_rounded,
                  iconColor: Colors.green,
                  destinationScreen: const AppointmentBookingScreen(),
                ),
                _buildDivider(),
                _buildServiceItem(
                  context,
                  title: 'Contact Staff',
                  subtitle: 'Message administration',
                  icon: Icons.support_agent_rounded,
                  iconColor: Colors.teal,
                  destinationScreen: const ContactStaffScreen(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      indent: 72,
      endIndent: 20,
      color: Colors.grey.withOpacity(0.1),
    );
  }

  Widget _buildServiceItem(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Widget destinationScreen,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        AppTheme.showAppModalBottomSheet(
          context: context,
          builder: destinationScreen,
        );
      },
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, size: 24, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white24 : Colors.grey[300],
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
