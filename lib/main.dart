import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // Import dotenv
import 'package:second_brain/app.dart';
import 'package:second_brain/features/notes/presentation/providers/notes_provider.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Environment Variables (API Key)
  await dotenv.load(fileName: ".env");

  // 2. Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // 3. Run app with Riverpod
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const App(),
    ),
  );
}