import 'package:flutter/material.dart';
import 'package:robot_compresor_video/core/services/screen_size_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text('Compresor de video'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [IconButton(icon: Icon(Icons.settings), onPressed: () {})],
      ),
      body: const Center(child: Text('Home Screen')),
      bottomNavigationBar: SizedBox(
        height: ScreenSizeService.heightPercent(context, 8),
        child: const Placeholder(),
      ),
    );
  }
}
