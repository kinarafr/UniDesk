import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'laptop_request_screen.dart';
import 'broken_pc_report_screen.dart';
import 'missing_item_report_screen.dart';
import 'appointment_booking_screen.dart';
import 'contact_staff_screen.dart';

enum ViewMode { recent, byStatus }

class MyRequestsScreen extends StatefulWidget {
  final VoidCallback? onBackPressed;
  const MyRequestsScreen({super.key, this.onBackPressed});

  @override
  State<MyRequestsScreen> createState() => _MyRequestsScreenState();
}

class _MyRequestsScreenState extends State<MyRequestsScreen> {
  final user = FirebaseAuth.instance.currentUser;
  ViewMode _currentViewMode = ViewMode.recent;

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
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Ongoing Services'),
        leading: widget.onBackPressed != null
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: widget.onBackPressed,
              )
            : null,
      ),
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

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ViewMode>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: const Color(0xFFB3E5FC),
                    ),
                    segments: const [
                      ButtonSegment<ViewMode>(
                        value: ViewMode.recent,
                        label: Text('Recent'),
                        icon: Icon(Icons.access_time),
                      ),
                      ButtonSegment<ViewMode>(
                        value: ViewMode.byStatus,
                        label: Text('By Status'),
                        icon: Icon(Icons.sort),
                      ),
                    ],
                    selected: {_currentViewMode},
                    onSelectionChanged: (Set<ViewMode> newSelection) {
                      setState(() {
                        _currentViewMode = newSelection.first;
                      });
                    },
                  ),
                ),
              ),
              Expanded(
                child: _currentViewMode == ViewMode.recent
                    ? _buildRecentList(docs)
                    : _buildByStatusList(docs),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildRecentList(List<QueryDocumentSnapshot> docs) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        return _buildRequestCard(docs[index]);
      },
    );
  }

  Widget _buildByStatusList(List<QueryDocumentSnapshot> docs) {
    final pending = docs
        .where((d) => (d.data() as Map<String, dynamic>)['status'] == 'Pending')
        .toList();
    final approved = docs
        .where(
          (d) =>
              (d.data() as Map<String, dynamic>)['status'] ==
              'Approved/Resolved',
        )
        .toList();
    final rejected = docs.where((d) {
      final status = (d.data() as Map<String, dynamic>)['status'];
      return status == 'Cancelled' || status == 'Rejected';
    }).toList();

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      children: [
        if (pending.isNotEmpty) ...[
          _buildSectionHeader('Pending'),
          ...pending.map((d) => _buildRequestCard(d)),
          const SizedBox(height: 16),
        ],
        if (approved.isNotEmpty) ...[
          _buildSectionHeader('Approved/Resolved'),
          ...approved.map((d) => _buildRequestCard(d)),
          const SizedBox(height: 16),
        ],
        if (rejected.isNotEmpty) ...[
          _buildSectionHeader('Cancelled / Rejected'),
          ...rejected.map((d) => _buildRequestCard(d)),
          const SizedBox(height: 16),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0, left: 4.0, top: 8.0),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildRequestCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'];

    IconData iconData = Icons.receipt;
    if (data['serviceType'] == 'laptop_request') iconData = Icons.laptop;
    if (data['serviceType'] == 'broken_pc_report') iconData = Icons.computer;
    if (data['serviceType'] == 'missing_item_report') iconData = Icons.search;
    if (data['serviceType'] == 'lecturer_appointment') iconData = Icons.event;
    if (data['serviceType'] == 'contact_staff') iconData = Icons.support_agent;

    Color labelColor = const Color(0xFFB3E5FC); // default Light Blue
    if (status == 'Pending') {
      labelColor = const Color(0xFFFFF9C4); // Pastel Yellow
    }
    if (status == 'Cancelled' || status == 'Rejected') {
      labelColor = const Color(0xFF90CAF9); // Secondary Pastel Blue
    }
    if (status == 'Approved/Resolved') {
      labelColor = const Color(0xFFC8E6C9); // Pastel Green
    }

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withOpacity(0.3)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRequestDetails(data, doc.id),
        child: Padding(
          padding: const EdgeInsets.all(20.0), // Spaced out layout padding
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: labelColor.withOpacity(0.6),
                  shape: BoxShape.circle,
                ),
                child: Icon(iconData, color: Colors.black87),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['serviceTitle'] ?? 'Service Request',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: labelColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 12.0),
                child: Icon(Icons.chevron_right, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
