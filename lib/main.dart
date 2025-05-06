import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:markpro_plus/screens/splash_screen.dart';
import 'package:markpro_plus/screens/login_screen.dart';
import 'package:markpro_plus/screens/dashboard_screen.dart';
import 'package:markpro_plus/screens/student_management_screen.dart';
import 'package:markpro_plus/screens/subject_management_screen.dart';
import 'package:markpro_plus/screens/lab_sessions_screen.dart';
import 'package:markpro_plus/screens/create_lab_session_screen.dart';
import 'package:markpro_plus/screens/lab_marks_entry_screen.dart';
import 'package:markpro_plus/screens/list_students_screen.dart';
import 'package:markpro_plus/screens/mid_sessions_screen.dart';
import 'package:markpro_plus/screens/create_mid_session_screen.dart';
import 'package:markpro_plus/screens/assignment_sessions_screen.dart';
import 'package:markpro_plus/screens/create_assignment_session_screen.dart';
import 'package:markpro_plus/screens/assignment_session_details_screen.dart';
import 'package:markpro_plus/screens/seminar_sessions_screen.dart';
import 'package:markpro_plus/screens/create_seminar_session_screen.dart';
import 'package:markpro_plus/screens/seminar_session_details_screen.dart';
import 'package:markpro_plus/services/firebase_config.dart';
import 'package:markpro_plus/services/auth_service.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: '.env');

  // Initialize Firebase
  await initializeFirebase();

  // Create test user
  final authService = AuthService();
  try {
    await authService.createTestUser();
    print('Test user created successfully!');
  } catch (e) {
    print('Error creating test user: $e');
  }
  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Initialize Firebase when app starts
  try {
    await initializeFirebase();
  } catch (e) {
    print('Error in main: $e');
  }
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Stream provider for auth state changes
        StreamProvider<User?>.value(
          value: AuthService().authStateChanges,
          initialData: null,
        ),
      ],
      child: MaterialApp(
        title: 'MarkPro+ Sessions',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1E3A8A), // Dark blue
            primary: const Color(0xFF1E3A8A),
            secondary: const Color(0xFF10B981), // Green
          ),
          useMaterial3: true,
          fontFamily: 'Roboto',
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.grey.shade50,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1E3A8A), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
        initialRoute: '/',
        routes: {
          '/': (context) => const SplashScreen(),
          '/login': (context) => const LoginScreen(),
          '/dashboard': (context) => const DashboardScreen(),
          '/student-management': (context) => const StudentManagementScreen(),
          '/list-students': (context) => const ListStudentsScreen(),
          '/subject-management': (context) => const SubjectManagementScreen(),
          '/lab-sessions': (context) => const LabSessionsScreen(),
          '/create-lab-session': (context) => const CreateLabSessionScreen(),
          '/lab-marks-entry': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as dynamic;
            return LabMarksEntryScreen(labSession: args);
          },
          // Tab-specific routes for lab marks entry
          '/lab-marks-entry/experiments': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as dynamic;
            return LabMarksEntryScreen(labSession: args, initialTabIndex: 0);
          },
          '/lab-marks-entry/internal': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as dynamic;
            return LabMarksEntryScreen(labSession: args, initialTabIndex: 1);
          },
          '/lab-marks-entry/results': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as dynamic;
            return LabMarksEntryScreen(labSession: args, initialTabIndex: 2);
          },
          '/lab-marks-entry/final': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as dynamic;
            return LabMarksEntryScreen(labSession: args, initialTabIndex: 3);
          },
          '/mid-sessions': (context) => const MidSessionsScreen(),
          '/create-mid-session': (context) => const CreateMidSessionScreen(),
          '/assignment-sessions': (context) => const AssignmentSessionsScreen(),
          '/create-assignment-session': (context) => const CreateAssignmentSessionScreen(),
          '/assignment-session-details': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as String;
            return AssignmentSessionDetailsScreen(sessionId: args);
          },
          '/seminar-sessions': (context) => const SeminarSessionsScreen(),
          '/create-seminar-session': (context) => const CreateSeminarSessionScreen(),
          '/seminar-session-details': (context) {
            final args = ModalRoute.of(context)!.settings.arguments as dynamic;
            return SeminarSessionDetailsScreen(seminarSession: args);
          },
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Initially show the splash screen
    return const SplashScreen();
  }
}
