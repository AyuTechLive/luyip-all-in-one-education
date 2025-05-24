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

class _TestStartPageState extends State<TestStartPage>
    with TickerProviderStateMixin {
  bool isLoading = false;
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Color scheme - Professional Blue Theme
  static const Color primaryBlue = ColorManager.primary;
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color backgroundGrey = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);

  // Added count variables with safe defaults
  late int mcqCount = 0;
  late int subjectiveCount = 0;
  late int totalQuestions = 0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
    ));

    _countQuestionTypes();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _countQuestionTypes() {
    try {
      final questions = widget.test['questions'];
      if (questions is List) {
        totalQuestions = questions.length;

        mcqCount = questions.where((q) {
          if (q is Map) {
            return q['type'] == 'mcq';
          } else if (q is TestQuestion) {
            return q.type == 'mcq';
          }
          return false;
        }).length;

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
    }
  }

  @override
  Widget build(BuildContext context) {
    final testTitle = widget.test['title'] ?? 'Test';
    final testDescription = widget.test['description'] ?? '';
    final durationMinutes = widget.test['durationMinutes'] ?? 60;
    final totalMarks = widget.test['totalMarks'] ?? 0;

    return Scaffold(
      backgroundColor: backgroundGrey,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Responsive design
            final isDesktop = constraints.maxWidth > 1200;
            final isTablet =
                constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
            final maxWidth =
                isDesktop ? 1000.0 : (isTablet ? 800.0 : double.infinity);

            return SingleChildScrollView(
              child: Center(
                child: Container(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Padding(
                        padding: EdgeInsets.all(isDesktop ? 40.0 : 20.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildHeader(context, testTitle, testDescription),
                            const SizedBox(height: 32),
                            _buildTestOverview(durationMinutes, totalMarks),
                            const SizedBox(height: 32),
                            _buildInstructionsSection(),
                            const SizedBox(height: 40),
                            _buildStartButton(),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, String testTitle, String testDescription) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primaryBlue,
            secondaryBlue,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_new,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${widget.courseName} • ${widget.subjectName}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Test Assessment',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            testTitle,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          if (testDescription.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              testDescription,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white70,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTestOverview(int durationMinutes, int totalMarks) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Test Overview',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  icon: Icons.access_time_rounded,
                  label: 'Duration',
                  value: '$durationMinutes min',
                  color: const Color(0xFF059669),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  icon: Icons.grade_rounded,
                  label: 'Total Marks',
                  value: '$totalMarks',
                  color: const Color(0xFFDC2626),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildQuestionBreakdown(),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionBreakdown() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.quiz_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Questions Breakdown',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$totalQuestions Total Questions',
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _buildQuestionTypeChip(
                        'MCQ', mcqCount, const Color(0xFF3B82F6)),
                    const SizedBox(width: 8),
                    _buildQuestionTypeChip(
                        'Subjective', subjectiveCount, const Color(0xFF8B5CF6)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionTypeChip(String type, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        '$count $type',
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Widget _buildInstructionsSection() {
    final instructions = [
      {
        'icon': Icons.timer_outlined,
        'title': 'Time Management',
        'description':
            'The test has a timer. Once started, you must complete the test within the allotted time.',
      },
      {
        'icon': Icons.radio_button_checked_outlined,
        'title': 'MCQ Questions',
        'description':
            'For multiple choice questions, select the correct option from the given choices.',
      },
      {
        'icon': Icons.edit_outlined,
        'title': 'Subjective Questions',
        'description':
            'For subjective questions, type your detailed answer in the provided text area.',
      },
      {
        'icon': Icons.auto_awesome_outlined,
        'title': 'Auto Evaluation',
        'description':
            'MCQ questions will be auto-evaluated. Subjective questions may be evaluated manually by your teacher.',
      },
      {
        'icon': Icons.lock_outline,
        'title': 'Single Attempt',
        'description':
            'Once you submit the test, you cannot retake it. Make sure to review your answers before submitting.',
      },
    ];

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: primaryBlue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Test Instructions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ...instructions.asMap().entries.map((entry) {
            final index = entry.key;
            final instruction = entry.value;
            return _buildInstructionItem(
              index + 1,
              instruction['icon'] as IconData,
              instruction['title'] as String,
              instruction['description'] as String,
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildInstructionItem(
      int number, IconData icon, String title, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: backgroundGrey,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor.withOpacity(0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [primaryBlue, lightBlue],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryBlue,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartButton() {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: isLoading
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue.withOpacity(0.7),
                    secondaryBlue.withOpacity(0.7)
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 2,
                  ),
                ),
              ),
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: EdgeInsets.zero,
              ),
              onPressed: _startTest,
              child: Ink(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [primaryBlue, secondaryBlue],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  width: double.infinity,
                  height: 60,
                  child: const Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Start Test',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
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
        submittedAt: null,
        totalAutoMarks: 0,
        totalManualMarks: null,
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
