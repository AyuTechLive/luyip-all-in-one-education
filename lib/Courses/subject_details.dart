import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:luyip_website_edu/Courses/videoplayer.dart';
import 'package:luyip_website_edu/exams/test_list_page.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class SubjectDetailPage extends StatefulWidget {
  final String subjectId;
  final String subjectName;
  final String courseName;

  const SubjectDetailPage({
    super.key,
    required this.subjectId,
    required this.subjectName,
    required this.courseName,
  });

  @override
  State<SubjectDetailPage> createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Future<Map<String, List<Map<String, dynamic>>>> _contentFuture;
  String userRole = 'student'; // Default role
  int testsCount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // Changed to 6 tabs
    _contentFuture = _fetchContent();
    _fetchUserRole();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserRole() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null && currentUser.email != null) {
        // Check for admin
        final adminSnapshot = await FirebaseDatabase.instance
            .ref('Admins')
            .orderByChild('email')
            .equalTo(currentUser.email)
            .once();

        if (adminSnapshot.snapshot.value != null) {
          setState(() {
            userRole = 'admin';
          });
          return;
        }

        // Check for teacher
        final teacherSnapshot = await FirebaseDatabase.instance
            .ref('Teachers')
            .orderByChild('email')
            .equalTo(currentUser.email)
            .once();

        if (teacherSnapshot.snapshot.value != null) {
          setState(() {
            userRole = 'teacher';
          });
          return;
        }
      }
    } catch (e) {
      print('Error fetching user role: ${e.toString()}');
    }
  }

  void _navigateToVideoPlayer(String videoUrl, String title, String subtitle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VideoPlayerPage(
          videoUrl: videoUrl,
          title: title,
          subtitle: subtitle,
        ),
      ),
    );
  }

  void _navigateToTestList() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TestListPage(
          courseName: widget.courseName,
          subjectName: widget.subjectId,
          userRole: userRole,
        ),
      ),
    );
  }

  Future<Map<String, List<Map<String, dynamic>>>> _fetchContent() async {
    Map<String, List<Map<String, dynamic>>> content = {
      'lectures': [],
      'notes': [],
      'dpp': [],
      'dppPdf': [],
      'dppVideos': [],
      'tests': [], // Added tests list
    };

    try {
      // Fetch Lectures/Videos
      final videosRef = FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(widget.subjectId)
          .child('Videos');

      DatabaseEvent videosEvent = await videosRef.once();

      if (videosEvent.snapshot.value != null) {
        Map<dynamic, dynamic> videosData =
            videosEvent.snapshot.value as Map<dynamic, dynamic>;

        videosData.forEach((key, value) {
          if (value is Map) {
            content['lectures']!.add({
              'id': value['id'] ?? key.toString(),
              'title': value['Title'] ?? 'No Title',
              'subtitle': value['Subtitle'] ?? '',
              'videoUrl': value['Video Link'] ?? '',
              'timestamp': value['timestamp'] ?? 0,
              'lectureName': key.toString(),
            });
          }
        });

        // Sort lectures by id (assuming it's a number)
        content['lectures']!.sort(
          (a, b) => int.parse(
            a['id'].toString(),
          ).compareTo(int.parse(b['id'].toString())),
        );
      }

      // Fetch Tests
      final testsRef = FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(widget.subjectId)
          .child('Tests');

      DatabaseEvent testsEvent = await testsRef.once();

      if (testsEvent.snapshot.value != null) {
        Map<dynamic, dynamic> testsData =
            testsEvent.snapshot.value as Map<dynamic, dynamic>;

        testsData.forEach((key, value) {
          if (value is Map) {
            // Only add active tests for students, show all for teachers/admins
            bool isActive = value['isActive'] ?? false;
            if (userRole != 'student' || isActive) {
              content['tests']!.add({
                'id': key.toString(),
                'title': value['title'] ?? 'No Title',
                'description': value['description'] ?? '',
                'totalMarks': value['totalMarks'] ?? 0,
                'durationMinutes': value['durationMinutes'] ?? 0,
                'isActive': isActive,
                'createdAt': value['createdAt'] ?? 0,
              });
            }
          }
        });

        // Sort tests by creation date (newest first)
        content['tests']!.sort(
          (a, b) => (b['createdAt'] as int).compareTo(a['createdAt'] as int),
        );

        testsCount = content['tests']!.length;
      }

      // Fetch DPP
      final dppRef = FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(widget.subjectId)
          .child('DPP');

      DatabaseEvent dppEvent = await dppRef.once();

      if (dppEvent.snapshot.value != null) {
        Map<dynamic, dynamic> dppData =
            dppEvent.snapshot.value as Map<dynamic, dynamic>;

        dppData.forEach((key, value) {
          if (value is Map) {
            content['dpp']!.add({
              'id': value['id'] ?? key.toString(),
              'title': value['Title'] ?? 'No Title',
              'subtitle': value['Subtitle'] ?? '',
              'pdfUrl': value['PDF Link'] ?? '',
              'timestamp': value['timestamp'] ?? 0,
              'dppName': key.toString(),
            });
          }
        });

        // Sort DPP by id
        content['dpp']!.sort(
          (a, b) => int.parse(
            a['id'].toString(),
          ).compareTo(int.parse(b['id'].toString())),
        );
      }

      // Fetch DPP PDF
      final dppPdfRef = FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(widget.subjectId)
          .child('DPP PDF');

      DatabaseEvent dppPdfEvent = await dppPdfRef.once();

      if (dppPdfEvent.snapshot.value != null) {
        Map<dynamic, dynamic> dppPdfData =
            dppPdfEvent.snapshot.value as Map<dynamic, dynamic>;

        dppPdfData.forEach((key, value) {
          if (value is Map) {
            content['dppPdf']!.add({
              'id': value['id'] ?? key.toString(),
              'title': value['Title'] ?? 'No Title',
              'subtitle': value['Subtitle'] ?? '',
              'pdfUrl': value['PDF Link'] ?? '',
              'timestamp': value['timestamp'] ?? 0,
              'pdfName': key.toString(),
            });
          }
        });

        // Sort DPP PDF by id
        content['dppPdf']!.sort(
          (a, b) => int.parse(
            a['id'].toString(),
          ).compareTo(int.parse(b['id'].toString())),
        );
      }

      // Fetch DPP VIDEOS
      final dppVideosRef = FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(widget.subjectId)
          .child('DPP VIDEOS');

      DatabaseEvent dppVideosEvent = await dppVideosRef.once();

      if (dppVideosEvent.snapshot.value != null) {
        Map<dynamic, dynamic> dppVideosData =
            dppVideosEvent.snapshot.value as Map<dynamic, dynamic>;

        dppVideosData.forEach((key, value) {
          if (value is Map) {
            content['dppVideos']!.add({
              'id': value['id'] ?? key.toString(),
              'title': value['Title'] ?? 'No Title',
              'subtitle': value['Subtitle'] ?? '',
              'videoUrl': value['Video Link'] ?? '',
              'timestamp': value['timestamp'] ?? 0,
              'videoName': key.toString(),
            });
          }
        });

        // Sort DPP Videos by id
        content['dppVideos']!.sort(
          (a, b) => int.parse(
            a['id'].toString(),
          ).compareTo(int.parse(b['id'].toString())),
        );
      }

      // Fetch Notes
      final notesRef = FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(widget.subjectId)
          .child('Notes');

      DatabaseEvent notesEvent = await notesRef.once();

      if (notesEvent.snapshot.value != null) {
        Map<dynamic, dynamic> notesData =
            notesEvent.snapshot.value as Map<dynamic, dynamic>;

        notesData.forEach((key, value) {
          if (value is Map) {
            content['notes']!.add({
              'id': value['id'] ?? key.toString(),
              'title': value['Title'] ?? 'No Title',
              'subtitle': value['Subtitle'] ?? '',
              'pdfUrl': value['PDF Link'] ?? '',
              'timestamp': value['timestamp'] ?? 0,
              'noteName': key.toString(),
            });
          }
        });

        // Sort Notes by id
        content['notes']!.sort(
          (a, b) => int.parse(
            a['id'].toString(),
          ).compareTo(int.parse(b['id'].toString())),
        );
      }

      return content;
    } catch (e) {
      Utils().toastMessage('Error fetching content: ${e.toString()}');
      return content;
    }
  }

  // void _launchURL(String url) async {
  //   try {
  //     if (await canLaunch(url)) {
  //       await launch(url);
  //     } else {
  //       Utils().toastMessage('Could not launch $url');
  //     }
  //   } catch (e) {
  //     Utils().toastMessage('Error launching URL: ${e.toString()}');
  //   }
  // }

  Widget _buildContentList(List<Map<String, dynamic>> items, String type) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForContentType(type),
              size: 64,
              color: ColorManager.textMedium.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No $type available for this subject',
              style: TextStyle(color: ColorManager.textMedium),
            ),
          ],
        ),
      );
    }

    if (type == 'tests') {
      return _buildTestsList(items);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              decoration: BoxDecoration(
                color: _getColorForContentType(type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(
                _getIconForContentType(type),
                color: _getColorForContentType(type),
                size: 24,
              ),
            ),
            title: Text(
              item['title'] ?? 'No Title',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: ColorManager.textDark,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item['subtitle'] != null &&
                    item['subtitle'].toString().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item['subtitle'],
                      style: TextStyle(color: ColorManager.textMedium),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    type == 'lectures' || type == 'dppVideos'
                        ? 'Click to watch video'
                        : 'Click to view PDF',
                    style: TextStyle(color: ColorManager.primary, fontSize: 12),
                  ),
                ),
              ],
            ),
            trailing: Icon(
              Icons.play_circle_outline,
              color: ColorManager.primary,
            ),
            onTap: () {
              if (type == 'lectures' || type == 'dppVideos') {
                if (item['videoUrl'] != null &&
                    item['videoUrl'].toString().isNotEmpty) {
                  _navigateToVideoPlayer(
                    item['videoUrl'],
                    item['title'] ?? 'Video Player',
                    item['subtitle'] ?? '',
                  );
                } else {
                  Utils().toastMessage('Video URL not available');
                }
              } else {
                if (item['pdfUrl'] != null &&
                    item['pdfUrl'].toString().isNotEmpty) {
                  // _launchURL(item['pdfUrl']);
                } else {
                  Utils().toastMessage('PDF URL not available');
                }
              }
            },
          ),
        );
      },
    );
  }

  Widget _buildTestsList(List<Map<String, dynamic>> tests) {
    if (tests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz,
              size: 64,
              color: ColorManager.textMedium.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No tests available for this subject',
              style: TextStyle(color: ColorManager.textMedium),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff321f73),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: _navigateToTestList,
            icon: const Icon(Icons.quiz),
            label: Text(
              userRole == 'student' ? 'View All Tests' : 'Manage Tests',
              style: const TextStyle(fontSize: 16),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: tests.length,
            itemBuilder: (context, index) {
              final test = tests[index];
              final DateTime createdAt =
                  DateTime.fromMillisecondsSinceEpoch(test['createdAt'] as int);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: InkWell(
                  onTap: _navigateToTestList,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                test['title'] ?? 'No Title',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: ColorManager.textDark,
                                ),
                              ),
                            ),
                            if (userRole != 'student')
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: test['isActive'] == true
                                      ? Colors.green.withOpacity(0.1)
                                      : Colors.red.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  test['isActive'] == true
                                      ? 'Active'
                                      : 'Inactive',
                                  style: TextStyle(
                                    color: test['isActive'] == true
                                        ? Colors.green
                                        : Colors.red,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          test['description'] ?? '',
                          style: TextStyle(
                            color: ColorManager.textMedium,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildTestInfoChip(
                                Icons.timer, '${test['durationMinutes']} min'),
                            _buildTestInfoChip(
                                Icons.star, '${test['totalMarks']} marks'),
                            Text(
                              '${createdAt.day}/${createdAt.month}/${createdAt.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: ColorManager.textMedium,
                              ),
                            ),
                          ],
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
    );
  }

  Widget _buildTestInfoChip(IconData icon, String text) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: ColorManager.textMedium,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: ColorManager.textMedium,
          ),
        ),
      ],
    );
  }

  IconData _getIconForContentType(String type) {
    switch (type) {
      case 'lectures':
        return Icons.video_library;
      case 'notes':
        return Icons.notes;
      case 'dpp':
        return Icons.assignment;
      case 'dppPdf':
        return Icons.picture_as_pdf;
      case 'dppVideos':
        return Icons.play_circle_fill;
      case 'tests':
        return Icons.quiz;
      default:
        return Icons.article;
    }
  }

  Color _getColorForContentType(String type) {
    switch (type) {
      case 'lectures':
        return Colors.blue;
      case 'notes':
        return Colors.green;
      case 'dpp':
        return Colors.purple;
      case 'dppPdf':
        return Colors.red;
      case 'dppVideos':
        return Colors.orange;
      case 'tests':
        return Colors.amber;
      default:
        return ColorManager.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          widget.subjectName,
          style: TextStyle(
            color: ColorManager.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textDark),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: ColorManager.primary,
          unselectedLabelColor: ColorManager.textMedium,
          indicatorColor: ColorManager.primary,
          tabs: const [
            Tab(text: 'Lectures'),
            Tab(text: 'Notes'),
            Tab(text: 'Tests'), // Added Tests tab
            Tab(text: 'DPP'),
            Tab(text: 'DPP PDF'),
            Tab(text: 'DPP VIDEOS'),
          ],
        ),
      ),
      body: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(color: ColorManager.primary),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading content: ${snapshot.error}',
                style: TextStyle(color: ColorManager.textMedium),
              ),
            );
          }

          final content = snapshot.data ??
              {
                'lectures': [],
                'notes': [],
                'tests': [], // Added tests
                'dpp': [],
                'dppPdf': [],
                'dppVideos': [],
              };

          return TabBarView(
            controller: _tabController,
            children: [
              _buildContentList(content['lectures']!, 'lectures'),
              _buildContentList(content['notes']!, 'notes'),
              _buildContentList(
                  content['tests']!, 'tests'), // Added tests tab content
              _buildContentList(content['dpp']!, 'dpp'),
              _buildContentList(content['dppPdf']!, 'dppPdf'),
              _buildContentList(content['dppVideos']!, 'dppVideos'),
            ],
          );
        },
      ),
    );
  }
}
