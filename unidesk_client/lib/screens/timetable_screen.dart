import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../core/app_theme.dart';
import '../widgets/app_pickers.dart';

class LectureEvent {
  final String title;
  final String time;
  final Color color;
  final String location;
  final String lecturer;
  final bool isCustom;

  const LectureEvent({
    required this.title,
    required this.time,
    required this.color,
    this.location = 'TBA',
    this.lecturer = 'TBA',
    this.isCustom = false,
  });
}

class TimetableScreen extends StatefulWidget {
  const TimetableScreen({super.key});

  @override
  State<TimetableScreen> createState() => _TimetableScreenState();
}

class _TimetableScreenState extends State<TimetableScreen> {
  final CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  bool _isLoading = true;

  final Map<DateTime, List<LectureEvent>> _events = {};

  final List<Color> _pastelColors = const [
    Color(0xFFB3E5FC), // Light Blue
    Color(0xFF90CAF9), // Secondary Pastel Blue
    Color(0xFFC8E6C9), // Pastel Green
    Color(0xFFFFF9C4), // Pastel Yellow
    Color(0xFFE1BEE7), // Pastel Purple
    Color(0xFFFFCC80), // Pastel Orange
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _loadScheduleData();
  }

  Future<void> _loadScheduleData() async {
    try {
      final jsonString = await rootBundle.loadString('assets/24.1.json');
      final List<dynamic> jsonList = jsonDecode(jsonString);

      if (jsonList.isEmpty) return;

      int colorIndex = 0;
      for (int i = 1; i < jsonList.length; i++) {
        final row = jsonList[i] as Map<String, dynamic>;
        final excelDate = row['Date'];
        if (excelDate == null || excelDate is! num) continue;

        // Convert Excel serial date to Dart DateTime
        // Excel epoch is Dec 30, 1899
        final targetDate = DateTime.utc(
          1899,
          12,
          30,
        ).add(Duration(days: excelDate.toInt()));

        String time1 = row['Time Slots']?.toString() ?? '';
        String time2 = row['__EMPTY']?.toString() ?? '';
        String time3 = row['__EMPTY_1']?.toString() ?? '';

        final List<String> extractedEvents = [time1, time2, time3]
            .where(
              (s) =>
                  s.trim().isNotEmpty &&
                  !s.toLowerCase().contains('weekdays') &&
                  !s.toLowerCase().contains('weekend'),
            )
            .toList();

        if (extractedEvents.isNotEmpty) {
          _events[targetDate] ??= [];
          for (final eventText in extractedEvents) {
            String extractedTitle = eventText.trim();
            String extractedTime = "TBA";

            // Simple heuristic to extract time if appended inside brackets or explicit
            if (extractedTitle.contains('-') && extractedTitle.contains('am') ||
                extractedTitle.contains('pm')) {
              // Leave times mostly as they are if it's uniquely formatted, otherwise we pass it explicitly.
            } else {
              extractedTime =
                  '09:00 AM - 12:00 PM'; // Generic fallback if we just see "Video Production [KW]"
            }

            _events[targetDate]!.add(
              LectureEvent(
                title: extractedTitle,
                time: extractedTime,
                color: _pastelColors[colorIndex % _pastelColors.length],
              ),
            );
            colorIndex++;
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing timetable JSON: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  List<LectureEvent> _getEventsForDay(DateTime day) {
    final normalizedDay = DateTime.utc(day.year, day.month, day.day);
    return _events[normalizedDay] ?? [];
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    // Navigate to zoomed-in day details view
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DayDetailsScreen(
          date: selectedDay,
          events: _getEventsForDay(selectedDay),
          onDelete: (event) {
            setState(() {
              final normalizedDay = DateTime.utc(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
              );
              _events[normalizedDay]?.remove(event);
            });
          },
          onEdit: (oldEvent, newEvent) {
            setState(() {
              final normalizedDay = DateTime.utc(
                selectedDay.year,
                selectedDay.month,
                selectedDay.day,
              );
              final index = _events[normalizedDay]?.indexOf(oldEvent) ?? -1;
              if (index != -1) {
                _events[normalizedDay]![index] = newEvent;
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 20, // Reduced height as title is removed
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        children: [
          const SizedBox(height: 8),
          // Calendar Card
          Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TableCalendar<LectureEvent>(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              availableCalendarFormats: const {CalendarFormat.month: 'Month'},
              sixWeekMonthsEnforced: true,
              selectedDayPredicate: (day) {
                return isSameDay(_selectedDay, day);
              },
              onDaySelected: _onDaySelected,
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              eventLoader: _getEventsForDay,
              headerStyle: HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                leftChevronIcon: Icon(
                  Icons.chevron_left_rounded,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                rightChevronIcon: Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
                titleTextStyle: TextStyle(
                  color: isDark ? Colors.white : Colors.black,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              daysOfWeekStyle: DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
                weekendStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.grey[600],
                ),
              ),
              calendarStyle: CalendarStyle(
                outsideDaysVisible: false,
                selectedDecoration: BoxDecoration(
                  color: isDark ? AppTheme.pastelBlue : const Color(0xFF3B5B8E),
                  shape: BoxShape.circle,
                ),
                selectedTextStyle: TextStyle(
                  color: isDark ? Colors.black : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                todayDecoration: BoxDecoration(
                  color:
                      (isDark ? AppTheme.pastelBlue : const Color(0xFF3B5B8E))
                          .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: isDark ? AppTheme.pastelBlue : const Color(0xFF3B5B8E),
                  fontWeight: FontWeight.bold,
                ),
                defaultTextStyle: const TextStyle(fontWeight: FontWeight.w500),
                weekendTextStyle: const TextStyle(fontWeight: FontWeight.w500),
                markerDecoration: BoxDecoration(
                  color: isDark ? AppTheme.pastelBlue : const Color(0xFF3B5B8E),
                  shape: BoxShape.circle,
                ),
                markersMaxCount: 1,
                markerSize: 4.5,
                cellMargin: const EdgeInsets.all(4),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Section (Today & Add Event)
          _buildActionSection(isDark),

          const SizedBox(height: 32),

          // Upcoming Lectures Section
          _buildUpcomingEvents(isDark),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildActionSection(bool isDark) {
    return Row(
      children: [
        _buildTodayButton(isDark),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _showAddEventDialog,
            icon: Icon(
              Icons.add_rounded,
              color: isDark ? Colors.black87 : Colors.white,
            ),
            label: Text(
              'Add Event',
              style: TextStyle(
                color: isDark ? Colors.black87 : Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? AppTheme.pastelBlue : Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayButton(bool isDark) {
    final today = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final isNotToday = !isSameDay(_selectedDay, today);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 300),
      opacity: isNotToday ? 1 : 0.5,
      child: IgnorePointer(
        ignoring: !isNotToday,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.pastelBlue.withOpacity(0.15),
            borderRadius: BorderRadius.circular(20),
          ),
          child: IconButton(
            onPressed: () {
              setState(() {
                _focusedDay = DateTime.now();
                _selectedDay = _focusedDay;
              });
            },
            icon: Icon(
              Icons.today_rounded,
              color: isDark ? Colors.white : const Color(0xFF1A237E),
            ),
            tooltip: 'Back to Today',
          ),
        ),
      ),
    );
  }

  void _showAddEventDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController startTimeController = TextEditingController();
    final TextEditingController endTimeController = TextEditingController();
    final TextEditingController locationController = TextEditingController();

    AppTheme.showAppModalBottomSheet(
      context: context,
      builder: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add New Event',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Event name (e.g. Study Group)',
                  labelText: 'Event Name*',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startTimeController,
                      readOnly: true,
                      onTap: () => AppPickers.showTimePicker(
                        context: context,
                        controller: startTimeController,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Start Time*',
                        hintText: 'Select',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: endTimeController,
                      readOnly: true,
                      onTap: () => AppPickers.showTimePicker(
                        context: context,
                        controller: endTimeController,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'End Time*',
                        hintText: 'Select',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Library',
                  labelText: 'Location (Optional)',
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (titleController.text.isNotEmpty &&
                          startTimeController.text.isNotEmpty &&
                          endTimeController.text.isNotEmpty) {
                        setState(() {
                          final normalizedDay = DateTime.utc(
                            _selectedDay?.year ?? _focusedDay.year,
                            _selectedDay?.month ?? _focusedDay.month,
                            _selectedDay?.day ?? _focusedDay.day,
                          );
                          _events[normalizedDay] ??= [];
                          _events[normalizedDay]!.add(
                            LectureEvent(
                              title: titleController.text.trim(),
                              time:
                                  '${startTimeController.text} - ${endTimeController.text}',
                              color: _pastelColors[5],
                              location: locationController.text.trim().isEmpty
                                  ? 'TBA'
                                  : locationController.text.trim(),
                              lecturer: 'Self',
                              isCustom: true,
                            ),
                          );
                        });
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text(
                      'Save Event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
  }

  Widget _buildUpcomingEvents(bool isDark) {
    final targetDay = _selectedDay ?? _focusedDay;
    final normalizedDay = DateTime.utc(
      targetDay.year,
      targetDay.month,
      targetDay.day,
    );

    final sortedDates = _events.keys.toList()..sort();
    final groupedEvents = <DateTime, List<LectureEvent>>{};

    for (final date in sortedDates) {
      if (date.isAfter(normalizedDay) || date.isAtSameMomentAs(normalizedDay)) {
        groupedEvents[date] = _events[date]!;
      }
    }

    final displayEntries = groupedEvents.entries.take(10).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Upcoming Lectures',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        if (displayEntries.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 40.0),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[850] : Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.event_note_outlined,
                    size: 40,
                    color: Colors.grey.withOpacity(0.3),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'No lectures scheduled',
                    style: TextStyle(
                      color: isDark ? Colors.white54 : Colors.grey[500],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ...displayEntries.map((entry) {
            final date = entry.key;
            final events = entry.value;

            String dateLabel = DateFormat('EEEE, MMM d').format(date);
            final today = DateTime.utc(
              DateTime.now().year,
              DateTime.now().month,
              DateTime.now().day,
            );
            if (date.isAtSameMomentAs(today)) {
              dateLabel = 'Today';
            } else if (date.isAtSameMomentAs(
              today.add(const Duration(days: 1)),
            )) {
              dateLabel = 'Tomorrow';
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4, top: 12, bottom: 12),
                  child: Text(
                    dateLabel,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppTheme.pastelBlue : Colors.grey[700],
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[850] : Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: events.asMap().entries.map((eventEntry) {
                      final idx = eventEntry.key;
                      final event = eventEntry.value;
                      return Column(
                        children: [
                          _buildCourseCard(event, isDark),
                          if (idx < events.length - 1)
                            Divider(
                              height: 1,
                              indent: 20,
                              endIndent: 20,
                              color: Colors.grey.withOpacity(0.1),
                            ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            );
          }),
      ],
    );
  }

  Widget _buildCourseCard(LectureEvent event, bool isDark) {
    final isHighContrast = UniDeskApp.settings.isHighContrast;
    String splitTime = event.time.split(' - ').first;
    if (splitTime == 'TBA') splitTime = 'TBA';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: isHighContrast
                  ? (isDark ? const Color(0xFFE0F2FE) : Colors.black)
                  : event.color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  event.title,
                  style: TextStyle(
                    fontWeight: isHighContrast
                        ? FontWeight.w900
                        : FontWeight.w600,
                    fontSize: 15,
                    color: isHighContrast
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark
                              ? Colors.white.withOpacity(0.9)
                              : Colors.black87),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Room ${event.location}',
                  style: TextStyle(
                    color: isHighContrast
                        ? (isDark ? Colors.white : Colors.black)
                        : (isDark ? Colors.white54 : Colors.grey[600]),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                splitTime,
                style: TextStyle(
                  color: isDark ? AppTheme.pastelBlue : const Color(0xFF3B5B8E),
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: isDark ? Colors.white24 : Colors.grey[400],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DayDetailsScreen extends StatefulWidget {
  final DateTime date;
  final List<LectureEvent> events;
  final Function(LectureEvent) onDelete;
  final Function(LectureEvent, LectureEvent) onEdit;

  const DayDetailsScreen({
    super.key,
    required this.date,
    required this.events,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<DayDetailsScreen> createState() => _DayDetailsScreenState();
}

class _DayDetailsScreenState extends State<DayDetailsScreen> {
  late List<LectureEvent> _currentEvents;

  @override
  void initState() {
    super.initState();
    _currentEvents = List.from(widget.events);
  }

  void _showEditEventDialog(LectureEvent oldEvent) {
    if (!oldEvent.isCustom) return;

    final titleController = TextEditingController(text: oldEvent.title);

    // Parse existing time string "Start - End"
    String startStr = '';
    String endStr = '';
    if (oldEvent.time.contains(' - ')) {
      final parts = oldEvent.time.split(' - ');
      startStr = parts[0];
      endStr = parts[1];
    } else {
      startStr = oldEvent.time;
    }

    final startTimeController = TextEditingController(text: startStr);
    final endTimeController = TextEditingController(text: endStr);
    final locationController = TextEditingController(text: oldEvent.location);

    AppTheme.showAppModalBottomSheet(
      context: context,
      builder: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.85,
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Edit Event',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Event Name*'),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startTimeController,
                      readOnly: true,
                      onTap: () => AppPickers.showTimePicker(
                        context: context,
                        controller: startTimeController,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Start Time*',
                        hintText: 'Select',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextField(
                      controller: endTimeController,
                      readOnly: true,
                      onTap: () => AppPickers.showTimePicker(
                        context: context,
                        controller: endTimeController,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'End Time*',
                        hintText: 'Select',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (Optional)',
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      if (titleController.text.isNotEmpty &&
                          startTimeController.text.isNotEmpty &&
                          endTimeController.text.isNotEmpty) {
                        final newEvent = LectureEvent(
                          title: titleController.text.trim(),
                          time:
                              '${startTimeController.text} - ${endTimeController.text}',
                          color: oldEvent.color,
                          location: locationController.text.trim().isEmpty
                              ? 'TBA'
                              : locationController.text.trim(),
                          lecturer: 'Self',
                          isCustom: true,
                        );

                        setState(() {
                          final index = _currentEvents.indexOf(oldEvent);
                          if (index != -1) {
                            _currentEvents[index] = newEvent;
                          }
                        });

                        widget.onEdit(oldEvent, newEvent);
                        Navigator.of(context).pop();
                      }
                    },
                    child: const Text(
                      'Save Event',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
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
  }

  void _deleteEvent(LectureEvent event) {
    setState(() {
      _currentEvents.remove(event);
    });
    widget.onDelete(event);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Event deleted')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final dateString = DateFormat.yMMMMd().format(widget.date);

    return Scaffold(
      appBar: AppBar(title: Text(dateString), elevation: 0),
      body: _currentEvents.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.event_busy,
                    size: 80,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No events on this day!',
                    style: TextStyle(
                      fontSize: 18,
                      color: isDark ? Colors.white70 : Colors.grey,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20.0),
              itemCount: _currentEvents.length,
              itemBuilder: (context, index) {
                final event = _currentEvents[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 20.0),
                  elevation: 4,
                  shadowColor: event.color.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  color: event
                      .color, // Pastel background directly driving the card color
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                event.title,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                  height: 1.2,
                                ),
                              ),
                            ),
                            if (event.isCustom)
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit,
                                      color: Colors.black54,
                                      size: 20,
                                    ),
                                    onPressed: () =>
                                        _showEditEventDialog(event),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                  const SizedBox(width: 8),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.black54,
                                      size: 20,
                                    ),
                                    onPressed: () => _deleteEvent(event),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                  ),
                                ],
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black12,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Text(
                                  event.time.split(' - ').first,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black12,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on,
                                size: 18,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              event.location,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black12,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.person,
                                size: 18,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              event.lecturer,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Colors.black12,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.access_time,
                                size: 18,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              event.time,
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
