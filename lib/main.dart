import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:time_mark/models/time_entry.dart';
import 'package:time_mark/screens/home_screen.dart';
import 'package:time_mark/services/time_entry_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive
  await Hive.initFlutter();
  
  // Register Adapter
  Hive.registerAdapter(TimeEntryAdapter());
  
  // Open Box
  await Hive.openBox<TimeEntry>(TimeEntryService.boxName);
  
  // Initialize Date Formatting
  await initializeDateFormatting();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Mark',   //name of the app
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Supports dark mode automatically
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.light),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple, brightness: Brightness.dark),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
