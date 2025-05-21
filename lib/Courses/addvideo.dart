import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/roundbutton.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class AddLecturesAdmin extends StatefulWidget {
  const AddLecturesAdmin({Key? key}) : super(key: key);

  @override
  State<AddLecturesAdmin> createState() => _AddLecturesAdminState();
}

class _AddLecturesAdminState extends State<AddLecturesAdmin> {
  bool loading = false;
  final _formKey = GlobalKey<FormState>();
  final postcontroller = TextEditingController();
  final cousenamecontroller = TextEditingController();
  final subjectcontroller = TextEditingController();
  final videotitlecontroller = TextEditingController();
  final videosubtitlecontroller = TextEditingController();
  final videourlcontroller = TextEditingController();
  final videolectureno = TextEditingController();
  String? selectedCourse;
  String? selectedSubject;
  List<String> courses = [];
  List<String> subjects = [];
  int counter = 0;
  bool _isCoursePreselected = false;

  @override
  void initState() {
    super.initState();

    // Check if course is preselected from arguments
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args =
          ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
      if (args != null) {
        final courseName = args['courseName'] as String?;
        final preSelectedSubject = args['selectedSubject'] as String?;

        if (courseName != null) {
          setState(() {
            selectedCourse = courseName;
            cousenamecontroller.text = courseName;
            _isCoursePreselected = true;
            if (preSelectedSubject != null) {
              selectedSubject = preSelectedSubject;
              subjectcontroller.text = preSelectedSubject;
            }
          });
          fetchSubjects(courseName);
        } else {
          fetchCourses();
        }
      } else {
        fetchCourses();
      }
    });
  }

  @override
  void dispose() {
    postcontroller.dispose();
    cousenamecontroller.dispose();
    subjectcontroller.dispose();
    videotitlecontroller.dispose();
    videosubtitlecontroller.dispose();
    videourlcontroller.dispose();
    videolectureno.dispose();
    super.dispose();
  }

  void fetchCourses() async {
    try {
      setState(() {
        loading = true;
      });

      var querySnapshot =
          await FirebaseFirestore.instance.collection('All Courses').get();

      setState(() {
        courses = querySnapshot.docs.map((doc) => doc.id).toList();
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      Utils().toastMessage('Error fetching courses: ${e.toString()}');
    }
  }

  void fetchSubjects(String courseName) async {
    try {
      setState(() {
        loading = true;
      });

      final databaseRef =
          FirebaseDatabase.instance.ref(courseName).child('SUBJECTS');
      DatabaseEvent event = await databaseRef.once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> subjectsData =
            event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          subjects = subjectsData.keys.map((key) => key.toString()).toList();
          loading = false;
        });
      } else {
        setState(() {
          subjects = [];
          loading = false;
        });
        Utils().toastMessage('No subjects found for this course');
      }
    } catch (e) {
      setState(() {
        loading = false;
      });
      Utils().toastMessage('Error fetching subjects: ${e.toString()}');
    }
  }

  Future<void> addVideoLecture() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCourse == null || selectedCourse!.isEmpty) {
      Utils().toastMessage('Please select a course');
      return;
    }

    if (subjectcontroller.text.isEmpty) {
      Utils().toastMessage('Please enter subject name');
      return;
    }

    if (videolectureno.text.isEmpty) {
      Utils().toastMessage('Please enter lecture number');
      return;
    }

    if (videotitlecontroller.text.isEmpty) {
      Utils().toastMessage('Please enter video title');
      return;
    }

    if (videourlcontroller.text.isEmpty) {
      Utils().toastMessage('Please enter video URL');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      final dbRef = FirebaseDatabase.instance.ref(selectedCourse!);

      // Check if subject exists, create if it doesn't
      if (!subjects.contains(subjectcontroller.text)) {
        await dbRef.child('SUBJECTS').child(subjectcontroller.text).set({
          'name': subjectcontroller.text,
          'timestamp': ServerValue.timestamp,
        });

        // Update subjects list
        setState(() {
          subjects.add(subjectcontroller.text);
        });
      }

      await dbRef
          .child('SUBJECTS')
          .child(subjectcontroller.text)
          .child('Videos')
          .child(videolectureno.text)
          .set({
        'id': videolectureno.text,
        'Title': videotitlecontroller.text,
        'Subtitle': videosubtitlecontroller.text,
        'Video Link': videourlcontroller.text,
        'timestamp': ServerValue.timestamp,
      });

      Utils().toastMessage('Lecture successfully added');

      // Clear form but keep course and subject selected
      setState(() {
        counter++;
        loading = false;
        videotitlecontroller.clear();
        videosubtitlecontroller.clear();
        videourlcontroller.clear();
        videolectureno.clear();
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      Utils().toastMessage('Error adding lecture: ${e.toString()}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorManager.primary,
        foregroundColor: Colors.white,
        title: const Text('Add Video Lectures'),
        elevation: 0,
      ),
      body: loading && courses.isEmpty && subjects.isEmpty
          ? Center(
              child: CircularProgressIndicator(color: ColorManager.primary),
            )
          : SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 24),

                      // Course Selection
                      _isCoursePreselected
                          ? _buildReadOnlyCourseField()
                          : _buildCourseDropdown(),
                      const SizedBox(height: 24),

                      // Subject Selection
                      if (selectedCourse != null) ...[
                        if (subjects.isNotEmpty)
                          _buildSubjectDropdown()
                        else
                          _buildSubjectTextField(),
                        const SizedBox(height: 24),
                      ],

                      // Lecture Number
                      TextFormField(
                        controller: videolectureno,
                        decoration: InputDecoration(
                          labelText: 'Lecture Number/ID',
                          hintText: 'Enter a unique lecture identifier',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.format_list_numbered),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter lecture number/ID';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Video Title
                      TextFormField(
                        controller: videotitlecontroller,
                        decoration: InputDecoration(
                          labelText: 'Video Title',
                          hintText: 'Enter video title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(height: 24),

                      // Video Subtitle
                      TextFormField(
                        controller: videosubtitlecontroller,
                        decoration: InputDecoration(
                          labelText: 'Video Subtitle (Optional)',
                          hintText: 'Enter video subtitle',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.subtitles),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Video URL
                      TextFormField(
                        controller: videourlcontroller,
                        decoration: InputDecoration(
                          labelText: 'Video URL',
                          hintText: 'Enter video URL',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
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
                      const SizedBox(height: 32),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.add_to_queue, color: Colors.white),
                          label: Text(
                            loading ? 'Adding Lecture...' : 'Add Video Lecture',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed: loading ? null : addVideoLecture,
                        ),
                      ),

                      // Success Counter
                      if (counter > 0)
                        Container(
                          margin: const EdgeInsets.only(top: 24),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle,
                                  color: Colors.green),
                              const SizedBox(width: 12),
                              Text(
                                '$counter lectures successfully added',
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Video Lectures',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create new video lectures for your course subjects',
          style: TextStyle(
            fontSize: 16,
            color: ColorManager.textMedium,
          ),
        ),
        const SizedBox(height: 16),
        Divider(color: ColorManager.textMedium.withOpacity(0.2)),
      ],
    );
  }

  Widget _buildReadOnlyCourseField() {
    return TextFormField(
      controller: cousenamecontroller,
      readOnly: true,
      enabled: false,
      decoration: InputDecoration(
        labelText: 'Course Name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
        prefixIcon: const Icon(Icons.school),
        suffixIcon: const Icon(Icons.lock_outline),
      ),
    );
  }

  Widget _buildCourseDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedCourse,
      decoration: InputDecoration(
        labelText: 'Select Course',
        hintText: 'Choose a course',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.school),
      ),
      items: courses.map((String course) {
        return DropdownMenuItem<String>(
          value: course,
          child: Text(course),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          selectedCourse = newValue;
          cousenamecontroller.text = selectedCourse ?? '';
          selectedSubject = null;
          subjectcontroller.clear();
          if (selectedCourse != null) {
            fetchSubjects(selectedCourse!);
          }
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a course';
        }
        return null;
      },
    );
  }

  Widget _buildSubjectDropdown() {
    return DropdownButtonFormField<String>(
      value: selectedSubject,
      decoration: InputDecoration(
        labelText: 'Select Subject',
        hintText: 'Choose a subject',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.subject),
      ),
      items: subjects.map((String subject) {
        return DropdownMenuItem<String>(
          value: subject,
          child: Text(subject),
        );
      }).toList(),
      onChanged: (newValue) {
        setState(() {
          selectedSubject = newValue;
          subjectcontroller.text = selectedSubject ?? '';
        });
      },
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please select a subject';
        }
        return null;
      },
    );
  }

  Widget _buildSubjectTextField() {
    return TextFormField(
      controller: subjectcontroller,
      decoration: InputDecoration(
        labelText: 'Subject Name',
        hintText: 'Enter subject name',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.subject),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter subject name';
        }
        return null;
      },
    );
  }
}
