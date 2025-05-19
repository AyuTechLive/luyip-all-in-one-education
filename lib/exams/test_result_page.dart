import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:luyip_website_edu/exams/test_model.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';
import 'package:luyip_website_edu/home/main_page.dart';
import 'package:intl/intl.dart';

class TestResultPage extends StatefulWidget {
  final Map<String, dynamic> test;
  final String submissionId;
  final int autoMarks;
  final int totalMarks;

  const TestResultPage({
    super.key,
    required this.test,
    required this.submissionId,
    required this.autoMarks,
    required this.totalMarks,
  });

  @override
  State<TestResultPage> createState() => _TestResultPageState();
}

class _TestResultPageState extends State<TestResultPage> {
  late Future<Map<String, dynamic>> _submissionFuture;
  bool isManuallyEvaluated = false;
  int? totalManualMarks;
  List<TestQuestion> questions = [];

  @override
  void initState() {
    super.initState();
    _parseQuestions();
    _submissionFuture = _fetchSubmission();
  }

  // Parse questions safely from test data
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

  Future<Map<String, dynamic>> _fetchSubmission() async {
    try {
      final testId = widget.test['id'];
      if (testId == null) {
        Utils().toastMessage('Test ID is missing');
        return {};
      }

      final snapshot = await FirebaseDatabase.instance
          .ref('TestSubmissions')
          .child(testId)
          .child(widget.submissionId)
          .once();

      if (snapshot.snapshot.value == null) {
        return {};
      }

      final submissionData = Map<String, dynamic>.from(
          snapshot.snapshot.value as Map<dynamic, dynamic>);

      // Check if test is manually evaluated
      if (submissionData.containsKey('isEvaluated') &&
          submissionData['isEvaluated'] == true) {
        setState(() {
          isManuallyEvaluated = true;
          totalManualMarks = submissionData['totalManualMarks'];
        });
      }

      return submissionData;
    } catch (e) {
      Utils().toastMessage('Error fetching test results: ${e.toString()}');
      return {};
    }
  }

  double calculatePercentage(int marks, int total) {
    if (total == 0) return 0; // Avoid division by zero
    return (marks / total) * 100;
  }

  String getGrade(double percentage) {
    if (percentage >= 90) return 'A+';
    if (percentage >= 80) return 'A';
    if (percentage >= 70) return 'B+';
    if (percentage >= 60) return 'B';
    if (percentage >= 50) return 'C';
    if (percentage >= 40) return 'D';
    return 'F';
  }

  Color getGradeColor(double percentage) {
    if (percentage >= 70) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // Navigate to main page when back is pressed
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
              builder: (context) => const MainPage(role: 'student')),
          (Route<dynamic> route) => false,
        );
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text(
            'Test Results',
            style: TextStyle(
              color: ColorManager.textDark,
              fontWeight: FontWeight.bold,
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: ColorManager.textDark),
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const MainPage(role: 'student'),
                  ),
                  (Route<dynamic> route) => false,
                );
              },
            ),
          ],
        ),
        body: SafeArea(
          child: FutureBuilder<Map<String, dynamic>>(
            future: _submissionFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError ||
                  !snapshot.hasData ||
                  snapshot.data!.isEmpty) {
                return const Center(
                  child: Text('Error loading test results'),
                );
              }

              final submissionData = snapshot.data!;
              final submittedAtMillis = submissionData['submittedAt'];

              if (submittedAtMillis == null) {
                return const Center(
                  child: Text('Test submission data is incomplete'),
                );
              }

              final submittedAt = DateTime.fromMillisecondsSinceEpoch(
                  submittedAtMillis is int ? submittedAtMillis : 0);

              // Get total obtained marks based on evaluation status
              final obtainedMarks = isManuallyEvaluated
                  ? totalManualMarks ?? widget.autoMarks
                  : widget.autoMarks;

              final percentage =
                  calculatePercentage(obtainedMarks, widget.totalMarks);
              final grade = getGrade(percentage);
              final gradeColor = getGradeColor(percentage);

              return SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Test completed header
                    Center(
                      child: Column(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 64,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Test Completed',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: ColorManager.textDark,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            DateFormat('dd MMM yyyy, hh:mm a')
                                .format(submittedAt),
                            style: TextStyle(
                              color: ColorManager.textMedium,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Test information
                    Text(
                      widget.test['title'] ?? 'Test Result',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: ColorManager.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.test['description'] ?? '',
                      style: TextStyle(
                        color: ColorManager.textMedium,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Score card
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Text(
                              'Your Score',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: ColorManager.textDark,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildScoreItem(
                                  'Marks',
                                  '$obtainedMarks/${widget.totalMarks}',
                                  Colors.blue,
                                ),
                                _buildScoreItem(
                                  'Percentage',
                                  '${percentage.toStringAsFixed(1)}%',
                                  Colors.purple,
                                ),
                                _buildScoreItem(
                                  'Grade',
                                  grade,
                                  gradeColor,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (!isManuallyEvaluated)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.info_outline,
                                      color: Colors.orange,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Note: Only MCQ questions have been auto-evaluated. '
                                        'Your final score may change after teacher evaluation of subjective questions.',
                                        style: TextStyle(
                                          color: Colors.orange.shade800,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Answer review section
                    if (submissionData.containsKey('responses') &&
                        questions.isNotEmpty)
                      _buildAnswerReviewSection(submissionData),

                    const SizedBox(height: 40),

                    // Return to home button
                    Center(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff321f73),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const MainPage(role: 'student'),
                            ),
                            (Route<dynamic> route) => false,
                          );
                        },
                        icon: const Icon(Icons.home),
                        label: const Text('Return to Home'),
                      ),
                    ),

                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildScoreItem(String label, String value, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: ColorManager.textMedium,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildAnswerReviewSection(Map<String, dynamic> submissionData) {
    if (!submissionData.containsKey('responses')) {
      return const SizedBox.shrink();
    }

    final responsesData = submissionData['responses'] as Map<dynamic, dynamic>;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Answer Review',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: questions.length,
          itemBuilder: (context, index) {
            final question = questions[index];
            final questionId = question.id;

            // Skip if no response for this question
            if (!responsesData.containsKey(questionId)) {
              return const SizedBox.shrink();
            }

            final response = Map<String, dynamic>.from(
                responsesData[questionId] as Map<dynamic, dynamic>);

            final userAnswer = response['userAnswer'] as String? ?? '';
            final isCorrect =
                question.type == 'mcq' && userAnswer == question.correctAnswer;

            final autoMarks = response['autoMarks'] as int?;
            final manualMarks = response['manualMarks'] as int?;
            final feedback = response['feedback'] as String?;

            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question number and type
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Q${index + 1} (${question.type.toUpperCase()})',
                          style: TextStyle(
                            color: ColorManager.textMedium,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${question.marks} marks',
                          style: TextStyle(
                            color: ColorManager.textMedium,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Question text
                    Text(
                      question.questionText,
                      style: TextStyle(
                        fontSize: 16,
                        color: ColorManager.textDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Your answer
                    Text(
                      'Your answer:',
                      style: TextStyle(
                        color: ColorManager.textMedium,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Container(
                      padding: const EdgeInsets.all(12),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: question.type == 'mcq'
                            ? (isCorrect
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1))
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        userAnswer.isEmpty ? 'Not answered' : userAnswer,
                        style: TextStyle(
                          color: question.type == 'mcq'
                              ? (isCorrect ? Colors.green : Colors.red)
                              : ColorManager.textDark,
                        ),
                      ),
                    ),

                    // Show correct answer for MCQs
                    if (question.type == 'mcq' &&
                        !isCorrect &&
                        question.correctAnswer != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Correct answer:',
                        style: TextStyle(
                          color: ColorManager.textMedium,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.all(12),
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          question.correctAnswer ?? 'Not provided',
                          style: const TextStyle(
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],

                    // Marks obtained
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Marks obtained:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: ColorManager.textDark,
                          ),
                        ),
                        Text(
                          question.type == 'mcq'
                              ? '${autoMarks ?? 0}/${question.marks}'
                              : isManuallyEvaluated
                                  ? '${manualMarks ?? 0}/${question.marks}'
                                  : 'Pending evaluation',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: question.type == 'mcq'
                                ? (isCorrect ? Colors.green : Colors.red)
                                : isManuallyEvaluated
                                    ? Colors.blue
                                    : Colors.orange,
                          ),
                        ),
                      ],
                    ),

                    // Teacher feedback
                    if (feedback != null && feedback.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Teacher feedback:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feedback,
                        style: TextStyle(
                          color: ColorManager.textMedium,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],

                    // Explanation
                    if (question.explanation != null &&
                        question.explanation!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Divider(),
                      const SizedBox(height: 8),
                      Text(
                        'Explanation:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        question.explanation!,
                        style: TextStyle(
                          color: ColorManager.textMedium,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
