import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:luyip_website_edu/exams/test_evaluation_page.dart';
import 'package:luyip_website_edu/exams/test_model.dart';
import 'package:luyip_website_edu/exams/test_result_page.dart';
import 'package:luyip_website_edu/exams/test_start_page.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

import 'package:intl/intl.dart';

class TestListPage extends StatefulWidget {
  final String courseName;
  final String subjectName;
  final String userRole;

  const TestListPage({
    super.key,
    required this.courseName,
    required this.subjectName,
    required this.userRole,
  });

  @override
  State<TestListPage> createState() => _TestListPageState();
}

class _TestListPageState extends State<TestListPage> {
  late Future<List<Map<String, dynamic>>> _testsFuture;
  bool isLoading = true;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  Map<String, String> testSubmissionStatus = {};

  @override
  void initState() {
    super.initState();
    _testsFuture = _fetchTests();
  }

  Future<List<Map<String, dynamic>>> _fetchTests() async {
    List<Map<String, dynamic>> tests = [];

    try {
      // Reference to tests in the database
      final databaseRef = FirebaseDatabase.instance
          .ref(widget.courseName)
          .child('SUBJECTS')
          .child(widget.subjectName)
          .child('Tests');

      DatabaseEvent event = await databaseRef.once();

      if (event.snapshot.value != null) {
        Map<dynamic, dynamic> testsData =
            event.snapshot.value as Map<dynamic, dynamic>;

        // Process each test
        for (var entry in testsData.entries) {
          var testId = entry.key;
          var testData = entry.value as Map<dynamic, dynamic>;

          // For student role, only show active tests
          bool isActive = testData['isActive'] ?? false;
          if (widget.userRole == 'student' && !isActive) {
            continue;
          }

          // Get the questions for this test
          List<TestQuestion> questions = [];
          if (testData.containsKey('Questions')) {
            try {
              var questionsData =
                  testData['Questions'] as Map<dynamic, dynamic>;
              for (var qEntry in questionsData.entries) {
                try {
                  Map<String, dynamic> questionMap = {};

                  // Convert dynamic map to String, dynamic map
                  Map<dynamic, dynamic> rawData =
                      qEntry.value as Map<dynamic, dynamic>;
                  rawData.forEach((key, value) {
                    if (key is String) {
                      questionMap[key] = value;
                    }
                  });

                  // Ensure ID is set
                  questionMap['id'] = qEntry.key.toString();

                  // Check if options exists and convert it
                  if (questionMap.containsKey('options') &&
                      questionMap['options'] is List) {
                    List<dynamic> rawOptions =
                        questionMap['options'] as List<dynamic>;
                    questionMap['options'] =
                        rawOptions.map((e) => e.toString()).toList();
                  }

                  // Create test question
                  questions.add(TestQuestion.fromMap(questionMap));
                } catch (e) {
                  print('Error parsing question: $e');
                }
              }
            } catch (e) {
              print('Error fetching questions: $e');
            }
          }

          // Build test data map
          Map<String, dynamic> testMap = {
            'id': testId,
            'title': testData['title'] ?? 'No Title',
            'description': testData['description'] ?? '',
            'totalMarks': testData['totalMarks'] ?? 0,
            'durationMinutes': testData['durationMinutes'] ?? 60,
            'isActive': testData['isActive'] ?? false,
            'createdAt':
                testData['createdAt'] ?? DateTime.now().millisecondsSinceEpoch,
            'questions': questions,
            'courseName': widget.courseName,
            'subjectName': widget.subjectName,
          };

          tests.add(testMap);

          // If student, check if they've attempted this test
          if (widget.userRole == 'student') {
            await _checkTestSubmissionStatus(testId.toString());
          }
        }

        // Sort by createdAt (newest first)
        tests.sort((a, b) {
          int aTime = a['createdAt'] ?? 0;
          int bTime = b['createdAt'] ?? 0;
          return bTime.compareTo(aTime);
        });
      }

      return tests;
    } catch (e) {
      Utils().toastMessage('Error fetching tests: ${e.toString()}');
      return [];
    }
  }

  Future<void> _checkTestSubmissionStatus(String testId) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      final submissionSnapshot = await FirebaseDatabase.instance
          .ref('UserTestResults')
          .child(userId)
          .child(testId)
          .once();

      if (submissionSnapshot.snapshot.value != null) {
        final submissionData =
            submissionSnapshot.snapshot.value as Map<dynamic, dynamic>;

        if (submissionData.containsKey('submittedAt') &&
            submissionData['submittedAt'] != null) {
          setState(() {
            testSubmissionStatus[testId] = 'Completed';
          });
        } else {
          setState(() {
            testSubmissionStatus[testId] = 'In Progress';
          });
        }
      }
    } catch (e) {
      print('Error checking test submission status: ${e.toString()}');
    }
  }

  Future<List<Map<String, dynamic>>> _fetchSubmissions(String testId) async {
    List<Map<String, dynamic>> submissions = [];

    try {
      final submissionsSnapshot = await FirebaseDatabase.instance
          .ref('TestSubmissions')
          .child(testId)
          .once();

      if (submissionsSnapshot.snapshot.value != null) {
        Map<dynamic, dynamic> submissionsData =
            submissionsSnapshot.snapshot.value as Map<dynamic, dynamic>;

        for (var entry in submissionsData.entries) {
          var submissionData = entry.value as Map<dynamic, dynamic>;

          // Convert to String, dynamic map
          Map<String, dynamic> cleanedData = {};
          submissionData.forEach((key, value) {
            if (key is String) {
              cleanedData[key] = value;
            }
          });

          submissions.add(cleanedData);
        }

        // Sort by submission date (newest first)
        submissions.sort((a, b) {
          var aDate = a['submittedAt'] ?? a['startedAt'] ?? 0;
          var bDate = b['submittedAt'] ?? b['startedAt'] ?? 0;
          return (bDate as int).compareTo(aDate as int);
        });
      }

      return submissions;
    } catch (e) {
      Utils().toastMessage('Error fetching submissions: ${e.toString()}');
      return [];
    }
  }

  void _navigateToTest(Map<String, dynamic> test) async {
    final testId = test['id'];

    if (widget.userRole == 'student') {
      // Check if student has already completed this test
      if (testSubmissionStatus[testId] == 'Completed') {
        try {
          // Get the current user ID
          final userId = _auth.currentUser?.uid;
          if (userId == null) {
            Utils().toastMessage('User authentication error');
            return;
          }

          // First, get the submission ID from UserTestResults
          final userTestRef = FirebaseDatabase.instance
              .ref('UserTestResults')
              .child(userId)
              .child(testId);

          final userTestSnapshot = await userTestRef.once();
          if (userTestSnapshot.snapshot.value == null) {
            Utils().toastMessage('Test result not found');
            return;
          }

          Map<dynamic, dynamic> userTestData =
              userTestSnapshot.snapshot.value as Map<dynamic, dynamic>;
          String submissionId = userTestData['submissionId'] ?? '';

          if (submissionId.isEmpty) {
            Utils().toastMessage('Test submission data is missing');
            return;
          }

          // Get marks information
          int autoMarks = 0;
          if (userTestData.containsKey('autoMarks')) {
            autoMarks = userTestData['autoMarks'] is int
                ? userTestData['autoMarks']
                : 0;
          }

          int? manualMarks;
          if (userTestData.containsKey('manualMarks')) {
            manualMarks = userTestData['manualMarks'] is int
                ? userTestData['manualMarks']
                : null;
          }

          int totalMarks = 0;
          if (userTestData.containsKey('totalMarks')) {
            totalMarks = userTestData['totalMarks'] is int
                ? userTestData['totalMarks']
                : 0;
          } else if (test.containsKey('totalMarks')) {
            totalMarks = test['totalMarks'] is int ? test['totalMarks'] : 0;
          }

          // Navigate to the result page
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TestResultPage(
                test: test,
                submissionId: submissionId,
                autoMarks:
                    manualMarks ?? autoMarks, // Use manual marks if available
                totalMarks: totalMarks,
              ),
            ),
          );
        } catch (e) {
          print('Error navigating to test result: $e');
          Utils()
              .toastMessage('Error accessing test result. Please try again.');
        }
        return;
      }

      // For tests not yet completed
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => TestStartPage(
            test: test,
            courseName: widget.courseName,
            subjectName: widget.subjectName,
          ),
        ),
      ).then((_) {
        // Refresh the list when returning from the test
        setState(() {
          _testsFuture = _fetchTests();
        });
      });
    } else if (widget.userRole == 'teacher' || widget.userRole == 'admin') {
      // For teachers and admins, show submissions
      _showSubmissionsDialog(test);
    }
  }

  void _showSubmissionsDialog(Map<String, dynamic> test) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${test['title']} - Submissions'),
        content: Container(
          width: double.maxFinite,
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _fetchSubmissions(test['id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final submissions = snapshot.data ?? [];

              if (submissions.isEmpty) {
                return const Center(
                  child: Text('No submissions yet'),
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final submission = submissions[index];
                  final isEvaluated = submission['isEvaluated'] ?? false;
                  final submittedAtMillis = submission['submittedAt'];

                  DateTime? submittedAt;
                  if (submittedAtMillis != null) {
                    submittedAt = DateTime.fromMillisecondsSinceEpoch(
                        submittedAtMillis as int);
                  }

                  return ListTile(
                    title: Text(submission['userName'] ?? 'Unknown user'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(submission['userEmail'] ?? ''),
                        if (submittedAt != null)
                          Text(
                            'Submitted: ${DateFormat('dd MMM yyyy, hh:mm a').format(submittedAt)}',
                          ),
                        Text(
                          'Status: ${isEvaluated ? 'Evaluated' : submittedAt != null ? 'Needs Evaluation' : 'In Progress'}',
                          style: TextStyle(
                            color: isEvaluated
                                ? Colors.green
                                : submittedAt != null
                                    ? Colors.orange
                                    : Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    trailing: submittedAt != null
                        ? ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isEvaluated
                                  ? Colors.blue
                                  : const Color(0xff321f73),
                            ),
                            onPressed: () {
                              Navigator.pop(context); // Close dialog
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TestEvaluationPage(
                                    test: test,
                                    submission: submission,
                                    courseName: widget.courseName,
                                    subjectName: widget.subjectName,
                                  ),
                                ),
                              ).then((_) {
                                // Refresh when returning
                                setState(() {
                                  _testsFuture = _fetchTests();
                                });
                              });
                            },
                            child: Text(
                              isEvaluated ? 'Review' : 'Evaluate',
                            ),
                          )
                        : const Text('Not Submitted'),
                  );
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorManager.background,
      appBar: AppBar(
        title: Text(
          'TestsSSSSSS',
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
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.subjectName} Tests',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.userRole == 'student'
                        ? 'Complete your tests to assess your knowledge'
                        : 'Manage and evaluate student test submissions',
                    style: TextStyle(
                      fontSize: 16,
                      color: ColorManager.textMedium,
                    ),
                  ),
                ],
              ),
            ),

            // Test List
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _testsFuture,
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
                        'Error loading tests: ${snapshot.error}',
                        style: TextStyle(color: ColorManager.textMedium),
                      ),
                    );
                  }

                  final tests = snapshot.data ?? [];

                  if (tests.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.quiz,
                            size: 64,
                            color: ColorManager.textMedium.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No tests available',
                            style: TextStyle(color: ColorManager.textMedium),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tests.length,
                    itemBuilder: (context, index) {
                      final test = tests[index];
                      final testId = test['id'];
                      final createdAtMillis = test['createdAt'] ??
                          DateTime.now().millisecondsSinceEpoch;
                      final createdAt =
                          DateTime.fromMillisecondsSinceEpoch(createdAtMillis);
                      final status = testSubmissionStatus[testId] ?? '';

                      return Card(
                        margin: const EdgeInsets.only(bottom: 16),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: InkWell(
                          onTap: () => _navigateToTest(test),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        test['title'] ?? 'No Title',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: ColorManager.textDark,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (status.isNotEmpty)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: status == 'Completed'
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          status,
                                          style: TextStyle(
                                            color: status == 'Completed'
                                                ? Colors.green
                                                : Colors.orange,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  test['description'] ?? '',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: ColorManager.textMedium,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.timer,
                                          size: 16,
                                          color: ColorManager.textMedium,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${test['durationMinutes'] ?? 60} minutes',
                                          style: TextStyle(
                                            color: ColorManager.textMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.star,
                                          size: 16,
                                          color: ColorManager.textMedium,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${test['totalMarks'] ?? 0} marks',
                                          style: TextStyle(
                                            color: ColorManager.textMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.quiz_outlined,
                                          size: 16,
                                          color: ColorManager.textMedium,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${(test['questions'] as List).length} questions',
                                          style: TextStyle(
                                            color: ColorManager.textMedium,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Created: ${DateFormat('dd MMM yyyy').format(createdAt)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: ColorManager.textMedium,
                                      ),
                                    ),

                                    // Add View Results button for completed tests
                                    if (status == 'Completed')
                                      ElevatedButton.icon(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              const Color(0xff321f73),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                        ),
                                        icon: const Icon(Icons.bar_chart,
                                            size: 16),
                                        label: const Text('View Results'),
                                        onPressed: () => _navigateToTest(test),
                                      ),
                                  ],
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
