import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:unidesk_admin/core/app_theme.dart';
import 'package:unidesk_admin/widgets/skeleton_loader.dart';

class HomeView extends StatefulWidget {
  final Function(int) onTabSwitch;
  const HomeView({super.key, required this.onTabSwitch});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const ClockWidget(),
      ],
    );
  }

  Widget _buildStatsGrid() {
    return Row(
      children: [
        Expanded(
          child: StatCard(
            title: 'Total Tickets',
            collectionPath: 'tickets',
            icon: Icons.receipt_long,
            color: Colors.blue,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: StatCard(
            title: 'Pending Action',
            collectionPath: 'tickets',
            query: (ref) => ref.where('status', isEqualTo: 'Pending'),
            icon: Icons.pending_actions,
            color: Colors.orange,
          ),
        ),
      ],
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
                  return const Padding(
                    padding: EdgeInsets.all(20.0),
                    child: SkeletonLoader(width: double.infinity, height: 300, borderRadius: 12),
                  );
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
                        data['createdAt'] != null
                            ? DateFormat('MMM d, hh:mm a').format((data['createdAt'] as Timestamp).toDate())
                            : 'N/A',
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
    return SizedBox(
      height: 120,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  const Text(
                    'Students Online',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(width: 4),
                  InkWell(
                    onTap: () => widget.onTabSwitch(2),
                    child: const Icon(
                      Icons.arrow_forward,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('role', isEqualTo: 'student')
                    .where('status', isEqualTo: 'online')
                    .snapshots(),
                builder: (context, snapshot) {
                  int onlineCount = 0;
                  if (snapshot.hasData) {
                    onlineCount = snapshot.data!.docs.length;
                  }

                  return Align(
                    alignment: Alignment.bottomRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.circle, color: Colors.green, size: 12),
                        const SizedBox(width: 8),
                        Text(
                          onlineCount.toString(),
                          style: Theme.of(context).textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
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

class ClockWidget extends StatefulWidget {
  const ClockWidget({super.key});

  @override
  State<ClockWidget> createState() => _ClockWidgetState();
}

class _ClockWidgetState extends State<ClockWidget> {
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

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            DateFormat('HH:mm').format(_currentTime),
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: isDark ? AppTheme.pastelBlue : theme.primaryColor,
              letterSpacing: -1,
            ),
          ),
          Text(
            DateFormat('EEEE, d MMMM yyyy').format(_currentTime),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String collectionPath;
  final Query Function(Query ref)? query;
  final IconData icon;
  final Color color;

  const StatCard({
    super.key,
    required this.title,
    required this.collectionPath,
    this.query,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    Query ref = FirebaseFirestore.instance.collection(collectionPath);
    if (query != null) {
      ref = query!(ref);
    }

    return SizedBox(
      height: 120,
      child: Card(
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
                  StreamBuilder<QuerySnapshot>(
                    stream: ref.snapshots(),
                    builder: (context, snapshot) {
                      String value = '0';
                      if (snapshot.hasData) {
                        value = snapshot.data!.docs.length.toString();
                      }
                      return Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
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
      ),
    );
  }
}
