import 'package:ads/home_screen.dart';
import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      key: navigatorKey,
      home: const HomeScreen(),
      builder: (context, child) => Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (context) => child!,
          ),
        ],
      ),
    );
  }
}
