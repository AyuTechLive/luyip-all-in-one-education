import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:luyip_website_edu/Courses/add_test_question.dart';
import 'package:luyip_website_edu/exams/test_model.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
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
            _isCoursePreselected = true;
            if (preSelectedSubject != null) {
              selectedSubject = preSelectedSubject;
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
    titleController.dispose();
    descriptionController.dispose();
    totalMarksController.dispose();
    durationController.dispose();
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

      setState(() {
        loading = false;
      });

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> subjectsData =
            event.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          subjects = subjectsData.keys.map((key) => key.toString()).toList();
          if (selectedSubject == null && subjects.isNotEmpty) {
            selectedSubject = subjects[0];
          }
        });
      } else {
        setState(() {
          subjects = [];
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
        backgroundColor: ColorManager.secondary,
        foregroundColor: Colors.white,
        title: const Text('Create New Test'),
        elevation: 0,
      ),
      body: loading && courses.isEmpty && subjects.isEmpty
          ? Center(
              child: CircularProgressIndicator(color: ColorManager.secondary),
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
                        _buildSubjectDropdown(),
                        const SizedBox(height: 24),
                      ],

                      // Test Title
                      TextFormField(
                        controller: titleController,
                        decoration: InputDecoration(
                          labelText: 'Test Title',
                          hintText: 'Enter test title',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.title),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter test title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Test Description
                      TextFormField(
                        controller: descriptionController,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: 'Test Description',
                          hintText: 'Enter test description',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.description),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter test description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Test Duration
                      TextFormField(
                        controller: durationController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Duration (minutes)',
                          hintText: 'Enter test duration in minutes',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          prefixIcon: const Icon(Icons.timer),
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
                      const SizedBox(height: 24),

                      // Test Active Toggle
                      Card(
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: SwitchListTile(
                            title: const Text('Test Active'),
                            subtitle: const Text(
                              'Enable this to make test available to students',
                              style: TextStyle(fontSize: 14),
                            ),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isActive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                isActive
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: isActive ? Colors.green : Colors.grey,
                              ),
                            ),
                            value: isActive,
                            activeColor: ColorManager.secondary,
                            onChanged: (bool value) {
                              setState(() {
                                isActive = value;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Questions Section
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: ColorManager.cardColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.quiz, color: ColorManager.secondary),
                                const SizedBox(width: 8),
                                const Text(
                                  'Test Questions',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  onPressed: _addQuestion,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Add Question'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: ColorManager.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 8),

                            // Questions List
                            if (questions.isEmpty)
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Column(
                                    children: [
                                      Icon(
                                        Icons.question_mark,
                                        size: 48,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'No questions added yet',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Click "Add Question" to create test questions',
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey.shade500,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: questions.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemBuilder: (context, index) {
                                  final question = questions[index];
                                  final typeIcon =
                                      _getQuestionTypeIcon(question.type);

                                  return ListTile(
                                    contentPadding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    leading: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: ColorManager.secondary
                                            .withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${index + 1}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: ColorManager.secondary,
                                          ),
                                        ),
                                      ),
                                    ),
                                    title: Text(
                                      question.questionText,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Row(
                                      children: [
                                        Icon(
                                          typeIcon,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          question.type.toUpperCase(),
                                          style: const TextStyle(fontSize: 12),
                                        ),
                                        const SizedBox(width: 12),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: ColorManager.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            '${question.marks} marks',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: ColorManager.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          questions.removeAt(index);
                                        });
                                      },
                                    ),
                                  );
                                },
                              ),

                            if (questions.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              const Divider(),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Questions:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '${questions.length}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: ColorManager.secondary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total Marks:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          ColorManager.primary.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '${questions.fold(0, (sum, q) => sum + q.marks)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: ColorManager.primary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Create Test Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            loading ? 'Creating Test...' : 'Create Test',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.secondary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          onPressed:
                              loading || questions.isEmpty ? null : addTest,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  IconData _getQuestionTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'multiple_choice':
        return Icons.checklist;
      case 'true_false':
        return Icons.rule;
      case 'short_answer':
        return Icons.short_text;
      case 'essay':
        return Icons.text_fields;
      case 'matching':
        return Icons.compare_arrows;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create Test or Quiz',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Create assessment tests for your course subjects',
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
      initialValue: selectedCourse,
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
          selectedSubject = null;
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
        hintText:
            subjects.isEmpty ? 'No subjects available' : 'Choose a subject',
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
      onChanged: subjects.isEmpty
          ? null
          : (newValue) {
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
    );
  }
}
