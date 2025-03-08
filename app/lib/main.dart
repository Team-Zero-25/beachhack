import 'package:flutter/material.dart';
import 'package:saferoute/register.dart';
// import 'package:saferoute/officerhome.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'login.dart';
import 'package:flutter/services.dart';
import 'call.dart';
import 'notification.dart';
import 'route_planner.dart';
import 'officerhome.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initNotifications();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<Widget> _initialScreen;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ));

    _initialScreen = getInitialScreen();
  }

  /// **Check login status and return appropriate screen**
  Future<Widget> getInitialScreen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    String userType = prefs.getString('usertype') ?? 'user';
    String name = prefs.getString('name') ?? 'Officer'; //
    String phoneNumber = prefs.getString('phone_number') ?? '0000000000';

    if (isLoggedIn) {
      return userType == 'officer' ? OfficerHome(officerName: name,officerPhone: phoneNumber,) : Home();
    } else {
      return Login();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SafeRoute',
      theme: ThemeData(
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<Widget>(
        future: _initialScreen,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: Center(child: CircularProgressIndicator()),
            );
          } else {
            return snapshot.data ?? Register();
          }
        },
      ),
    );
  }
}
