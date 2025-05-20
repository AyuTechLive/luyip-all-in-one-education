import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/roundbutton.dart';
import 'package:luyip_website_edu/helpers/utils.dart';
import 'dart:io';
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
  File? _testimonialPhoto;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _websiteDataFuture = _fetchWebsiteData();
  }

  @override
  void dispose() {
    _tabController.dispose();
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _testimonialPhoto = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImage() async {
    if (_testimonialPhoto == null) return null;

    try {
      final fileName =
          'testimonial_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('testimonials/$fileName');
      final uploadTask = ref.putFile(_testimonialPhoto!);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Website Content Management',
          style: TextStyle(
            color: ColorManager.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          labelColor: ColorManager.primary,
          unselectedLabelColor: ColorManager.textMedium,
          indicatorColor: ColorManager.primary,
          tabs: const [
            Tab(text: 'Announcements'),
            Tab(text: 'Upcoming Events'),
            Tab(text: 'Testimonials'),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _websiteDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: ColorManager.primary,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading website data. Please try again.',
                style: TextStyle(color: ColorManager.textMedium),
              ),
            );
          }

          final websiteData = snapshot.data!;
          final announcements = websiteData['announcements'] as List;
          final upcomingEvents = websiteData['upcomingEvents'] as List;
          final testimonials = websiteData['testimonials'] as List;

          return TabBarView(
            controller: _tabController,
            children: [
              // Announcements Tab
              _buildAnnouncementsTab(announcements, websiteData),

              // Upcoming Events Tab
              _buildEventsTab(upcomingEvents, websiteData),

              // Testimonials Tab
              _buildTestimonialsTab(testimonials, websiteData),
            ],
          );
        },
      ),
    );
  }

  Widget _buildAnnouncementsTab(
      List announcements, Map<String, dynamic> websiteData) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Announcements',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Add New Announcement Form
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                    decoration: InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _announcementContentController,
                    decoration: InputDecoration(
                      labelText: 'Content',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_announcementTitleController.text.isEmpty ||
                              _announcementContentController.text.isEmpty) {
                            Utils().toastMessage('Please fill in all fields');
                            return;
                          }

                          final now = DateTime.now();
                          final formattedDate =
                              DateFormat('MMM d, yyyy').format(now);

                          final newAnnouncement = {
                            'title': _announcementTitleController.text,
                            'content': _announcementContentController.text,
                            'date': formattedDate,
                            'timestamp': now.millisecondsSinceEpoch,
                          };

                          List updatedAnnouncements = [
                            ...announcements,
                            newAnnouncement
                          ];
                          final updatedData = {
                            ...websiteData,
                            'announcements': updatedAnnouncements,
                          };

                          _saveWebsiteData(updatedData).then((_) {
                            _announcementTitleController.clear();
                            _announcementContentController.clear();
                            _refreshData();
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Announcement'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
            'Current Announcements',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),

          // List of existing announcements
          Expanded(
            child: announcements.isEmpty
                ? Center(
                    child: Text(
                      'No announcements yet',
                      style: TextStyle(
                        color: ColorManager.textMedium,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: announcements.length,
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return Dismissible(
                        key: Key(
                            'announcement-${index}-${announcement['timestamp']}'),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          List updatedAnnouncements = List.from(announcements)
                            ..removeAt(index);
                          final updatedData = {
                            ...websiteData,
                            'announcements': updatedAnnouncements,
                          };

                          _saveWebsiteData(updatedData).then((_) {
                            _refreshData();
                          });
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              announcement['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(announcement['content'] ?? ''),
                                const SizedBox(height: 4),
                                Text(
                                  announcement['date'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ColorManager.textLight,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                List updatedAnnouncements =
                                    List.from(announcements)..removeAt(index);
                                final updatedData = {
                                  ...websiteData,
                                  'announcements': updatedAnnouncements,
                                };

                                _saveWebsiteData(updatedData).then((_) {
                                  _refreshData();
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsTab(
      List upcomingEvents, Map<String, dynamic> websiteData) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Upcoming Events',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Add New Event Form
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                    decoration: InputDecoration(
                      labelText: 'Event Title',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _eventCategoryController,
                    decoration: InputDecoration(
                      labelText:
                          'Category (e.g., Web Development, Data Structures)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _showDatePicker,
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
                          decoration: InputDecoration(
                            labelText: 'Time (e.g., 3:00 PM)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          if (_eventTitleController.text.isEmpty ||
                              _eventCategoryController.text.isEmpty ||
                              _eventTimeController.text.isEmpty ||
                              _selectedEventDate == null) {
                            Utils().toastMessage('Please fill in all fields');
                            return;
                          }

                          final formattedDate =
                              DateFormat('MMM d').format(_selectedEventDate!);
                          final time =
                              '${formattedDate}, ${_eventTimeController.text}';

                          final newEvent = {
                            'title': _eventTitleController.text,
                            'category': _eventCategoryController.text,
                            'time': time,
                            'date': Timestamp.fromDate(_selectedEventDate!),
                          };

                          List updatedEvents = [...upcomingEvents, newEvent];
                          final updatedData = {
                            ...websiteData,
                            'upcomingEvents': updatedEvents,
                          };

                          _saveWebsiteData(updatedData).then((_) {
                            _eventTitleController.clear();
                            _eventCategoryController.clear();
                            _eventTimeController.clear();
                            setState(() {
                              _selectedEventDate = null;
                            });
                            _refreshData();
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Add Event'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
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
            'Upcoming Events',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),

          // List of existing events
          Expanded(
            child: upcomingEvents.isEmpty
                ? Center(
                    child: Text(
                      'No upcoming events',
                      style: TextStyle(
                        color: ColorManager.textMedium,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: upcomingEvents.length,
                    itemBuilder: (context, index) {
                      final event = upcomingEvents[index];
                      return Dismissible(
                        key: Key('event-$index-${event['title']}'),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          List updatedEvents = List.from(upcomingEvents)
                            ..removeAt(index);
                          final updatedData = {
                            ...websiteData,
                            'upcomingEvents': updatedEvents,
                          };

                          _saveWebsiteData(updatedData).then((_) {
                            _refreshData();
                          });
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 8,
                              height: double.infinity,
                              color: _getCategoryColor(event['category'] ?? ''),
                            ),
                            title: Text(
                              event['title'] ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(event['category'] ?? ''),
                                const SizedBox(height: 4),
                                Text(
                                  event['time'] ?? '',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ColorManager.textLight,
                                  ),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                List updatedEvents = List.from(upcomingEvents)
                                  ..removeAt(index);
                                final updatedData = {
                                  ...websiteData,
                                  'upcomingEvents': updatedEvents,
                                };

                                _saveWebsiteData(updatedData).then((_) {
                                  _refreshData();
                                });
                              },
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonialsTab(
      List testimonials, Map<String, dynamic> websiteData) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Manage Testimonials',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 16),

          // Add New Testimonial Form
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
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
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _testimonialNameController,
                          decoration: InputDecoration(
                            labelText: 'Student Name',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: ColorManager.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(40),
                            border: Border.all(
                              color: ColorManager.primary.withOpacity(0.5),
                            ),
                          ),
                          child: _testimonialPhoto != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(40),
                                  child: Image.file(
                                    _testimonialPhoto!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(
                                  Icons.add_a_photo,
                                  color: ColorManager.primary,
                                  size: 30,
                                ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _testimonialCourseController,
                    decoration: InputDecoration(
                      labelText: 'Course Name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _testimonialContentController,
                    decoration: InputDecoration(
                      labelText: 'Testimonial Content',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
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
                      _isLoading
                          ? CircularProgressIndicator(
                              color: ColorManager.primary,
                            )
                          : ElevatedButton.icon(
                              onPressed: () async {
                                if (_testimonialNameController.text.isEmpty ||
                                    _testimonialCourseController.text.isEmpty ||
                                    _testimonialContentController
                                        .text.isEmpty) {
                                  Utils().toastMessage(
                                      'Please fill in all fields');
                                  return;
                                }

                                setState(() {
                                  _isLoading = true;
                                });

                                String? photoUrl;
                                if (_testimonialPhoto != null) {
                                  photoUrl = await _uploadImage();
                                }

                                final newTestimonial = {
                                  'name': _testimonialNameController.text,
                                  'courseName':
                                      _testimonialCourseController.text,
                                  'content': _testimonialContentController.text,
                                  'rating': _testimonialRating,
                                  'photoUrl': photoUrl ?? '',
                                  'timestamp':
                                      DateTime.now().millisecondsSinceEpoch,
                                };

                                List updatedTestimonials = [
                                  ...testimonials,
                                  newTestimonial
                                ];
                                final updatedData = {
                                  ...websiteData,
                                  'testimonials': updatedTestimonials,
                                };

                                await _saveWebsiteData(updatedData);
                                _testimonialNameController.clear();
                                _testimonialCourseController.clear();
                                _testimonialContentController.clear();
                                setState(() {
                                  _testimonialPhoto = null;
                                  _testimonialRating = 5.0;
                                  _isLoading = false;
                                });
                                await _refreshData();
                              },
                              icon: const Icon(Icons.add),
                              label: const Text('Add Testimonial'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorManager.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
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
            'Current Testimonials',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),

          // List of existing testimonials
          Expanded(
            child: testimonials.isEmpty
                ? Center(
                    child: Text(
                      'No testimonials yet',
                      style: TextStyle(
                        color: ColorManager.textMedium,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: testimonials.length,
                    itemBuilder: (context, index) {
                      final testimonial = testimonials[index];
                      final String name = testimonial['name'] ?? 'Student';
                      final String courseName = testimonial['courseName'] ?? '';
                      final String content = testimonial['content'] ?? '';
                      final double rating = testimonial['rating'] is int
                          ? (testimonial['rating'] as int).toDouble()
                          : (testimonial['rating'] as double? ?? 5.0);
                      final String photoUrl = testimonial['photoUrl'] ?? '';

                      return Dismissible(
                        key: Key(
                            'testimonial-$index-${testimonial['timestamp']}'),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          child: const Icon(
                            Icons.delete,
                            color: Colors.white,
                          ),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          List updatedTestimonials = List.from(testimonials)
                            ..removeAt(index);
                          final updatedData = {
                            ...websiteData,
                            'testimonials': updatedTestimonials,
                          };

                          _saveWebsiteData(updatedData).then((_) {
                            _refreshData();
                          });
                        },
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Padding(
                            padding: const EdgeInsets.all(12.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Photo
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color:
                                        ColorManager.primary.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: photoUrl.isNotEmpty
                                      ? ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(30),
                                          child: Image.network(
                                            photoUrl,
                                            fit: BoxFit.cover,
                                            width: 60,
                                            height: 60,
                                            errorBuilder:
                                                (context, error, stackTrace) =>
                                                    Icon(
                                              Icons.person,
                                              color: ColorManager.primary,
                                              size: 30,
                                            ),
                                          ),
                                        )
                                      : Icon(
                                          Icons.person,
                                          color: ColorManager.primary,
                                          size: 30,
                                        ),
                                ),
                                const SizedBox(width: 12),

                                // Content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete,
                                                color: Colors.red, size: 20),
                                            onPressed: () {
                                              List updatedTestimonials =
                                                  List.from(testimonials)
                                                    ..removeAt(index);
                                              final updatedData = {
                                                ...websiteData,
                                                'testimonials':
                                                    updatedTestimonials,
                                              };

                                              _saveWebsiteData(updatedData)
                                                  .then((_) {
                                                _refreshData();
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                      Text(
                                        courseName,
                                        style: TextStyle(
                                          color: ColorManager.textMedium,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: List.generate(
                                          5,
                                          (i) => Icon(
                                            i < rating.floor()
                                                ? Icons.star
                                                : Icons.star_border,
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
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
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
