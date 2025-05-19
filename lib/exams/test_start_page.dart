import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:luyip_website_edu/exams/test_model.dart';
import 'package:luyip_website_edu/exams/test_taking_page.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class TestStartPage extends StatefulWidget {
  final Map<String, dynamic> test;
  final String courseName;
  final String subjectName;

  const TestStartPage({
    super.key,
    required this.test,
    required this.courseName,
    required this.subjectName,
  });

  @override
  State<TestStartPage> createState() => _TestStartPageState();
}

class _TestStartPageState extends State<TestStartPage> {
  bool isLoading = false;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  // Added count variables with safe defaults
  late int mcqCount = 0;
  late int subjectiveCount = 0;
  late int totalQuestions = 0;

  @override
  void initState() {
    super.initState();
    // Safely count question types
    _countQuestionTypes();
  }

  void _countQuestionTypes() {
    try {
      final questions = widget.test['questions'];
      if (questions is List) {
        totalQuestions = questions.length;

        // Count MCQ questions safely
        mcqCount = questions.where((q) {
          if (q is Map) {
            return q['type'] == 'mcq';
          } else if (q is TestQuestion) {
            return q.type == 'mcq';
          }
          return false;
        }).length;

        // Count subjective questions safely
        subjectiveCount = questions.where((q) {
          if (q is Map) {
            return q['type'] == 'subjective';
          } else if (q is TestQuestion) {
            return q.type == 'subjective';
          }
          return false;
        }).length;
      }
    } catch (e) {
      print('Error counting question types: $e');
      // Use defaults already set
    }
  }

  @override
  Widget build(BuildContext context) {
    // Safely get test details with defaults
    final testTitle = widget.test['title'] ?? 'Test';
    final testDescription = widget.test['description'] ?? '';
    final durationMinutes = widget.test['durationMinutes'] ?? 60;
    final totalMarks = widget.test['totalMarks'] ?? 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          'Test Instructions',
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Test Title
                Text(
                  testTitle,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),

                const SizedBox(height: 12),

                // Test Description
                Text(
                  testDescription,
                  style: TextStyle(
                    fontSize: 16,
                    color: ColorManager.textMedium,
                  ),
                ),

                const SizedBox(height: 24),

                // Test Details
                _buildInfoCard(
                    'Duration', '$durationMinutes minutes', Icons.timer),
                _buildInfoCard('Total Marks', '$totalMarks', Icons.star),
                _buildInfoCard(
                    'Questions',
                    '$totalQuestions ($mcqCount MCQ, $subjectiveCount Subjective)',
                    Icons.quiz_outlined),

                const SizedBox(height: 32),

                // Test Instructions
                _buildInstructionsCard(),

                const SizedBox(height: 32),

                // Start Test Button
                isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff321f73),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _startTest,
                          child: const Text(
                            'Start Test',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, String value, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xff321f73).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: const Color(0xff321f73),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: ColorManager.textMedium,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionsCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Test Instructions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildInstructionItem(
              '1',
              'The test has a timer. Once started, you must complete the test within the allotted time.',
            ),
            _buildInstructionItem(
              '2',
              'For MCQ questions, select the correct option from the given choices.',
            ),
            _buildInstructionItem(
              '3',
              'For subjective questions, type your answer in the provided text area.',
            ),
            _buildInstructionItem(
              '4',
              'MCQ questions will be auto-evaluated. Subjective questions may be evaluated manually by your teacher.',
            ),
            _buildInstructionItem(
              '5',
              'Once you submit the test, you cannot retake it.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInstructionItem(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            margin: const EdgeInsets.only(right: 12, top: 4),
            decoration: BoxDecoration(
              color: const Color(0xff321f73),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              number,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: ColorManager.textDark,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startTest() async {
    setState(() {
      isLoading = true;
    });

    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        Utils().toastMessage('You need to be logged in to take the test');
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Fetch user details
      String userName = 'Student';
      final userEmail = currentUser.email ?? 'No email';

      try {
        final userDoc = await _firestore
            .collection('Users')
            .doc('student')
            .collection('accounts')
            .doc(userEmail)
            .get();

        if (userDoc.exists) {
          userName = userDoc.data()?['Name'] ?? 'Student';
        }
      } catch (e) {
        print('Error fetching user details: ${e.toString()}');
      }

      // Safely get test ID
      final testId = widget.test['id'];
      if (testId == null) {
        Utils().toastMessage('Test ID is missing');
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Create test submission object
      final submissionId =
          'submission_${DateTime.now().millisecondsSinceEpoch}';
      final startedAt = DateTime.now();

      final testSubmission = TestSubmission(
        id: submissionId,
        testId: testId,
        userId: currentUser.uid,
        userEmail: userEmail,
        userName: userName,
        startedAt: startedAt,
        submittedAt: null, // Will be set when the test is submitted
        totalAutoMarks: 0, // Will be calculated upon submission
        totalManualMarks: null, // Will be set by the teacher
        isEvaluated: false,
        responses: {},
      );

      // Save the test submission to the database
      await FirebaseDatabase.instance
          .ref('TestSubmissions')
          .child(testId)
          .child(submissionId)
          .set(testSubmission.toMap());

      // Also save in user's test results
      await FirebaseDatabase.instance
          .ref('UserTestResults')
          .child(currentUser.uid)
          .child(testId)
          .set({
        'submissionId': submissionId,
        'testId': testId,
        'courseName': widget.courseName,
        'subjectName': widget.subjectName,
        'startedAt': startedAt.millisecondsSinceEpoch,
        'title': widget.test['title'] ?? 'Test',
      });

      // Add courseName and subjectName to the test data for reference
      final testData = Map<String, dynamic>.from(widget.test);
      if (!testData.containsKey('courseName')) {
        testData['courseName'] = widget.courseName;
      }
      if (!testData.containsKey('subjectName')) {
        testData['subjectName'] = widget.subjectName;
      }

      // Navigate to the test taking page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TestTakingPage(
            test: testData,
            submissionId: submissionId,
            startTime: startedAt,
          ),
        ),
      );
    } catch (e) {
      Utils().toastMessage('Error starting test: ${e.toString()}');
      setState(() {
        isLoading = false;
      });
    }
  }
}
