import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // <--- thêm dòng này
import 'screens/student/student_panel.dart';
import 'screens/teacher/teacher_panel.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Thêm options cho Web
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Student Quiz App',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: const TeacherPanel(),
      debugShowCheckedModeBanner: false,
    );
  }
}
