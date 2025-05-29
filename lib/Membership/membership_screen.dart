import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:luyip_website_edu/student_dashboard/membership_card.dart';
import 'package:razorpay_web/razorpay_web.dart';
import 'package:intl/intl.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

import 'membership_service.dart';
// Import the unified transaction service
import 'package:luyip_website_edu/Courses/transaction_service.dart'; // Update path if needed

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({Key? key}) : super(key: key);

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  final MembershipService _membershipService = MembershipService();
  // Add transaction service
  final TransactionService _transactionService = TransactionService();
  bool _isLoading = true;
  bool _isMember = false;
  DateTime? _expiryDate;
  String? _membershipId;
  DateTime? _startDate;
  bool _isProcessingPayment = false;
  late Razorpay _razorpay;
  double _membershipFee = 1000.0;

  @override
  void initState() {
    super.initState();
    _initializeRazorpay();
    _loadMembershipStatus();
    _loadMembershipFee();
  }

  Future<void> _loadMembershipFee() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('website_general')
          .doc('dashboard')
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final websiteContent = data['websiteContent'] as Map<String, dynamic>?;

        if (websiteContent != null &&
            websiteContent.containsKey('membershipFee')) {
          setState(() {
            _membershipFee =
                (websiteContent['membershipFee'] as num?)?.toDouble() ?? 1000.0;
          });
        }
      }
    } catch (e) {
      print('Error loading membership fee: $e');
      // Keep default value of 1000.0
    }
  }

  void _initializeRazorpay() {
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  Future<void> _loadMembershipStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final membershipStatus = await _membershipService.getMembershipStatus();

      setState(() {
        _isMember = membershipStatus['isMember'] ?? false;
        _expiryDate = membershipStatus['expiryDate'];
        _membershipId = membershipStatus['membershipId'];
        _startDate = membershipStatus['startDate'];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading membership status: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _purchaseMembership() async {
    setState(() {
      _isProcessingPayment = true;
    });

    try {
      await _membershipService.purchaseMembership(
        context,
        onPaymentSuccess: _handlePaymentSuccess,
        onPaymentError: _handlePaymentError,
        onExternalWallet: _handleExternalWallet,
      );
    } catch (e) {
      setState(() {
        _isProcessingPayment = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error initiating payment: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Updated to use the new TransactionService
  void _handlePaymentSuccess(PaymentSuccessResponse response) async {
    setState(() {
      _isProcessingPayment = false;
    });

    try {
      bool success = await _transactionService.activateMembership(
        transactionId: response.paymentId!,
        amount: _membershipFee, // Use dynamic fee instead of hardcoded 1000.0
        currency: 'INR',
      );

      if (success) {
        Utils().toastMessage('Membership activated successfully!');
        await _loadMembershipStatus();
      } else {
        Utils().toastMessage('Failed to activate membership');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error activating membership: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    setState(() {
      _isProcessingPayment = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Payment failed: ${response.message}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    setState(() {
      _isProcessingPayment = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('External wallet selected: ${response.walletName}'),
        backgroundColor: Colors.blue,
      ),
    );
  }

  void _viewIDCard() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const StudentIDCardScreen(),
      ),
    );
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: ColorManager.primary),
            )
          : SingleChildScrollView(
              child: Column(
                children: [
                  // Membership Status Card
                  _buildMembershipStatusCard(),

                  // Benefits Section
                  _buildBenefitsSection(),

                  // Action Button (Join or View ID)
                  _buildActionButton(),

                  const SizedBox(height: 40),

                  // FAQ Section
                  _buildFAQSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildMembershipStatusCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _isMember ? Colors.green : ColorManager.primary,
                  _isMember ? Colors.green.shade800 : ColorManager.primaryDark,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Column(
              children: [
                Icon(
                  _isMember ? Icons.verified : Icons.card_membership,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(height: 8),
                Text(
                  _isMember ? 'Active Membership' : 'No Active Membership',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _isMember
                      ? 'You are a premium member!'
                      : 'Become a member to unlock benefits',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Membership Details
          Padding(
            padding: const EdgeInsets.all(20),
            child: _isMember
                ? Column(
                    children: [
                      _buildDetailRow(
                        'Membership ID',
                        _membershipId ?? 'N/A',
                        Icons.badge,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Start Date',
                        _startDate != null
                            ? DateFormat('dd MMM yyyy').format(_startDate!)
                            : 'N/A',
                        Icons.calendar_today,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Expiry Date',
                        _expiryDate != null
                            ? DateFormat('dd MMM yyyy').format(_expiryDate!)
                            : 'N/A',
                        Icons.event_busy,
                      ),
                      const SizedBox(height: 12),
                      _buildDetailRow(
                        'Status',
                        'Active',
                        Icons.verified,
                        statusColor: Colors.green,
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Text(
                        'Annual Membership Fee',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '₹',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.textDark,
                            ),
                          ),
                          Text(
                            _membershipFee.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.textDark,
                            ),
                          ),
                          Text(
                            '/year',
                            style: TextStyle(
                              fontSize: 16,
                              color: ColorManager.textMedium,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Unlock premium benefits with our annual membership',
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorManager.textMedium,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon,
      {Color? statusColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorManager.light,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: ColorManager.primary,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: ColorManager.textMedium,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: statusColor ?? ColorManager.textDark,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBenefitsSection() {
    final benefits = [
      {
        'icon': Icons.school,
        'title': 'Exclusive Discounts',
        'description': 'Get discounts on all course fees',
      },
      {
        'icon': Icons.card_membership,
        'title': 'ID Card',
        'description': 'Access to official student ID card',
      },
      {
        'icon': Icons.event_available,
        'title': 'Priority Access',
        'description': 'Early access to new courses and events',
      },
      {
        'icon': Icons.support_agent,
        'title': 'Premium Support',
        'description': 'Get priority customer support',
      },
    ];

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Membership Benefits',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 20),
          ...benefits.map((benefit) => _buildBenefitItem(
                benefit['icon'] as IconData,
                benefit['title'] as String,
                benefit['description'] as String,
              )),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: ColorManager.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: ColorManager.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorManager.textMedium,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: _isProcessingPayment
              ? null
              : _isMember
                  ? _viewIDCard
                  : _purchaseMembership,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isMember ? Colors.green : ColorManager.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: _isProcessingPayment
              ? const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Processing Payment...',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isMember ? Icons.credit_card : Icons.payment,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _isMember
                          ? 'View ID Card'
                          : 'Join Membership (₹${_membershipFee.toStringAsFixed(0)}/year)',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildFAQSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Frequently Asked Questions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 20),
          _buildFAQItem(
            'How long is the membership valid?',
            'Membership is valid for one year (365 days) from the date of purchase.',
          ),
          _buildFAQItem(
            'How much discount will I get on courses?',
            'Discount percentages vary by course. Each course has a specific membership discount that will be applied automatically.',
          ),
          _buildFAQItem(
            'Can I cancel my membership?',
            'Memberships are non-refundable, but will automatically expire after one year.',
          ),
          _buildFAQItem(
            'What happens after my membership expires?',
            'Once expired, you\'ll need to renew your membership to continue enjoying the benefits.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: ColorManager.textDark,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              color: ColorManager.textMedium,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
