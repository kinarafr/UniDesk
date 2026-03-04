import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import 'admin_login_screen.dart';
import '../core/app_theme.dart';
import '../widgets/ticket_notification_overlay.dart';
import 'dart:async';
import 'package:intl/intl.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> {
  int _selectedIndex = 0;
  StreamSubscription<QuerySnapshot>? _ticketSubscription;
  final List<Map<String, dynamic>> _activeNotifications = [];

  @override
  void initState() {
    super.initState();
    _listenForNewTickets();
  }

  void _listenForNewTickets() {
    _ticketSubscription = FirebaseFirestore.instance
        .collection('tickets')
        .snapshots()
        .listen((snapshot) {
          if (snapshot.docChanges.isEmpty) return;

          for (var change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final data = change.doc.data();
              if (data != null) {
                final createdAt = data['createdAt'] as Timestamp?;
                // Only show notification for tickets created in the last 10 seconds to avoid spam on initial load
                if (createdAt != null &&
                    DateTime.now().difference(createdAt.toDate()).inSeconds <
                        10) {
                  _showNotification(data, change.doc.id);
                }
              }
            }
          }
        });
  }

  void _showNotification(Map<String, dynamic> data, String docId) {
    if (!mounted) return;
    setState(() {
      _activeNotifications.add({'data': data, 'id': docId, 'key': UniqueKey()});
    });
  }

  void _removeNotification(Key key) {
    if (!mounted) return;
    setState(() {
      _activeNotifications.removeWhere(
        (notification) => notification['key'] == key,
      );
    });
  }

  @override
  void dispose() {
    _ticketSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset(
              'assets/images/nibm_logo.png', // Assuming logo path based on client app
              height: 32,
              errorBuilder: (context, error, stackTrace) {
                // Fallback to text if logo not found
                return const Text(
                  'NIBM ',
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.blue,
                  ),
                );
              },
            ),
            const SizedBox(width: 12),
            const Text('UniDesk Admin Dashboard'),
          ],
        ),
        centerTitle: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 50),
              tooltip: 'Profile',
              icon: CircleAvatar(
                backgroundColor: Theme.of(context).primaryColor,
                child: const Icon(Icons.person, color: Colors.white),
              ),
              itemBuilder: (context) {
                final user = FirebaseAuth.instance.currentUser;
                return [
                  PopupMenuItem<String>(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user?.displayName ?? 'Admin User',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? 'No email available',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'help',
                    child: Row(
                      children: [
                        Icon(
                          Icons.help_outline,
                          size: 20,
                          color: Theme.of(context).iconTheme.color,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Help & Support',
                          style: TextStyle(
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                ];
              },
              onSelected: (value) {
                if (value == 'help') {
                  UniDeskAdminApp.showAppDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Help & Support'),
                      content: const Text(
                        'For assistance, please contact the system administrator or check the documentation.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Close'),
                        ),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() {
                _selectedIndex = index;
              });
            },
            labelType: NavigationRailLabelType.all,
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.confirmation_number_outlined),
                selectedIcon: Icon(Icons.confirmation_number),
                label: Text('Tickets'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.people_outline),
                selectedIcon: Icon(Icons.people),
                label: Text('Users'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.inventory_2_outlined),
                selectedIcon: Icon(Icons.inventory_2),
                label: Text('Inventory'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings),
                label: Text('Settings'),
              ),
            ],
            trailing: Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: IconButton(
                    icon: const Icon(Icons.logout, color: Colors.red),
                    onPressed: () async {
                      await FirebaseAuth.instance.signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => const AdminLoginScreen(),
                          ),
                        );
                      }
                    },
                    tooltip: 'Logout',
                  ),
                ),
              ),
            ),
          ),
          const VerticalDivider(thickness: 1, width: 1),
          Expanded(
            child: _selectedIndex == 0
                ? HomeView(
                    onTabSwitch: (index) {
                      setState(() {
                        _selectedIndex = index;
                      });
                    },
                  )
                : _selectedIndex == 1
                ? const TicketsView()
                : _selectedIndex == 2
                ? const UsersView()
                : _selectedIndex == 3
                ? const InventoryView()
                : const SettingsView(),
          ),
        ],
      ),
      floatingActionButton: _activeNotifications.isNotEmpty
          ? Stack(
              children: _activeNotifications.map((notification) {
                return TicketNotificationOverlay(
                  key: notification['key'],
                  ticketData: notification['data'],
                  ticketId: notification['id'],
                  onDismiss: () => _removeNotification(notification['key']),
                  onViewTicket: (data, id) {
                    setState(() {
                      _selectedIndex =
                          1; // Switch to tickets view (now index 1)
                    });
                    // Wait for view to switch then show dialog
                    Future.delayed(const Duration(milliseconds: 300), () {
                      if (mounted) {
                        UniDeskAdminApp.showAppDialog(
                          context: context,
                          builder: (context) =>
                              _buildTicketDetailsDialog(context, data, id),
                        );
                      }
                    });
                  },
                );
              }).toList(),
            )
          : null,
    );
  }

  Widget _buildTicketDetailsDialog(
    BuildContext context,
    Map<String, dynamic> data,
    String docId,
  ) {
    final details = data['details'] as Map<String, dynamic>? ?? {};
    final status = data['status'];
    Color statusColor = Colors.grey;
    if (status == 'Pending') statusColor = Colors.orange;
    if (status == 'Cancelled' || status == 'Rejected') {
      statusColor = Colors.red;
    }
    if (status == 'Approved/Resolved') statusColor = Colors.green;

    IconData iconData = Icons.receipt;
    if (data['serviceType'] == 'laptop_request') iconData = Icons.laptop;
    if (data['serviceType'] == 'broken_pc_report') {
      iconData = Icons.computer;
    }
    if (data['serviceType'] == 'missing_item_report') {
      iconData = Icons.search;
    }
    if (data['serviceType'] == 'lecturer_appointment') {
      iconData = Icons.event;
    }
    if (data['serviceType'] == 'contact_staff') {
      iconData = Icons.support_agent;
    }

    void showActionConfirmationDialog(
      String actionName,
      String newStatus,
      Color actionColor,
    ) {
      UniDeskAdminApp.showAppDialog(
        context: context,
        builder: (confirmContext) => AlertDialog(
          title: Text('Confirm $actionName'),
          content: Text('Are you sure you want to $actionName this ticket?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: actionColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                FirebaseFirestore.instance
                    .collection('tickets')
                    .doc(docId)
                    .update({'status': newStatus});
                Navigator.pop(confirmContext); // Close confirm
                Navigator.pop(context); // Close details

                // Show notification snackbar
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Theme.of(context).cardColor,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: actionColor.withOpacity(0.5)),
                    ),
                    margin: EdgeInsets.only(
                      bottom: 24,
                      right: 24,
                      left: MediaQuery.of(context).size.width > 400
                          ? MediaQuery.of(context).size.width - 350 - 24
                          : 24,
                    ),
                    content: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: actionColor.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.info_outline, color: actionColor),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ticket $actionName successfully',
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).textTheme.bodyLarge?.color,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    duration: const Duration(seconds: 4),
                  ),
                );
              },
              child: Text(
                'Yes, $actionName',
                style: const TextStyle(fontWeight: FontWeight.normal),
              ),
            ),
          ],
        ),
      );
    }

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
                    decoration: BoxDecoration(
                      color:
                          (Theme.of(context).brightness == Brightness.dark
                                  ? AppTheme.pastelBlue
                                  : Theme.of(context).primaryColor)
                              .withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      iconData,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppTheme.pastelBlue
                          : Theme.of(context).primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['serviceTitle'] ?? 'Ticket Details',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: statusColor.withOpacity(0.5),
                            ),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
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
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.grey[850]
                            : Colors.grey[100],
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
                                const Text(
                                  'Requested By',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                                Text(
                                  data['userName'] ?? 'Unknown',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  data['userEmail'] ?? '',
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Request Details',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...details.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              e.key,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${e.value}',
                              style: const TextStyle(fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (status == 'Pending') ...[
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => showActionConfirmationDialog(
                        'Reject',
                        'Rejected',
                        Colors.red,
                      ),
                      child: const Text(
                        'Reject',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => showActionConfirmationDialog(
                        'Approve',
                        'Approved/Resolved',
                        Colors.green,
                      ),
                      child: const Text(
                        'Approve',
                        style: TextStyle(fontWeight: FontWeight.normal),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Home View
class HomeView extends StatefulWidget {
  final Function(int) onTabSwitch;
  const HomeView({super.key, required this.onTabSwitch});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(theme, isDark),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _buildStatsGrid(),
                    const SizedBox(height: 24),
                    _buildRecentTicketsCard(),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildOnlineStatusCard(),
                    const SizedBox(height: 24),
                    _buildAvailabilityCard(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    final dateStr = DateFormat('EEEE, MMMM d, y').format(_currentTime);
    final timeStr = DateFormat('hh:mm:ss a').format(_currentTime);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard Overview',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome back, Admin',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timeStr,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                  color: isDark ? AppTheme.pastelBlue : theme.primaryColor,
                ),
              ),
              Text(
                dateStr,
                style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tickets').snapshots(),
      builder: (context, snapshot) {
        int total = 0;
        int pending = 0;
        if (snapshot.hasData) {
          total = snapshot.data!.docs.length;
          pending = snapshot.data!.docs
              .where((doc) => doc['status'] == 'Pending')
              .length;
        }

        return GridView.count(
          shrinkWrap: true,
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard(
              'Total Tickets',
              total.toString(),
              Icons.receipt_long,
              Colors.blue,
            ),
            _buildStatCard(
              'Pending Action',
              pending.toString(),
              Icons.pending_actions,
              Colors.orange,
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTicketsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Tickets',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => widget.onTabSwitch(1),
                  tooltip: 'Go to Tickets',
                ),
              ],
            ),
            const Divider(),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('tickets')
                  .orderBy('createdAt', descending: true)
                  .limit(5)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: Text('No recent tickets'),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (context, index) => const Divider(),
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final status = data['status'] ?? 'Pending';
                    Color statusColor = Colors.grey;
                    if (status == 'Pending') statusColor = Colors.orange;
                    if (status == 'Approved/Resolved') {
                      statusColor = Colors.green;
                    }
                    if (status == 'Rejected' || status == 'Cancelled') {
                      statusColor = Colors.red;
                    }

                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.1),
                        child: Icon(
                          _getIconForService(data['serviceType']),
                          color: statusColor,
                          size: 20,
                        ),
                      ),
                      title: Text(
                        data['studentName'] ?? 'Unknown Student',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        DateFormat(
                          'MMM d, hh:mm a',
                        ).format((data['createdAt'] as Timestamp).toDate()),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForService(String? type) {
    switch (type) {
      case 'laptop_request':
        return Icons.laptop;
      case 'broken_pc_report':
        return Icons.computer;
      case 'missing_item_report':
        return Icons.search;
      case 'lecturer_appointment':
        return Icons.event;
      case 'contact_staff':
        return Icons.support_agent;
      default:
        return Icons.receipt;
    }
  }

  Widget _buildOnlineStatusCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Students Online',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => widget.onTabSwitch(2),
                  tooltip: 'Go to Users',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.circle, color: Colors.green, size: 12),
                const SizedBox(width: 8),
                Text(
                  '124',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                const Text('Students currently active'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvailabilityCard() {
    final List<Map<String, dynamic>> availability = [
      {'name': 'PC Lab 01', 'type': 'Lab', 'status': 'Available'},
      {'name': 'PC Lab 02', 'type': 'Lab', 'status': 'Occupied'},
      {'name': 'Lecture Hall A', 'type': 'Room', 'status': 'Available'},
      {'name': 'Lecture Room 102', 'type': 'Room', 'status': 'Available'},
      {'name': 'Main Auditorium', 'type': 'Room', 'status': 'Occupied'},
    ];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resources Availability',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: availability.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (context, index) {
                final item = availability[index];
                final isAvailable = item['status'] == 'Available';
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        item['type'] == 'Lab'
                            ? Icons.computer
                            : Icons.meeting_room,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          item['name'],
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: (isAvailable ? Colors.green : Colors.red)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item['status'],
                          style: TextStyle(
                            color: isAvailable ? Colors.green : Colors.red,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Tickets Management View
class TicketsView extends StatefulWidget {
  const TicketsView({super.key});

  @override
  State<TicketsView> createState() => _TicketsViewState();
}

class _TicketsViewState extends State<TicketsView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedSort = 'Recent'; // Sorting state ('Recent' or 'By Status')

  void _showTicketDetails(Map<String, dynamic> data, String docId) {
    UniDeskAdminApp.showAppDialog(
      context: context,
      builder: (context) {
        final details = data['details'] as Map<String, dynamic>? ?? {};
        final status = data['status'];
        Color statusColor = Colors.grey;
        if (status == 'Pending') statusColor = Colors.orange;
        if (status == 'Cancelled' || status == 'Rejected') {
          statusColor = Colors.red;
        }
        if (status == 'Approved/Resolved') statusColor = Colors.green;

        IconData iconData = Icons.receipt;
        if (data['serviceType'] == 'laptop_request') iconData = Icons.laptop;
        if (data['serviceType'] == 'broken_pc_report') {
          iconData = Icons.computer;
        }
        if (data['serviceType'] == 'missing_item_report') {
          iconData = Icons.search;
        }
        if (data['serviceType'] == 'lecturer_appointment') {
          iconData = Icons.event;
        }
        if (data['serviceType'] == 'contact_staff') {
          iconData = Icons.support_agent;
        }

        void showActionConfirmationDialog(
          String actionName,
          String newStatus,
          Color actionColor,
        ) {
          UniDeskAdminApp.showAppDialog(
            context: context,
            builder: (confirmContext) => AlertDialog(
              title: Text('Confirm $actionName'),
              content: Text(
                'Are you sure you want to $actionName this ticket?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(confirmContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: actionColor,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    FirebaseFirestore.instance
                        .collection('tickets')
                        .doc(docId)
                        .update({'status': newStatus});
                    Navigator.pop(confirmContext); // Close confirm
                    Navigator.pop(context); // Close details

                    // Show notification snackbar
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: Theme.of(context).cardColor,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: actionColor.withOpacity(0.5)),
                        ),
                        margin: EdgeInsets.only(
                          bottom: 24,
                          right: 24,
                          left: MediaQuery.of(context).size.width > 400
                              ? MediaQuery.of(context).size.width - 350 - 24
                              : 24,
                        ),
                        content: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: actionColor.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.info_outline,
                                color: actionColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ticket $actionName successfully',
                                style: TextStyle(
                                  color: Theme.of(
                                    context,
                                  ).textTheme.bodyLarge?.color,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        duration: const Duration(seconds: 4),
                      ),
                    );
                  },
                  child: Text(
                    'Yes, $actionName',
                    style: const TextStyle(fontWeight: FontWeight.normal),
                  ),
                ),
              ],
            ),
          );
        }

        return ValueListenableBuilder<bool>(
          valueListenable: UniDeskAdminApp.highContrastNotifier,
          builder: (context, highContrast, _) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            final primaryColor = isDark
                ? AppTheme.pastelBlue
                : Theme.of(context).primaryColor;

            final iconBgColor = highContrast
                ? primaryColor
                : primaryColor.withOpacity(0.1);
            final iconFgColor = highContrast
                ? (isDark ? AppTheme.pastelBlueDark : Colors.white)
                : primaryColor;

            final badgeBgColor = highContrast
                ? statusColor
                : statusColor.withOpacity(0.1);
            final badgeFgColor = highContrast ? Colors.white : statusColor;
            final badgeBorderColor = highContrast
                ? Colors.transparent
                : statusColor.withOpacity(0.5);

            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
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
                            decoration: BoxDecoration(
                              color: iconBgColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(iconData, color: iconFgColor, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['serviceTitle'] ?? 'Ticket Details',
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: badgeBgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: badgeBorderColor),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: badgeFgColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                            tooltip: 'Close',
                          ),
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
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color:
                                    Theme.of(context).brightness ==
                                        Brightness.dark
                                    ? Colors.grey[850]
                                    : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.person, color: Colors.grey),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'Requested By',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                        Text(
                                          data['userName'] ?? 'Unknown',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          data['userEmail'] ?? '',
                                          style: const TextStyle(fontSize: 13),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                            const Text(
                              'Request Details',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...details.entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.only(bottom: 12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      e.key,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${e.value}',
                                      style: const TextStyle(fontSize: 15),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (status == 'Pending') ...[
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => showActionConfirmationDialog(
                                'Reject',
                                'Rejected',
                                Colors.red,
                              ),
                              child: const Text(
                                'Reject',
                                style: TextStyle(fontWeight: FontWeight.normal),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                                foregroundColor: Colors.white,
                              ),
                              onPressed: () => showActionConfirmationDialog(
                                'Approve',
                                'Approved/Resolved',
                                Colors.green,
                              ),
                              child: const Text(
                                'Approve',
                                style: TextStyle(fontWeight: FontWeight.normal),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTicketCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final status = data['status'];

    IconData iconData = Icons.receipt;
    if (data['serviceType'] == 'laptop_request') iconData = Icons.laptop;
    if (data['serviceType'] == 'broken_pc_report') {
      iconData = Icons.computer;
    }
    if (data['serviceType'] == 'missing_item_report') {
      iconData = Icons.search;
    }
    if (data['serviceType'] == 'lecturer_appointment') {
      iconData = Icons.event;
    }
    if (data['serviceType'] == 'contact_staff') {
      iconData = Icons.support_agent;
    }

    Color statusColor = Colors.grey;
    if (status == 'Pending') statusColor = Colors.orange;
    if (status == 'Cancelled' || status == 'Rejected') {
      statusColor = Colors.red;
    }
    if (status == 'Approved/Resolved') statusColor = Colors.green;

    return ValueListenableBuilder<bool>(
      valueListenable: UniDeskAdminApp.highContrastNotifier,
      builder: (context, highContrast, _) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        final primaryColor = isDark
            ? AppTheme.pastelBlue
            : Theme.of(context).primaryColor;

        final iconBgColor = highContrast
            ? primaryColor
            : primaryColor.withOpacity(0.1);
        final iconFgColor = highContrast
            ? (isDark ? AppTheme.pastelBlueDark : Colors.white)
            : primaryColor;

        final badgeBgColor = highContrast
            ? statusColor
            : statusColor.withOpacity(0.1);
        final badgeFgColor = highContrast ? Colors.white : statusColor;
        final badgeBorderColor = highContrast
            ? Colors.transparent
            : statusColor.withOpacity(0.5);

        return Card(
          elevation: 0,
          color: Theme.of(context).cardColor,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.withOpacity(0.2)),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _showTicketDetails(data, doc.id),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: iconBgColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(iconData, color: iconFgColor),
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
                            const SizedBox(height: 4),
                            Text(
                              'Requested by: ${data['userName']}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: badgeBgColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: badgeBorderColor),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: badgeFgColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusSection(
    String title,
    List<QueryDocumentSnapshot> docs,
    Color color,
  ) {
    if (docs.isEmpty) return const SizedBox.shrink();

    return ValueListenableBuilder<bool>(
      valueListenable: UniDeskAdminApp.highContrastNotifier,
      builder: (context, highContrast, _) {
        final titleBgColor = highContrast ? color : Colors.transparent;
        final titleFgColor = highContrast ? Colors.white : color;
        final borderColor = highContrast ? color : color.withOpacity(0.3);

        return Theme(
          data: Theme.of(context).copyWith(
            dividerColor: Colors.transparent,
            listTileTheme: ListTileThemeData(
              tileColor: titleBgColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          child: Card(
            elevation: 0,
            color: Colors.transparent,
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(color: borderColor),
            ),
            child: ExpansionTile(
              initiallyExpanded: title == 'Pending',
              title: Text(
                '$title (${docs.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: titleFgColor,
                ),
              ),
              collapsedIconColor: titleFgColor,
              iconColor: titleFgColor,
              childrenPadding: const EdgeInsets.all(16).copyWith(top: 0),
              children: docs.map((doc) => _buildTicketCard(doc)).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTicketList(List<QueryDocumentSnapshot> docs) {
    if (docs.isEmpty) {
      return const Center(
        child: Text('No active tickets found in this category.'),
      );
    }

    return ListView.builder(
      itemCount: docs.length,
      padding: const EdgeInsets.only(top: 16),
      itemBuilder: (context, index) {
        return _buildTicketCard(docs[index]);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tickets Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedSort,
                        icon: Icon(
                          Icons.sort,
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppTheme.pastelBlue
                              : null,
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Recent',
                            child: Text('Sort: Recent'),
                          ),
                          DropdownMenuItem(
                            value: 'By Status',
                            child: Text('Sort: By Status'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedSort = value;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('tickets')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                var allDocs = snapshot.data?.docs ?? [];

                if (_selectedSort == 'By Status') {
                  final Map<String, List<QueryDocumentSnapshot>> groupedDocs = {
                    'Pending': [],
                    'Approved/Resolved': [],
                    'Rejected': [],
                    'Cancelled': [],
                  };

                  for (var doc in allDocs) {
                    final status =
                        (doc.data() as Map<String, dynamic>)['status'] ??
                        'Pending';
                    if (groupedDocs.containsKey(status)) {
                      groupedDocs[status]!.add(doc);
                    } else {
                      groupedDocs['Pending']!.add(doc);
                    }
                  }

                  return ListView(
                    padding: const EdgeInsets.only(top: 16),
                    children: [
                      _buildStatusSection(
                        'Pending',
                        groupedDocs['Pending']!,
                        Colors.orange,
                      ),
                      _buildStatusSection(
                        'Approved/Resolved',
                        groupedDocs['Approved/Resolved']!,
                        Colors.green,
                      ),
                      _buildStatusSection(
                        'Rejected',
                        groupedDocs['Rejected']!,
                        Colors.red,
                      ),
                      _buildStatusSection(
                        'Cancelled',
                        groupedDocs['Cancelled']!,
                        Colors.red,
                      ),
                    ],
                  );
                }

                return _buildTicketList(allDocs);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// User Management View
class UsersView extends StatefulWidget {
  const UsersView({super.key});

  @override
  State<UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<UsersView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showAddUserDialog() {
    UniDeskAdminApp.showAppDialog(
      context: context,
      builder: (context) => const AddUserDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'User Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddUserDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add User'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('users').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No users found.'));
                }

                return ListView.builder(
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(data['role'] == 'teacher' ? 'T' : 'S'),
                        ),
                        title: Text(data['name'] ?? 'Unknown Name'),
                        subtitle: Text(
                          '${data['email']} • Role: ${data['role']}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(
                            Icons.delete,
                            color: AppTheme.pastelBlue,
                          ),
                          onPressed: () {
                            // TO DO: Delete logic (requires Cloud Function or server to delete Auth user)
                            // For now, we just delete the Firestore document.
                            _firestore.collection('users').doc(doc.id).delete();
                          },
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class AddUserDialog extends StatefulWidget {
  const AddUserDialog({super.key});

  @override
  State<AddUserDialog> createState() => _AddUserDialogState();
}

class _AddUserDialogState extends State<AddUserDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  String _role = 'student';
  bool _isLoading = false;

  Future<void> _createUser() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // 1. Create User in Firebase Auth
      // Note: This signs out the current admin. To prevent this, we use a secondary Firebase app
      // or Cloud Functions in production. For simplicity here, we'll re-authenticate or allow it.
      // A better approach for Admin SDK is Cloud Functions, but let's do this for now.

      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      final userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await secondaryApp.delete();

      // 2. Save User Details in Firestore
      if (userCredential.user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCredential.user!.uid)
            .set({
              'name': _nameController.text.trim(),
              'email': _emailController.text.trim(),
              'role': _role,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.pastelBlue,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add New User'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full Name'),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter a name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email Address'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) =>
                    value!.isEmpty ? 'Please enter an email' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (value) => value!.length < 6
                    ? 'Password must be at least 6 characters'
                    : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'student', child: Text('Student')),
                  DropdownMenuItem(value: 'teacher', child: Text('Teacher')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _role = value;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _createUser,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(),
                )
              : const Text('Create User'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}

// Added via python script natively
class InventoryView extends StatefulWidget {
  const InventoryView({super.key});

  @override
  State<InventoryView> createState() => _InventoryViewState();
}

class _InventoryViewState extends State<InventoryView> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  void _showEditStockDialog(String docId, String itemName, int currentStock) {
    final controller = TextEditingController(text: currentStock.toString());

    UniDeskAdminApp.showAppDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Stock: $itemName'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Available Quantity'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final newStock = int.tryParse(controller.text.trim()) ?? 0;
              await _firestore.collection('inventory').doc(docId).update({
                'stock': newStock,
              });
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final stockController = TextEditingController();
    String category = 'Laptops';

    UniDeskAdminApp.showAppDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add New Item'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Item Name (e.g. HDMI Cable)',
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: const [
                DropdownMenuItem(value: 'Laptops', child: Text('Laptops')),
                DropdownMenuItem(
                  value: 'Peripherals',
                  child: Text('Peripherals (Mice, Keyboards)'),
                ),
                DropdownMenuItem(
                  value: 'Cables',
                  child: Text('Cables & Adapters'),
                ),
                DropdownMenuItem(
                  value: 'Other',
                  child: Text('Other Equipment'),
                ),
              ],
              onChanged: (value) {
                if (value != null) category = value;
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: stockController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Initial Stock Quantity',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              final newStock = int.tryParse(stockController.text.trim()) ?? 0;

              await _firestore.collection('inventory').add({
                'name': nameController.text.trim(),
                'category': category,
                'stock': newStock,
                'status': 'Active',
                'createdAt': FieldValue.serverTimestamp(),
              });

              if (mounted) Navigator.pop(context);
            },
            child: const Text('Add Item'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Inventory Management',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: _showAddItemDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Item'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('inventory')
                  .orderBy('category')
                  .orderBy('name')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Inventory is empty.',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () async {
                            // Seed dummy data
                            final batch = _firestore.batch();
                            final items = [
                              {
                                'name': 'Dell XPS 15 (Performance)',
                                'category': 'Laptops',
                                'stock': 5,
                              },
                              {
                                'name': 'HP ProBook (Standard)',
                                'category': 'Laptops',
                                'stock': 12,
                              },
                              {
                                'name': 'HDMI to VGA Adapter',
                                'category': 'Cables',
                                'stock': 8,
                              },
                              {
                                'name': 'USB-C Display Cable',
                                'category': 'Cables',
                                'stock': 15,
                              },
                              {
                                'name': 'Logitech Wireless Mouse',
                                'category': 'Peripherals',
                                'stock': 20,
                              },
                              {
                                'name': 'Mechanical Keyboard',
                                'category': 'Peripherals',
                                'stock': 4,
                              },
                            ];
                            for (var item in items) {
                              item['status'] = 'Active';
                              item['createdAt'] = FieldValue.serverTimestamp();
                              batch.set(
                                _firestore.collection('inventory').doc(),
                                item,
                              );
                            }
                            await batch.commit();
                          },
                          child: const Text('Seed Dummy Inventory'),
                        ),
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 3,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final doc = snapshot.data!.docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    final stock = data['stock'] ?? 0;
                    final isLowStock = stock < 3;

                    IconData iconData = Icons.device_unknown;
                    if (data['category'] == 'Laptops') iconData = Icons.laptop;
                    if (data['category'] == 'Peripherals')
                      iconData = Icons.keyboard;
                    if (data['category'] == 'Cables') iconData = Icons.cable;

                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: isLowStock
                              ? AppTheme.pastelBlue.withOpacity(0.5)
                              : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isLowStock
                              ? AppTheme.pastelBlue.withOpacity(0.1)
                              : Theme.of(context).primaryColor.withOpacity(0.1),
                          child: Icon(
                            iconData,
                            color: isLowStock
                                ? AppTheme.pastelBlue
                                : Theme.of(context).primaryColor,
                          ),
                        ),
                        title: Text(
                          data['name'] ?? 'Unknown Item',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Category: ${data['category']}\nAvailable: $stock',
                          style: TextStyle(
                            color: isLowStock ? AppTheme.pastelBlue : null,
                            fontWeight: isLowStock ? FontWeight.bold : null,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit),
                          onPressed: () =>
                              _showEditStockDialog(doc.id, data['name'], stock),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Settings',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: UniDeskAdminApp.themeNotifier,
              builder: (context, currentMode, _) {
                final isDark =
                    currentMode == ThemeMode.dark ||
                    (currentMode == ThemeMode.system &&
                        MediaQuery.of(context).platformBrightness ==
                            Brightness.dark);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Display',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ListTile(
                      title: const Text(
                        'Theme',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: const Text(
                        'Choose light, dark, or system theme',
                      ),
                      leading: CircleAvatar(
                        backgroundColor:
                            (isDark
                                    ? AppTheme.pastelBlue
                                    : Theme.of(context).primaryColor)
                                .withOpacity(0.1),
                        child: Icon(
                          currentMode == ThemeMode.system
                              ? Icons.brightness_auto
                              : (isDark ? Icons.dark_mode : Icons.light_mode),
                          color: isDark
                              ? AppTheme.pastelBlue
                              : Theme.of(context).primaryColor,
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.3),
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<ThemeMode>(
                            value: currentMode,
                            icon: Icon(
                              Icons.arrow_drop_down,
                              color: isDark ? AppTheme.pastelBlue : null,
                            ),
                            onChanged: (ThemeMode? newMode) {
                              if (newMode != null) {
                                UniDeskAdminApp.themeNotifier.value = newMode;
                              }
                            },
                            items: const [
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text('Light'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text('Dark'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text('System Theme'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ValueListenableBuilder<ThemeMode>(
              valueListenable: UniDeskAdminApp.themeNotifier,
              builder: (context, currentMode, _) {
                final isDark =
                    currentMode == ThemeMode.dark ||
                    (currentMode == ThemeMode.system &&
                        MediaQuery.of(context).platformBrightness ==
                            Brightness.dark);

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Accessibility',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                    ValueListenableBuilder<bool>(
                      valueListenable: UniDeskAdminApp.highContrastNotifier,
                      builder: (context, highContrast, _) {
                        return SwitchListTile(
                          title: const Text(
                            'High Contrast Mode',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Increase visual contrast for better readability',
                          ),
                          secondary: CircleAvatar(
                            backgroundColor:
                                (isDark
                                        ? AppTheme.pastelBlue
                                        : Theme.of(context).primaryColor)
                                    .withOpacity(0.1),
                            child: Icon(
                              Icons.contrast,
                              color: isDark
                                  ? AppTheme.pastelBlue
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                          activeColor: isDark
                              ? AppTheme.pastelBlue
                              : Theme.of(context).primaryColor,
                          value: highContrast,
                          onChanged: (bool value) {
                            UniDeskAdminApp.highContrastNotifier.value = value;
                          },
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ValueListenableBuilder<bool>(
                      valueListenable: UniDeskAdminApp.reduceMotionNotifier,
                      builder: (context, reduceMotion, _) {
                        return SwitchListTile(
                          title: const Text(
                            'Reduce Motion',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: const Text(
                            'Disable animations and switch to fast fades',
                          ),
                          secondary: CircleAvatar(
                            backgroundColor:
                                (isDark
                                        ? AppTheme.pastelBlue
                                        : Theme.of(context).primaryColor)
                                    .withOpacity(0.1),
                            child: Icon(
                              Icons.animation,
                              color: isDark
                                  ? AppTheme.pastelBlue
                                  : Theme.of(context).primaryColor,
                            ),
                          ),
                          activeColor: isDark
                              ? AppTheme.pastelBlue
                              : Theme.of(context).primaryColor,
                          value: reduceMotion,
                          onChanged: (bool value) {
                            UniDeskAdminApp.reduceMotionNotifier.value = value;
                          },
                        );
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
