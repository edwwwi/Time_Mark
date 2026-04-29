import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:time_mark/models/time_entry.dart';
import 'package:time_mark/screens/editor_screen.dart';
import 'package:time_mark/services/time_entry_service.dart';
////////////////////////////////////
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
/////////////////////////
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _currentTime = DateTime.now();
  late Timer _timer;
  CalendarFormat _calendarFormat = CalendarFormat.week;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  List<TimeEntry> _currentEntries = [];

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    // Update time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
    _loadEntries();
  }

  void _loadEntries() {
    if (_selectedDay != null) {
      setState(() {
        _currentEntries = TimeEntryService.getEntriesForDate(_selectedDay!);
      });
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    if (!isSameDay(_selectedDay, selectedDay)) {
      setState(() {
        _selectedDay = selectedDay;
        _focusedDay = focusedDay;
      });
      _loadEntries();
    }
  }

  Future<void> _navigateToAddEdit({TimeEntry? entry}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditorScreen(
          initialDate: _selectedDay ?? DateTime.now(),
          entry: entry,
        ),
      ),
    );

    if (result == true) {
      _loadEntries();
    }
  }

  Future<void> _deleteEntry(String id) async {
    await TimeEntryService.deleteEntry(id);
    _loadEntries();
  }

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a'); // 12-hour format
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header Section
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    timeFormat.format(_currentTime),
                    style: Theme.of(context).textTheme.displayLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dateFormat.format(_currentTime),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Calendar Section
            TableCalendar(
              firstDay: DateTime.utc(2020, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: _focusedDay,
              calendarFormat: _calendarFormat,
              selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
              onDaySelected: _onDaySelected,
              onFormatChanged: (format) {
                if (_calendarFormat != format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                }
              },
              onPageChanged: (focusedDay) {
                _focusedDay = focusedDay;
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                todayDecoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                todayTextStyle: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),

            const Divider(),

            // Entries List
            Expanded(
              child: _currentEntries.isEmpty
                  ? Center(
                      child: Text(
                        'No events for this day',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _currentEntries.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemBuilder: (context, index) {
                        final entry = _currentEntries[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          elevation: 0,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: InkWell(
                            onTap: () => _navigateToAddEdit(entry: entry),
                            borderRadius: BorderRadius.circular(12),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        TimeOfDay(
                                          hour: int.parse(entry.time.split(':')[0]),
                                          minute: int.parse(entry.time.split(':')[1]),
                                        ).format(context),
                                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                              fontWeight: FontWeight.bold,
                                              color: Theme.of(context).colorScheme.primary,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Text(
                                      entry.text,
                                      style: Theme.of(context).textTheme.bodyLarge,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    onPressed: () => _deleteEntry(entry.id),
                                    color: Theme.of(context).colorScheme.error,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToAddEdit(),
        label: const Text('Add Event'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
