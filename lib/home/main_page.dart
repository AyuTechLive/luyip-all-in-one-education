import 'package:flutter/material.dart';
import 'package:luyip_website_edu/admin_dashboard/sidebar.dart';

import 'package:luyip_website_edu/home/admin_dashboard.dart';
import 'package:luyip_website_edu/home/franchise_dashboard.dart';
import 'package:luyip_website_edu/home/student_dashboard.dart';
import 'package:luyip_website_edu/home/teacher_dashboard.dart';
import 'package:luyip_website_edu/student_dashboard/student_dashboard.dart';

class MainPage extends StatelessWidget {
  final String role;

  const MainPage({Key? key, required this.role}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Redirect based on role
    switch (role) {
      case 'student':
        return const StudentDashboardContainer();
      case 'teacher':
        return const TeacherDashboard();
      case 'franchise':
        return const FranchiseDashboard();
      case 'admin':
        return const AdminDashboardContainer();
      default:
        return const StudentDashboardContainer(); // Default fallback
    }
  }
}
