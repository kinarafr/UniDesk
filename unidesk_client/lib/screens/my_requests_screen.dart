import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'laptop_request_screen.dart';
import 'broken_pc_report_screen.dart';
import 'missing_item_report_screen.dart';
import 'appointment_booking_screen.dart';
import 'contact_staff_screen.dart';

class MyRequestsScreen extends StatefulWidget {
  const MyRequestsScreen({super.key});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final user = FirebaseAuth.instance.currentUser;

  Future<void> _cancelRequest(String docId) async {
    try {
      await FirebaseFirestore.instance.collection('tickets').doc(docId).update({
        'status': 'Cancelled',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request cancelled successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error cancelling: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _editRequest(Map<String, dynamic> data, String docId) {
    final serviceType = data['serviceType'];
    Widget? targetScreen;

    if (serviceType == 'laptop_request') {
      targetScreen = LaptopRequestScreen(ticketId: docId, existingData: data);
    } else if (serviceType == 'broken_pc_report') {
      targetScreen = BrokenPcReportScreen(ticketId: docId, existingData: data);
    } else if (serviceType == 'missing_item_report') {
      targetScreen = MissingItemReportScreen(
        ticketId: docId,
        existingData: data,
      );
    } else if (serviceType == 'lecturer_appointment') {
      targetScreen = AppointmentBookingScreen(
        ticketId: docId,
        existingData: data,
      );
    } else if (serviceType == 'contact_staff') {
      targetScreen = ContactStaffScreen(ticketId: docId, existingData: data);
    }

    if (targetScreen != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => targetScreen!),
      );
    }
  }

  void _showRequestDetails(Map<String, dynamic> data, String docId) {
    showDialog(
      context: context,
      builder: (context) {
        final details = data['details'] as Map<String, dynamic>? ?? {};
        final status = data['status'];
        final isPending = status == 'Pending';

        return AlertDialog(
          title: Text(data['serviceTitle'] ?? 'Request Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Status: $status',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: status == 'Pending'
                        ? Colors.orange
                        : (status == 'Cancelled' || status == 'Rejected'
                              ? Colors.red
                              : Colors.green),
                  ),
                ),
                const Divider(),
                const Text(
                  'Details:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                ...details.entries.map(
                  (e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4.0),
                    child: Text('${e.key}: ${e.value}'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (isPending) ...[
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _cancelRequest(docId);
                },
                child: const Text(
                  'Cancel Request',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _editRequest(data, docId);
                },
                child: const Text('Edit Request'),
              ),
            ] else ...[
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null)
      return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      appBar: AppBar(title: const Text('My Ongoing Services')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('userId', isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'You have no requested services.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final docs = snapshot.data!.docs.toList();

          docs.sort((a, b) {
            final aData = a.data() as Map<String, dynamic>;
            final bData = b.data() as Map<String, dynamic>;

            final aTime = aData['createdAt'] as Timestamp?;
            final bTime = bData['createdAt'] as Timestamp?;

            if (aTime == null && bTime == null) return 0;
            if (aTime == null) return 1;
            if (bTime == null) return -1;

            return bTime.compareTo(aTime); // Descending order
          });

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final status = data['status'];

              IconData iconData = Icons.receipt;
              if (data['serviceType'] == 'laptop_request')
                iconData = Icons.laptop;
              if (data['serviceType'] == 'broken_pc_report')
                iconData = Icons.computer;
              if (data['serviceType'] == 'missing_item_report')
                iconData = Icons.search;
              if (data['serviceType'] == 'lecturer_appointment')
                iconData = Icons.event;
              if (data['serviceType'] == 'contact_staff')
                iconData = Icons.support_agent;

              Color statusColor = Colors.grey;
              if (status == 'Pending') statusColor = Colors.orange;
              if (status == 'Cancelled' || status == 'Rejected')
                statusColor = Colors.red;
              if (status == 'Approved/Resolved') statusColor = Colors.green;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor.withOpacity(0.1),
                    child: Icon(iconData, color: statusColor),
                  ),
                  title: Text(
                    data['serviceTitle'] ?? 'Service Request',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Status: $status'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showRequestDetails(data, doc.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
