import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:luyip_website_edu/helpers/roundbutton.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class AddLecturesAdmin extends StatefulWidget {
  const AddLecturesAdmin({super.key});

  @override
  State<AddLecturesAdmin> createState() => _AddLecturesAdminState();
}

class _AddLecturesAdminState extends State<AddLecturesAdmin> {
  bool loading = false;
  final postcontroller = TextEditingController();
  late TextEditingController cousenamecontroller;
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

  @override
  void initState() {
    super.initState(); // Fix 1: Always call super.initState() first

    cousenamecontroller = TextEditingController();
    fetchCourses();
  }

  @override
  void dispose() {
    // Fix 2: Clean up controllers when the widget is disposed
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
      // Fix 3: Add error handling for Firestore operations
      var querySnapshot =
          await FirebaseFirestore.instance.collection('All Courses').get();

      setState(() {
        courses = querySnapshot.docs.map((doc) => doc.id).toList();
      });
    } catch (e) {
      Utils().toastMessage('Error fetching courses: ${e.toString()}');
    }
  }

  void fetchSubjects(String courseName) async {
    try {
      // Fix 4: Handle null values properly for Realtime Database
      final databaseRef = FirebaseDatabase.instance
          .ref(courseName)
          .child('SUBJECTS');
      DatabaseEvent event = await databaseRef.once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> subjectsData =
            event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          subjects = subjectsData.keys.map((key) => key.toString()).toList();
          selectedSubject =
              null; // Reset the selected subject when course changes
        });
      } else {
        setState(() {
          subjects = [];
          selectedSubject = null;
        });
        Utils().toastMessage('No subjects found for this course');
      }
    } catch (e) {
      Utils().toastMessage('Error fetching subjects: ${e.toString()}');
    }
  }

  Future<void> addVideoLecture() async {
    if (selectedCourse == null || selectedCourse!.isEmpty) {
      Utils().toastMessage('Please select a course');
      return;
    }

    if (subjectcontroller.text.isEmpty) {
      Utils().toastMessage('Please enter subject name');
      return;
    }

    if (videolectureno.text.isEmpty) {
      Utils().toastMessage('Please enter lecture name');
      return;
    }

    // Fix 5: Set up proper loading state
    setState(() {
      loading = true;
    });

    try {
      // Fix 6: Better structure for database references
      final dbRef = FirebaseDatabase.instance.ref(selectedCourse!);

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
            'timestamp':
                ServerValue.timestamp, // Fix 7: Add timestamp for sorting
          });

      Utils().toastMessage('Lecture successfully added');

      setState(() {
        counter++;
        loading = false;
        subjectcontroller.clear();
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
        backgroundColor: const Color(
          0xff321f73,
        ), // Fix 8: Added const for optimization
        foregroundColor: Colors.white,
        title: const Text('Add Your Course Content'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 30),
              // Fix 9: Better dropdown UI and validation
              DropdownButtonFormField<String>(
                value: selectedCourse,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select Course',
                ),
                items:
                    courses.map((String course) {
                      return DropdownMenuItem<String>(
                        value: course,
                        child: Text(course),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    selectedCourse = newValue;
                    cousenamecontroller.text = selectedCourse ?? '';
                    if (selectedCourse != null) {
                      fetchSubjects(selectedCourse!);
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
              if (selectedCourse != null && subjects.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: selectedSubject,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select Subject',
                  ),
                  items:
                      subjects.map((String subject) {
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
                ),
                const SizedBox(height: 20),
              ],
              TextFormField(
                controller: subjectcontroller,
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Enter Your Subject',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: videolectureno,
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Lecture name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: videotitlecontroller,
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Enter Your VideoTitle',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: videosubtitlecontroller,
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Enter Your VideoSubtitle',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: videourlcontroller,
                maxLines: 1,
                decoration: const InputDecoration(
                  hintText: 'Enter Your videourl',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 30),
              Roundbuttonnew(
                loading: loading,
                title: 'Add Video Lecture',
                ontap:
                    addVideoLecture, // Fix 10: Use the new structured function
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
