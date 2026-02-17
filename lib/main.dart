import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:second_brain/app.dart';
import 'package:second_brain/features/notes/data/models/note_model.dart';
import 'package:second_brain/features/notes/presentation/providers/notes_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Load Environment Variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint("Error loading .env file: $e"); // FIXED
  }

  // 2. Initialize Hive
  await Hive.initFlutter();
  Hive.registerAdapter(NoteModelAdapter());

  // 3. Open the Box
  final noteBox = await Hive.openBox<NoteModel>('notes');

  // 4. Run the App
  runApp(
    ProviderScope(
      overrides: [
        notesBoxProvider.overrideWithValue(noteBox),
      ],
      child: const App(),
    ),
  );
}