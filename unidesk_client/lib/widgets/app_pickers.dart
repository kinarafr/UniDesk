import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../core/app_theme.dart';

class AppPickers {
  static Future<void> showTimePicker({
    required BuildContext context,
    required TextEditingController controller,
    TimeOfDay? initialTime,
  }) async {
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;

    DateTime initialDateTime = DateTime.now();
    if (initialTime != null) {
      initialDateTime = DateTime(
        2026,
        1,
        1,
        initialTime.hour,
        initialTime.minute,
      );
    }

    DateTime selectedDateTime = initialDateTime;

    await AppTheme.showAppModalBottomSheet(
      context: context,
      builder: Container(
        padding: const EdgeInsets.only(top: 6.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isDark ? Colors.white12 : Colors.black12,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color: isDark ? Colors.redAccent : Colors.red,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  Text(
                    'Select Time',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      controller.text = DateFormat(
                        'hh:mm a',
                      ).format(selectedDateTime);
                      Navigator.pop(context);
                    },
                    child: Text(
                      'Done',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF90CAF9) : Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 250,
              child: CupertinoTheme(
                data: CupertinoThemeData(
                  brightness: brightness,
                  textTheme: CupertinoTextThemeData(
                    dateTimePickerTextStyle: TextStyle(
                      color: isDark ? Colors.white : Colors.black,
                      fontSize: 22,
                    ),
                  ),
                ),
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initialDateTime,
                  onDateTimeChanged: (DateTime newDateTime) {
                    selectedDateTime = newDateTime;
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  static Future<void> showAppDatePicker({
    required BuildContext context,
    required TextEditingController controller,
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    final Brightness brightness = Theme.of(context).brightness;
    final bool isDark = brightness == Brightness.dark;
    DateTime selectedDate = initialDate ?? DateTime.now();

    await AppTheme.showAppModalBottomSheet(
      context: context,
      builder: StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Cancel',
                        style: TextStyle(
                          color: isDark ? Colors.redAccent : Colors.red,
                        ),
                      ),
                    ),
                    const Text(
                      'Select Date',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        controller.text = DateFormat(
                          'yyyy-MM-dd',
                        ).format(selectedDate);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Done',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? const Color(0xFF90CAF9)
                              : Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
                Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: Theme.of(context).colorScheme.copyWith(
                      primary: isDark ? const Color(0xFF90CAF9) : Colors.black,
                      onPrimary: isDark ? Colors.black : Colors.white,
                      surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      onSurface: isDark ? Colors.white : Colors.black,
                    ),
                    dividerColor: Colors.transparent,
                  ),
                  child: CalendarDatePicker(
                    initialDate: selectedDate,
                    firstDate:
                        firstDate ??
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate:
                        lastDate ??
                        DateTime.now().add(const Duration(days: 365 * 5)),
                    onDateChanged: (date) {
                      setModalState(() {
                        selectedDate = date;
                      });
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
