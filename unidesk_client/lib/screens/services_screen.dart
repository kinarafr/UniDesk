import 'package:flutter/material.dart';
import 'laptop_request_screen.dart';
import 'broken_pc_report_screen.dart';
import 'missing_item_report_screen.dart';
import 'appointment_booking_screen.dart';
import 'contact_staff_screen.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Services & Requests'),
        automaticallyImplyLeading: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildServiceCard(
            context: context,
            title: 'Request Laptop',
            subtitle: 'Borrow a laptop for university use',
            icon: Icons.laptop_mac,
            destinationScreen: const LaptopRequestScreen(),
          ),
          const SizedBox(height: 12),
          _buildServiceCard(
            context: context,
            title: 'Report Broken Computer',
            subtitle: 'Report a broken PC or missing part in a lab',
            icon: Icons.computer,
            destinationScreen: const BrokenPcReportScreen(),
          ),
          const SizedBox(height: 12),
          _buildServiceCard(
            context: context,
            title: 'Report Missing Item',
            subtitle: 'Lost something? Let us know',
            icon: Icons.search,
            destinationScreen: const MissingItemReportScreen(),
          ),
          const SizedBox(height: 12),
          _buildServiceCard(
            context: context,
            title: 'Book Appointment',
            subtitle: 'Schedule a meeting with a lecturer',
            icon: Icons.event,
            destinationScreen: const AppointmentBookingScreen(),
          ),
          const SizedBox(height: 12),
          _buildServiceCard(
            context: context,
            title: 'Contact Staff',
            subtitle: 'Send a message to university administration',
            icon: Icons.support_agent,
            destinationScreen: const ContactStaffScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget destinationScreen,
  }) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => destinationScreen),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: theme.primaryColor),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
