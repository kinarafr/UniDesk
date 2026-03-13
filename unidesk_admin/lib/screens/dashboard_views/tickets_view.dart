import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:unidesk_admin/main.dart';
import 'package:unidesk_admin/core/app_theme.dart';
import 'package:unidesk_admin/widgets/skeleton_loader.dart';

class TicketsView extends StatefulWidget {
  const TicketsView({super.key});

  @override
  State<TicketsView> createState() => _TicketsViewState();
}

class _TicketsViewState extends State<TicketsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedSort = 'Recent';
  
  // Pagination variables
  final int _pageSize = 15;
  bool _isLoading = false;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  final List<QueryDocumentSnapshot> _tickets = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchTickets();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        if (!_isLoading && _hasMore && _selectedSort == 'Recent') {
          _fetchTickets();
        }
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTickets() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      Query query = _firestore
          .collection('tickets')
          .orderBy('createdAt', descending: true)
          .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.length < _pageSize) {
        _hasMore = false;
      }

      if (snapshot.docs.isNotEmpty) {
        _lastDocument = snapshot.docs.last;
        setState(() {
          _tickets.addAll(snapshot.docs);
        });
      }
    } catch (e) {
      debugPrint('Error fetching tickets: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _resetPagination() {
    setState(() {
      _tickets.clear();
      _lastDocument = null;
      _hasMore = true;
    });
    _fetchTickets();
  }

  void _showTicketDetails(Map<String, dynamic> data, String docId) {
    UniDeskAdminApp.showAppDialog(
      context: context,
      builder: (context) {
        final details = data['details'] as Map<String, dynamic>? ?? {};
        final status = data['status'];
        Color statusColor = _getStatusColor(status);

        IconData iconData = _getIconForService(data['serviceType']);

        return ValueListenableBuilder<bool>(
          valueListenable: UniDeskAdminApp.highContrastNotifier,
          builder: (context, highContrast, _) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryColor = isDark ? AppTheme.pastelBlue : Theme.of(context).primaryColor;

            final iconBgColor = highContrast ? primaryColor : primaryColor.withOpacity(0.1);
            final iconFgColor = highContrast ? (isDark ? AppTheme.pastelBlueDark : Colors.white) : primaryColor;

            final badgeBgColor = highContrast ? statusColor : statusColor.withOpacity(0.1);
            final badgeFgColor = highContrast ? Colors.white : statusColor;
            final badgeBorderColor = highContrast ? Colors.transparent : statusColor.withOpacity(0.5);

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                width: 500,
                constraints: const BoxConstraints(maxHeight: 600),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
                            child: Icon(iconData, color: iconFgColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(data['serviceTitle'] ?? 'Ticket Details', 
                                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: badgeBorderColor)),
                                  child: Text(status, style: TextStyle(color: badgeFgColor, fontWeight: FontWeight.bold, fontSize: 12)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Flexible(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildRequestedByCard(data, isDark),
                            const SizedBox(height: 24),
                            const Text('Request Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 12),
                            ...details.entries.map((e) => _buildDetailItem(e.key, e.value.toString())),
                          ],
                        ),
                      ),
                    ),
                    if (status == 'Pending') _buildActionButtons(docId, data),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRequestedByCard(Map<String, dynamic> data, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.person, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Requested By', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text(data['userName'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(data['userEmail'] ?? '', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildActionButtons(String docId, Map<String, dynamic> data) {
    return Column(
      children: [
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                onPressed: () => _showActionConfirmation(docId, 'Reject', 'Rejected', Colors.red, data),
                child: const Text('Reject'),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                onPressed: () => _showActionConfirmation(docId, 'Approve', 'Approved/Resolved', Colors.green, data),
                child: const Text('Approve'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showActionConfirmation(String docId, String action, String newStatus, Color color, Map<String, dynamic> data) {
    UniDeskAdminApp.showAppDialog(
      context: context,
      builder: (confirmContext) => AlertDialog(
        title: Text('Confirm $action'),
        content: Text('Are you sure you want to $action this ticket?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(confirmContext), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
            onPressed: () async {
              await _firestore.collection('tickets').doc(docId).update({'status': newStatus});
              
              // Create notification for user
              final userId = data['userId'];
              if (userId != null) {
                final serviceName = data['serviceTitle'] ?? 'Your request';
                await _firestore.collection('notifications').add({
                  'userId': userId,
                  'ticketId': docId,
                  'title': newStatus == 'Approved/Resolved' ? 'Ticket Resolved' : 'Ticket Rejected',
                  'body': '$serviceName has been ${newStatus == 'Approved/Resolved' ? 'resolved' : 'rejected'}.',
                  'status': newStatus,
                  'isSeen': false,
                  'createdAt': FieldValue.serverTimestamp(),
                });
              }

              if (mounted) {
                Navigator.pop(confirmContext);
                Navigator.pop(context); // Close details
                _resetPagination(); // Refresh list
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Ticket $action successfully')));
              }
            },
            child: Text('Yes, $action'),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String? status) {
    if (status == 'Pending') return Colors.orange;
    if (status == 'Cancelled' || status == 'Rejected') return Colors.red;
    if (status == 'Approved/Resolved') return Colors.green;
    return Colors.grey;
  }

  IconData _getIconForService(String? type) {
    switch (type) {
      case 'laptop_request': return Icons.laptop;
      case 'broken_pc_report': return Icons.computer;
      case 'missing_item_report': return Icons.search;
      case 'lecturer_appointment': return Icons.event;
      case 'contact_staff': return Icons.support_agent;
      default: return Icons.receipt;
    }
  }

  Widget _buildTicketCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'];
    final statusColor = _getStatusColor(status);
    final iconData = _getIconForService(data['serviceType']);

    return ValueListenableBuilder<bool>(
      valueListenable: UniDeskAdminApp.highContrastNotifier,
      builder: (context, highContrast, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = isDark ? AppTheme.pastelBlue : Theme.of(context).primaryColor;
        final iconBgColor = highContrast ? primaryColor : primaryColor.withOpacity(0.1);
        final iconFgColor = highContrast ? (isDark ? AppTheme.pastelBlueDark : Colors.white) : primaryColor;
        final badgeBgColor = highContrast ? statusColor : statusColor.withOpacity(0.1);
        final badgeFgColor = highContrast ? Colors.white : statusColor;
        final badgeBorderColor = highContrast ? Colors.transparent : statusColor.withOpacity(0.5);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.grey.withOpacity(0.2))),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showTicketDetails(data, doc.id),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
                    child: Icon(iconData, color: iconFgColor),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(data['serviceTitle'] ?? 'Service Request', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        const SizedBox(height: 4),
                        Text('Requested by: ${data['userName']}', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: badgeBgColor, borderRadius: BorderRadius.circular(20), border: Border.all(color: badgeBorderColor)),
                    child: Text(status, style: TextStyle(color: badgeFgColor, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          Expanded(child: _buildMainContent()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Tickets Management', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        _buildSortDropdown(),
      ],
    );
  }

  Widget _buildSortDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedSort,
          items: const [
            DropdownMenuItem(value: 'Recent', child: Text('Sort: Recent')),
            DropdownMenuItem(value: 'By Status', child: Text('Sort: By Status')),
          ],
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedSort = value);
              if (value == 'Recent') _resetPagination();
            }
          },
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_selectedSort == 'By Status') {
      return StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('tickets').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const TableSkeleton();
          
          final Map<String, List<QueryDocumentSnapshot>> grouped = {
            'Pending': [], 'Approved/Resolved': [], 'Rejected': [], 'Cancelled': [],
          };
          for (var doc in snapshot.data!.docs) {
            final status = (doc.data() as Map<String, dynamic>)['status'] ?? 'Pending';
            if (grouped.containsKey(status)) grouped[status]!.add(doc);
          }

          return ListView(
            children: [
              _buildStatusSection('Pending', grouped['Pending']!, Colors.orange),
              _buildStatusSection('Approved/Resolved', grouped['Approved/Resolved']!, Colors.green),
              _buildStatusSection('Rejected', grouped['Rejected']!, Colors.red),
              _buildStatusSection('Cancelled', grouped['Cancelled']!, Colors.red),
            ],
          );
        },
      );
    }

    if (_tickets.isEmpty && _isLoading) return const TableSkeleton();

    return ListView.builder(
      controller: _scrollController,
      itemCount: _tickets.length + (_hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _tickets.length) {
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }
        return _buildTicketCard(_tickets[index]);
      },
    );
  }

  Widget _buildStatusSection(String title, List<QueryDocumentSnapshot> docs, Color color) {
    if (docs.isEmpty) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
      valueListenable: UniDeskAdminApp.highContrastNotifier,
      builder: (context, highContrast, _) {
        final titleFgColor = highContrast ? Colors.white : color;
        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: color.withOpacity(0.3))),
          child: ExpansionTile(
            initiallyExpanded: title == 'Pending',
            title: Text('$title (${docs.length})', style: TextStyle(fontWeight: FontWeight.bold, color: titleFgColor)),
            childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
            children: docs.map((doc) => _buildTicketCard(doc)).toList(),
          ),
        );
      },
    );
  }
}
