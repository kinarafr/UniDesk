import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'laptop_request_screen.dart';
import 'broken_pc_report_screen.dart';
import 'missing_item_report_screen.dart';
import 'appointment_booking_screen.dart';
import 'contact_staff_screen.dart';

import 'package:flutter_svg/flutter_svg.dart';

class QuickActionDef {
  final String id;
  final String title;
  final String svgPath;
  final Widget destination;

  const QuickActionDef({
    required this.id,
    required this.title,
    required this.svgPath,
    required this.destination,
  });
}

final List<QuickActionDef> _allAvailableActions = [
  const QuickActionDef(
    id: 'contact',
    title: 'Contact\nStaff',
    svgPath: 'assets/svgs/User.svg',
    destination: ContactStaffScreen(),
  ),
  const QuickActionDef(
    id: 'laptop',
    title: 'Borrow\na Laptop',
    svgPath: 'assets/svgs/Laptop.svg',
    destination: LaptopRequestScreen(),
  ),
  const QuickActionDef(
    id: 'broken',
    title: 'Report\nan Issue',
    svgPath: 'assets/svgs/Warning.svg',
    destination: BrokenPcReportScreen(),
  ),
  const QuickActionDef(
    id: 'missing',
    title: 'Report an\nMissing Item', // Following mockup text
    svgPath: 'assets/svgs/Search.svg',
    destination: MissingItemReportScreen(),
  ),
  const QuickActionDef(
    id: 'appointment',
    title:
        'Report an\nMissing Item', // Mockup repeated this text but used schedule icon
    svgPath: 'assets/svgs/Schedule.svg',
    destination: AppointmentBookingScreen(),
  ),
];

class HomeScreen extends StatefulWidget {
  final VoidCallback? onNavigateToTimetable;

  const HomeScreen({super.key, this.onNavigateToTimetable});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final user = FirebaseAuth.instance.currentUser;

  void _showEditQuickActionsDialog(
    BuildContext context,
    List<String> currentSelections,
  ) {
    List<String> tempSelections = List.from(currentSelections);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
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
                            final isSelected = tempSelections.contains(
                              action.id,
                            );

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
        );
      },
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
                          const Text(
                            'Hello,',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Upcoming Today',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: widget.onNavigateToTimetable,
                        child: const Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3B5B8E), // UniDesk Blue
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
                      itemCount: 4, // Increased dummy count to allow scrolling
                      itemBuilder: (context, index) {
                        return Container(
                          width: 300,
                          margin: const EdgeInsets.only(right: 16),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            image: const DecorationImage(
                              image: AssetImage(
                                'assets/images/Software-Engineering-Hero-1600x900.jpg',
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
                                  color: const Color(
                                    0xFF3B5B8E,
                                  ).withOpacity(0.95),
                                  borderRadius: const BorderRadius.only(
                                    bottomLeft: Radius.circular(16),
                                    bottomRight: Radius.circular(16),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Software Engineering',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        SizedBox(height: 4),
                                        Text(
                                          'Mr. Sanjaya Elvetigala',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 12,
                                          ),
                                        ),
                                        Text(
                                          '10:00 AM - 12:00 PM',
                                          style: TextStyle(
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
                                          'LAB',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const Text(
                                          '05',
                                          style: TextStyle(
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
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            _showEditQuickActionsDialog(context, userActionIds),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF3B5B8E), // UniDesk Blue
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
                              action.destination,
                            );
                          },
                        );
                      },
                    ),
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
    Widget destinationScreen,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF333333) : const Color(0xFFEEF0FA);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => destinationScreen),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SvgPicture.asset(
              svgPath,
              height: 40,
              colorFilter: ColorFilter.mode(
                isDark ? Colors.white : const Color(0xFF3B5B8E),
                BlendMode.srcIn,
              ),
            ),
            const Spacer(),
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
