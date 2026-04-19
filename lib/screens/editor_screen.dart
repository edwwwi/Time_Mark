import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:time_mark/models/time_entry.dart';
import 'package:time_mark/services/time_entry_service.dart';

class EditorScreen extends StatefulWidget {
  final DateTime initialDate;
  final TimeEntry? entry;
//////
  const EditorScreen({
    super.key,
    required this.initialDate,
    this.entry,
  });

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late TimeOfDay _selectedTime;
  final TextEditingController _textController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.entry != null) {
      // Edit mode
      _textController.text = widget.entry!.text;
      // Parse time string "HH:mm" to TimeOfDay
      final parts = widget.entry!.time.split(':');
      _selectedTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    } else {
      // Add mode
      // Default to current time if on today, otherwise 09:00 or similar? 
      // Requirement says "Time picker (manual + current time option)"
      // Defaulting to current time is easiest.
      _selectedTime = TimeOfDay.now();
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      final timeString = '${_selectedTime.hour.toString().padLeft(2, '0')}:${_selectedTime.minute.toString().padLeft(2, '0')}';
      
      if (widget.entry != null) {
        // Update
        final updatedEntry = TimeEntry(
          id: widget.entry!.id,
          date: widget.entry!.date, // Keep original date or update? Usually keep date unless moved.
          time: timeString,
          text: _textController.text.trim(),
        );
        await TimeEntryService.updateEntry(updatedEntry);
      } else {
        // Create
        final newEntry = TimeEntry(
          date: widget.initialDate,
          time: timeString,
          text: _textController.text.trim(),
        );
        await TimeEntryService.addEntry(newEntry);
      }

      if (mounted) {
        Navigator.pop(context, true); // Return true to trigger refresh
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMM d, yyyy');
    
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.entry != null ? 'Edit Event' : 'New Event'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date Display (Non-editable for now as per requirements focus on Time + One-line text)
              Text(
                dateFormat.format(widget.entry?.date ?? widget.initialDate),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // Time Picker Section
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  decoration: BoxDecoration(
                    border: Border.all(color: Theme.of(context).colorScheme.outline),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.access_time, size: 32, color: Theme.of(context).colorScheme.primary),
                      const SizedBox(width: 16),
                      Text(
                        _selectedTime.format(context),
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Text Input
              TextFormField(
                controller: _textController,
                decoration: const InputDecoration(
                  labelText: 'Event Description',
                  hintText: 'e.g., Got bus',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
                maxLines: 1,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
