import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main.dart';
import 'laptop_request_screen.dart';
import 'broken_pc_report_screen.dart';
import 'missing_item_report_screen.dart';
import 'appointment_booking_screen.dart';
import 'contact_staff_screen.dart';
import '../widgets/ticket_detail_sheet.dart';
import '../core/app_theme.dart';
import '../widgets/skeleton_loader.dart';

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
    AppTheme.showAppModalBottomSheet(
      context: context,
      builder: TicketDetailSheet(
        data: data,
        docId: docId,
        onEdit: () => _editRequest(data, docId),
        onCancel: _cancelRequest,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Not logged in')));
    }

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 20,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tickets')
            .where('userId', isEqualTo: user!.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const ListSkeleton();
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
          final isHighContrast = UniDeskApp.settings.isHighContrast;
          final isDark = Theme.of(context).brightness == Brightness.dark;

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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  'Ongoing\nServices',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    letterSpacing: -1.5,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: SegmentedButton<ViewMode>(
                    style: SegmentedButton.styleFrom(
                      selectedBackgroundColor: isHighContrast
                          ? (isDark ? Colors.white : Colors.black)
                          : const Color(0xFFB3E5FC),
                      selectedForegroundColor: isHighContrast
                          ? (isDark ? Colors.black : Colors.white)
                          : Colors.black87,
                      backgroundColor: isDark ? Colors.black26 : Colors.white,
                      foregroundColor: isDark ? Colors.white70 : Colors.black87,
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
    final isHighContrast = UniDeskApp.settings.isHighContrast;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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
      elevation: isHighContrast ? 4 : 0,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isHighContrast
              ? (isDark ? Colors.white : Colors.black)
              : Colors.grey.withOpacity(0.3),
          width: isHighContrast ? 2 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showRequestDetails(data, doc.id),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? (isDark ? const Color(0xFFE0F2FE) : Colors.black)
                      : labelColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  iconData,
                  color: isHighContrast
                      ? (isDark ? Colors.black : Colors.white)
                      : Colors.black87,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['serviceTitle'] ?? 'Service Request',
                      style: TextStyle(
                        fontWeight: isHighContrast
                            ? FontWeight.w900
                            : FontWeight.bold,
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
                        color: isHighContrast
                            ? (isDark ? Colors.white : Colors.black)
                            : labelColor,
                        borderRadius: BorderRadius.circular(20),
                        border: isHighContrast
                            ? Border.all(
                                color: isDark ? Colors.black : Colors.white,
                                width: 1,
                              )
                            : null,
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: isHighContrast
                              ? (isDark ? Colors.black : Colors.white)
                              : Colors.black87,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Icon(
                  Icons.chevron_right,
                  color: isHighContrast
                      ? (isDark ? Colors.white : Colors.black)
                      : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
