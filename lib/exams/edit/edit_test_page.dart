import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:luyip_website_edu/Courses/add_test_question.dart';

import 'package:luyip_website_edu/exams/edit/edit_test_question.dart';
import 'package:luyip_website_edu/exams/test_model.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/roundbutton.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class EditTestPage extends StatefulWidget {
  final String courseId;
  final String subjectId;
  final String testId;

  const EditTestPage({
    Key? key,
    required this.courseId,
    required this.subjectId,
    required this.testId,
  }) : super(key: key);

  @override
  State<EditTestPage> createState() => _EditTestPageState();
}

class _EditTestPageState extends State<EditTestPage> {
  bool _isLoading = true;
  bool _isSaving = false;
  bool _hasSubmissions = false;
  bool _isDeleting = false;

  // Form key and controllers
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _durationController = TextEditingController();

  // Test data
  bool _isActive = false;
  List<TestQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _loadTestData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  Future<void> _loadTestData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Fetch test data
      final testRef = FirebaseDatabase.instance
          .ref(widget.courseId)
          .child('SUBJECTS')
          .child(widget.subjectId)
          .child('Tests')
          .child(widget.testId);

      final testSnapshot = await testRef.once();

      if (testSnapshot.snapshot.value == null) {
        Utils().toastMessage('Test not found');
        Navigator.pop(context);
        return;
      }

      final testData = testSnapshot.snapshot.value as Map<dynamic, dynamic>;

      // Initialize controllers with test data
      _titleController.text = testData['title'] ?? '';
      _descriptionController.text = testData['description'] ?? '';
      _durationController.text =
          testData['durationMinutes']?.toString() ?? '60';
      _isActive = testData['isActive'] ?? false;

      // Fetch questions
      List<TestQuestion> questions = [];
      if (testData.containsKey('Questions')) {
        final questionsData = testData['Questions'] as Map<dynamic, dynamic>;

        questionsData.forEach((key, value) {
          Map<String, dynamic> questionMap = {};

          // Convert to correct map format
          if (value is Map) {
            value.forEach((k, v) {
              if (k is String) {
                questionMap[k] = v;
              } else {
                questionMap[k.toString()] = v;
              }
            });
          }

          // Ensure ID is set
          questionMap['id'] = key.toString();

          try {
            // Parse options list
            if (questionMap.containsKey('options') &&
                questionMap['options'] is List) {
              List<dynamic> rawOptions =
                  questionMap['options'] as List<dynamic>;
              questionMap['options'] =
                  rawOptions.map((e) => e.toString()).toList();
            }

            // Add the question to the list
            final testQuestion = TestQuestion.fromMap(questionMap);
            questions.add(testQuestion);
          } catch (e) {
            print('Error parsing question: $e');
          }
        });
      }

      // Sort questions by ID
      questions.sort((a, b) {
        // Extract numeric part from ID if possible
        try {
          final idA = a.id.replaceAll(RegExp(r'[^0-9]'), '');
          final idB = b.id.replaceAll(RegExp(r'[^0-9]'), '');

          if (idA.isNotEmpty && idB.isNotEmpty) {
            return int.parse(idA).compareTo(int.parse(idB));
          }
          return a.id.compareTo(b.id);
        } catch (e) {
          return a.id.compareTo(b.id);
        }
      });

      // Check if there are any submissions for this test
      final submissionsRef =
          FirebaseDatabase.instance.ref('TestSubmissions').child(widget.testId);

      final submissionsSnapshot = await submissionsRef.once();
      bool hasSubmissions = submissionsSnapshot.snapshot.value != null;

      setState(() {
        _questions = questions;
        _hasSubmissions = hasSubmissions;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading test data: $e');
      Utils().toastMessage('Error loading test data: ${e.toString()}');

      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _updateTest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_questions.isEmpty) {
      Utils().toastMessage('Please add at least one question');
      return;
    }

    // Check if test has submissions
    if (_hasSubmissions) {
      // Show warning about editing a test with submissions
      bool continueEdit = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Warning: Test Has Submissions'),
              content: const Text(
                  'This test already has student submissions. Editing the test may affect existing results. Continue?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ) ??
          false;

      if (!continueEdit) {
        return;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Calculate total marks
      int totalMarks =
          _questions.fold(0, (sum, question) => sum + question.marks);

      // Update test data
      final testRef = FirebaseDatabase.instance
          .ref(widget.courseId)
          .child('SUBJECTS')
          .child(widget.subjectId)
          .child('Tests')
          .child(widget.testId);

      // Prepare test data for update
      Map<String, dynamic> testData = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'durationMinutes': int.parse(_durationController.text),
        'isActive': _isActive,
        'totalMarks': totalMarks,
        'updatedAt': ServerValue.timestamp,
      };

      // Update the test data
      await testRef.update(testData);

      // Update questions
      final questionsRef = testRef.child('Questions');

      // First, get all existing question IDs
      final questionsSnapshot = await questionsRef.once();
      List<String> existingQuestionIds = [];

      if (questionsSnapshot.snapshot.value != null) {
        Map<dynamic, dynamic> existingQuestions =
            questionsSnapshot.snapshot.value as Map<dynamic, dynamic>;
        existingQuestionIds =
            existingQuestions.keys.map((key) => key.toString()).toList();
      }

      // Get current question IDs
      List<String> currentQuestionIds = _questions.map((q) => q.id).toList();

      // Find questions to remove (in existing but not in current)
      List<String> questionsToRemove = existingQuestionIds
          .where((id) => !currentQuestionIds.contains(id))
          .toList();

      // Remove questions that are no longer included
      for (String questionId in questionsToRemove) {
        await questionsRef.child(questionId).remove();
      }

      // Update or add current questions
      for (TestQuestion question in _questions) {
        await questionsRef.child(question.id).set(question.toMap());
      }

      Utils().toastMessage('Test updated successfully');
      Navigator.pop(context);
    } catch (e) {
      print('Error updating test: $e');
      Utils().toastMessage('Error updating test: ${e.toString()}');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  Future<void> _deleteTest() async {
    // Check if test has submissions
    if (_hasSubmissions) {
      // Show warning about deleting a test with submissions
      bool confirmDelete = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Warning: Test Has Submissions'),
              content: const Text(
                'This test has student submissions. Deleting the test will permanently remove all submission data. This action cannot be undone.',
                style: TextStyle(color: Colors.red),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete Anyway'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirmDelete) {
        return;
      }
    } else {
      // Regular confirmation dialog
      bool confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Confirm Delete'),
              content: const Text(
                  'Are you sure you want to delete this test? This action cannot be undone.'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete'),
                ),
              ],
            ),
          ) ??
          false;

      if (!confirm) {
        return;
      }
    }

    setState(() {
      _isDeleting = true;
    });

    try {
      // Delete test from the database
      await FirebaseDatabase.instance
          .ref(widget.courseId)
          .child('SUBJECTS')
          .child(widget.subjectId)
          .child('Tests')
          .child(widget.testId)
          .remove();

      // Delete test submissions if they exist
      if (_hasSubmissions) {
        await FirebaseDatabase.instance
            .ref('TestSubmissions')
            .child(widget.testId)
            .remove();
      }

      Utils().toastMessage('Test deleted successfully');
      Navigator.pop(context);
    } catch (e) {
      print('Error deleting test: $e');
      Utils().toastMessage('Error deleting test: ${e.toString()}');
    } finally {
      setState(() {
        _isDeleting = false;
      });
    }
  }

  void _editQuestion(TestQuestion question, int index) async {
    final result = await Navigator.push<TestQuestion>(
      context,
      MaterialPageRoute(
        builder: (context) => EditTestQuestionPage(question: question),
      ),
    );

    if (result != null) {
      setState(() {
        _questions[index] = result;
      });
    }
  }

  void _addNewQuestion() async {
    final result = await Navigator.push<TestQuestion>(
      context,
      MaterialPageRoute(
        builder: (context) => AddQuestionAdmin(),
      ),
    );

    if (result != null) {
      setState(() {
        _questions.add(result);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorManager.secondary,
        foregroundColor: Colors.white,
        title: const Text('Edit Test'),
        elevation: 0,
        actions: [
          if (!_isLoading && !_isSaving && !_isDeleting)
            IconButton(
              icon: const Icon(Icons.delete),
              tooltip: 'Delete Test',
              onPressed: _deleteTest,
            ),
        ],
      ),
      body: _isLoading
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

                      // Course and Subject (read-only)
                      TextFormField(
                        initialValue: widget.courseId,
                        readOnly: true,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Course',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          prefixIcon: const Icon(Icons.school),
                        ),
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        initialValue: widget.subjectId,
                        readOnly: true,
                        enabled: false,
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          prefixIcon: const Icon(Icons.subject),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Test Title
                      TextFormField(
                        controller: _titleController,
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
                        controller: _descriptionController,
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
                        controller: _durationController,
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
                                color: _isActive
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                _isActive
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: _isActive ? Colors.green : Colors.grey,
                              ),
                            ),
                            value: _isActive,
                            activeColor: ColorManager.secondary,
                            onChanged: (bool value) {
                              setState(() {
                                _isActive = value;
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
                                  onPressed: _addNewQuestion,
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
                            if (_questions.isEmpty)
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
                                itemCount: _questions.length,
                                separatorBuilder: (context, index) =>
                                    const Divider(),
                                itemBuilder: (context, index) {
                                  final question = _questions[index];
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
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit,
                                              color: Colors.blue),
                                          onPressed: () =>
                                              _editQuestion(question, index),
                                          tooltip: 'Edit Question',
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () {
                                            setState(() {
                                              _questions.removeAt(index);
                                            });
                                          },
                                          tooltip: 'Delete Question',
                                        ),
                                      ],
                                    ),
                                    onTap: () => _editQuestion(question, index),
                                  );
                                },
                              ),

                            if (_questions.isNotEmpty) ...[
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
                                    '${_questions.length}',
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
                                      '${_questions.fold(0, (sum, q) => sum + q.marks)}',
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

                      // Warning about submissions
                      if (_hasSubmissions) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.yellow.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.yellow.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded,
                                  color: Colors.orange.shade800),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Test Has Submissions',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'This test has been taken by students. Editing may affect existing results.',
                                      style: TextStyle(
                                        color: Colors.orange.shade800,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Update Test Button
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.save, color: Colors.white),
                          label: Text(
                            _isSaving ? 'Saving Changes...' : 'Save Changes',
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
                              (_isSaving || _isDeleting || _questions.isEmpty)
                                  ? null
                                  : _updateTest,
                        ),
                      ),

                      // Delete Button
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: TextButton.icon(
                          icon: Icon(
                            Icons.delete,
                            color: _isDeleting ? Colors.grey : Colors.red,
                          ),
                          label: Text(
                            _isDeleting ? 'Deleting...' : 'Delete Test',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _isDeleting ? Colors.grey : Colors.red,
                            ),
                          ),
                          style: TextButton.styleFrom(
                            backgroundColor: Colors.red.withOpacity(0.1),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(
                                  color: Colors.red.withOpacity(0.5)),
                            ),
                          ),
                          onPressed:
                              (_isSaving || _isDeleting) ? null : _deleteTest,
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
      case 'mcq':
        return Icons.check_circle_outline;
      case 'subjective':
        return Icons.text_fields;
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
          'Edit Test',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Modify test details, questions, options and settings',
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
}
