import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screen/auth_screen.dart';
import 'theme_provider.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: TaskManagerApp(),
    ),
  );
}

class TaskManagerApp extends StatefulWidget {
  const TaskManagerApp({super.key});

  @override
  _TaskManagerAppState createState() => _TaskManagerAppState();
}

class _TaskManagerAppState extends State<TaskManagerApp> {
  @override
  void initState() {
    super.initState();
    _setupFCM();
  }

  void _setupFCM() async {
    FirebaseMessaging messaging = FirebaseMessaging.instance;

    NotificationSettings settings = await messaging.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
    }

    String? _ = await messaging.getToken();

    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Task Manager',
          theme: ThemeData.light(),
          darkTheme: ThemeData.dark(),
          themeMode: themeProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          home: AuthScreen(),
        );
      },
    );
  }
}
