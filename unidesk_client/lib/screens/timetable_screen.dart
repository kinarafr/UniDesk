import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

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
    Color(0xFFF8BBD0), // Pastel Pink
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
        appBar: AppBar(
          title: const Text(
            'Schedule',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          centerTitle: true,
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Schedule',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 20),
          onPressed: () {
            // Usually drops back to previous tab or stack
          },
        ),
        actions: [IconButton(icon: const Icon(Icons.tune), onPressed: () {})],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddEventDialog,
        backgroundColor: const Color(0xFF3B5B8E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: ListView(
        children: [
          TableCalendar<LectureEvent>(
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
              titleCentered: false,
              leftChevronIcon: Icon(
                Icons.chevron_left,
                color: isDark ? Colors.white : Colors.black87,
              ),
              rightChevronIcon: Icon(
                Icons.chevron_right,
                color: isDark ? Colors.white : Colors.black87,
              ),
              titleTextStyle: const TextStyle(
                color: Color(0xFF3B5B8E), // UniDesk Blue
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            daysOfWeekStyle: DaysOfWeekStyle(
              weekdayStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
              weekendStyle: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            calendarStyle: CalendarStyle(
              outsideDaysVisible: false,
              selectedDecoration: const BoxDecoration(
                color: Color(0xFF3B5B8E), // Solid Blue Circle
                shape: BoxShape.circle,
              ),
              selectedTextStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
              todayDecoration: const BoxDecoration(
                color: Colors.transparent,
                shape: BoxShape.circle,
              ),
              todayTextStyle: const TextStyle(
                color: Color(0xFF3B5B8E),
                fontWeight: FontWeight.bold,
              ),
              defaultTextStyle: const TextStyle(fontWeight: FontWeight.w500),
              weekendTextStyle: const TextStyle(fontWeight: FontWeight.w500),
              markerDecoration: const BoxDecoration(
                color: Color(0xFF3B5B8E),
                shape: BoxShape.circle,
              ),
              markersMaxCount: 1,
              markerSize: 4.5,
            ),
          ),
          _buildActionButtons(),
          _buildUpcomingEvents(isDark),
        ],
      ),
    );
  }

  void _showAddEventDialog() {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController timeController = TextEditingController();
    final TextEditingController locationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  hintText: 'Event name (e.g. Study Group)',
                  labelText: 'Event Name*',
                ),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  hintText: 'e.g. 10:00 AM - 11:00 AM',
                  labelText: 'Time*',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  hintText: 'e.g. Library',
                  labelText: 'Location (Optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    timeController.text.isNotEmpty) {
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
                        time: timeController.text.trim(),
                        color: _pastelColors[5], // Use Orange for custom
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
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionButtons() {
    final today = DateTime.utc(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final isNotToday = !isSameDay(_selectedDay, today);

    if (!isNotToday) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () {
            setState(() {
              _focusedDay = DateTime.now();
              _selectedDay = _focusedDay;
            });
          },
          icon: const Icon(Icons.today, size: 18),
          label: const Text('Today'),
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Upcoming Lectures',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          if (displayEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32.0),
              child: Center(
                child: Text(
                  'No lectures scheduled.',
                  style: TextStyle(
                    color: isDark ? Colors.white54 : Colors.black54,
                  ),
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
                    padding: const EdgeInsets.only(top: 8.0, bottom: 12.0),
                    child: Text(
                      dateLabel,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ...events.map(
                    (event) => Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: _buildCourseCard(event, isDark),
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCourseCard(LectureEvent event, bool isDark) {
    // Determine card background based on design
    final bgColor = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF8F9FE);

    // Extract a shorter time string, e.g. "14:00" from "10:00 AM - 12:00 PM"
    String splitTime = event.time.split(' - ').first;
    if (splitTime == 'TBA') splitTime = 'TBA';

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Colored vertical indicator
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: event.color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 20.0,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize
                            .min, // Prevents layout overflows in IntrinsicHeight
                        children: [
                          Text(
                            event.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '2 hours • Room ${event.location}', // Mockup format
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 18,
                          color: isDark
                              ? Colors.grey[300]
                              : const Color(0xFF3B5B8E),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          splitTime,
                          style: TextStyle(
                            color: isDark
                                ? Colors.grey[300]
                                : const Color(0xFF3B5B8E),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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
    final timeController = TextEditingController(text: oldEvent.time);
    final locationController = TextEditingController(text: oldEvent.location);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Event'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                decoration: const InputDecoration(labelText: 'Event Name*'),
                autofocus: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: timeController,
                decoration: const InputDecoration(
                  labelText: 'Time (e.g. 10:00 AM - 11:00 AM)*',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: locationController,
                decoration: const InputDecoration(
                  labelText: 'Location (Optional)',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (titleController.text.isNotEmpty &&
                    timeController.text.isNotEmpty) {
                  final newEvent = LectureEvent(
                    title: titleController.text.trim(),
                    time: timeController.text.trim(),
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
              child: const Text('Save'),
            ),
          ],
        );
      },
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
                  const Text(
                    'No events on this day!',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
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
