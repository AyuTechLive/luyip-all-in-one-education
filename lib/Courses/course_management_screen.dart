import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_network/image_network.dart';

import 'package:luyip_website_edu/Courses/add_test.dart';
import 'package:luyip_website_edu/Courses/addvideo.dart';
import 'package:luyip_website_edu/Courses/subject_management.dart';
import 'package:luyip_website_edu/exams/test_list_page.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class CourseContentManagement extends StatefulWidget {
  final String courseName;

  const CourseContentManagement({
    Key? key,
    required this.courseName,
  }) : super(key: key);

  @override
  State<CourseContentManagement> createState() =>
      _CourseContentManagementState();
}

class _CourseContentManagementState extends State<CourseContentManagement>
    with SingleTickerProviderStateMixin {
  int _selectedTabIndex = 0;
  List<String> subjects = [];
  bool _isLoading = true;
  String? _courseImageUrl;
  Map<String, dynamic>? _courseData;
  String? _selectedSubject;
  late TabController _tabController;

  // Content lists
  List<Map<String, dynamic>> _notesList = [];
  List<Map<String, dynamic>> _dppList = [];
  List<Map<String, dynamic>> _videosList = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
    _fetchCourseDetails();
    _fetchSubjects();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchCourseDetails() async {
    try {
      final courseDoc = await FirebaseFirestore.instance
          .collection('All Courses')
          .doc(widget.courseName)
          .get();

      if (courseDoc.exists) {
        setState(() {
          _courseData = courseDoc.data();
          _courseImageUrl = _courseData?['Course Img Link'];
        });
      }
    } catch (e) {
      Utils().toastMessage('Error fetching course details: ${e.toString()}');
    }
  }

  Future<void> _fetchSubjects() async {
    try {
      final databaseRef =
          FirebaseDatabase.instance.ref(widget.courseName).child('SUBJECTS');
      DatabaseEvent event = await databaseRef.once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> subjectsData =
            event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          subjects = subjectsData.keys.map((key) => key.toString()).toList();
          if (subjects.isNotEmpty) {
            _selectedSubject = subjects[0];
            _fetchContentForSelectedSubject();
          }
        });
      } else {
        Utils().toastMessage('No subjects found for this course');
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Utils().toastMessage('Error fetching subjects: ${e.toString()}');
    }
  }

  Future<void> _fetchContentForSelectedSubject() async {
    if (_selectedSubject == null) return;

    setState(() {
      _isLoading = true;
      _notesList = [];
      _dppList = [];
      _videosList = [];
    });

    try {
      // Fetch Notes
      final notesRef = FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(_selectedSubject!)
          .child('Notes');

      DatabaseEvent notesEvent = await notesRef.once();

      if (notesEvent.snapshot.value != null) {
        Map<dynamic, dynamic> notesData =
            notesEvent.snapshot.value as Map<dynamic, dynamic>;

        notesData.forEach((key, value) {
          if (value is Map) {
            _notesList.add({
              'id': value['id'] ?? key.toString(),
              'title': value['title'] ?? 'No Title',
              'description': value['description'] ?? '',
              'url': value['url'] ?? '',
              'timestamp': value['timestamp'] ?? 0,
              'docKey': key.toString(),
            });
          }
        });

        _notesList.sort((a, b) {
          if (a['timestamp'] != 0 && b['timestamp'] != 0) {
            return (b['timestamp'] as int).compareTo(a['timestamp'] as int);
          }
          return a['id'].toString().compareTo(b['id'].toString());
        });
      }

      // Fetch DPP
      final dppRef = FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(_selectedSubject!)
          .child('DPP');

      DatabaseEvent dppEvent = await dppRef.once();

      if (dppEvent.snapshot.value != null) {
        Map<dynamic, dynamic> dppData =
            dppEvent.snapshot.value as Map<dynamic, dynamic>;

        dppData.forEach((key, value) {
          if (value is Map) {
            _dppList.add({
              'id': value['id'] ?? key.toString(),
              'title': value['title'] ?? 'No Title',
              'description': value['description'] ?? '',
              'url': value['url'] ?? '',
              'timestamp': value['timestamp'] ?? 0,
              'docKey': key.toString(),
            });
          }
        });

        _dppList.sort((a, b) {
          if (a['timestamp'] != 0 && b['timestamp'] != 0) {
            return (b['timestamp'] as int).compareTo(a['timestamp'] as int);
          }
          return a['id'].toString().compareTo(b['id'].toString());
        });
      }

      // Fetch Videos
      final videosRef = FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(_selectedSubject!)
          .child('Videos');

      DatabaseEvent videosEvent = await videosRef.once();

      if (videosEvent.snapshot.value != null) {
        Map<dynamic, dynamic> videosData =
            videosEvent.snapshot.value as Map<dynamic, dynamic>;

        videosData.forEach((key, value) {
          if (value is Map) {
            _videosList.add({
              'id': value['id'] ?? key.toString(),
              'title': value['Title'] ?? 'No Title',
              'subtitle': value['Subtitle'] ?? '',
              'videoUrl': value['Video Link'] ?? '',
              'timestamp': value['timestamp'] ?? 0,
              'docKey': key.toString(),
            });
          }
        });

        _videosList.sort((a, b) {
          if (a['timestamp'] != 0 && b['timestamp'] != 0) {
            return (b['timestamp'] as int).compareTo(a['timestamp'] as int);
          }
          try {
            return int.parse(a['id'].toString())
                .compareTo(int.parse(b['id'].toString()));
          } catch (e) {
            return a['id'].toString().compareTo(b['id'].toString());
          }
        });
      }
    } catch (e) {
      Utils().toastMessage('Error fetching content: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToAddDocument() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDocumentPage(
          courseName: widget.courseName,
          subjectName: _selectedSubject ?? '',
          documentType: 'notes',
        ),
      ),
    ).then((_) {
      _fetchContentForSelectedSubject();
    });
  }

  void _navigateToAddDpp() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddDocumentPage(
          courseName: widget.courseName,
          subjectName: _selectedSubject ?? '',
          documentType: 'dpp',
        ),
      ),
    ).then((_) {
      _fetchContentForSelectedSubject();
    });
  }

  void _navigateToEditDocument(Map<String, dynamic> document, String type) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditDocumentPage(
          courseName: widget.courseName,
          subjectName: _selectedSubject ?? '',
          documentType: type,
          document: document,
        ),
      ),
    ).then((_) {
      _fetchContentForSelectedSubject();
    });
  }

  void _navigateToAddVideos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddVideoPage(
            courseName: widget.courseName, subjectName: _selectedSubject ?? ''),
        settings: RouteSettings(
          arguments: {
            'courseName': widget.courseName,
            'selectedSubject': _selectedSubject,
          },
        ),
      ),
    ).then((_) {
      _fetchContentForSelectedSubject();
    });
  }

  void _navigateToEditVideo(Map<String, dynamic> video) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVideoPage(
          courseName: widget.courseName,
          subjectName: _selectedSubject ?? '',
          video: video,
        ),
      ),
    ).then((_) {
      _fetchContentForSelectedSubject();
    });
  }

  void _navigateToAddTests() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTestAdmin(),
        settings: RouteSettings(
          arguments: {
            'courseName': widget.courseName,
            'selectedSubject': _selectedSubject,
          },
        ),
      ),
    );
  }

  void _navigateToTestList() {
    if (_selectedSubject != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestListPage(
            courseName: widget.courseName,
            subjectName: _selectedSubject!,
            userRole: 'admin',
          ),
        ),
      );
    } else {
      Utils().toastMessage('Please select a subject first');
    }
  }

  Future<void> _confirmDelete(Map<String, dynamic> item, String type) async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.warning_rounded,
                    color: Colors.red,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Confirm Delete',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            content: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Are you sure you want to delete "${item['title']}"?\n\nThis action cannot be undone.',
                style: const TextStyle(fontSize: 16, height: 1.5),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    setState(() {
      _isLoading = true;
    });

    try {
      String folderName = "";
      if (type == 'notes') {
        folderName = "Notes";
      } else if (type == 'dpp') {
        folderName = "DPP";
      } else if (type == 'videos') {
        folderName = "Videos";
      }

      await FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(_selectedSubject!)
          .child(folderName)
          .child(item['docKey'])
          .remove();

      if (type == 'notes' || type == 'dpp') {
        final courseDoc = await FirebaseFirestore.instance
            .collection('All Courses')
            .doc(widget.courseName)
            .get();

        if (courseDoc.exists && courseDoc.data()!.containsKey('KeyDocuments')) {
          List<dynamic> keyDocs = List.from(courseDoc.data()!['KeyDocuments']);

          keyDocs.removeWhere((doc) =>
              doc['url'] == item['url'] ||
              (doc['title'] == item['title'] &&
                  doc['subject'] == _selectedSubject));

          await FirebaseFirestore.instance
              .collection('All Courses')
              .doc(widget.courseName)
              .update({'KeyDocuments': keyDocs});
        }
      }

      Utils().toastMessage('Item deleted successfully');
      _fetchContentForSelectedSubject();
    } catch (e) {
      Utils().toastMessage('Error deleting item: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            _buildSliverAppBar(),
          ];
        },
        body: _isLoading
            ? _buildLoadingState()
            : Column(
                children: [
                  _buildEnhancedHeader(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildNotesTab(),
                        _buildDppTab(),
                        _buildVideosTab(),
                        _buildTestsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
      floatingActionButton: _buildEnhancedFAB(),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: ColorManager.textDark,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                ColorManager.primary.withOpacity(0.9),
                ColorManager.primary,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.admin_panel_settings,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Course Management',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage course content and materials',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: ColorManager.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: ColorManager.primary,
            unselectedLabelColor: Colors.grey.shade600,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
            tabs: const [
              Tab(
                icon: Icon(Icons.description, size: 20),
                text: 'Notes',
              ),
              Tab(
                icon: Icon(Icons.assignment, size: 20),
                text: 'DPP',
              ),
              Tab(
                icon: Icon(Icons.video_library, size: 20),
                text: 'Videos',
              ),
              Tab(
                icon: Icon(Icons.quiz, size: 20),
                text: 'Tests',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CircularProgressIndicator(
                color: ColorManager.primary,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Loading course content...',
              style: TextStyle(
                fontSize: 16,
                color: ColorManager.textMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Course info card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: ColorManager.primary.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: _courseImageUrl != null
                        ? ImageNetwork(
                            image: _courseImageUrl!,
                            width: 60,
                            height: 60,
                            fitAndroidIos: BoxFit.cover,
                            onLoading: Container(
                              color: ColorManager.primary.withOpacity(0.1),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: ColorManager.primary,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            onError: Container(
                              decoration: BoxDecoration(
                                color: ColorManager.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Icons.school,
                                color: ColorManager.primary,
                                size: 30,
                              ),
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: ColorManager.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Icon(
                              Icons.school,
                              color: ColorManager.primary,
                              size: 30,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Managing Course',
                        style: TextStyle(
                          color: ColorManager.textMedium,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.courseName,
                        style: TextStyle(
                          color: ColorManager.textDark,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: ColorManager.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: _navigateToSubjectManagement,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.settings,
                          color: ColorManager.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Manage',
                          style: TextStyle(
                            color: ColorManager.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Subject selector
          _buildSubjectSelector(),
        ],
      ),
    );
  }

  Widget _buildSubjectSelector() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.subject,
              color: ColorManager.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'Subject:',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSubject,
                  hint: Text(
                    'Select Subject',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  isExpanded: true,
                  icon: Icon(Icons.keyboard_arrow_down,
                      color: ColorManager.primary),
                  onChanged: (String? newValue) {
                    if (newValue == 'ADD_NEW') {
                      _showAddSubjectDialog();
                    } else {
                      setState(() {
                        _selectedSubject = newValue;
                      });
                      _fetchContentForSelectedSubject();
                    }
                  },
                  items: [
                    ...subjects.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      );
                    }).toList(),
                    DropdownMenuItem<String>(
                      value: 'ADD_NEW',
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_circle_outline,
                            size: 18,
                            color: ColorManager.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Add New Subject',
                            style: TextStyle(
                              color: ColorManager.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedFAB() {
    final fabConfigs = [
      {
        'icon': Icons.note_add,
        'label': 'Add Note',
        'color': Colors.green,
        'onPressed': _navigateToAddDocument,
      },
      {
        'icon': Icons.assignment_add,
        'label': 'Add DPP',
        'color': Colors.purple,
        'onPressed': _navigateToAddDpp,
      },
      {
        'icon': Icons.video_call,
        'label': 'Add Video',
        'color': Colors.blue,
        'onPressed': _navigateToAddVideos,
      },
      {
        'icon': Icons.quiz,
        'label': 'Add Test',
        'color': Colors.orange,
        'onPressed': _navigateToAddTests,
      },
    ];

    final config = fabConfigs[_selectedTabIndex];

    return FloatingActionButton.extended(
      onPressed: config['onPressed'] as VoidCallback,
      backgroundColor: config['color'] as Color,
      foregroundColor: Colors.white,
      elevation: 8,
      icon: Icon(config['icon'] as IconData, size: 20),
      label: Text(
        config['label'] as String,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildTestsTab() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.orange.withOpacity(0.1),
                    Colors.orange.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.quiz,
                size: 60,
                color: Colors.orange,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Test Management Hub',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: ColorManager.textDark,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Create and manage assessments for ${widget.courseName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: ColorManager.textMedium,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildTestActionCard(
                  'Create New Test',
                  'Design fresh assessments',
                  Icons.add_task,
                  Colors.orange,
                  _navigateToAddTests,
                ),
                const SizedBox(width: 20),
                _buildTestActionCard(
                  'Manage Tests',
                  'Edit existing assessments',
                  Icons.edit_note,
                  ColorManager.primary,
                  _navigateToTestList,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTestActionCard(
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: ColorManager.textMedium,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddSubjectDialog() {
    final TextEditingController subjectController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: ColorManager.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.add_circle_outline,
                  color: ColorManager.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Add New Subject',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: TextField(
              controller: subjectController,
              decoration: InputDecoration(
                hintText: 'Enter subject name',
                labelText: 'Subject Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.subject),
              ),
              autofocus: true,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (subjectController.text.trim().isNotEmpty) {
                  Navigator.of(context).pop();
                  await _addNewSubject(subjectController.text.trim());
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Add Subject'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addNewSubject(String subjectName) async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (subjects.contains(subjectName)) {
        Utils().toastMessage('Subject already exists');
        setState(() {
          _selectedSubject = subjectName;
          _isLoading = false;
        });
        _fetchContentForSelectedSubject();
        return;
      }

      await FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(subjectName)
          .set({
        'name': subjectName,
        'timestamp': ServerValue.timestamp,
      });

      setState(() {
        subjects.add(subjectName);
        _selectedSubject = subjectName;
      });

      Utils().toastMessage('Subject added successfully');
      _fetchContentForSelectedSubject();
    } catch (e) {
      Utils().toastMessage('Error adding subject: ${e.toString()}');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _navigateToSubjectManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectManagementPage(
          courseName: widget.courseName,
        ),
      ),
    ).then((_) {
      _fetchSubjects();
    });
  }

  Widget _buildNotesTab() {
    return _buildContentTab(
      items: _notesList,
      type: 'notes',
      emptyIcon: Icons.description,
      emptyTitle: 'No Study Notes Yet',
      emptySubtitle:
          'Start building your knowledge base by adding comprehensive study notes',
      addAction: _navigateToAddDocument,
      color: Colors.green,
    );
  }

  Widget _buildDppTab() {
    return _buildContentTab(
      items: _dppList,
      type: 'dpp',
      emptyIcon: Icons.assignment,
      emptyTitle: 'No Practice Problems Yet',
      emptySubtitle:
          'Enhance learning with daily practice problems and exercises',
      addAction: _navigateToAddDpp,
      color: Colors.purple,
    );
  }

  Widget _buildVideosTab() {
    return _buildContentTab(
      items: _videosList,
      type: 'videos',
      emptyIcon: Icons.video_library,
      emptyTitle: 'No Video Lectures Yet',
      emptySubtitle:
          'Create engaging video content to enhance the learning experience',
      addAction: _navigateToAddVideos,
      color: Colors.blue,
    );
  }

  Widget _buildContentTab({
    required List<Map<String, dynamic>> items,
    required String type,
    required IconData emptyIcon,
    required String emptyTitle,
    required String emptySubtitle,
    required VoidCallback addAction,
    required Color color,
  }) {
    if (items.isEmpty) {
      return _buildEmptyState(
        icon: emptyIcon,
        title: emptyTitle,
        subtitle: emptySubtitle,
        actionText:
            'Add ${type == 'notes' ? 'Notes' : type == 'dpp' ? 'DPP' : 'Videos'}',
        onAction: addAction,
        color: color,
      );
    }

    return Container(
      color: Colors.grey.shade50,
      child: ListView.builder(
        padding: const EdgeInsets.all(20),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildEnhancedContentCard(item, type);
        },
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String actionText,
    required VoidCallback onAction,
    required Color color,
  }) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  icon,
                  size: 64,
                  color: color.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                title,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.textDark,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 16,
                  color: ColorManager.textMedium,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              ElevatedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add, size: 20),
                label: Text(actionText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedContentCard(Map<String, dynamic> item, String type) {
    Color typeColor;
    IconData typeIcon;
    String title;
    String description;
    String subtitle;

    if (type == 'videos') {
      typeIcon = Icons.play_circle_filled;
      typeColor = Colors.blue;
      title = item['title'] ?? 'No Title';
      description = item['subtitle'] ?? '';
      subtitle = 'Video Lecture';
    } else {
      typeIcon = type == 'notes' ? Icons.description : Icons.assignment;
      typeColor = type == 'notes' ? Colors.green : Colors.purple;
      title = item['title'] ?? 'No Title';
      description = item['description'] ?? '';
      subtitle = type == 'notes' ? 'Study Notes' : 'Practice Problem';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (type == 'videos') {
              _navigateToEditVideo(item);
            } else {
              _navigateToEditDocument(item, type);
            }
          },
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: typeColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        typeIcon,
                        color: typeColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: ColorManager.textDark,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: typeColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  subtitle,
                                  style: TextStyle(
                                    color: typeColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              description,
                              style: TextStyle(
                                color: ColorManager.textMedium,
                                fontSize: 14,
                                height: 1.4,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _formatTimestamp(item['timestamp']),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildActionButton(
                      icon: Icons.edit,
                      color: ColorManager.primary,
                      onPressed: () {
                        if (type == 'videos') {
                          _navigateToEditVideo(item);
                        } else {
                          _navigateToEditDocument(item, type);
                        }
                      },
                    ),
                    const SizedBox(width: 8),
                    _buildActionButton(
                      icon: Icons.delete,
                      color: Colors.red,
                      onPressed: () => _confirmDelete(item, type),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Icon(
              icon,
              color: color,
              size: 16,
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null || timestamp == 0) {
      return 'No date';
    }

    try {
      final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Invalid date';
    }
  }
}

// Enhanced Add Document Page
class AddDocumentPage extends StatefulWidget {
  final String courseName;
  final String subjectName;
  final String documentType;

  const AddDocumentPage({
    Key? key,
    required this.courseName,
    required this.subjectName,
    required this.documentType,
  }) : super(key: key);

  @override
  State<AddDocumentPage> createState() => _AddDocumentPageState();
}

class _AddDocumentPageState extends State<AddDocumentPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  bool _isLoading = false;
  List<String> subjects = [];
  String? _selectedSubject;

  @override
  void initState() {
    super.initState();
    _fetchSubjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _fetchSubjects() async {
    try {
      final databaseRef =
          FirebaseDatabase.instance.ref(widget.courseName).child('SUBJECTS');
      DatabaseEvent event = await databaseRef.once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> subjectsData =
            event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          subjects = subjectsData.keys.map((key) => key.toString()).toList();
          _selectedSubject = widget.subjectName.isNotEmpty
              ? widget.subjectName
              : (subjects.isNotEmpty ? subjects[0] : null);
        });
      }
    } catch (e) {
      Utils().toastMessage('Error fetching subjects: ${e.toString()}');
    }
  }

  Future<void> _saveDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubject == null) {
      Utils().toastMessage('Please select a subject');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final documentId = 'doc_${DateTime.now().millisecondsSinceEpoch}';

      if (!subjects.contains(_selectedSubject)) {
        await FirebaseDatabase.instance
            .ref(widget.courseName)
            .child('SUBJECTS')
            .child(_selectedSubject!)
            .set({
          'name': _selectedSubject,
          'timestamp': ServerValue.timestamp,
        });

        setState(() {
          subjects.add(_selectedSubject!);
        });
      }

      String folderName = widget.documentType == 'notes' ? "Notes" : "DPP";

      await FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(_selectedSubject!)
          .child(folderName)
          .child(documentId)
          .set({
        'id': documentId,
        'title': _titleController.text,
        'description': _descriptionController.text,
        'url': _urlController.text,
        'type': widget.documentType,
        'timestamp': ServerValue.timestamp,
      });

      await FirebaseFirestore.instance
          .collection('All Courses')
          .doc(widget.courseName)
          .update({
        'KeyDocuments': FieldValue.arrayUnion([
          {
            'title': _titleController.text,
            'description': _descriptionController.text,
            'url': _urlController.text,
            'type': widget.documentType,
            'subject': _selectedSubject,
          }
        ]),
      });

      Utils().toastMessage('Document successfully added');
      Navigator.pop(context);
    } catch (e) {
      Utils().toastMessage('Error adding document: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: ColorManager.textDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: (widget.documentType == 'notes'
                        ? Colors.green
                        : Colors.purple)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                widget.documentType == 'notes'
                    ? Icons.description
                    : Icons.assignment,
                color: widget.documentType == 'notes'
                    ? Colors.green
                    : Colors.purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              'Add ${widget.documentType == 'notes' ? 'Study Notes' : 'Practice Problems'}',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: ColorManager.primary),
                    const SizedBox(height: 16),
                    const Text('Saving document...'),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSubjectSelector(),
                        const SizedBox(height: 24),
                        _buildFormField(
                          controller: _titleController,
                          label: 'Document Title',
                          hint: 'Enter a descriptive title',
                          icon: Icons.title,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter document title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildFormField(
                          controller: _descriptionController,
                          label: 'Description',
                          hint: 'Provide a detailed description',
                          icon: Icons.description,
                          maxLines: 4,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter document description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 20),
                        _buildFormField(
                          controller: _urlController,
                          label: 'Document URL',
                          hint: 'Enter the document link',
                          icon: Icons.link,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter document URL';
                            }
                            if (!Uri.parse(value).isAbsolute) {
                              return 'Please enter a valid URL';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildSubjectSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedSubject,
              hint: const Text('Select Subject'),
              isExpanded: true,
              icon:
                  Icon(Icons.keyboard_arrow_down, color: ColorManager.primary),
              onChanged: (String? newValue) {
                setState(() {
                  _selectedSubject = newValue;
                });
              },
              items: subjects.map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: ColorManager.primary),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: ColorManager.primary, width: 2),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveDocument,
        style: ElevatedButton.styleFrom(
          backgroundColor:
              widget.documentType == 'notes' ? Colors.green : Colors.purple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
        ),
        child: _isLoading
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
                  SizedBox(width: 16),
                  Text('Saving...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.documentType == 'notes'
                        ? Icons.description
                        : Icons.assignment,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Save Document',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// Similar enhancements for EditDocumentPage and EditVideoPage would follow the same pattern

// Create a separate page for editing documents (Notes and DPP)
class EditDocumentPage extends StatefulWidget {
  final String courseName;
  final String subjectName;
  final String documentType; // 'notes' or 'dpp'
  final Map<String, dynamic> document;

  const EditDocumentPage({
    Key? key,
    required this.courseName,
    required this.subjectName,
    required this.documentType,
    required this.document,
  }) : super(key: key);

  @override
  State<EditDocumentPage> createState() => _EditDocumentPageState();
}

class _EditDocumentPageState extends State<EditDocumentPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _urlController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing document data
    _titleController =
        TextEditingController(text: widget.document['title'] ?? '');
    _descriptionController =
        TextEditingController(text: widget.document['description'] ?? '');
    _urlController = TextEditingController(text: widget.document['url'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _updateDocument() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final documentId = widget.document['id'];
      final docKey = widget.document['docKey'];

      // Define folder name based on document type
      String folderName = widget.documentType == 'notes' ? "Notes" : "DPP";

      // Update in Realtime Database
      await FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(widget.subjectName)
          .child(folderName)
          .child(docKey)
          .update({
        'title': _titleController.text,
        'description': _descriptionController.text,
        'url': _urlController.text,
        'timestamp': ServerValue.timestamp,
      });

      // Update in KeyDocuments array in Firestore
      final courseDoc = await FirebaseFirestore.instance
          .collection('All Courses')
          .doc(widget.courseName)
          .get();

      if (courseDoc.exists && courseDoc.data()!.containsKey('KeyDocuments')) {
        List<dynamic> keyDocs = List.from(courseDoc.data()!['KeyDocuments']);

        // Find and update the matching document
        bool docFound = false;
        for (int i = 0; i < keyDocs.length; i++) {
          // Match based on URL or title/subject combo
          if (keyDocs[i]['url'] == widget.document['url'] ||
              (keyDocs[i]['title'] == widget.document['title'] &&
                  keyDocs[i]['subject'] == widget.subjectName)) {
            keyDocs[i] = {
              'title': _titleController.text,
              'description': _descriptionController.text,
              'url': _urlController.text,
              'type': widget.documentType,
              'subject': widget.subjectName,
            };
            docFound = true;
            break;
          }
        }

        // If match not found, add as new
        if (!docFound) {
          keyDocs.add({
            'title': _titleController.text,
            'description': _descriptionController.text,
            'url': _urlController.text,
            'type': widget.documentType,
            'subject': widget.subjectName,
          });
        }

        // Update the KeyDocuments array
        await FirebaseFirestore.instance
            .collection('All Courses')
            .doc(widget.courseName)
            .update({'KeyDocuments': keyDocs});
      }

      Utils().toastMessage('Document successfully updated');
      Navigator.pop(context); // Return to the previous screen
    } catch (e) {
      Utils().toastMessage('Error updating document: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorManager.primary,
        foregroundColor: Colors.white,
        title: Text('Edit ${widget.documentType == 'notes' ? 'Notes' : 'DPP'}'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: ColorManager.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Document ID display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Document ID: ${widget.document['id']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorManager.textMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Document Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Document Title',
                        hintText: 'Enter document title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter document title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Document Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Document Description',
                        hintText: 'Enter document description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter document description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Document URL
                    TextFormField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'Document URL',
                        hintText: 'Enter document URL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.link),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter document URL';
                        }
                        if (!Uri.parse(value).isAbsolute) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateDocument,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? Row(
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
                                  const SizedBox(width: 12),
                                  const Text('Updating...'),
                                ],
                              )
                            : const Text('Update Document'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

// Create a separate page for editing videos
class EditVideoPage extends StatefulWidget {
  final String courseName;
  final String subjectName;
  final Map<String, dynamic> video;

  const EditVideoPage({
    Key? key,
    required this.courseName,
    required this.subjectName,
    required this.video,
  }) : super(key: key);

  @override
  State<EditVideoPage> createState() => _EditVideoPageState();
}

class _EditVideoPageState extends State<EditVideoPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _subtitleController;
  late final TextEditingController _videoUrlController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing video data
    _titleController = TextEditingController(text: widget.video['title'] ?? '');
    _subtitleController =
        TextEditingController(text: widget.video['subtitle'] ?? '');
    _videoUrlController =
        TextEditingController(text: widget.video['videoUrl'] ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _updateVideo() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final docKey = widget.video['docKey'];

      // Update in Realtime Database
      await FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(widget.subjectName)
          .child('Videos')
          .child(docKey)
          .update({
        'Title': _titleController.text,
        'Subtitle': _subtitleController.text,
        'Video Link': _videoUrlController.text,
        'timestamp': ServerValue.timestamp,
      });

      Utils().toastMessage('Video successfully updated');
      Navigator.pop(context); // Return to the previous screen
    } catch (e) {
      Utils().toastMessage('Error updating video: ${e.toString()}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorManager.primary,
        foregroundColor: Colors.white,
        title: const Text('Edit Video'),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: ColorManager.primary),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Video ID display
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Video ID: ${widget.video['id']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorManager.textMedium,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Video Title
                    TextFormField(
                      controller: _titleController,
                      decoration: InputDecoration(
                        labelText: 'Video Title',
                        hintText: 'Enter video title',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.title),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter video title';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Video Subtitle
                    TextFormField(
                      controller: _subtitleController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Video Subtitle',
                        hintText: 'Enter video subtitle or description',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.description),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter video subtitle';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Video URL
                    TextFormField(
                      controller: _videoUrlController,
                      decoration: InputDecoration(
                        labelText: 'Video URL',
                        hintText: 'Enter video URL',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        prefixIcon: const Icon(Icons.link),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter video URL';
                        }
                        if (!Uri.parse(value).isAbsolute) {
                          return 'Please enter a valid URL';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _updateVideo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? Row(
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
                                  const SizedBox(width: 12),
                                  const Text('Updating...'),
                                ],
                              )
                            : const Text('Update Video'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
