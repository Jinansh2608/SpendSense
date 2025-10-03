import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:spendsense/constants/colors/colors.dart';

class CustomCalendar extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const CustomCalendar({super.key, required this.transactions});

  @override
  _CustomCalendarState createState() => _CustomCalendarState();
}

class _CustomCalendarState extends State<CustomCalendar> {
  final ValueNotifier<DateTime> _focusedDay = ValueNotifier(DateTime.now());
  final ValueNotifier<CalendarFormat> _calendarFormat =
      ValueNotifier(CalendarFormat.week);

  Map<DateTime, double> _spendingPerDay = {};

  @override
  void initState() {
    super.initState();
    _prepareSpendingData();
  }

  void _prepareSpendingData() {
    final Map<DateTime, double> spendingMap = {};
    for (var transaction in widget.transactions) {
      if (transaction['txn_type'] == 'Debit') {
        final date = DateTime.parse(transaction['date']).toLocal();
        final day = DateTime.utc(date.year, date.month, date.day);
        spendingMap[day] = (spendingMap[day] ?? 0) + (transaction['amount'] as num).toDouble();
      }
    }
    setState(() {
      _spendingPerDay = spendingMap;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<CalendarFormat>(
      valueListenable: _calendarFormat,
      builder: (context, format, _) {
        return TableCalendar(
          focusedDay: _focusedDay.value,
          firstDay: DateTime.utc(2010, 10, 16),
          lastDay: DateTime.utc(2030, 3, 14),
          calendarFormat: format,
          onFormatChanged: (format) {
            _calendarFormat.value = format;
          },
          selectedDayPredicate: (day) {
            return isSameDay(_focusedDay.value, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            _focusedDay.value = focusedDay;
          },
          headerStyle: HeaderStyle(
            formatButtonVisible: true,
            titleCentered: true,
            formatButtonShowsNext: false,
            formatButtonDecoration: BoxDecoration(
              color: Ycolor.primarycolor,
              borderRadius: BorderRadius.circular(12.0),
            ),
            formatButtonTextStyle: const TextStyle(
              color: Colors.white,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              final spending = _spendingPerDay[DateTime.utc(date.year, date.month, date.day)];
              if (spending != null && spending > 0) {
                return Positioned(
                  bottom: 1,
                  child: Container(
                    decoration: BoxDecoration(
                      color: _getColorForSpending(spending),
                      shape: BoxShape.circle,
                    ),
                    width: 7,
                    height: 7,
                  ),
                );
              }
              return null;
            },
          ),
          calendarStyle: CalendarStyle(
            todayDecoration: BoxDecoration(
              color: Ycolor.primarycolor.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: Ycolor.primarycolor,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }

  Color _getColorForSpending(double spending) {
    if (spending > 1000) {
      return Colors.red;
    } else if (spending > 500) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }
}
