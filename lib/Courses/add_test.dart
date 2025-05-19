import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:luyip_website_edu/Courses/add_test_question.dart';
import 'package:luyip_website_edu/exams/test_model.dart';
import 'package:luyip_website_edu/helpers/roundbutton.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

import 'package:intl/intl.dart';

class AddTestAdmin extends StatefulWidget {
  const AddTestAdmin({super.key});

  @override
  State<AddTestAdmin> createState() => _AddTestAdminState();
}

class _AddTestAdminState extends State<AddTestAdmin> {
  bool loading = false;
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final totalMarksController = TextEditingController();
  final durationController = TextEditingController();

  String? selectedCourse;
  String? selectedSubject;
  List<String> courses = [];
  List<String> subjects = [];
  List<TestQuestion> questions = [];
  bool isActive = true;

  @override
  void initState() {
    super.initState();
    fetchCourses();
  }

  @override
  void dispose() {
    titleController.dispose();
    descriptionController.dispose();
    totalMarksController.dispose();
    durationController.dispose();
    super.dispose();
  }

  void fetchCourses() async {
    try {
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
      final databaseRef =
          FirebaseDatabase.instance.ref(courseName).child('SUBJECTS');
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

  Future<void> addTest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (selectedCourse == null || selectedCourse!.isEmpty) {
      Utils().toastMessage('Please select a course');
      return;
    }

    if (selectedSubject == null || selectedSubject!.isEmpty) {
      Utils().toastMessage('Please select a subject');
      return;
    }

    if (questions.isEmpty) {
      Utils().toastMessage('Please add at least one question');
      return;
    }

    setState(() {
      loading = true;
    });

    try {
      // Create test ID with timestamp to ensure uniqueness
      final testId = 'test_${DateTime.now().millisecondsSinceEpoch}';

      // Calculate total marks from questions
      int calculatedTotalMarks =
          questions.fold(0, (sum, question) => sum + question.marks);

      // Create test object
      Test test = Test(
        id: testId,
        title: titleController.text,
        description: descriptionController.text,
        totalMarks: calculatedTotalMarks,
        durationMinutes: int.parse(durationController.text),
        isActive: isActive,
        courseName: selectedCourse!,
        subjectName: selectedSubject!,
        createdAt: DateTime.now(),
        questions: questions,
      );

      // Save test data
      final dbRef = FirebaseDatabase.instance.ref(selectedCourse!);

      // Save test metadata
      await dbRef
          .child('SUBJECTS')
          .child(selectedSubject!)
          .child('Tests')
          .child(testId)
          .set(test.toMap());

      // Save questions separately
      for (var question in questions) {
        await dbRef
            .child('SUBJECTS')
            .child(selectedSubject!)
            .child('Tests')
            .child(testId)
            .child('Questions')
            .child(question.id)
            .set(question.toMap());
      }

      Utils().toastMessage('Test successfully created');

      setState(() {
        loading = false;
        titleController.clear();
        descriptionController.clear();
        totalMarksController.clear();
        durationController.clear();
        questions = [];
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      Utils().toastMessage('Error creating test: ${e.toString()}');
    }
  }

  Future<void> _addQuestion() async {
    final result = await Navigator.push<TestQuestion>(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuestionAdmin(),
      ),
    );

    if (result != null) {
      setState(() {
        questions.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff321f73),
        foregroundColor: Colors.white,
        title: const Text('Create New Test'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 30),

                // Course Selection
                DropdownButtonFormField<String>(
                  value: selectedCourse,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    hintText: 'Select Course',
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
                ),

                const SizedBox(height: 20),

                // Subject Selection
                if (selectedCourse != null)
                  DropdownButtonFormField<String>(
                    value: selectedSubject,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Select Subject',
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
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a subject';
                      }
                      return null;
                    },
                  ),

                const SizedBox(height: 20),

                // Test Title
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Test Title',
                    hintText: 'Enter test title',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter test title';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Test Description
                TextFormField(
                  controller: descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Test Description',
                    hintText: 'Enter test description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter test description';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Test Duration
                TextFormField(
                  controller: durationController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Duration (minutes)',
                    hintText: 'Enter test duration in minutes',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter test duration';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Test Active Toggle
                SwitchListTile(
                  title: const Text('Test Active'),
                  subtitle: const Text(
                      'Enable this to make test available to students'),
                  value: isActive,
                  onChanged: (bool value) {
                    setState(() {
                      isActive = value;
                    });
                  },
                ),

                const SizedBox(height: 20),

                // Questions Section
                const Text(
                  'Questions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 10),

                // Questions List
                if (questions.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('No questions added yet'),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: questions.length,
                    itemBuilder: (context, index) {
                      final question = questions[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(question.questionText),
                          subtitle: Text(
                            '${question.type.toUpperCase()} - ${question.marks} marks',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () {
                              setState(() {
                                questions.removeAt(index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 20),

                // Add Question Button
                Center(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff321f73),
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _addQuestion,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Question'),
                  ),
                ),

                const SizedBox(height: 30),

                // Total Marks Display
                Text(
                  'Total Marks: ${questions.fold(0, (sum, question) => sum + question.marks)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 30),

                // Create Test Button
                Roundbuttonnew(
                  loading: loading,
                  title: 'Create Test',
                  ontap: addTest,
                ),

                const SizedBox(height: 50),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
