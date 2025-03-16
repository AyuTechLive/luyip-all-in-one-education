import 'package:flutter/material.dart';

class FranchiseDashboard extends StatelessWidget {
  const FranchiseDashboard({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: const Color(0xFF5E4DCD),
      ),
      body: const Center(child: Text('Welcome to the Student Dashboard')),
    );
  }
}
