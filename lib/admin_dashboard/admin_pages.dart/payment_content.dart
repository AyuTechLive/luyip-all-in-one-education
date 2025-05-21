import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:intl/intl.dart';

class PaymentsContent extends StatefulWidget {
  const PaymentsContent({Key? key}) : super(key: key);

  @override
  State<PaymentsContent> createState() => _PaymentsContentState();
}

class _PaymentsContentState extends State<PaymentsContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = true;
  List<Map<String, dynamic>> _transactions = [];
  String _selectedFilter = 'all';

  // Summary statistics
  double _totalRevenue = 0.0;
  double _courseRevenue = 0.0;
  double _membershipRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Query all transactions, ordered by most recent first
      final QuerySnapshot snapshot = await _firestore
          .collection('Transactions')
          .orderBy('timestamp', descending: true)
          .get();

      List<Map<String, dynamic>> transactions = [];
      double totalRevenue = 0.0;
      double courseRevenue = 0.0;
      double membershipRevenue = 0.0;

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Add formatted data to list
        transactions.add({
          'id': doc.id,
          'transactionId': data['transactionId'] ?? 'Unknown',
          'userId': data['userId'] ?? '',
          'userEmail': data['userEmail'] ?? 'Unknown',
          'amount': data['amount'] is double
              ? data['amount']
              : double.tryParse(data['amount'].toString()) ?? 0.0,
          'currency': data['currency'] ?? 'INR',
          'type': data['type'] ?? 'other',
          'timestamp': data['timestamp'] ?? Timestamp.now(),
          'status': data['status'] ?? 'completed',
          // Type-specific data
          'courseName': data['courseName'],
          'membershipId': data['membershipId'],
          'startDate': data['startDate'],
          'expiryDate': data['expiryDate'],
        });

        // Calculate revenue totals
        double amount = data['amount'] is double
            ? data['amount']
            : double.tryParse(data['amount'].toString()) ?? 0.0;

        totalRevenue += amount;

        // Count by type
        String type = data['type'] ?? 'other';
        if (type == 'course') {
          courseRevenue += amount;
        } else if (type == 'membership') {
          membershipRevenue += amount;
        }
      }

      setState(() {
        _transactions = transactions;
        _totalRevenue = totalRevenue;
        _courseRevenue = courseRevenue;
        _membershipRevenue = membershipRevenue;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transactions: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> _getFilteredTransactions() {
    if (_selectedFilter == 'all') {
      return _transactions;
    } else {
      return _transactions
          .where((tx) => tx['type'] == _selectedFilter)
          .toList();
    }
  }

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'N/A';

    final DateTime dateTime = timestamp.toDate();
    return DateFormat('dd MMM yyyy, h:mm a').format(dateTime);
  }

  String _formatCurrency(double amount) {
    final NumberFormat formatter = NumberFormat.currency(
      symbol: '₹',
      locale: 'en_IN',
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'course':
        return ColorManager.primary;
      case 'membership':
        return ColorManager.success;
      default:
        return ColorManager.info;
    }
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'course':
        return Icons.school_outlined;
      case 'membership':
        return Icons.card_membership;
      default:
        return Icons.payments_outlined;
    }
  }

  String _getDisplayNameForType(String type) {
    switch (type) {
      case 'course':
        return 'Course Enrollment';
      case 'membership':
        return 'Membership Purchase';
      default:
        return 'Payment';
    }
  }

  @override
  Widget build(BuildContext context) {
    // Wrap everything in a Material widget to provide the Material design context
    return Material(
        color: ColorManager.background,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Payment Transactions',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'View and manage all payment transactions',
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorManager.textMedium,
                        ),
                      ),
                    ],
                  ),
                  ElevatedButton.icon(
                    onPressed: _loadTransactions,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Revenue summary cards
              Row(
                children: [
                  // Total Revenue
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Total Revenue',
                      amount: _totalRevenue,
                      icon: Icons.monetization_on_outlined,
                      color: ColorManager.primary,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Course Revenue
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Course Revenue',
                      amount: _courseRevenue,
                      icon: Icons.school_outlined,
                      color: ColorManager.secondary,
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Membership Revenue
                  Expanded(
                    child: _buildSummaryCard(
                      title: 'Membership Revenue',
                      amount: _membershipRevenue,
                      icon: Icons.card_membership,
                      color: ColorManager.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Filter controls
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Text(
                      'Filter by:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                    const SizedBox(width: 16),

                    _buildFilterChip('All Transactions', 'all'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Course Enrollments', 'course'),
                    const SizedBox(width: 8),
                    _buildFilterChip('Memberships', 'membership'),

                    const Spacer(),

                    // Search could be added here
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Transactions table
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: ColorManager.primary,
                        ),
                      )
                    : _transactions.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.payment_outlined,
                                  size: 48,
                                  color: ColorManager.textLight,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No transactions found',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: ColorManager.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : _buildTransactionsTable(),
              ),
            ],
          ),
        ));
  }

  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: ColorManager.textMedium,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _formatCurrency(amount),
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final bool isSelected = _selectedFilter == value;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedFilter = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? ColorManager.primary : Colors.transparent,
          border: Border.all(
            color: isSelected ? ColorManager.primary : ColorManager.textLight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : ColorManager.textDark,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionsTable() {
    final filteredTransactions = _getFilteredTransactions();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: ColorManager.light,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Transaction ID',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'User',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Type',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Details',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Text(
                      'Amount',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      'Date',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 50), // Action column
                ],
              ),
            ),
          ),
          // Table body
          Expanded(
            child: ListView.separated(
              itemCount: filteredTransactions.length,
              separatorBuilder: (context, index) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final transaction = filteredTransactions[index];
                final Color typeColor = _getColorForType(transaction['type']);

                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  child: Row(
                    children: [
                      // Transaction ID
                      Expanded(
                        flex: 2,
                        child: Text(
                          transaction['transactionId'],
                          style: TextStyle(
                            fontWeight: FontWeight.w500,
                            color: ColorManager.textDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // User
                      Expanded(
                        flex: 2,
                        child: Text(
                          transaction['userEmail'],
                          style: TextStyle(
                            color: ColorManager.textMedium,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Type
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: typeColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Icon(
                                _getIconForType(transaction['type']),
                                size: 16,
                                color: typeColor,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _getDisplayNameForType(transaction['type']),
                              style: TextStyle(
                                color: ColorManager.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Details
                      Expanded(
                        flex: 2,
                        child: Text(
                          transaction['type'] == 'course'
                              ? transaction['courseName'] ?? 'N/A'
                              : transaction['type'] == 'membership'
                                  ? 'ID: ${transaction['membershipId'] ?? 'N/A'}'
                                  : 'N/A',
                          style: TextStyle(
                            color: ColorManager.textMedium,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                      // Amount
                      Expanded(
                        flex: 1,
                        child: Text(
                          _formatCurrency(transaction['amount']),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ColorManager.success,
                          ),
                        ),
                      ),

                      // Date
                      Expanded(
                        flex: 2,
                        child: Text(
                          _formatDate(transaction['timestamp']),
                          style: TextStyle(
                            color: ColorManager.textMedium,
                          ),
                        ),
                      ),

                      // Actions
                      SizedBox(
                        width: 50,
                        child: IconButton(
                          icon: Icon(
                            Icons.more_vert,
                            color: ColorManager.textLight,
                          ),
                          onPressed: () {
                            _showTransactionDetails(transaction);
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Table footer with pagination (could be added)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: ColorManager.light,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'Showing ${filteredTransactions.length} transactions',
                  style: TextStyle(
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

  void _showTransactionDetails(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              _getIconForType(transaction['type']),
              color: _getColorForType(transaction['type']),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Transaction Details',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          height: MediaQuery.of(context).size.height * 0.6,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Transaction ID', transaction['transactionId']),
                _buildDetailRow('User Email', transaction['userEmail']),
                _buildDetailRow(
                    'Amount', _formatCurrency(transaction['amount'])),
                _buildDetailRow(
                    'Type', _getDisplayNameForType(transaction['type'])),
                _buildDetailRow('Date', _formatDate(transaction['timestamp'])),
                _buildDetailRow('Status', transaction['status']),

                // Type-specific details
                if (transaction['type'] == 'course')
                  _buildDetailRow('Course', transaction['courseName'] ?? 'N/A'),

                if (transaction['type'] == 'membership') ...[
                  _buildDetailRow(
                      'Membership ID', transaction['membershipId'] ?? 'N/A'),
                  if (transaction['startDate'] != null)
                    _buildDetailRow(
                        'Start Date', _formatDate(transaction['startDate'])),
                  if (transaction['expiryDate'] != null)
                    _buildDetailRow(
                        'Expiry Date', _formatDate(transaction['expiryDate'])),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: ColorManager.textDark,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
