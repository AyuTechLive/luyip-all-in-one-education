import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:intl/intl.dart';

class WebsiteGeneralAdminPage extends StatefulWidget {
  const WebsiteGeneralAdminPage({Key? key}) : super(key: key);

  @override
  State<WebsiteGeneralAdminPage> createState() =>
      _WebsiteGeneralAdminPageState();
}

class _WebsiteGeneralAdminPageState extends State<WebsiteGeneralAdminPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, dynamic>> _websiteDataFuture;
  bool _isLoading = false;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Banners
  final TextEditingController _bannerTitleController = TextEditingController();
  final TextEditingController _bannerSubtitleController =
      TextEditingController();
  final TextEditingController _bannerCtaController = TextEditingController();
  String _selectedBannerColor = 'purple';
  XFile? _pickedBannerImage;
  Uint8List? _webBannerImage;
  File? _bannerImageFile;

  // Announcements
  final TextEditingController _announcementTitleController =
      TextEditingController();
  final TextEditingController _announcementContentController =
      TextEditingController();

  // Events
  final TextEditingController _eventTitleController = TextEditingController();
  final TextEditingController _eventCategoryController =
      TextEditingController();
  final TextEditingController _eventTimeController = TextEditingController();
  DateTime? _selectedEventDate;

  // Testimonials
  final TextEditingController _testimonialNameController =
      TextEditingController();
  final TextEditingController _testimonialCourseController =
      TextEditingController();
  final TextEditingController _testimonialContentController =
      TextEditingController();
  double _testimonialRating = 5.0;
  XFile? _pickedTestimonialPhoto;
  Uint8List? _webTestimonialPhoto;
  File? _testimonialPhotoFile;

  // Available banner colors
  final List<Map<String, dynamic>> _bannerColors = [
    {'name': 'Purple', 'value': 'purple', 'color': Color(0xFF5E4DCD)},
    {'name': 'Blue', 'value': 'blue', 'color': Colors.blue.shade600},
    {'name': 'Green', 'value': 'green', 'color': Colors.green.shade600},
    {'name': 'Orange', 'value': 'orange', 'color': Colors.orange.shade600},
    {'name': 'Pink', 'value': 'pink', 'color': Colors.pink.shade600},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _websiteDataFuture = _fetchWebsiteData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bannerTitleController.dispose();
    _bannerSubtitleController.dispose();
    _bannerCtaController.dispose();
    _announcementTitleController.dispose();
    _announcementContentController.dispose();
    _eventTitleController.dispose();
    _eventCategoryController.dispose();
    _eventTimeController.dispose();
    _testimonialNameController.dispose();
    _testimonialCourseController.dispose();
    _testimonialContentController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _fetchWebsiteData() async {
    Map<String, dynamic> websiteData = {
      'banners': [],
      'announcements': [],
      'upcomingEvents': [],
      'testimonials': [],
    };

    try {
      final doc =
          await _firestore.collection('website_general').doc('dashboard').get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        websiteData = {
          'banners': data['banners'] ?? [],
          'announcements': data['announcements'] ?? [],
          'upcomingEvents': data['upcomingEvents'] ?? [],
          'testimonials': data['testimonials'] ?? [],
        };
      }

      return websiteData;
    } catch (e) {
      print('Error fetching website data: $e');
      return websiteData;
    }
  }

  Future<void> _saveWebsiteData(Map<String, dynamic> websiteData) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _firestore
          .collection('website_general')
          .doc('dashboard')
          .set(websiteData);
      Utils().toastMessage('Website data updated successfully');
    } catch (e) {
      Utils().toastMessage('Error updating website data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _websiteDataFuture = _fetchWebsiteData();
    });
  }

  Future<void> _pickBannerImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _pickedBannerImage = pickedFile;

      if (kIsWeb) {
        _webBannerImage = await pickedFile.readAsBytes();
        setState(() {});
      } else {
        setState(() {
          _bannerImageFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<String?> _uploadBannerImage() async {
    if (_pickedBannerImage == null) return null;

    try {
      final fileName = 'banner_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('banners/$fileName');

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(
          await _pickedBannerImage!.readAsBytes(),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        uploadTask = ref.putFile(_bannerImageFile!);
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _pickTestimonialImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      _pickedTestimonialPhoto = pickedFile;

      if (kIsWeb) {
        _webTestimonialPhoto = await pickedFile.readAsBytes();
        setState(() {});
      } else {
        setState(() {
          _testimonialPhotoFile = File(pickedFile.path);
        });
      }
    }
  }

  Future<String?> _uploadTestimonialImage() async {
    if (_pickedTestimonialPhoto == null) return null;

    try {
      final fileName =
          'testimonial_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('testimonials/$fileName');

      UploadTask uploadTask;
      if (kIsWeb) {
        uploadTask = ref.putData(
          await _pickedTestimonialPhoto!.readAsBytes(),
          SettableMetadata(contentType: 'image/jpeg'),
        );
      } else {
        uploadTask = ref.putFile(_testimonialPhotoFile!);
      }

      final snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print('Error uploading image: $e');
      return null;
    }
  }

  Future<void> _showDatePicker() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedEventDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null && picked != _selectedEventDate) {
      setState(() {
        _selectedEventDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Website Content Management',
          style: TextStyle(
            color: ColorManager.textDark,
            fontWeight: FontWeight.bold,
            fontSize: isSmallScreen ? 18 : 22,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorManager.primary,
          unselectedLabelColor: ColorManager.textMedium,
          indicatorColor: ColorManager.primary,
          isScrollable: isSmallScreen,
          labelStyle: TextStyle(
              fontSize: isSmallScreen ? 12 : 14, fontWeight: FontWeight.w600),
          tabs: const [
            Tab(text: 'Banners'),
            Tab(text: 'Announcements'),
            Tab(text: 'Events'),
            Tab(text: 'Testimonials'),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _websiteDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: ColorManager.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline,
                      size: 64, color: ColorManager.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading website data',
                    style:
                        TextStyle(color: ColorManager.textMedium, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: _refreshData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final websiteData = snapshot.data!;
          final banners = websiteData['banners'] as List;
          final announcements = websiteData['announcements'] as List;
          final upcomingEvents = websiteData['upcomingEvents'] as List;
          final testimonials = websiteData['testimonials'] as List;

          return TabBarView(
            controller: _tabController,
            children: [
              _buildBannersTab(banners, websiteData, isSmallScreen),
              _buildAnnouncementsTab(announcements, websiteData, isSmallScreen),
              _buildEventsTab(upcomingEvents, websiteData, isSmallScreen),
              _buildTestimonialsTab(testimonials, websiteData, isSmallScreen),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBannersTab(
      List banners, Map<String, dynamic> websiteData, bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Homepage Banners',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Add New Banner Form
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Banner',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Responsive layout for form fields
                  if (isSmallScreen)
                    _buildMobileBannerForm()
                  else
                    _buildDesktopBannerForm(),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_isLoading)
                        CircularProgressIndicator(
                            color: ColorManager.primary, strokeWidth: 2)
                      else
                        ElevatedButton.icon(
                          onPressed: () => _addBanner(banners, websiteData),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Banner'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: isSmallScreen ? 8 : 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Current Banners (${banners.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),

          // List of existing banners
          if (banners.isEmpty)
            _buildEmptyState('No banners yet', Icons.image_outlined)
          else
            ...banners.asMap().entries.map((entry) {
              final index = entry.key;
              final banner = entry.value;
              return _buildBannerCard(
                  banner, index, banners, websiteData, isSmallScreen);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildMobileBannerForm() {
    return Column(
      children: [
        TextField(
          controller: _bannerTitleController,
          decoration: _inputDecoration('Banner Title'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bannerSubtitleController,
          decoration: _inputDecoration('Banner Subtitle'),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _bannerCtaController,
          decoration: _inputDecoration('Call to Action Button Text'),
        ),
        const SizedBox(height: 12),
        _buildColorDropdown(),
        const SizedBox(height: 16),
        _buildImagePicker(true),
      ],
    );
  }

  Widget _buildDesktopBannerForm() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Column(
            children: [
              TextField(
                controller: _bannerTitleController,
                decoration: _inputDecoration('Banner Title'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bannerSubtitleController,
                decoration: _inputDecoration('Banner Subtitle'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _bannerCtaController,
                decoration: _inputDecoration('Call to Action Button Text'),
              ),
              const SizedBox(height: 12),
              _buildColorDropdown(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildImagePicker(false),
      ],
    );
  }

  Widget _buildColorDropdown() {
    return DropdownButtonFormField<String>(
      decoration: _inputDecoration('Banner Color'),
      value: _selectedBannerColor,
      isExpanded: true,
      items: _bannerColors.map((colorData) {
        return DropdownMenuItem<String>(
          value: colorData['value'],
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: colorData['color'],
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(colorData['name']),
            ],
          ),
        );
      }).toList(),
      onChanged: (String? value) {
        setState(() {
          _selectedBannerColor = value ?? 'purple';
        });
      },
    );
  }

  Widget _buildImagePicker(bool isMobile) {
    return GestureDetector(
      onTap: _pickBannerImage,
      child: Container(
        width: isMobile ? double.infinity : 120,
        height: 120,
        decoration: BoxDecoration(
          color: ColorManager.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: ColorManager.primary.withOpacity(0.5)),
        ),
        child: _pickedBannerImage != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: kIsWeb
                        ? Image.memory(
                            _webBannerImage!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 120,
                          )
                        : Image.file(
                            _bannerImageFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 120,
                          ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _pickedBannerImage = null;
                            _bannerImageFile = null;
                            _webBannerImage = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate,
                      color: ColorManager.primary, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Banner Image',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: ColorManager.primary, fontSize: 12),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildBannerCard(Map<String, dynamic> banner, int index, List banners,
      Map<String, dynamic> websiteData, bool isSmallScreen) {
    final color = _getColorFromString(banner['color'] ?? 'purple');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: isSmallScreen
            ? _buildMobileBannerCard(banner, color, index, banners, websiteData)
            : _buildDesktopBannerCard(
                banner, color, index, banners, websiteData),
      ),
    );
  }

  Widget _buildMobileBannerCard(Map<String, dynamic> banner, Color color,
      int index, List banners, Map<String, dynamic> websiteData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                banner['title'] ?? 'Banner Title',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () => _deleteBanner(index, banners, websiteData),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (banner['imageUrl'] != null &&
            banner['imageUrl'].toString().isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              banner['imageUrl'],
              width: double.infinity,
              height: 100,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                height: 100,
                color: color.withOpacity(0.2),
                child: Icon(Icons.image_not_supported, color: color),
              ),
            ),
          ),
        const SizedBox(height: 8),
        Text(
          banner['subtitle'] ?? 'Banner Subtitle',
          style: TextStyle(color: ColorManager.textMedium, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            banner['cta'] ?? 'Call to Action',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopBannerCard(Map<String, dynamic> banner, Color color,
      int index, List banners, Map<String, dynamic> websiteData) {
    return Row(
      children: [
        Icon(Icons.drag_handle, color: Colors.grey),
        const SizedBox(width: 8),
        Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 12),
        if (banner['imageUrl'] != null &&
            banner['imageUrl'].toString().isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              banner['imageUrl'],
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 60,
                height: 60,
                color: color.withOpacity(0.2),
                child: Icon(Icons.image_not_supported, color: color),
              ),
            ),
          )
        else
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.image, color: color),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                banner['title'] ?? 'Banner Title',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Text(
                banner['subtitle'] ?? 'Banner Subtitle',
                style: TextStyle(color: ColorManager.textMedium, fontSize: 14),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  banner['cta'] ?? 'Call to Action',
                  style: TextStyle(
                      color: color, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteBanner(index, banners, websiteData),
        ),
      ],
    );
  }

  Widget _buildAnnouncementsTab(List announcements,
      Map<String, dynamic> websiteData, bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Announcements',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Add New Announcement Form
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Announcement',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _announcementTitleController,
                    decoration: _inputDecoration('Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _announcementContentController,
                    decoration: _inputDecoration('Content'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () =>
                            _addAnnouncement(announcements, websiteData),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Announcement'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Current Announcements (${announcements.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),

          // List of existing announcements
          if (announcements.isEmpty)
            _buildEmptyState('No announcements yet', Icons.campaign_outlined)
          else
            ...announcements.asMap().entries.map((entry) {
              final index = entry.key;
              final announcement = entry.value;
              return _buildAnnouncementCard(announcement, index, announcements,
                  websiteData, isSmallScreen);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildAnnouncementCard(
      Map<String, dynamic> announcement,
      int index,
      List announcements,
      Map<String, dynamic> websiteData,
      bool isSmallScreen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 4 : 8,
        ),
        title: Text(
          announcement['title'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              announcement['content'] ?? '',
              maxLines: isSmallScreen ? 2 : 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              announcement['date'] ?? '',
              style: TextStyle(fontSize: 12, color: ColorManager.textLight),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () =>
              _deleteAnnouncement(index, announcements, websiteData),
        ),
      ),
    );
  }

  Widget _buildEventsTab(List upcomingEvents, Map<String, dynamic> websiteData,
      bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Upcoming Events',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Add New Event Form
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Event',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _eventTitleController,
                    decoration: _inputDecoration('Event Title'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _eventCategoryController,
                    decoration: _inputDecoration(
                        'Category (e.g., Web Development, Data Structures)'),
                  ),
                  const SizedBox(height: 12),
                  if (isSmallScreen) ...[
                    InkWell(
                      onTap: _showDatePicker,
                      child: InputDecorator(
                        decoration: _inputDecoration('Date'),
                        child: Text(
                          _selectedEventDate == null
                              ? 'Select Date'
                              : DateFormat('MMM d, yyyy')
                                  .format(_selectedEventDate!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _eventTimeController,
                      decoration: _inputDecoration('Time (e.g., 3:00 PM)'),
                    ),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _showDatePicker,
                            child: InputDecorator(
                              decoration: _inputDecoration('Date'),
                              child: Text(
                                _selectedEventDate == null
                                    ? 'Select Date'
                                    : DateFormat('MMM d, yyyy')
                                        .format(_selectedEventDate!),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _eventTimeController,
                            decoration:
                                _inputDecoration('Time (e.g., 3:00 PM)'),
                          ),
                        ),
                      ],
                    ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _addEvent(upcomingEvents, websiteData),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: isSmallScreen ? 8 : 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Upcoming Events (${upcomingEvents.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),

          // List of existing events
          if (upcomingEvents.isEmpty)
            _buildEmptyState('No upcoming events', Icons.event_outlined)
          else
            ...upcomingEvents.asMap().entries.map((entry) {
              final index = entry.key;
              final event = entry.value;
              return _buildEventCard(
                  event, index, upcomingEvents, websiteData, isSmallScreen);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildEventCard(
      Map<String, dynamic> event,
      int index,
      List upcomingEvents,
      Map<String, dynamic> websiteData,
      bool isSmallScreen) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 16,
          vertical: isSmallScreen ? 4 : 8,
        ),
        leading: Container(
          width: 8,
          height: double.infinity,
          color: _getCategoryColor(event['category'] ?? ''),
        ),
        title: Text(
          event['title'] ?? '',
          style: const TextStyle(fontWeight: FontWeight.bold),
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              event['category'] ?? '',
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              event['time'] ?? '',
              style: TextStyle(fontSize: 12, color: ColorManager.textLight),
            ),
          ],
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () => _deleteEvent(index, upcomingEvents, websiteData),
        ),
      ),
    );
  }

  Widget _buildTestimonialsTab(
      List testimonials, Map<String, dynamic> websiteData, bool isSmallScreen) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Testimonials',
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Add New Testimonial Form
          Card(
            elevation: 3,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add New Testimonial',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (isSmallScreen) ...[
                    TextField(
                      controller: _testimonialNameController,
                      decoration: _inputDecoration('Student Name'),
                    ),
                    const SizedBox(height: 12),
                    _buildTestimonialImagePicker(true),
                    const SizedBox(height: 12),
                  ] else
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _testimonialNameController,
                            decoration: _inputDecoration('Student Name'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildTestimonialImagePicker(false),
                      ],
                    ),
                  TextField(
                    controller: _testimonialCourseController,
                    decoration: _inputDecoration('Course Name'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _testimonialContentController,
                    decoration: _inputDecoration('Testimonial Content'),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Rating: ${_testimonialRating.toInt()}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  Slider(
                    value: _testimonialRating,
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: _testimonialRating.round().toString(),
                    activeColor: ColorManager.primary,
                    onChanged: (value) {
                      setState(() {
                        _testimonialRating = value;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (_isLoading)
                        CircularProgressIndicator(
                            color: ColorManager.primary, strokeWidth: 2)
                      else
                        ElevatedButton.icon(
                          onPressed: () =>
                              _addTestimonial(testimonials, websiteData),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Testimonial'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.primary,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 12 : 16,
                              vertical: isSmallScreen ? 8 : 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          Text(
            'Current Testimonials (${testimonials.length})',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),

          // List of existing testimonials
          if (testimonials.isEmpty)
            _buildEmptyState('No testimonials yet', Icons.star_outline)
          else
            ...testimonials.asMap().entries.map((entry) {
              final index = entry.key;
              final testimonial = entry.value;
              return _buildTestimonialCard(
                  testimonial, index, testimonials, websiteData, isSmallScreen);
            }).toList(),
        ],
      ),
    );
  }

  Widget _buildTestimonialImagePicker(bool isMobile) {
    return GestureDetector(
      onTap: _pickTestimonialImage,
      child: Container(
        width: isMobile ? double.infinity : 80,
        height: 80,
        decoration: BoxDecoration(
          color: ColorManager.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: ColorManager.primary.withOpacity(0.5)),
        ),
        child: _pickedTestimonialPhoto != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(40),
                    child: kIsWeb
                        ? Image.memory(
                            _webTestimonialPhoto!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 80,
                          )
                        : Image.file(
                            _testimonialPhotoFile!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 80,
                          ),
                  ),
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 12),
                        padding: const EdgeInsets.all(4),
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          setState(() {
                            _pickedTestimonialPhoto = null;
                            _testimonialPhotoFile = null;
                            _webTestimonialPhoto = null;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              )
            : Icon(Icons.add_a_photo, color: ColorManager.primary, size: 30),
      ),
    );
  }

  Widget _buildTestimonialCard(Map<String, dynamic> testimonial, int index,
      List testimonials, Map<String, dynamic> websiteData, bool isSmallScreen) {
    final String name = testimonial['name'] ?? 'Student';
    final String courseName = testimonial['courseName'] ?? '';
    final String content = testimonial['content'] ?? '';
    final double rating = testimonial['rating'] is int
        ? (testimonial['rating'] as int).toDouble()
        : (testimonial['rating'] as double? ?? 5.0);
    final String photoUrl = testimonial['photoUrl'] ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: EdgeInsets.all(isSmallScreen ? 8 : 12),
        child: isSmallScreen
            ? _buildMobileTestimonialCard(name, courseName, content, rating,
                photoUrl, index, testimonials, websiteData)
            : _buildDesktopTestimonialCard(name, courseName, content, rating,
                photoUrl, index, testimonials, websiteData),
      ),
    );
  }

  Widget _buildMobileTestimonialCard(
      String name,
      String courseName,
      String content,
      double rating,
      String photoUrl,
      int index,
      List testimonials,
      Map<String, dynamic> websiteData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: photoUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(25),
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        width: 50,
                        height: 50,
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.person,
                          color: ColorManager.primary,
                          size: 25,
                        ),
                      ),
                    )
                  : Icon(Icons.person, color: ColorManager.primary, size: 25),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    courseName,
                    style:
                        TextStyle(color: ColorManager.textMedium, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () =>
                  _deleteTestimonial(index, testimonials, websiteData),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(
            5,
            (i) => Icon(
              i < rating.floor() ? Icons.star : Icons.star_border,
              color: Colors.amber,
              size: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
              color: ColorManager.textMedium, fontStyle: FontStyle.italic),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDesktopTestimonialCard(
      String name,
      String courseName,
      String content,
      double rating,
      String photoUrl,
      int index,
      List testimonials,
      Map<String, dynamic> websiteData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: ColorManager.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: photoUrl.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    width: 60,
                    height: 60,
                    errorBuilder: (context, error, stackTrace) => Icon(
                      Icons.person,
                      color: ColorManager.primary,
                      size: 30,
                    ),
                  ),
                )
              : Icon(Icons.person, color: ColorManager.primary, size: 30),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                    onPressed: () =>
                        _deleteTestimonial(index, testimonials, websiteData),
                  ),
                ],
              ),
              Text(
                courseName,
                style: TextStyle(color: ColorManager.textMedium, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Row(
                children: List.generate(
                  5,
                  (i) => Icon(
                    i < rating.floor() ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                content,
                style: TextStyle(
                    color: ColorManager.textMedium,
                    fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: ColorManager.textLight),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: ColorManager.textMedium, fontSize: 16),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
    );
  }

  // Action methods
  Future<void> _addBanner(
      List banners, Map<String, dynamic> websiteData) async {
    if (_bannerTitleController.text.isEmpty ||
        _bannerSubtitleController.text.isEmpty ||
        _bannerCtaController.text.isEmpty) {
      Utils().toastMessage('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    String? imageUrl;
    if (_pickedBannerImage != null) {
      imageUrl = await _uploadBannerImage();
    }

    final newBanner = {
      'title': _bannerTitleController.text,
      'subtitle': _bannerSubtitleController.text,
      'cta': _bannerCtaController.text,
      'color': _selectedBannerColor,
      'imageUrl': imageUrl ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    List updatedBanners = [...banners, newBanner];
    final updatedData = {...websiteData, 'banners': updatedBanners};

    await _saveWebsiteData(updatedData);
    _bannerTitleController.clear();
    _bannerSubtitleController.clear();
    _bannerCtaController.clear();
    setState(() {
      _pickedBannerImage = null;
      _bannerImageFile = null;
      _webBannerImage = null;
      _selectedBannerColor = 'purple';
      _isLoading = false;
    });
    await _refreshData();
  }

  void _deleteBanner(
      int index, List banners, Map<String, dynamic> websiteData) {
    List updatedBanners = List.from(banners)..removeAt(index);
    final updatedData = {...websiteData, 'banners': updatedBanners};
    _saveWebsiteData(updatedData).then((_) => _refreshData());
  }

  void _addAnnouncement(List announcements, Map<String, dynamic> websiteData) {
    if (_announcementTitleController.text.isEmpty ||
        _announcementContentController.text.isEmpty) {
      Utils().toastMessage('Please fill in all fields');
      return;
    }

    final now = DateTime.now();
    final formattedDate = DateFormat('MMM d, yyyy').format(now);

    final newAnnouncement = {
      'title': _announcementTitleController.text,
      'content': _announcementContentController.text,
      'date': formattedDate,
      'timestamp': now.millisecondsSinceEpoch,
    };

    List updatedAnnouncements = [...announcements, newAnnouncement];
    final updatedData = {...websiteData, 'announcements': updatedAnnouncements};

    _saveWebsiteData(updatedData).then((_) {
      _announcementTitleController.clear();
      _announcementContentController.clear();
      _refreshData();
    });
  }

  void _deleteAnnouncement(
      int index, List announcements, Map<String, dynamic> websiteData) {
    List updatedAnnouncements = List.from(announcements)..removeAt(index);
    final updatedData = {...websiteData, 'announcements': updatedAnnouncements};
    _saveWebsiteData(updatedData).then((_) => _refreshData());
  }

  void _addEvent(List upcomingEvents, Map<String, dynamic> websiteData) {
    if (_eventTitleController.text.isEmpty ||
        _eventCategoryController.text.isEmpty ||
        _eventTimeController.text.isEmpty ||
        _selectedEventDate == null) {
      Utils().toastMessage('Please fill in all fields');
      return;
    }

    final formattedDate = DateFormat('MMM d').format(_selectedEventDate!);
    final time = '${formattedDate}, ${_eventTimeController.text}';

    final newEvent = {
      'title': _eventTitleController.text,
      'category': _eventCategoryController.text,
      'time': time,
      'date': Timestamp.fromDate(_selectedEventDate!),
    };

    List updatedEvents = [...upcomingEvents, newEvent];
    final updatedData = {...websiteData, 'upcomingEvents': updatedEvents};

    _saveWebsiteData(updatedData).then((_) {
      _eventTitleController.clear();
      _eventCategoryController.clear();
      _eventTimeController.clear();
      setState(() => _selectedEventDate = null);
      _refreshData();
    });
  }

  void _deleteEvent(
      int index, List upcomingEvents, Map<String, dynamic> websiteData) {
    List updatedEvents = List.from(upcomingEvents)..removeAt(index);
    final updatedData = {...websiteData, 'upcomingEvents': updatedEvents};
    _saveWebsiteData(updatedData).then((_) => _refreshData());
  }

  Future<void> _addTestimonial(
      List testimonials, Map<String, dynamic> websiteData) async {
    if (_testimonialNameController.text.isEmpty ||
        _testimonialCourseController.text.isEmpty ||
        _testimonialContentController.text.isEmpty) {
      Utils().toastMessage('Please fill in all fields');
      return;
    }

    setState(() => _isLoading = true);

    String? photoUrl;
    if (_pickedTestimonialPhoto != null) {
      photoUrl = await _uploadTestimonialImage();
    }

    final newTestimonial = {
      'name': _testimonialNameController.text,
      'courseName': _testimonialCourseController.text,
      'content': _testimonialContentController.text,
      'rating': _testimonialRating,
      'photoUrl': photoUrl ?? '',
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    };

    List updatedTestimonials = [...testimonials, newTestimonial];
    final updatedData = {...websiteData, 'testimonials': updatedTestimonials};

    await _saveWebsiteData(updatedData);
    _testimonialNameController.clear();
    _testimonialCourseController.clear();
    _testimonialContentController.clear();
    setState(() {
      _pickedTestimonialPhoto = null;
      _webTestimonialPhoto = null;
      _testimonialPhotoFile = null;
      _testimonialRating = 5.0;
      _isLoading = false;
    });
    await _refreshData();
  }

  void _deleteTestimonial(
      int index, List testimonials, Map<String, dynamic> websiteData) {
    List updatedTestimonials = List.from(testimonials)..removeAt(index);
    final updatedData = {...websiteData, 'testimonials': updatedTestimonials};
    _saveWebsiteData(updatedData).then((_) => _refreshData());
  }

  // Helper methods
  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'purple':
        return const Color(0xFF5E4DCD);
      case 'blue':
        return Colors.blue.shade600;
      case 'green':
        return Colors.green.shade600;
      case 'orange':
        return Colors.orange.shade600;
      case 'pink':
        return Colors.pink.shade600;
      default:
        return const Color(0xFF5E4DCD);
    }
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'web development':
        return ColorManager.primary;
      case 'data structures':
        return ColorManager.error;
      case 'ui/ux design':
        return ColorManager.warning;
      case 'general':
        return ColorManager.info;
      default:
        return ColorManager.secondary;
    }
  }
}
