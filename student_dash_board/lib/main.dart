// lib/main.dart
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import 'screens/student/student_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    // For web, Firebase is initialized via index.html
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyBXzAkBGbhRuppzcZTteiE1QS6iIUHXjFQ",
        authDomain: "exam-system-d7709.firebaseapp.com",
        projectId: "exam-system-d7709",
        storageBucket: "exam-system-d7709.firebasestorage.app",
        messagingSenderId: "653290580720",
        appId: "1:653290580720:web:a675fa963cb7efaf077035",
        measurementId: "G-WFBT2L3LG8",
      ),
    );
  } else {
    // For mobile, use google-services.json / GoogleService-Info.plist
    await Firebase.initializeApp();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Quiz System',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const StudentPanel(studentId: 'student_001'),
      debugShowCheckedModeBanner: false,
    );
  }
}
