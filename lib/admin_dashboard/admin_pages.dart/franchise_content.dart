import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/add_franchise.dart';
import 'package:luyip_website_edu/Courses/transaction_service.dart';

class FranchisesContent extends StatefulWidget {
  const FranchisesContent({Key? key}) : super(key: key);

  @override
  State<FranchisesContent> createState() => _FranchisesContentState();
}

class _FranchisesContentState extends State<FranchisesContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TransactionService _transactionService = TransactionService();

  String _searchQuery = '';
  String _selectedStatus = 'All';
  String _selectedCategory = 'All';

  final List<String> _statusFilters = ['All', 'Active', 'Inactive', 'Pending'];
  final List<String> _categoryFilters = [
    'All',
    'Standard',
    'Premium',
    'Gold',
    'Platinum'
  ];

  // Cache for franchise revenue data
  Map<String, Map<String, dynamic>> _franchiseRevenueCache = {};
  bool _isLoadingRevenue = false;
  Set<String> _loadingFranchises =
      {}; // Track which franchises are being loaded
  Set<String> _processedFranchisesList =
      {}; // Track processed franchise lists to prevent duplicate loading

  @override
  void initState() {
    super.initState();
  }

  void _refreshPage() {
    setState(() {
      _franchiseRevenueCache.clear(); // Clear cache on refresh
      _loadingFranchises.clear(); // Clear loading set
      _processedFranchisesList.clear(); // Clear processed lists
    });
  }

  // Fetch revenue data for a specific franchise
  Future<Map<String, dynamic>> _getFranchiseRevenueData(
      String franchiseEmail) async {
    // Check cache first
    if (_franchiseRevenueCache.containsKey(franchiseEmail)) {
      return _franchiseRevenueCache[franchiseEmail]!;
    }

    // Check if already loading
    if (_loadingFranchises.contains(franchiseEmail)) {
      // Wait a bit and check cache again
      await Future.delayed(const Duration(milliseconds: 100));
      if (_franchiseRevenueCache.containsKey(franchiseEmail)) {
        return _franchiseRevenueCache[franchiseEmail]!;
      }
    }

    // Mark as loading
    _loadingFranchises.add(franchiseEmail);

    try {
      // Get commission summary from TransactionService
      Map<String, dynamic> commissionSummary = await _transactionService
          .getFranchiseCommissionSummaryByEmail(franchiseEmail);

      // Get all commissions to calculate monthly revenue
      List<Map<String, dynamic>> allCommissions = await _transactionService
          .getFranchiseCommissionsByEmail(franchiseEmail);

      // Calculate current month revenue
      DateTime now = DateTime.now();
      String currentMonthKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';

      double currentMonthRevenue = 0.0;
      int totalStudents = 0;

      for (var commission in allCommissions) {
        // Count students (only membership commissions count as students)
        if (commission['type'] == 'membership') {
          totalStudents++;
        }

        // Calculate current month revenue
        if (commission['timestamp'] != null) {
          try {
            DateTime commissionDate =
                (commission['timestamp'] as Timestamp).toDate();
            String commissionMonthKey =
                '${commissionDate.year}-${commissionDate.month.toString().padLeft(2, '0')}';

            if (commissionMonthKey == currentMonthKey) {
              currentMonthRevenue +=
                  (commission['commissionAmount'] as num?)?.toDouble() ?? 0.0;
            }
          } catch (e) {
            print('Error processing commission timestamp: $e');
            // Skip this commission if timestamp is invalid
          }
        }
      }

      Map<String, dynamic> revenueData = {
        'totalRevenue': commissionSummary['totalCommission'] ?? 0.0,
        'monthlyRevenue': currentMonthRevenue,
        'totalStudents': totalStudents,
        'totalTransactions': commissionSummary['totalTransactions'] ?? 0,
        'membershipCommissions':
            commissionSummary['membershipCommissions'] ?? 0,
        'courseCommissions': commissionSummary['courseCommissions'] ?? 0,
      };

      // Cache the result
      _franchiseRevenueCache[franchiseEmail] = revenueData;

      return revenueData;
    } catch (e) {
      print('Error fetching revenue for $franchiseEmail: $e');
      // Return default values on error
      Map<String, dynamic> defaultData = {
        'totalRevenue': 0.0,
        'monthlyRevenue': 0.0,
        'totalStudents': 0,
        'totalTransactions': 0,
        'membershipCommissions': 0,
        'courseCommissions': 0,
      };

      _franchiseRevenueCache[franchiseEmail] = defaultData;
      return defaultData;
    } finally {
      // Remove from loading set
      _loadingFranchises.remove(franchiseEmail);
    }
  }

  // Bulk load revenue data for all visible franchises
  Future<void> _loadRevenueDataForFranchises(
      List<String> franchiseEmails) async {
    if (_isLoadingRevenue) return;

    setState(() {
      _isLoadingRevenue = true;
    });

    try {
      // Load revenue data for franchises not in cache and not currently loading
      List<Future<void>> futures = [];

      for (String email in franchiseEmails) {
        if (!_franchiseRevenueCache.containsKey(email) &&
            !_loadingFranchises.contains(email) &&
            email.isNotEmpty) {
          futures.add(_getFranchiseRevenueData(email).then((_) {}));
        }
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }

      if (mounted) {
        setState(() {
          _isLoadingRevenue = false;
        });
      }
    } catch (e) {
      print('Error loading bulk revenue data: $e');
      if (mounted) {
        setState(() {
          _isLoadingRevenue = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Franchise Management',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Manage your franchise partners and their performance',
                      style: TextStyle(
                        fontSize: 16,
                        color: ColorManager.textMedium,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AddFranchisePage(
                          onFranchiseAdded: _refreshPage,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Franchise'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorManager.primary,
                    foregroundColor: Colors.white,
                    elevation: 2,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Filters and search section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      onChanged: (value) =>
                          setState(() => _searchQuery = value),
                      decoration: InputDecoration(
                        hintText: 'Search franchises...',
                        prefixIcon:
                            Icon(Icons.search, color: ColorManager.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: Colors.grey.shade300),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(color: ColorManager.primary),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFilterDropdown(
                      'Status',
                      _selectedStatus,
                      _statusFilters,
                      (value) => setState(() => _selectedStatus = value!),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildFilterDropdown(
                      'Category',
                      _selectedCategory,
                      _categoryFilters,
                      (value) => setState(() => _selectedCategory = value!),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Franchises list container
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('Users')
                    .doc('franchise')
                    .collection('accounts')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Container(
                      height: 400,
                      child: const Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (snapshot.hasError) {
                    return Container(
                      height: 400,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.error_outline,
                                color: Colors.red, size: 60),
                            const SizedBox(height: 16),
                            Text(
                              'Error loading franchises',
                              style: TextStyle(color: Colors.red, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Container(
                      height: 400,
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.store_outlined,
                              color: ColorManager.textLight,
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No franchises found',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: ColorManager.textMedium,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add your first franchise to get started',
                              style: TextStyle(
                                fontSize: 16,
                                color: ColorManager.textLight,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AddFranchisePage(
                                      onFranchiseAdded: _refreshPage,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add First Franchise'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorManager.primary,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Filter franchises based on search and filters
                  List<QueryDocumentSnapshot> filteredFranchises =
                      snapshot.data!.docs.where((doc) {
                    Map<String, dynamic> data =
                        doc.data() as Map<String, dynamic>;

                    // Search filter
                    if (_searchQuery.isNotEmpty) {
                      String searchLower = _searchQuery.toLowerCase();
                      bool matchesSearch = (data['Name']
                                  ?.toString()
                                  .toLowerCase()
                                  .contains(searchLower) ??
                              false) ||
                          (data['FranchiseName']
                                  ?.toString()
                                  .toLowerCase()
                                  .contains(searchLower) ??
                              false) ||
                          (data['Email']
                                  ?.toString()
                                  .toLowerCase()
                                  .contains(searchLower) ??
                              false) ||
                          (data['City']
                                  ?.toString()
                                  .toLowerCase()
                                  .contains(searchLower) ??
                              false);
                      if (!matchesSearch) return false;
                    }

                    // Status filter
                    if (_selectedStatus != 'All' &&
                        data['Status'] != _selectedStatus) {
                      return false;
                    }

                    // Category filter
                    if (_selectedCategory != 'All' &&
                        data['Category'] != _selectedCategory) {
                      return false;
                    }

                    return true;
                  }).toList();

                  // Load revenue data for visible franchises
                  List<String> franchiseEmails = filteredFranchises
                      .map((doc) {
                        Map<String, dynamic> data =
                            doc.data() as Map<String, dynamic>;
                        return data['Email'] as String? ?? '';
                      })
                      .where((email) => email.isNotEmpty)
                      .toList();

                  // Create a unique key for this franchise list
                  String franchiseListKey = franchiseEmails.join(',');

                  // Load revenue data only if this list hasn't been processed
                  if (!_processedFranchisesList.contains(franchiseListKey)) {
                    _processedFranchisesList.add(franchiseListKey);
                    // Use Future.microtask instead of addPostFrameCallback to prevent flickering
                    Future.microtask(
                        () => _loadRevenueDataForFranchises(franchiseEmails));
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: ColorManager.primary.withOpacity(0.05),
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(12),
                            topRight: Radius.circular(12),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.store, color: ColorManager.primary),
                            const SizedBox(width: 12),
                            Text(
                              'Franchises (${filteredFranchises.length})',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ColorManager.textDark,
                              ),
                            ),
                            if (_isLoadingRevenue) ...[
                              const SizedBox(width: 16),
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Loading revenue data...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: ColorManager.textMedium,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Franchises list - Remove ListView and use Column instead
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            for (int index = 0;
                                index < filteredFranchises.length;
                                index++) ...[
                              _buildFranchiseCard(filteredFranchises[index]
                                  .data() as Map<String, dynamic>),
                              if (index < filteredFranchises.length - 1)
                                const SizedBox(
                                    height: 24), // Space between cards
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),

            // Add some bottom padding for better UX
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String value,
    List<String> items,
    Function(String?) onChanged,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonFormField<String>(
            value: value,
            onChanged: onChanged,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildFranchiseCard(Map<String, dynamic> data) {
    String franchiseEmail = data['Email'] ?? '';
    Map<String, dynamic> revenueData = _franchiseRevenueCache[franchiseEmail] ??
        {
          'totalRevenue': 0.0,
          'monthlyRevenue': 0.0,
          'totalStudents': 0,
          'totalTransactions': 0,
          'membershipCommissions': 0,
          'courseCommissions': 0,
        };

    bool isLoadingThisRevenue =
        !_franchiseRevenueCache.containsKey(franchiseEmail) &&
            franchiseEmail.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with franchise name and status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['FranchiseName'] ?? 'Unknown Franchise',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      data['Name'] ?? 'Unknown Owner',
                      style: TextStyle(
                        fontSize: 16,
                        color: ColorManager.textMedium,
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _buildStatusChip(data['Status'] ?? 'Unknown'),
                  const SizedBox(width: 12),
                  _buildCategoryChip(data['Category'] ?? 'Standard'),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Information grid
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    _buildInfoItem(
                      'Contact Information',
                      [
                        _buildInfoRow(Icons.email_outlined, 'Email',
                            data['Email'] ?? 'N/A'),
                        _buildInfoRow(Icons.phone_outlined, 'Phone',
                            data['Phone'] ?? 'N/A'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoItem(
                      'Location',
                      [
                        _buildInfoRow(Icons.location_on_outlined, 'City',
                            data['City'] ?? 'N/A'),
                        _buildInfoRow(Icons.map_outlined, 'State',
                            data['State'] ?? 'N/A'),
                        _buildInfoRow(Icons.pin_drop_outlined, 'PIN Code',
                            data['PinCode'] ?? 'N/A'),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  children: [
                    _buildInfoItem(
                      'Business Details',
                      [
                        _buildInfoRow(Icons.percent_outlined, 'Commission',
                            '${data['CommissionPercent'] ?? 0}%'),
                        _buildInfoRow(Icons.calendar_today_outlined, 'Joined',
                            _formatDate(data['DOJ'])),
                        _buildInfoRow(
                            Icons.people_outlined,
                            'Students',
                            isLoadingThisRevenue
                                ? 'Loading...'
                                : '${revenueData['totalStudents']}'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoItem(
                      'Revenue Performance',
                      [
                        _buildInfoRow(
                            Icons.attach_money_outlined,
                            'Total Commission',
                            isLoadingThisRevenue
                                ? 'Loading...'
                                : '₹${_formatCurrency(revenueData['totalRevenue'])}'),
                        _buildInfoRow(
                            Icons.trending_up_outlined,
                            'This Month',
                            isLoadingThisRevenue
                                ? 'Loading...'
                                : '₹${_formatCurrency(revenueData['monthlyRevenue'])}'),
                        _buildInfoRow(
                            Icons.receipt_outlined,
                            'Transactions',
                            isLoadingThisRevenue
                                ? 'Loading...'
                                : '${revenueData['totalTransactions']}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Commission breakdown
          if (!isLoadingThisRevenue &&
              (revenueData['membershipCommissions'] > 0 ||
                  revenueData['courseCommissions'] > 0)) ...[
            const SizedBox(height: 20),
            _buildInfoItem(
              'Commission Breakdown',
              [
                Row(
                  children: [
                    Expanded(
                      child: _buildCommissionChip(
                        'Memberships',
                        revenueData['membershipCommissions'].toString(),
                        Colors.green,
                        Icons.card_membership,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildCommissionChip(
                        'Courses',
                        revenueData['courseCommissions'].toString(),
                        Colors.blue,
                        Icons.book,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],

          // Address section
          if (data['Address'] != null &&
              data['Address'].toString().isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildInfoItem(
              'Full Address',
              [
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        color: ColorManager.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['Address'],
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorManager.textMedium,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],

          // Notes section
          if (data['Notes'] != null && data['Notes'].toString().isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildInfoItem(
              'Notes',
              [
                Row(
                  children: [
                    Icon(Icons.note_outlined,
                        color: ColorManager.primary, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        data['Notes'],
                        style: TextStyle(
                          fontSize: 14,
                          color: ColorManager.textMedium,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _editFranchise(data),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Edit'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorManager.primary,
                    side: BorderSide(color: ColorManager.primary),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _viewFranchiseDetails(data, revenueData),
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('View Details'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorManager.info,
                    side: BorderSide(color: ColorManager.info),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _deleteFranchise(data),
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: ColorManager.error,
                    side: BorderSide(color: ColorManager.error),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCommissionChip(
      String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    switch (status.toLowerCase()) {
      case 'active':
        color = ColorManager.success;
        break;
      case 'inactive':
        color = ColorManager.error;
        break;
      case 'pending':
        color = ColorManager.warning;
        break;
      default:
        color = ColorManager.textMedium;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String category) {
    Color color;
    switch (category.toLowerCase()) {
      case 'platinum':
        color = const Color(0xFF6C5CE7);
        break;
      case 'gold':
        color = const Color(0xFFF39C12);
        break;
      case 'premium':
        color = ColorManager.primary;
        break;
      default:
        color = ColorManager.textMedium;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            category,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Icon(icon, color: ColorManager.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: $value',
              style: TextStyle(
                fontSize: 13,
                color: ColorManager.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return '0';
    double numValue =
        value is double ? value : double.tryParse(value.toString()) ?? 0;

    if (numValue >= 100000) {
      return '${(numValue / 100000).toStringAsFixed(2)}L';
    } else if (numValue >= 1000) {
      return '${(numValue / 1000).toStringAsFixed(1)}K';
    } else {
      return numValue.toStringAsFixed(0);
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';

    try {
      // Handle different date formats
      if (date is Timestamp) {
        return DateFormat('dd MMM yyyy').format(date.toDate());
      } else if (date is DateTime) {
        return DateFormat('dd MMM yyyy').format(date);
      } else if (date is String) {
        // Try to parse common date formats
        DateTime? parsedDate;

        // Try format: dd-MM-yyyy
        try {
          List<String> parts = date.split('-');
          if (parts.length == 3) {
            int day = int.parse(parts[0]);
            int month = int.parse(parts[1]);
            int year = int.parse(parts[2]);
            parsedDate = DateTime(year, month, day);
          }
        } catch (e) {
          // Try other formats if needed
          try {
            parsedDate = DateTime.parse(date);
          } catch (e2) {
            print('Error parsing date string: $date - $e2');
            return date; // Return original string if can't parse
          }
        }

        if (parsedDate != null) {
          return DateFormat('dd MMM yyyy').format(parsedDate);
        }
      }

      return date.toString();
    } catch (e) {
      print('Error formatting date: $date - $e');
      return date?.toString() ?? 'N/A';
    }
  }

  void _editFranchise(Map<String, dynamic> data) {
    // Navigate to edit franchise page (you can implement this)
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Franchise'),
        content:
            const Text('Edit franchise functionality can be implemented here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _viewFranchiseDetails(
      Map<String, dynamic> data, Map<String, dynamic> revenueData) {
    String franchiseEmail = data['Email'] ?? '';
    bool isLoadingRevenue =
        !_franchiseRevenueCache.containsKey(franchiseEmail) &&
            franchiseEmail.isNotEmpty;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 700,
          constraints: const BoxConstraints(maxHeight: 600),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                        data['FranchiseName'] ?? 'Unknown Franchise',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Owner: ${data['Name'] ?? 'Unknown'}',
                        style: TextStyle(
                          fontSize: 16,
                          color: ColorManager.textMedium,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),

              const SizedBox(height: 20),
              const Divider(),
              const SizedBox(height: 20),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Revenue Summary Cards
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Commission',
                              isLoadingRevenue
                                  ? 'Loading...'
                                  : '₹${_formatCurrency(revenueData['totalRevenue'])}',
                              Icons.account_balance_wallet,
                              Colors.green,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Students Added',
                              isLoadingRevenue
                                  ? 'Loading...'
                                  : '${revenueData['totalStudents']}',
                              Icons.people,
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryCard(
                              'Total Transactions',
                              isLoadingRevenue
                                  ? 'Loading...'
                                  : '${revenueData['totalTransactions']}',
                              Icons.receipt,
                              Colors.orange,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Business Information
                      Text(
                        'Business Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('Email', data['Email'] ?? 'N/A'),
                            _buildDetailRow('Phone', data['Phone'] ?? 'N/A'),
                            _buildDetailRow('Commission Rate',
                                '${data['CommissionPercent'] ?? 0}%'),
                            _buildDetailRow(
                                'Category', data['Category'] ?? 'Standard'),
                            _buildDetailRow(
                                'Status', data['Status'] ?? 'Unknown'),
                            _buildDetailRow(
                                'Date Joined', _formatDate(data['DOJ'])),
                          ],
                        ),
                      ),

                      const SizedBox(height: 20),

                      // Location Information
                      Text(
                        'Location Information',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                        ),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow('City', data['City'] ?? 'N/A'),
                            _buildDetailRow('State', data['State'] ?? 'N/A'),
                            _buildDetailRow(
                                'PIN Code', data['PinCode'] ?? 'N/A'),
                            if (data['Address'] != null &&
                                data['Address'].toString().isNotEmpty)
                              _buildDetailRow('Full Address', data['Address']),
                          ],
                        ),
                      ),

                      // Performance Metrics
                      if (!isLoadingRevenue) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Performance Metrics',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorManager.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            children: [
                              _buildDetailRow('This Month Revenue',
                                  '₹${_formatCurrency(revenueData['monthlyRevenue'])}'),
                              _buildDetailRow('Membership Commissions',
                                  '${revenueData['membershipCommissions']}'),
                              _buildDetailRow('Course Commissions',
                                  '${revenueData['courseCommissions']}'),
                              _buildDetailRow(
                                  'Average per Student',
                                  revenueData['totalStudents'] > 0
                                      ? '₹${_formatCurrency(revenueData['totalRevenue'] / revenueData['totalStudents'])}'
                                      : '₹0'),
                            ],
                          ),
                        ),
                      ],

                      // Notes section
                      if (data['Notes'] != null &&
                          data['Notes'].toString().isNotEmpty) ...[
                        const SizedBox(height: 20),
                        Text(
                          'Notes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorManager.textDark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.yellow.shade200),
                          ),
                          child: Text(
                            data['Notes'],
                            style: TextStyle(
                              fontSize: 14,
                              color: ColorManager.textMedium,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _editFranchise(data);
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit Franchise'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: ColorManager.textMedium,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: ColorManager.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: ColorManager.textMedium,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _deleteFranchise(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Franchise'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete ${data['FranchiseName']}?'),
            const SizedBox(height: 8),
            const Text(
              'This will also delete:',
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const Text('• All commission records'),
            const Text('• Transaction history'),
            const Text('• Associated student records'),
            const SizedBox(height: 8),
            const Text(
              'This action cannot be undone.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                String franchiseEmail = data['Email'] ?? '';

                // Show loading
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Row(
                      children: [
                        CircularProgressIndicator(strokeWidth: 2),
                        SizedBox(width: 16),
                        Text('Deleting franchise and related data...'),
                      ],
                    ),
                    duration: Duration(seconds: 2),
                  ),
                );

                // Delete from Users collection
                await _firestore
                    .collection('Users')
                    .doc('franchise')
                    .collection('accounts')
                    .doc(franchiseEmail)
                    .delete();

                // Delete all franchise commissions
                QuerySnapshot commissions = await _firestore
                    .collection('FranchiseCommissions')
                    .where('franchiseEmail', isEqualTo: franchiseEmail)
                    .get();

                WriteBatch batch = _firestore.batch();
                for (var doc in commissions.docs) {
                  batch.delete(doc.reference);
                }
                await batch.commit();

                // Remove from cache
                _franchiseRevenueCache.remove(franchiseEmail);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Franchise deleted successfully'),
                    backgroundColor: Colors.green,
                  ),
                );
                _refreshPage();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error deleting franchise: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
