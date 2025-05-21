import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:image_network/image_network.dart';

import 'package:luyip_website_edu/Courses/add_test.dart';
import 'package:luyip_website_edu/Courses/addvideo.dart';
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
  final _pdfTitleController = TextEditingController();
  final _pdfDescriptionController = TextEditingController();
  final _pdfUrlController = TextEditingController();
  String _selectedPdfType = 'notes';
  String? _selectedSubject;
  final _formKey = GlobalKey<FormState>();
  bool _isUploading = false;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _pdfTitleController.dispose();
    _pdfDescriptionController.dispose();
    _pdfUrlController.dispose();
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

      setState(() {
        _isLoading = false;
      });

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> subjectsData =
            event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          subjects = subjectsData.keys.map((key) => key.toString()).toList();
          if (subjects.isNotEmpty) {
            _selectedSubject = subjects[0];
          }
        });
      } else {
        Utils().toastMessage('No subjects found for this course');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      Utils().toastMessage('Error fetching subjects: ${e.toString()}');
    }
  }

  Future<void> _uploadPdf() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedSubject == null) {
      Utils().toastMessage('Please select a subject');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final documentId = 'doc_${DateTime.now().millisecondsSinceEpoch}';

      // Check if subject exists, create if it doesn't
      if (!subjects.contains(_selectedSubject)) {
        await FirebaseDatabase.instance
            .ref(widget.courseName)
            .child('SUBJECTS')
            .child(_selectedSubject!)
            .set({
          'name': _selectedSubject,
          'timestamp': ServerValue.timestamp,
        });

        // Update subjects list
        setState(() {
          subjects.add(_selectedSubject!);
        });
      }

      // Define the appropriate folder name based on document type
      String folderName = "";
      if (_selectedPdfType == 'notes') {
        folderName = "Notes";
      } else if (_selectedPdfType == 'dpp') {
        folderName = "DPP";
      }

      // Add to Realtime Database in the appropriate folder
      await FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(_selectedSubject!)
          .child(folderName) // Use the appropriate folder
          .child(documentId)
          .set({
        'id': documentId,
        'title': _pdfTitleController.text,
        'description': _pdfDescriptionController.text,
        'url': _pdfUrlController.text,
        'type': _selectedPdfType,
        'timestamp': ServerValue.timestamp,
      });

      // Also add to KeyDocuments array for reference
      await FirebaseFirestore.instance
          .collection('All Courses')
          .doc(widget.courseName)
          .update({
        'KeyDocuments': FieldValue.arrayUnion([
          {
            'title': _pdfTitleController.text,
            'description': _pdfDescriptionController.text,
            'url': _pdfUrlController.text,
            'type': _selectedPdfType,
            'subject': _selectedSubject,
          }
        ]),
      });

      Utils().toastMessage('Document successfully added');

      // Clear form
      setState(() {
        _pdfTitleController.clear();
        _pdfDescriptionController.clear();
        _pdfUrlController.clear();
        _isUploading = false;
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      Utils().toastMessage('Error adding document: ${e.toString()}');
    }
  }

  void _navigateToAddVideos() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddLecturesAdmin(),
        settings: RouteSettings(
          arguments: {
            'courseName': widget.courseName,
            'selectedSubject': _selectedSubject,
          },
        ),
      ),
    );
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
            userRole:
                'admin', // Default to admin since this is a management screen
          ),
        ),
      );
    } else {
      Utils().toastMessage('Please select a subject first');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorManager.primary,
        foregroundColor: Colors.white,
        title: const Text('Course Content Management'),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: const [
              Tab(icon: Icon(Icons.upload_file), text: 'Documents'),
              Tab(icon: Icon(Icons.video_library), text: 'Videos'),
              Tab(icon: Icon(Icons.quiz), text: 'Tests'),
            ],
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: ColorManager.primary),
            )
          : Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildAddPdfTab(),
                      _buildAddVideoTab(),
                      _buildAddTestTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      color: ColorManager.cardColor,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                  color: ColorManager.primary.withOpacity(0.3), width: 2),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: _courseImageUrl != null
                  ? ImageNetwork(
                      image: _courseImageUrl!,
                      width: 48,
                      height: 48,
                      fitAndroidIos: BoxFit.cover,
                      onLoading: Center(
                        child: CircularProgressIndicator(
                            color: ColorManager.primary, strokeWidth: 2),
                      ),
                      onError: Image.asset(
                        'assets/images/placeholder_course.jpg',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      color: ColorManager.secondary,
                      child: const Icon(Icons.school,
                          color: Colors.white, size: 24),
                    ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Managing Course:',
                  style: TextStyle(
                    color: ColorManager.textMedium,
                    fontSize: 12,
                  ),
                ),
                Text(
                  widget.courseName,
                  style: TextStyle(
                    color: ColorManager.textDark,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          DropdownButton<String>(
            value: _selectedSubject,
            hint: const Text('Select Subject'),
            underline: Container(
              height: 1,
              color: ColorManager.primary.withOpacity(0.3),
            ),
            onChanged: (String? newValue) {
              setState(() {
                _selectedSubject = newValue;
              });
            },
            items: subjects.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAddPdfTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle(
                'Upload Notes & DPP Documents', Icons.upload_file),
            const SizedBox(height: 24),

            // Subject with add new option
            _buildSubjectWithNewOption(),
            const SizedBox(height: 20),

            // Document Type Selection
            _buildDocumentTypeSelection(),
            const SizedBox(height: 20),

            // PDF Title
            TextFormField(
              controller: _pdfTitleController,
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

            // PDF Description
            TextFormField(
              controller: _pdfDescriptionController,
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

            // PDF URL
            TextFormField(
              controller: _pdfUrlController,
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
              height: 42,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadPdf,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isUploading
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
                          const Text('Uploading...'),
                        ],
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.upload_file, size: 18),
                          SizedBox(width: 8),
                          Text('Upload Document'),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddVideoTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.video_library,
              size: 40,
              color: ColorManager.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add Video Lectures',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create and manage video lectures for ${widget.courseName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ColorManager.textMedium,
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _navigateToAddVideos,
            icon: const Icon(Icons.add),
            label: const Text('Add Videos'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddTestTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: ColorManager.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.quiz,
              size: 40,
              color: ColorManager.secondary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Manage Tests & Quizzes',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: ColorManager.textDark,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              'Create and manage tests for ${widget.courseName}',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: ColorManager.textMedium,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _navigateToAddTests,
                icon: const Icon(Icons.add),
                label: const Text('Create New Test'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.secondary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _navigateToTestList,
                icon: const Icon(Icons.list),
                label: const Text('Manage Existing Tests'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorManager.primary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: ColorManager.primary,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectWithNewOption() {
    final TextEditingController newSubjectController = TextEditingController();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Subject',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedSubject,
                      hint: const Text('Select Subject'),
                      isExpanded: true,
                      onChanged: (String? newValue) {
                        if (newValue == 'ADD_NEW') {
                          // Show dialog to add new subject
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text('Add New Subject'),
                                content: TextField(
                                  controller: newSubjectController,
                                  decoration: const InputDecoration(
                                    hintText: 'Enter subject name',
                                  ),
                                ),
                                actions: <Widget>[
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text('Cancel'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      if (newSubjectController
                                          .text.isNotEmpty) {
                                        setState(() {
                                          _selectedSubject =
                                              newSubjectController.text;
                                        });
                                        Navigator.of(context).pop();
                                      }
                                    },
                                    child: const Text('Add'),
                                  ),
                                ],
                              );
                            },
                          );
                        } else {
                          setState(() {
                            _selectedSubject = newValue;
                          });
                        }
                      },
                      items: [
                        ...subjects
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        const DropdownMenuItem<String>(
                          value: 'ADD_NEW',
                          child: Row(
                            children: [
                              Icon(Icons.add, size: 16),
                              SizedBox(width: 8),
                              Text('Add New Subject'),
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
        ),
      ],
    );
  }

  Widget _buildDocumentTypeSelection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Document Type',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            // Modified to match subject screen sections
            _buildDocTypeChip('notes', 'Notes', Icons.description),
            _buildDocTypeChip('dpp', 'DPP', Icons.assignment),
          ],
        ),
      ],
    );
  }

  Widget _buildDocTypeChip(String type, String label, IconData icon) {
    final isSelected = _selectedPdfType == type;

    return ChoiceChip(
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: isSelected ? Colors.white : ColorManager.textMedium,
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 12)),
        ],
      ),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedPdfType = type;
          });
        }
      },
      backgroundColor: Colors.grey.shade200,
      selectedColor: ColorManager.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : ColorManager.textMedium,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}
