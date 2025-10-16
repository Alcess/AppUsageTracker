import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App Usage Tracker',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: DefaultTabController(length: 3, child: Scaffold(
        appBar: AppBar(
          title: const Text('App Usage Tracker'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.calendar_today)),
              Tab(icon: Icon(Icons.home_filled)),
              Tab(icon: Icon(Icons.notifications)),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            HomeScreen(),
            Icon(Icons.home_filled),
            Icon(Icons.notifications),
          ],
        ),
      )),
    );
  }
}
