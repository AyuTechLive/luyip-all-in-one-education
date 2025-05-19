// TestEvaluationPage with fixes for TestQuestion objects

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:luyip_website_edu/exams/test_model.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';
import 'package:luyip_website_edu/helpers/roundbutton.dart';
import 'package:intl/intl.dart';

class TestEvaluationPage extends StatefulWidget {
  final Map<String, dynamic> test;
  final Map<String, dynamic> submission;
  final String courseName;
  final String subjectName;

  const TestEvaluationPage({
    super.key,
    required this.test,
    required this.submission,
    required this.courseName,
    required this.subjectName,
  });

  @override
  State<TestEvaluationPage> createState() => _TestEvaluationPageState();
}

class _TestEvaluationPageState extends State<TestEvaluationPage> {
  List<TestQuestion> questions = [];
  late Map<String, dynamic> responses;
  Map<String, TextEditingController> marksControllers = {};
  Map<String, TextEditingController> feedbackControllers = {};
  bool isSubmitting = false;
  int totalAutoMarks = 0;
  int totalManualMarks = 0;
  bool isAlreadyEvaluated = false;

  @override
  void initState() {
    super.initState();
    _parseQuestions();
    _initializeResponses();
  }

  void _parseQuestions() {
    try {
      final questionsData = widget.test['questions'];
      if (questionsData is List) {
        questions = questionsData.map((q) {
          // If it's already a TestQuestion, return it directly
          if (q is TestQuestion) {
            return q;
          }
          // Otherwise, convert from Map
          if (q is Map) {
            try {
              final questionMap = Map<String, dynamic>.from(q);
              return TestQuestion.fromMap(questionMap);
            } catch (e) {
              print('Error converting question map: $e');
              // Return a placeholder question on error
              return TestQuestion(
                id: q['id'] ?? 'unknown',
                questionText: q['questionText'] ?? 'Error loading question',
                type: q['type'] ?? 'mcq',
                marks: q['marks'] is int ? q['marks'] : 0,
              );
            }
          }
          // Fallback for unexpected types
          return TestQuestion(
            id: 'unknown',
            questionText: 'Error loading question',
            type: 'mcq',
            marks: 0,
          );
        }).toList();
      }
    } catch (e) {
      print('Error parsing questions: $e');
      // Keep empty questions list
    }
  }

  void _initializeResponses() {
    try {
      // Get responses from submission safely with proper type conversion
      if (widget.submission.containsKey('responses')) {
        final rawResponses = widget.submission['responses'];

        // Initialize responses as an empty map
        responses = {};

        // Check if responses exists and is a Map
        if (rawResponses != null && rawResponses is Map) {
          // Convert the LinkedMap<Object?, Object?> to Map<String, dynamic>
          (rawResponses as Map<dynamic, dynamic>).forEach((key, value) {
            if (key != null) {
              String stringKey = key.toString();
              if (value is Map) {
                // Convert inner map to Map<String, dynamic>
                Map<String, dynamic> cleanValue = {};
                value.forEach((k, v) {
                  if (k != null) {
                    cleanValue[k.toString()] = v;
                  }
                });
                responses[stringKey] = cleanValue;
              } else {
                // For non-map values, just add them directly
                responses[stringKey] = value;
              }
            }
          });
        }
      } else {
        responses = {};
        return; // No responses to process
      }

      // Initialize controllers and calculate automatic marks
      totalAutoMarks = 0;
      totalManualMarks = 0;

      for (var question in questions) {
        // Skip if there's no response for this question
        if (!responses.containsKey(question.id)) continue;

        try {
          final responseData = responses[question.id];

          // Make sure we have a Map<String, dynamic> to work with
          Map<String, dynamic> response;
          if (responseData is Map<String, dynamic>) {
            response = responseData;
          } else if (responseData is Map) {
            // Convert non-typed map to typed map
            response = {};
            responseData.forEach((k, v) {
              if (k != null) {
                response[k.toString()] = v;
              }
            });
          } else {
            // Skip this response if it's not a map
            continue;
          }

          // For MCQ, the marks are automatically calculated
          if (question.type == 'mcq' && response.containsKey('autoMarks')) {
            final autoMarks = response['autoMarks'];
            if (autoMarks is int) {
              totalAutoMarks += autoMarks;
            }
          }

          // For subjective questions, create controllers
          if (question.type == 'subjective') {
            // Create marks controller with properly handled initial value
            String initialMarksText = '';
            if (response.containsKey('manualMarks') &&
                response['manualMarks'] != null) {
              initialMarksText = response['manualMarks'].toString();

              // Add to total manual marks if it's a valid integer
              int? marks = int.tryParse(initialMarksText);
              if (marks != null) {
                totalManualMarks += marks;
                isAlreadyEvaluated = true;
              }
            }
            marksControllers[question.id] =
                TextEditingController(text: initialMarksText);

            // Create feedback controller with properly handled initial value
            String initialFeedback = '';
            if (response.containsKey('feedback') &&
                response['feedback'] != null) {
              initialFeedback = response['feedback'].toString();
            }
            feedbackControllers[question.id] =
                TextEditingController(text: initialFeedback);
          }
        } catch (e) {
          print('Error processing response for question ${question.id}: $e');
          // Continue with other questions
        }
      }
    } catch (e) {
      print('Error initializing responses: $e');
      responses = {};
      totalAutoMarks = 0;
      totalManualMarks = 0;
    }
  }

  @override
  void dispose() {
    // Dispose controllers
    for (var controller in marksControllers.values) {
      controller.dispose();
    }
    for (var controller in feedbackControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitEvaluation() async {
    if (questions.isEmpty) {
      Utils().toastMessage('No questions to evaluate');
      return;
    }

    // Validate that all subjective questions have marks
    bool allMarksEntered = true;
    String missingQuestionId = '';

    for (var question in questions) {
      if (question.type == 'subjective' &&
          responses.containsKey(question.id) &&
          marksControllers.containsKey(question.id)) {
        final marksText = marksControllers[question.id]!.text.trim();
        if (marksText.isEmpty) {
          allMarksEntered = false;
          missingQuestionId = question.id;
          break;
        }

        // Validate max marks
        final enteredMarks = int.tryParse(marksText) ?? 0;
        if (enteredMarks > question.marks) {
          Utils().toastMessage(
              'Marks for Q${questions.indexOf(question) + 1} cannot exceed maximum marks (${question.marks})');
          return;
        }
      }
    }

    if (!allMarksEntered) {
      final missingIndex =
          questions.indexWhere((q) => q.id == missingQuestionId);
      Utils()
          .toastMessage('Please enter marks for Question ${missingIndex + 1}');
      return;
    }

    // Get confirmation
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
            isAlreadyEvaluated ? 'Update Evaluation?' : 'Submit Evaluation?'),
        content: Text(
          isAlreadyEvaluated
              ? 'Are you sure you want to update the evaluation?'
              : 'Are you sure you want to submit this evaluation?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xff321f73),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isAlreadyEvaluated ? 'Update' : 'Submit'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      isSubmitting = true;
    });

    try {
      // Get test ID
      final testId = widget.test['id'];
      if (testId == null) {
        throw Exception('Test ID is missing');
      }

      // Get submission ID
      final submissionId = widget.submission['id'];
      if (submissionId == null) {
        throw Exception('Submission ID is missing');
      }

      // Calculate total manual marks
      int calculatedManualMarks = 0;
      Map<String, dynamic> updatedResponses = {};

      for (var question in questions) {
        if (!responses.containsKey(question.id)) continue;

        // Get the response data and ensure it's a Map<String, dynamic>
        final responseData = responses[question.id];
        Map<String, dynamic> response;

        if (responseData is Map<String, dynamic>) {
          response = responseData;
        } else if (responseData is Map) {
          // Convert from a non-typed map to a typed map
          response = {};
          responseData.forEach((k, v) {
            if (k != null) {
              response[k.toString()] = v;
            }
          });
        } else {
          // Create a new response object if it's not a map
          response = {
            'questionId': question.id,
            'userAnswer': '',
          };
        }

        // For MCQ, keep auto marks
        if (question.type == 'mcq') {
          if (response.containsKey('autoMarks') &&
              response['autoMarks'] is int) {
            calculatedManualMarks += response['autoMarks'] as int;
          }
          updatedResponses[question.id] = response;
          continue;
        }

        // For subjective, update marks and feedback
        if (question.type == 'subjective' &&
            marksControllers.containsKey(question.id)) {
          final marksText = marksControllers[question.id]!.text.trim();
          final manualMarks = int.tryParse(marksText) ?? 0;
          calculatedManualMarks += manualMarks;

          final feedback = feedbackControllers[question.id]!.text.trim();

          response['manualMarks'] = manualMarks;
          response['feedback'] = feedback;
          updatedResponses[question.id] = response;
        }
      }

      // Update the submission
      final submissionRef = FirebaseDatabase.instance
          .ref('TestSubmissions')
          .child(testId)
          .child(submissionId);

      // First, ensure responses map is formatted correctly for Firebase
      Map<String, dynamic> firebaseResponses = {};
      updatedResponses.forEach((key, value) {
        // Ensure inner maps have the expected format
        if (value is Map) {
          firebaseResponses[key] = Map<String, dynamic>.from(value);
        } else {
          firebaseResponses[key] = value;
        }
      });

      // Prepare update data
      Map<String, dynamic> updateData = {
        'totalManualMarks': calculatedManualMarks,
        'isEvaluated': true,
        'evaluatedAt': ServerValue.timestamp,
        'responses': firebaseResponses,
      };

      await submissionRef.update(updateData);

      // Update user's test result
      final userId = widget.submission['userId'];
      if (userId != null) {
        await FirebaseDatabase.instance
            .ref('UserTestResults')
            .child(userId)
            .child(testId)
            .update({
          'manualMarks': calculatedManualMarks,
          'isEvaluated': true,
        });
      }

      Utils().toastMessage(isAlreadyEvaluated
          ? 'Evaluation updated successfully'
          : 'Evaluation submitted successfully');

      Navigator.pop(context);
    } catch (e) {
      print('Error submitting evaluation: $e');
      setState(() {
        isSubmitting = false;
      });
      Utils().toastMessage('Error submitting evaluation: ${e.toString()}');
    }
  }

  int _getAutoMarks(String questionId) {
    try {
      if (!responses.containsKey(questionId)) return 0;

      final responseData = responses[questionId];

      // Handle different map types
      if (responseData is Map<String, dynamic>) {
        // Already the correct type
        final autoMarks = responseData['autoMarks'];
        if (autoMarks is int) {
          return autoMarks;
        }
      } else if (responseData is Map) {
        // Convert from other map type
        final autoMarks = responseData['autoMarks'];
        if (autoMarks is int) {
          return autoMarks;
        }
      }
      return 0;
    } catch (e) {
      print('Error getting auto marks: $e');
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely get submittedAt with fallback
    DateTime submittedAt;
    try {
      final submittedAtMillis = widget.submission['submittedAt'];
      if (submittedAtMillis != null && submittedAtMillis is int) {
        submittedAt = DateTime.fromMillisecondsSinceEpoch(submittedAtMillis);
      } else {
        submittedAt = DateTime.now();
      }
    } catch (e) {
      submittedAt = DateTime.now();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Test Evaluation',
          style: TextStyle(
            color: ColorManager.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: ColorManager.textDark),
      ),
      body: isSubmitting
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Submitting evaluation...'),
                ],
              ),
            )
          : SafeArea(
              child: Column(
                children: [
                  // Student info and test details
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: Colors.grey.shade50,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.test['title'] ?? 'Test Evaluation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: ColorManager.textDark,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              Icons.person,
                              size: 16,
                              color: ColorManager.textMedium,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.submission['userName'] ?? 'Student',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ColorManager.textDark,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Icon(
                              Icons.email,
                              size: 16,
                              color: ColorManager.textMedium,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.submission['userEmail'] ?? '',
                              style: TextStyle(
                                color: ColorManager.textMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 16,
                              color: ColorManager.textMedium,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Submitted: ${DateFormat('dd MMM yyyy, hh:mm a').format(submittedAt)}',
                              style: TextStyle(
                                color: ColorManager.textMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // Auto marks display
                        Row(
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 16,
                              color: ColorManager.textMedium,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Auto-evaluated: $totalAutoMarks marks',
                              style: TextStyle(
                                color: ColorManager.textMedium,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Questions and evaluation fields
                  Expanded(
                    child: questions.isEmpty
                        ? Center(
                            child: Text(
                              'No questions found',
                              style: TextStyle(color: ColorManager.textMedium),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: questions.length,
                            itemBuilder: (context, index) {
                              final question = questions[index];

                              // Skip if no response for this question
                              if (!responses.containsKey(question.id)) {
                                return const SizedBox.shrink();
                              }

                              // Get response data safely
                              String userAnswer = '';
                              bool isCorrect = false;

                              try {
                                final responseData = responses[question.id];
                                if (responseData is Map) {
                                  final response =
                                      Map<String, dynamic>.from(responseData);
                                  userAnswer =
                                      response['userAnswer'] as String? ?? '';
                                  isCorrect = question.type == 'mcq' &&
                                      userAnswer == question.correctAnswer;
                                }
                              } catch (e) {
                                print('Error getting response: $e');
                              }

                              return Card(
                                margin: const EdgeInsets.only(bottom: 16),
                                elevation: 2,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Question header
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Q${index + 1} (${question.type.toUpperCase()})',
                                            style: TextStyle(
                                              color: ColorManager.textMedium,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xff321f73)
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Text(
                                              'Max: ${question.marks} marks',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: Color(0xff321f73),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 12),

                                      // Question text
                                      Text(
                                        question.questionText,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: ColorManager.textDark,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 24),

                                      // Student's answer
                                      Text(
                                        'Student\'s answer:',
                                        style: TextStyle(
                                          color: ColorManager.textMedium,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: question.type == 'mcq'
                                              ? (isCorrect
                                                  ? Colors.green
                                                      .withOpacity(0.1)
                                                  : Colors.red.withOpacity(0.1))
                                              : Colors.grey.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          border: Border.all(
                                            color: question.type == 'mcq'
                                                ? (isCorrect
                                                    ? Colors.green
                                                        .withOpacity(0.3)
                                                    : Colors.red
                                                        .withOpacity(0.3))
                                                : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Text(
                                          userAnswer.isEmpty
                                              ? 'Not answered'
                                              : userAnswer,
                                          style: TextStyle(
                                            color: question.type == 'mcq'
                                                ? (isCorrect
                                                    ? Colors.green
                                                    : Colors.red)
                                                : ColorManager.textDark,
                                          ),
                                        ),
                                      ),

                                      // For MCQ - show correct answer if incorrect
                                      if (question.type == 'mcq' &&
                                          !isCorrect &&
                                          question.correctAnswer != null) ...[
                                        const SizedBox(height: 12),
                                        Row(
                                          children: [
                                            Text(
                                              'Correct answer: ',
                                              style: TextStyle(
                                                color: ColorManager.textMedium,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Text(
                                              question.correctAnswer ??
                                                  'Not provided',
                                              style: const TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      const SizedBox(height: 24),

                                      // For MCQ - auto-evaluated
                                      if (question.type == 'mcq') ...[
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              'Marks (Auto-evaluated):',
                                              style: TextStyle(
                                                color: ColorManager.textDark,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                horizontal: 12,
                                                vertical: 6,
                                              ),
                                              decoration: BoxDecoration(
                                                color: isCorrect
                                                    ? Colors.green
                                                        .withOpacity(0.1)
                                                    : Colors.red
                                                        .withOpacity(0.1),
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                              ),
                                              child: Text(
                                                '${_getAutoMarks(question.id)} / ${question.marks}',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  color: isCorrect
                                                      ? Colors.green
                                                      : Colors.red,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],

                                      // For subjective - manual evaluation
                                      if (question.type == 'subjective') ...[
                                        Text(
                                          'Assign Marks:',
                                          style: TextStyle(
                                            color: ColorManager.textDark,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Row(
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: marksControllers[
                                                    question.id],
                                                keyboardType:
                                                    TextInputType.number,
                                                decoration: InputDecoration(
                                                  hintText:
                                                      'Enter marks (max: ${question.marks})',
                                                  border:
                                                      const OutlineInputBorder(),
                                                  contentPadding:
                                                      const EdgeInsets
                                                          .symmetric(
                                                    horizontal: 16,
                                                    vertical: 14,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Row(
                                              children: [
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.red.shade100,
                                                    foregroundColor: Colors.red,
                                                  ),
                                                  onPressed: () {
                                                    marksControllers[
                                                            question.id]!
                                                        .text = '0';
                                                  },
                                                  child: const Text('0'),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                        Colors.green.shade100,
                                                    foregroundColor:
                                                        Colors.green,
                                                  ),
                                                  onPressed: () {
                                                    marksControllers[
                                                                question.id]!
                                                            .text =
                                                        question.marks
                                                            .toString();
                                                  },
                                                  child:
                                                      Text('${question.marks}'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Feedback (Optional):',
                                          style: TextStyle(
                                            color: ColorManager.textDark,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        TextFormField(
                                          controller:
                                              feedbackControllers[question.id],
                                          maxLines: 3,
                                          decoration: const InputDecoration(
                                            hintText:
                                                'Provide feedback to student',
                                            border: OutlineInputBorder(),
                                          ),
                                        ),
                                      ],

                                      // Explanation (if available)
                                      if (question.explanation != null &&
                                          question.explanation!.isNotEmpty) ...[
                                        const SizedBox(height: 16),
                                        const Divider(),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Explanation:',
                                          style: TextStyle(
                                            color: ColorManager.textDark,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          question.explanation!,
                                          style: TextStyle(
                                            color: ColorManager.textMedium,
                                            fontStyle: FontStyle.italic,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),

                  // Submit button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Roundbuttonnew(
                      loading: isSubmitting,
                      title: isAlreadyEvaluated
                          ? 'Update Evaluation'
                          : 'Submit Evaluation',
                      ontap: _submitEvaluation,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Helper method to safely get auto marks from a response
}
