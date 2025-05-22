import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/admin_dashboard/admin_pages.dart/add_franchise.dart';

class FranchisesContent extends StatefulWidget {
  const FranchisesContent({Key? key}) : super(key: key);

  @override
  State<FranchisesContent> createState() => _FranchisesContentState();
}

class _FranchisesContentState extends State<FranchisesContent> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  void _refreshPage() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
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
                    'Manage your franchise partners and their details',
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                    onChanged: (value) => setState(() => _searchQuery = value),
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

          // Franchises list
          Expanded(
            child: Container(
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
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
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
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
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

                  return Column(
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
                          ],
                        ),
                      ),

                      // Franchises list
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: filteredFranchises.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 24),
                          itemBuilder: (context, index) {
                            Map<String, dynamic> data =
                                filteredFranchises[index].data()
                                    as Map<String, dynamic>;
                            return _buildFranchiseCard(data);
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
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
                            data['DOJ'] ?? 'N/A'),
                        _buildInfoRow(Icons.people_outlined, 'Students',
                            '${data['TotalStudents'] ?? 0}'),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildInfoItem(
                      'Revenue',
                      [
                        _buildInfoRow(
                            Icons.attach_money_outlined,
                            'Total Revenue',
                            '₹${_formatCurrency(data['TotalRevenue'] ?? 0)}'),
                        _buildInfoRow(
                            Icons.trending_up_outlined,
                            'Monthly Revenue',
                            '₹${_formatCurrency(data['MonthlyRevenue'] ?? 0)}'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

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
                  onPressed: () => _viewFranchiseDetails(data),
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

  void _viewFranchiseDetails(Map<String, dynamic> data) {
    // Show detailed view of franchise
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          width: 600,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Franchise Details',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Add detailed view content here
              Text(
                'Detailed view of ${data['FranchiseName']} can be implemented here.',
                style: TextStyle(color: ColorManager.textMedium),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteFranchise(Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Franchise'),
        content: Text(
            'Are you sure you want to delete ${data['FranchiseName']}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Delete from Users collection
                await _firestore
                    .collection('Users')
                    .doc('franchise')
                    .collection('accounts')
                    .doc(data['Email'])
                    .delete();

                // Delete from Franchises collection
                await _firestore
                    .collection('Franchises')
                    .doc(data['Email'])
                    .delete();

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Franchise deleted successfully')),
                );
                _refreshPage();
              } catch (e) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error deleting franchise: $e')),
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
