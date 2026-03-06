import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';
import '../core/app_theme.dart';
import 'laptop_request_screen.dart';
import 'broken_pc_report_screen.dart';
import 'missing_item_report_screen.dart';
import 'appointment_booking_screen.dart';
import 'contact_staff_screen.dart';
import '../widgets/lecture_detail_sheet.dart';

import 'package:flutter_svg/flutter_svg.dart';

class QuickActionDef {
  final String id;
  final String title;
  final String svgPath;
  final Color color;
  final Widget destination;

  const QuickActionDef({
    required this.id,
    required this.title,
    required this.svgPath,
    required this.color,
    required this.destination,
  });
}

final List<QuickActionDef> _allAvailableActions = [
  const QuickActionDef(
    id: 'contact',
    title: 'Contact\nStaff',
    svgPath: 'assets/svgs/User.svg',
    color: Color(0xFFB3E5FC), // Light Blue
    destination: ContactStaffScreen(),
  ),
  const QuickActionDef(
    id: 'laptop',
    title: 'Borrow\na Laptop',
    svgPath: 'assets/svgs/Laptop.svg',
    color: Color(0xFF90CAF9), // Secondary Pastel Blue
    destination: LaptopRequestScreen(),
  ),
  const QuickActionDef(
    id: 'broken',
    title: 'Report\nan Issue',
    svgPath: 'assets/svgs/Warning.svg',
    color: Color(0xFFC8E6C9), // Pastel Green
    destination: BrokenPcReportScreen(),
  ),
  const QuickActionDef(
    id: 'missing',
    title: 'Report a\nMissing Item', // Following mockup text
    svgPath: 'assets/svgs/Search.svg',
    color: Color(0xFFFFF9C4), // Pastel Yellow
    destination: MissingItemReportScreen(),
  ),
  const QuickActionDef(
    id: 'appointment',
    title: 'Book\nAppointment', // Following mockup text
    svgPath: 'assets/svgs/Schedule.svg',
    color: Color(0xFFE1BEE7), // Pastel Purple
    destination: AppointmentBookingScreen(),
  ),
];

// Dummy Data
final List<Map<String, dynamic>> _upcomingLectures = [
  {
    'title': 'Web Development',
    'lecturer': 'Mr Sanjaya Elvetigala',
    'time': '09:00 AM - 12:00 PM',
    'room': 'Lab 05',
    'imagePath': 'assets/images/web_dev.jpg',
    'color': const Color(0xFF3B5B8E), // UniDesk Blue
  },
  {
    'title': 'Cinematography',
    'lecturer': 'Mr Shanaka',
    'time': '01:00 PM - 04:00 PM',
    'room': 'Lab 02',
    'imagePath': 'assets/images/cine.png',
    'color': const Color(0xFF3B8E65), // Pastel Green accent
  },
  {
    'title': 'Motion Graphics',
    'lecturer': 'Mrs. Vasana',
    'time': '05:00 PM - 08:00 PM',
    'room': 'Lab 05',
    'imagePath': 'assets/images/motion.png',
    'color': const Color(0xFF8E3B65), // Pastel Purple/Red accent
  },
];

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTimetable;

  const HomeScreen({super.key, this.onNavigateToTimetable});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _showEditQuickActionsDialog(
    BuildContext context,
    List<String> currentSelections,
  ) {
    List<String> tempSelections = List.from(currentSelections);

    AppTheme.showAppModalBottomSheet(
      context: context,
      builder: StatefulBuilder(
        builder: (context, setModalState) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            minChildSize: 0.4,
            maxChildSize: 0.85,
            expand: false,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Customize Actions',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (user != null) {
                              await FirebaseFirestore.instance
                                  .collection('users')
                                  .doc(user!.uid)
                                  .set({
                                    'quickActions': tempSelections,
                                  }, SetOptions(merge: true));
                            }
                            if (context.mounted) Navigator.pop(context);
                          },
                          child: const Text('Save'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _allAvailableActions.length,
                        itemBuilder: (context, index) {
                          final action = _allAvailableActions[index];
                          final isSelected = tempSelections.contains(action.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(
                                  context,
                                ).primaryColor.withOpacity(0.1),
                                child: SvgPicture.asset(
                                  action.svgPath,
                                  height: 24,
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).primaryColor,
                                    BlendMode.srcIn,
                                  ),
                                ),
                              ),
                              title: Text(action.title.replaceAll('\n', ' ')),
                              trailing: IconButton(
                                icon: Icon(
                                  isSelected
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: isSelected
                                      ? Colors.green
                                      : Colors.grey,
                                  size: 28,
                                ),
                                onPressed: () {
                                  setModalState(() {
                                    if (isSelected) {
                                      tempSelections.remove(action.id);
                                    } else {
                                      tempSelections.add(action.id);
                                    }
                                  });
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Center(child: Text('Not logged in'));
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            Map<String, dynamic> userData = {};
            if (snapshot.hasData && snapshot.data!.exists) {
              userData = snapshot.data!.data() as Map<String, dynamic>;
            }

            final name = userData['name'] ?? 'Student';

            List<String> userActionIds = [];
            if (userData.containsKey('quickActions')) {
              userActionIds = List<String>.from(userData['quickActions']);
            } else {
              userActionIds = ['laptop', 'broken', 'contact'];
            }

            final userActions = userActionIds
                .map(
                  (id) => _allAvailableActions.firstWhere(
                    (a) => a.id == id,
                    orElse: () => _allAvailableActions.first,
                  ),
                )
                .toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 16.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Hello,',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : null,
                            ),
                          ),
                          Text(
                            name,
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: theme.brightness == Brightness.dark
                                  ? Colors.white
                                  : null,
                            ),
                          ),
                        ],
                      ),
                      Image.asset(
                        theme.brightness == Brightness.dark
                            ? 'assets/logos/NIBM_White.png'
                            : 'assets/logos/NIBM_Black.png',
                        height: 48,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  _buildSearchBar(context, theme.brightness == Brightness.dark),
                  const SizedBox(height: 32),

                  if (_searchQuery.isNotEmpty)
                    _buildSearchResults()
                  else ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Upcoming Today',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : null,
                          ),
                        ),
                        GestureDetector(
                          onTap: widget.onNavigateToTimetable,
                          child: Text(
                            'View All',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF90CAF9) // Pastel Blue
                                  : const Color(0xFF3B5B8E), // UniDesk Blue
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Image Carousel
                    SizedBox(
                      height: 180,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _upcomingLectures.length,
                        itemBuilder: (context, index) {
                          final lecture = _upcomingLectures[index];
                          return GestureDetector(
                            onTap: () {
                              AppTheme.showAppModalBottomSheet(
                                context: context,
                                builder: LectureDetailSheet(
                                  lecture: lecture,
                                  onNavigateToTimetable:
                                      widget.onNavigateToTimetable ?? () {},
                                ),
                              );
                            },
                            child: Container(
                              width: 300,
                              margin: const EdgeInsets.only(right: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(16),
                                image: DecorationImage(
                                  image: AssetImage(
                                    lecture['imagePath'] as String,
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(16.0),
                                    decoration: BoxDecoration(
                                      color: (lecture['color'] as Color)
                                          .withOpacity(0.95),
                                      borderRadius: const BorderRadius.only(
                                        bottomLeft: Radius.circular(16),
                                        bottomRight: Radius.circular(16),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              lecture['title'] as String,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              lecture['lecturer'] as String,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                            Text(
                                              lecture['time'] as String,
                                              style: const TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.end,
                                          children: [
                                            const Text(
                                              'ROOM',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 14,
                                              ),
                                            ),
                                            Text(
                                              lecture['room'] as String,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 26,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Quick Actions',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: theme.brightness == Brightness.dark
                                ? Colors.white
                                : null,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _showEditQuickActionsDialog(
                            context,
                            userActionIds,
                          ),
                          child: Text(
                            'Edit',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: theme.brightness == Brightness.dark
                                  ? const Color(0xFF90CAF9) // Pastel Blue
                                  : const Color(0xFF3B5B8E), // UniDesk Blue
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (userActions.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text(
                            'No quick actions selected. Click Edit to add some!',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    else
                      LayoutBuilder(
                        builder: (context, constraints) {
                          // Default to 3 columns on standard mobile screens
                          // Expand beyond 3 columns only if the screen is wider than 450px (e.g., Tablets/Web)
                          int columns = 3;
                          if (constraints.maxWidth > 450) {
                            columns = (constraints.maxWidth / 130).floor();
                          }

                          return GridView.builder(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: columns,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.85,
                                ),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: userActions.length,
                            itemBuilder: (context, index) {
                              final action = userActions[index];
                              return _buildQuickActionCard(
                                context,
                                action.svgPath,
                                action.title,
                                action.color,
                                action.destination,
                              );
                            },
                          );
                        },
                      ),
                  ], // End of the else ...[ block
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildQuickActionCard(
    BuildContext context,
    String svgPath,
    String label,
    Color bgColor,
    Widget destinationScreen,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighContrast = UniDeskApp.settings.isHighContrast;

    return InkWell(
      onTap: () {
        AppTheme.showAppModalBottomSheet(
          context: context,
          builder: destinationScreen,
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: isHighContrast
              ? bgColor
              : (isDark
                    ? bgColor
                    : bgColor), // Use full color in dark mode as requested
          borderRadius: BorderRadius.circular(16),
          border: isHighContrast
              ? Border.all(
                  color: isDark ? Colors.white : Colors.black,
                  width: 2,
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              svgPath,
              height: 40,
              colorFilter: ColorFilter.mode(
                isHighContrast
                    ? Colors.black
                    : (isDark
                          ? Colors.black
                          : Colors.black87), // Black icon in dark mode
                BlendMode.srcIn,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isHighContrast ? FontWeight.w900 : FontWeight.w600,
                height: 1.2,
                color: isHighContrast
                    ? Colors.black
                    : (isDark ? Colors.black : null), // Black text in dark mode
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context, bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          const Icon(CupertinoIcons.search, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Ask or search for anything',
                hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                });
                _searchFocus.unfocus();
              },
              child: const Icon(Icons.close, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    final query = _searchQuery.toLowerCase();

    // Quick actions (tickets, etc)
    final matchedActions = _allAvailableActions
        .where((a) => a.title.toLowerCase().contains(query))
        .toList();

    // Simulated global tickets
    final globalTickets =
        [
              {'id': 'TKT-1042', 'title': 'Laptop Request'},
              {'id': 'TKT-1089', 'title': 'Computer Broken Issue'},
              {'id': 'TKT-2001', 'title': 'Missing Item Report'},
            ]
            .where((t) => (t['title'] as String).toLowerCase().contains(query))
            .toList();

    // Lectures
    final matchedLectures =
        [
              {
                'title': 'Mathematics',
                'lecturer': 'Dr. Alan Turing',
                'time': '09:00 AM - 11:00 AM',
                'room': '01',
                'color': const Color(0xFF3B5B8E), // UniDesk Blue
              },
              {
                'title': 'DBMS',
                'lecturer': 'Ms. Ada Lovelace',
                'time': '12:00 PM - 02:00 PM',
                'room': '03',
                'color': const Color(0xFF3B8E65), // Pastel Green accent
              },
              {
                'title': 'Software Engineering',
                'lecturer': 'Mr. Sanjaya Elvetigala',
                'time': '03:00 PM - 05:00 PM',
                'room': '05',
                'color': const Color(0xFF8E3B65), // Pastel Purple/Red accent
              },
            ]
            .where((l) => (l['title'] as String).toLowerCase().contains(query))
            .toList();

    if (matchedActions.isEmpty &&
        globalTickets.isEmpty &&
        matchedLectures.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(16.0),
        child: Text('No results found.', style: TextStyle(color: Colors.grey)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (matchedLectures.isNotEmpty) ...[
          const Text(
            'Lectures',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ...matchedLectures.map(
            (l) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(CupertinoIcons.book, color: l['color'] as Color),
                title: Text(l['title'] as String),
                subtitle: Text('${l['lecturer']} • ${l['time']}'),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (matchedActions.isNotEmpty) ...[
          const Text(
            'Services',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ...matchedActions.map(
            (a) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).primaryColor.withOpacity(0.1),
                  child: SvgPicture.asset(
                    a.svgPath,
                    height: 20,
                    colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColor,
                      BlendMode.srcIn,
                    ),
                  ),
                ),
                title: Text(a.title),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  AppTheme.showAppModalBottomSheet(
                    context: context,
                    builder: a.destination,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
        if (globalTickets.isNotEmpty) ...[
          const Text(
            'Tickets',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          ...globalTickets.map(
            (t) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(
                  CupertinoIcons.ticket,
                  color: Colors.orange,
                ),
                title: Text(t['title'] as String),
                subtitle: Text('ID: ${t['id']}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  // Navigate to specific ticket detail page
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}
