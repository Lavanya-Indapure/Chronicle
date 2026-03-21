import 'package:flutter/material.dart';

class LifeLessonsScreen extends StatelessWidget {
  const LifeLessonsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Life Lessons')),
      body: const Center(child: Text('Coming Soon: Reflect on your journey.')),
    );
  }
}

class MiscellaneousScreen extends StatelessWidget {
  const MiscellaneousScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Miscellaneous')),
      body: const Center(child: Text('Coming Soon: Other memories.')),
    );
  }
}
