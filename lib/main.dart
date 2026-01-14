import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:google_fonts/google_fonts.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
          apiKey: "AIzaSyDCxMT_ouWkmcSNw015ANi-MwvsDryHqlE",
          authDomain: "allmahgame.firebaseapp.com",
          projectId: "allmahgame",
          storageBucket: "allmahgame.firebasestorage.app",
          messagingSenderId: "564436165702",
          appId: "1:564436165702:web:e5835d1939d8122cab9647",
          measurementId: "G-STJQ93CRJL"),
    );
  } catch (e) {
    debugPrint('Firebase initialization error: $e');
  }
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  final _appRouter = AppRouter();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'SeenJeem Admin',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        textTheme: GoogleFonts.interTextTheme(),
        useMaterial3: true,
      ),
      routerConfig: _appRouter.config(),
    );
  }
}
