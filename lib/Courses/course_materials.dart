import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:luyip_website_edu/Courses/subject_details.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class CourseMaterials extends StatefulWidget {
  final String courseName;

  const CourseMaterials({super.key, required this.courseName});

  @override
  State<CourseMaterials> createState() => _CourseMaterialsState();
}

class _CourseMaterialsState extends State<CourseMaterials> {
  late Future<List<Map<String, dynamic>>> _subjectsFuture;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _subjectsFuture = _fetchSubjects();
  }

  Future<List<Map<String, dynamic>>> _fetchSubjects() async {
    List<Map<String, dynamic>> subjects = [];

    try {
      // Use the same database reference structure as in AddLecturesAdmin
      final databaseRef =
          FirebaseDatabase.instance.ref(widget.courseName).child('SUBJECTS');
      DatabaseEvent event = await databaseRef.once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> subjectsData =
            event.snapshot.value as Map<dynamic, dynamic>;

        // Convert the data to the format expected by the UI
        subjectsData.forEach((key, value) {
          // Default icon based on subject name
          int iconCode = Icons.book.codePoint;

          // Try to get videos count if available
          int chaptersCount = 1;
          if (value is Map && value.containsKey('Videos')) {
            if (value['Videos'] is Map) {
              chaptersCount = (value['Videos'] as Map).length;
            }
          }

          subjects.add({
            'id': key,
            'name': key, // Subject name is the key in the database
            'icon': _getIconTypeForSubject(key.toString()),
            'chapters': chaptersCount,
          });
        });
      }

      return subjects;
    } catch (e) {
      Utils().toastMessage('Error fetching subjects: ${e.toString()}');
      return [];
    }
  }

  int _getIconCodeForSubject(String subjectName) {
    // Assign appropriate icons based on subject name
    String lowercaseSubject = subjectName.toLowerCase();

    if (lowercaseSubject.contains('notice')) return Icons.campaign.codePoint;
    if (lowercaseSubject.contains('strength')) return Icons.layers.codePoint;
    if (lowercaseSubject.contains('thermo')) return Icons.thermostat.codePoint;
    if (lowercaseSubject.contains('industrial')) return Icons.factory.codePoint;
    if (lowercaseSubject.contains('mechanic')) return Icons.article.codePoint;
    if (lowercaseSubject.contains('machine'))
      return Icons.precision_manufacturing.codePoint;
    if (lowercaseSubject.contains('heat')) return Icons.whatshot.codePoint;
    if (lowercaseSubject.contains('fluid')) return Icons.water.codePoint;
    if (lowercaseSubject.contains('design')) return Icons.settings.codePoint;
    if (lowercaseSubject.contains('material')) return Icons.science.codePoint;

    // Default icon
    return Icons.book.codePoint;
  }

  IconData _getIconData(String iconType) {
    // Map string identifiers to constant IconData objects
    switch (iconType) {
      case 'notice':
        return Icons.campaign;
      case 'strength':
        return Icons.layers;
      case 'thermo':
        return Icons.thermostat;
      case 'industrial':
        return Icons.factory;
      case 'mechanic':
        return Icons.article;
      case 'machine':
        return Icons.precision_manufacturing;
      case 'heat':
        return Icons.whatshot;
      case 'fluid':
        return Icons.water;
      case 'design':
        return Icons.settings;
      case 'material':
        return Icons.science;
      case 'book':
      default:
        return Icons.book;
    }
  }

  Color _getIconColor(Map<String, dynamic> subject) {
    // Generate a color based on the subject name
    final String name = subject['name'] as String;
    if (name.isEmpty) return ColorManager.primary;

    final int charCode = name.codeUnitAt(0);
    final List<Color> colors = [
      Colors.blue,
      Colors.green,
      Colors.purple,
      Colors.orange,
      Colors.pink,
      Colors.teal,
      Colors.indigo,
      Colors.red,
    ];

    return colors[charCode % colors.length];
  }

  String _getIconTypeForSubject(String subjectName) {
    // Assign appropriate icon types based on subject name
    String lowercaseSubject = subjectName.toLowerCase();

    if (lowercaseSubject.contains('notice')) return 'notice';
    if (lowercaseSubject.contains('strength')) return 'strength';
    if (lowercaseSubject.contains('thermo')) return 'thermo';
    if (lowercaseSubject.contains('industrial')) return 'industrial';
    if (lowercaseSubject.contains('mechanic')) return 'mechanic';
    if (lowercaseSubject.contains('machine')) return 'machine';
    if (lowercaseSubject.contains('heat')) return 'heat';
    if (lowercaseSubject.contains('fluid')) return 'fluid';
    if (lowercaseSubject.contains('design')) return 'design';
    if (lowercaseSubject.contains('material')) return 'material';

    // Default icon
    return 'book';
  }
  // In the CourseMaterials class, update the _navigateToSubjectDetail method:

  void _navigateToSubjectDetail(String subjectId, String subjectName) {
    // Navigate to subject detail page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening $subjectName materials...'),
        backgroundColor: ColorManager.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );

    // Implement navigation to the SubjectDetailPage
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SubjectDetailPage(
          subjectId: subjectId,
          subjectName: subjectName,
          courseName: widget.courseName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'Course Materials',
          style: TextStyle(
            color: ColorManager.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textDark),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.courseName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your subjects & start learning',
                    style: TextStyle(
                      fontSize: 16,
                      color: ColorManager.textMedium,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _subjectsFuture,
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
                        'Error loading subjects: ${snapshot.error}',
                        style: TextStyle(color: ColorManager.textMedium),
                      ),
                    );
                  }

                  final subjects = snapshot.data ?? [];

                  if (subjects.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.book,
                            size: 64,
                            color: ColorManager.textMedium.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No subjects available for this course',
                            style: TextStyle(color: ColorManager.textMedium),
                          ),
                        ],
                      ),
                    );
                  }

                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 4,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final subject = subjects[index];
                      final IconData iconData = _getIconData(subject['icon']);
                      final Color iconColor = _getIconColor(subject);

                      return GestureDetector(
                        onTap: () => _navigateToSubjectDetail(
                          subject['id'],
                          subject['name'],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    color: iconColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  padding: const EdgeInsets.all(8),
                                  child: Icon(
                                    iconData,
                                    color: iconColor,
                                    size: 32,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  subject['name'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: ColorManager.textDark,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${subject['chapters']} Chapters',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: ColorManager.textMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
