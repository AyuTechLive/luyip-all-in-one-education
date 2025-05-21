import 'package:flutter/material.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/payment_content.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

// Import your PaymentsContent widget
// Update path as needed

class PaymentsScreen extends StatelessWidget {
  const PaymentsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Payment Transactions',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: ColorManager.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: const PaymentsContent(),
    );
  }
}
