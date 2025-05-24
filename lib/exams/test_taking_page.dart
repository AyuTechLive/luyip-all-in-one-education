import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:luyip_website_edu/exams/test_model.dart';
import 'package:luyip_website_edu/exams/test_result_page.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class TestTakingPage extends StatefulWidget {
  final Map<String, dynamic> test;
  final String submissionId;
  final DateTime startTime;

  const TestTakingPage({
    super.key,
    required this.test,
    required this.submissionId,
    required this.startTime,
  });

  @override
  State<TestTakingPage> createState() => _TestTakingPageState();
}

class _TestTakingPageState extends State<TestTakingPage>
    with TickerProviderStateMixin {
  List<TestQuestion> questions = [];
  Map<String, String> answers = {};
  Map<String, int?> autoMarks = {};
  bool isSubmitting = false;

  // For MCQ options
  Map<String, int> selectedOptions = {};

  // For timer
  late Timer _timer;
  late int _secondsRemaining;
  String _timeDisplay = '';

  int _currentQuestionIndex = 0;
  final PageController _pageController = PageController();

  // Map of TextEditingControllers for subjective answers
  final Map<String, TextEditingController> _textControllers = {};

  // Autosave timer
  Timer? _autoSaveTimer;
  DateTime? _lastSaved;
  bool _isSaving = false;
  bool _isInitialized = false;

  // Animation controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Professional Color Scheme
  static const Color primaryBlue = ColorManager.primary;
  static const Color secondaryBlue = Color(0xFF3B82F6);
  static const Color lightBlue = Color(0xFF3B82F6);
  static const Color accentBlue = Color(0xFF60A5FA);
  static const Color backgroundGrey = Color(0xFFF8FAFC);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color borderColor = Color(0xFFE2E8F0);
  static const Color successGreen = Color(0xFF059669);
  static const Color warningOrange = Color(0xFFF59E0B);
  static const Color dangerRed = Color(0xFFDC2626);

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _loadQuestions();
  }

  @override
  void dispose() {
    _timer.cancel();
    _autoSaveTimer?.cancel();
    _fadeController.dispose();
    _slideController.dispose();

    // Dispose text controllers
    for (var controller in _textControllers.values) {
      controller.dispose();
    }

    _pageController.dispose();
    super.dispose();
  }

  void _loadQuestions() {
    try {
      // Check if we have 'questions' directly in the test map
      if (widget.test.containsKey('questions') &&
          widget.test['questions'] is List) {
        final questionsList = widget.test['questions'] as List;
        questions = questionsList.map((q) {
          if (q is TestQuestion) return q;
          return TestQuestion.fromMap(Map<String, dynamic>.from(q));
        }).toList();
        _initializeTest();
        return;
      }

      // If not, we need to fetch questions from Firebase
      _fetchQuestionsFromFirebase();
    } catch (e) {
      print('Error loading questions: $e');
      Utils().toastMessage('Error loading test questions: $e');
    }
  }

  Future<void> _fetchQuestionsFromFirebase() async {
    try {
      final testId = widget.test['id'];
      final courseName = widget.test['courseName'];
      final subjectName = widget.test['subjectName'];

      if (testId == null || courseName == null || subjectName == null) {
        Utils().toastMessage('Test details are incomplete');
        return;
      }

      final questionsRef = FirebaseDatabase.instance
          .ref(courseName)
          .child('SUBJECTS')
          .child(subjectName)
          .child('Tests')
          .child(testId)
          .child('Questions');

      final snapshot = await questionsRef.once();

      if (snapshot.snapshot.value == null) {
        Utils().toastMessage('No questions found for this test');
        return;
      }

      final questionsData = snapshot.snapshot.value as Map<dynamic, dynamic>;
      List<TestQuestion> loadedQuestions = [];

      questionsData.forEach((key, value) {
        try {
          // Create a clean Map<String, dynamic> from the Firebase data
          final Map<String, dynamic> questionData = {};

          if (value is Map) {
            final rawData = value as Map<dynamic, dynamic>;
            rawData.forEach((k, v) {
              if (k is String) {
                questionData[k] = v;
              }
            });
          }

          // Ensure required fields are present
          questionData['id'] = key.toString();

          if (!questionData.containsKey('questionText')) {
            questionData['questionText'] = 'Question text unavailable';
          }

          if (!questionData.containsKey('type')) {
            questionData['type'] = 'mcq'; // Default to MCQ
          }

          if (!questionData.containsKey('marks')) {
            questionData['marks'] = 1; // Default to 1 mark
          }

          // Handle options for MCQ
          if (questionData['type'] == 'mcq' &&
              questionData.containsKey('options')) {
            if (questionData['options'] is List) {
              List<dynamic> rawOptions =
                  questionData['options'] as List<dynamic>;
              questionData['options'] =
                  rawOptions.map((e) => e?.toString() ?? '').toList();
            } else {
              // Create a default options list if missing
              questionData['options'] = ['Option 1', 'Option 2'];
            }
          }

          // Create the TestQuestion object with the cleaned data
          loadedQuestions.add(TestQuestion.fromMap(questionData));
        } catch (e) {
          print('Error parsing question: $e');
          // Skip this question and continue with others
        }
      });

      setState(() {
        questions = loadedQuestions;
      });

      if (questions.isNotEmpty) {
        _initializeTest();
      } else {
        Utils().toastMessage('Error loading test questions');
      }
    } catch (e) {
      print('Error fetching questions: $e');
      Utils().toastMessage('Error loading test questions: $e');
    }
  }

  void _initializeTest() {
    if (_isInitialized) return;
    _isInitialized = true;

    // Create text controllers for each subjective question
    for (var question in questions) {
      if (question.type == 'subjective') {
        _textControllers[question.id] = TextEditingController();
      }
    }

    // Set up timer
    final durationMinutes =
        widget.test['durationMinutes'] as int? ?? 60; // Default to 60 min
    final testEndTime =
        widget.startTime.add(Duration(minutes: durationMinutes));
    _secondsRemaining = testEndTime.difference(DateTime.now()).inSeconds;
    if (_secondsRemaining < 0) _secondsRemaining = 0;
    _startTimer();

    // Set up autosave timer (every 30 seconds)
    _autoSaveTimer =
        Timer.periodic(const Duration(seconds: 30), (timer) => _autoSave());

    // Check if there are already saved answers
    _loadSavedAnswers();

    // Start animations
    _fadeController.forward();
    _slideController.forward();
  }

  Future<void> _loadSavedAnswers() async {
    try {
      final testId = widget.test['id'];
      if (testId == null) return;

      final DatabaseReference submissionRef = FirebaseDatabase.instance
          .ref('TestSubmissions')
          .child(testId)
          .child(widget.submissionId);

      final snapshot = await submissionRef.child('responses').once();

      if (snapshot.snapshot.value != null) {
        final Map<dynamic, dynamic> responseData =
            snapshot.snapshot.value as Map<dynamic, dynamic>;

        setState(() {
          responseData.forEach((key, value) {
            final response = Map<String, dynamic>.from(value as Map);
            final questionId = key.toString();
            final userAnswer = response['userAnswer'] as String;

            answers[questionId] = userAnswer;

            // Update text controllers for subjective questions
            if (_textControllers.containsKey(questionId)) {
              _textControllers[questionId]!.text = userAnswer;
            }

            // For MCQ, find the index of the selected option
            final question = questions.firstWhere(
              (q) => q.id == questionId,
              orElse: () => TestQuestion(
                id: '',
                questionText: '',
                type: '',
                marks: 0,
              ),
            );

            if (question.type == 'mcq' && question.options != null) {
              final optionIndex = question.options!.indexOf(userAnswer);
              if (optionIndex != -1) {
                selectedOptions[questionId] = optionIndex;
              }
            }
          });
        });
      }
    } catch (e) {
      print('Error loading saved answers: ${e.toString()}');
    }
  }

  void _startTimer() {
    _updateTimeDisplay();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_secondsRemaining > 0) {
          _secondsRemaining--;
          _updateTimeDisplay();
        } else {
          _timer.cancel();
          _submitTest(true); // Auto-submit when time is up
        }
      });
    });
  }

  void _updateTimeDisplay() {
    final hours = _secondsRemaining ~/ 3600;
    final minutes = (_secondsRemaining % 3600) ~/ 60;
    final seconds = _secondsRemaining % 60;

    setState(() {
      if (hours > 0) {
        _timeDisplay =
            '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      } else {
        _timeDisplay =
            '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
      }
    });
  }

  Future<void> _autoSave() async {
    if (_isSaving || questions.isEmpty)
      return; // Don't save if already saving or no questions loaded

    // Update answers map with current values
    _updateAnswersMap();

    if (answers.isEmpty) return; // Don't save if no answers

    setState(() {
      _isSaving = true;
    });

    try {
      // Save responses to database
      final testId = widget.test['id'];
      if (testId == null) throw Exception('Test ID is missing');

      final DatabaseReference submissionRef = FirebaseDatabase.instance
          .ref('TestSubmissions')
          .child(testId)
          .child(widget.submissionId);

      // Create response objects
      final Map<String, dynamic> responses = {};

      answers.forEach((questionId, answer) {
        responses[questionId] = {
          'questionId': questionId,
          'userAnswer': answer,
        };
      });

      // Update responses in database
      await submissionRef.child('responses').update(responses);

      setState(() {
        _lastSaved = DateTime.now();
        _isSaving = false;
      });
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      print('Error autosaving answers: ${e.toString()}');
    }
  }

  void _updateAnswersMap() {
    // Update answers from text controllers
    _textControllers.forEach((questionId, controller) {
      final text = controller.text.trim();
      if (text.isNotEmpty) {
        answers[questionId] = text;
      }
    });
  }

  Future<void> _submitTest(bool isAutoSubmit) async {
    if (isSubmitting || questions.isEmpty) return;

    // If not auto-submit, show confirmation dialog
    if (!isAutoSubmit) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => _buildSubmitDialog(),
      );

      if (confirmed != true) return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Update answers map with current values
      _updateAnswersMap();

      // Evaluate MCQ answers
      int totalAutoMarks = 0;
      Map<String, UserTestResponse> responses = {};

      for (var question in questions) {
        final userAnswer = answers[question.id] ?? '';
        int? questionMarks;

        // Auto-evaluate MCQs
        if (question.type == 'mcq' && question.correctAnswer != null) {
          if (userAnswer == question.correctAnswer) {
            questionMarks = question.marks;
            totalAutoMarks += question.marks;
          } else {
            questionMarks = 0;
          }
        }

        // Create response object
        responses[question.id] = UserTestResponse(
          questionId: question.id,
          userAnswer: userAnswer,
          autoMarks: questionMarks,
          manualMarks: null,
          feedback: null,
        );
      }

      // Save test submission
      final testId = widget.test['id'];
      if (testId == null) throw Exception('Test ID is missing');

      final submissionRef = FirebaseDatabase.instance
          .ref('TestSubmissions')
          .child(testId)
          .child(widget.submissionId);

      final submittedAt = DateTime.now();

      await submissionRef.update({
        'submittedAt': submittedAt.millisecondsSinceEpoch,
        'totalAutoMarks': totalAutoMarks,
        'isEvaluated': false,
        'responses':
            responses.map((key, value) => MapEntry(key, value.toMap())),
      });

      // Update user test results
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        await FirebaseDatabase.instance
            .ref('UserTestResults')
            .child(userId)
            .child(testId)
            .update({
          'submittedAt': submittedAt.millisecondsSinceEpoch,
          'autoMarks': totalAutoMarks,
          'totalMarks': widget.test['totalMarks'],
        });
      }

      // Cancel timers
      _timer.cancel();
      _autoSaveTimer?.cancel();

      // Navigate to results page
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => TestResultPage(
            test: widget.test,
            submissionId: widget.submissionId,
            autoMarks: totalAutoMarks,
            totalMarks: widget.test['totalMarks'] ?? 0,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        isSubmitting = false;
      });
      Utils().toastMessage('Error submitting test: ${e.toString()}');
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  Widget _buildSubmitDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, backgroundGrey],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: warningOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.warning_amber_rounded,
                color: warningOrange,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Submit Test?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Are you sure you want to submit this test? You cannot change your answers after submission.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: textSecondary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: successGreen,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Submit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMCQOptions(TestQuestion question) {
    // Handle case where options might be null or empty
    final options = question.options ?? ['Option not available'];
    if (options.isEmpty) {
      return Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: warningOrange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: warningOrange.withOpacity(0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: warningOrange),
              const SizedBox(width: 12),
              const Text(
                'No options available for this question',
                style: TextStyle(
                  fontSize: 16,
                  color: textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(options.length, (index) {
          final option = options[index];
          final isSelected = selectedOptions[question.id] == index;
          final optionLabel = String.fromCharCode(65 + index); // A, B, C, D

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedOptions[question.id] = index;
                  answers[question.id] = option;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          colors: [
                            primaryBlue.withOpacity(0.1),
                            accentBlue.withOpacity(0.05),
                          ],
                        )
                      : null,
                  border: Border.all(
                    color: isSelected ? primaryBlue : borderColor,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  color: isSelected ? null : cardBackground,
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: primaryBlue.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                ),
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: isSelected
                            ? LinearGradient(
                                colors: [primaryBlue, secondaryBlue],
                              )
                            : null,
                        border: Border.all(
                          color: isSelected ? Colors.transparent : borderColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected ? null : cardBackground,
                      ),
                      child: Center(
                        child: Text(
                          optionLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : textSecondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          color: textPrimary,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: successGreen,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSubjectiveAnswer(TestQuestion question) {
    // Create controller if it doesn't exist
    if (!_textControllers.containsKey(question.id)) {
      _textControllers[question.id] = TextEditingController();
    }

    final controller = _textControllers[question.id]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 2),
            borderRadius: BorderRadius.circular(16),
            color: cardBackground,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextField(
            controller: controller,
            maxLines: 10,
            style: const TextStyle(
              fontSize: 16,
              color: textPrimary,
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText: 'Type your detailed answer here...',
              hintStyle: TextStyle(
                color: textSecondary,
                fontSize: 16,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.all(20),
            ),
            onChanged: (value) {
              answers[question.id] = value;
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              'Provide a detailed explanation for full marks',
              style: TextStyle(
                fontSize: 14,
                color: textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        backgroundColor: backgroundGrey,
        body: Center(
          child: Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CircularProgressIndicator(
                    color: primaryBlue,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Loading Test Questions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait while we prepare your test...',
                  style: TextStyle(
                    fontSize: 16,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => _buildExitDialog(),
        );
        return confirmed ?? false;
      },
      child: Scaffold(
        backgroundColor: backgroundGrey,
        body: LayoutBuilder(
          builder: (context, constraints) {
            final isDesktop = constraints.maxWidth > 1200;
            final isTablet =
                constraints.maxWidth > 768 && constraints.maxWidth <= 1200;
            final maxWidth =
                isDesktop ? 1200.0 : (isTablet ? 900.0 : double.infinity);

            return SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Center(
                    child: Container(
                      constraints: BoxConstraints(maxWidth: maxWidth),
                      child: isSubmitting
                          ? _buildSubmittingState()
                          : CustomScrollView(
                              slivers: [
                                SliverToBoxAdapter(
                                  child: Column(
                                    children: [
                                      _buildHeader(),
                                      _buildProgressSection(),
                                    ],
                                  ),
                                ),
                                SliverFillRemaining(
                                  fillOverscroll: true,
                                  child: _buildQuestionSection(),
                                ),
                                SliverToBoxAdapter(
                                  child: _buildNavigationSection(),
                                ),
                              ],
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

  Widget _buildExitDialog() {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 16,
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white, backgroundGrey],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: dangerRed.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.exit_to_app_rounded,
                color: dangerRed,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Exit Test?',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Your progress will be saved, but the test will not be submitted. Are you sure you want to exit?',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade200,
                      foregroundColor: textSecondary,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: dangerRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text(
                      'Exit',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmittingState() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    primaryBlue.withOpacity(0.1),
                    successGreen.withOpacity(0.1)
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: CircularProgressIndicator(
                color: primaryBlue,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Submitting Your Test',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please wait while we process your submission...',
              style: TextStyle(
                fontSize: 16,
                color: textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [primaryBlue, secondaryBlue],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.test['title'] ?? 'Test Assessment',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.test['courseName'] ?? ''} • ${widget.test['subjectName'] ?? ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: _secondsRemaining < 300
                  ? dangerRed.withOpacity(0.2)
                  : Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: _secondsRemaining < 300 ? dangerRed : Colors.white30,
                width: 2,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.timer_outlined,
                  size: 20,
                  color: _secondsRemaining < 300 ? dangerRed : Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _timeDisplay,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: _secondsRemaining < 300 ? dangerRed : Colors.white,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final answeredQuestions = answers.length;
    final progressPercentage = answeredQuestions / questions.length;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$answeredQuestions answered • ${questions.length - answeredQuestions} remaining',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
              if (_lastSaved != null) ...[
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        _isSaving ? Icons.sync : Icons.cloud_done_outlined,
                        size: 16,
                        color: successGreen,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          _isSaving ? 'Saving...' : 'Auto-saved',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: successGreen,
                          ),
                        ),
                        Text(
                          '${_lastSaved!.hour}:${_lastSaved!.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(
                            fontSize: 11,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textSecondary,
                    ),
                  ),
                  Text(
                    '${(progressPercentage * 100).toInt()}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: (_currentQuestionIndex + 1) / questions.length,
                  backgroundColor: borderColor,
                  valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: PageView.builder(
        controller: _pageController,
        itemCount: questions.length,
        onPageChanged: (index) {
          setState(() {
            _currentQuestionIndex = index;
          });
        },
        itemBuilder: (context, index) {
          final question = questions[index];
          final isAnswered = answers.containsKey(question.id) &&
              answers[question.id]!.isNotEmpty;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            primaryBlue.withOpacity(0.1),
                            accentBlue.withOpacity(0.1)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: primaryBlue.withOpacity(0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.star_outline,
                            size: 16,
                            color: primaryBlue,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${question.marks} ${question.marks == 1 ? 'mark' : 'marks'}',
                            style: TextStyle(
                              color: primaryBlue,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: question.type == 'mcq'
                            ? secondaryBlue.withOpacity(0.1)
                            : Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: question.type == 'mcq'
                              ? secondaryBlue.withOpacity(0.3)
                              : Colors.purple.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        question.type.toUpperCase(),
                        style: TextStyle(
                          color: question.type == 'mcq'
                              ? secondaryBlue
                              : Colors.purple,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if (isAnswered)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: successGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.check_circle_outline,
                          size: 20,
                          color: successGreen,
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 24),

                // Question Text
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: backgroundGrey,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor.withOpacity(0.5)),
                  ),
                  child: Text(
                    question.questionText,
                    style: const TextStyle(
                      fontSize: 20,
                      color: textPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.6,
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Answer Section - Now scrollable within each question
                question.type == 'mcq'
                    ? _buildMCQOptions(question)
                    : _buildSubjectiveAnswer(question),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildNavigationSection() {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Question Navigation Dots
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: List.generate(questions.length, (index) {
                  final isActive = index == _currentQuestionIndex;
                  final isAnswered = answers.containsKey(questions[index].id) &&
                      answers[questions[index].id]!.isNotEmpty;

                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeInOutCubic,
                      );
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        gradient: isActive
                            ? LinearGradient(
                                colors: [primaryBlue, secondaryBlue])
                            : isAnswered
                                ? LinearGradient(colors: [
                                    successGreen,
                                    successGreen.withOpacity(0.8)
                                  ])
                                : null,
                        color: isActive || isAnswered
                            ? null
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isActive
                              ? Colors.transparent
                              : isAnswered
                                  ? Colors.transparent
                                  : borderColor,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: isAnswered && !isActive
                            ? const Icon(
                                Icons.check,
                                size: 16,
                                color: Colors.white,
                              )
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.white
                                      : isAnswered
                                          ? Colors.white
                                          : textSecondary,
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),

          const SizedBox(width: 20),

          // Navigation Buttons
          Row(
            children: [
              if (_currentQuestionIndex > 0)
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: textPrimary,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _previousQuestion,
                  icon: const Icon(Icons.arrow_back, size: 18),
                  label: const Text(
                    'Previous',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (_currentQuestionIndex > 0) const SizedBox(width: 12),
              _currentQuestionIndex < questions.length - 1
                  ? ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _nextQuestion,
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text(
                        'Next',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [successGreen, successGreen.withOpacity(0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: successGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () => _submitTest(false),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text(
                          'Submit Test',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }
}

// Add missing import for FontFeature if not already imported
