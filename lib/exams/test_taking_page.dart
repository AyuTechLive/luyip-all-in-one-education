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

class _TestTakingPageState extends State<TestTakingPage> {
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

  @override
  void initState() {
    super.initState();

    _loadQuestions();
  }

  @override
  void dispose() {
    _timer.cancel();
    _autoSaveTimer?.cancel();

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
        builder: (context) => AlertDialog(
          title: const Text('Submit Test?'),
          content: const Text(
            'Are you sure you want to submit this test? You cannot change your answers after submission.',
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
              child: const Text('Submit'),
            ),
          ],
        ),
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Widget _buildMCQOptions(TestQuestion question) {
    // Handle case where options might be null or empty
    final options = question.options ?? ['Option not available'];
    if (options.isEmpty) {
      return const Center(
        child: Text('No options available for this question'),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...List.generate(options.length, (index) {
          final option = options[index];
          final isSelected = selectedOptions[question.id] == index;

          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              onTap: () {
                setState(() {
                  selectedOptions[question.id] = index;
                  answers[question.id] = option;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xff321f73)
                        : Colors.grey.shade300,
                    width: isSelected ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  color: isSelected
                      ? const Color(0xff321f73).withOpacity(0.05)
                      : Colors.white,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xff321f73)
                              : Colors.grey.shade400,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color:
                            isSelected ? const Color(0xff321f73) : Colors.white,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: Colors.white,
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option,
                        style: TextStyle(
                          fontSize: 16,
                          color: ColorManager.textDark,
                          fontWeight:
                              isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
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
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: controller,
            maxLines: 8,
            decoration: const InputDecoration(
              hintText: 'Type your answer here...',
              border: InputBorder.none,
              contentPadding: EdgeInsets.all(16),
            ),
            onChanged: (value) {
              answers[question.id] = value;
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading Test'),
          backgroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading test questions...'),
            ],
          ),
        ),
      );
    }

    return WillPopScope(
      onWillPop: () async {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit Test?'),
            content: const Text(
              'Your progress will be saved, but the test will not be submitted. Are you sure you want to exit?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );

        return confirmed ?? false;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Row(
            children: [
              Expanded(
                child: Text(
                  widget.test['title'] ?? 'Test',
                  style: TextStyle(
                    color: ColorManager.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _secondsRemaining < 300
                      ? Colors.red.withOpacity(0.1)
                      : const Color(0xff321f73).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.timer,
                      size: 16,
                      color: _secondsRemaining < 300
                          ? Colors.red
                          : const Color(0xff321f73),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _timeDisplay,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _secondsRemaining < 300
                            ? Colors.red
                            : const Color(0xff321f73),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme: IconThemeData(color: ColorManager.textDark),
        ),
        body: SafeArea(
          child: isSubmitting
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Submitting your test...'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Progress indicator
                    Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Question ${_currentQuestionIndex + 1} of ${questions.length}',
                                style: TextStyle(
                                  color: ColorManager.textMedium,
                                  fontSize: 14,
                                ),
                              ),
                              if (_lastSaved != null)
                                Text(
                                  'Last saved: ${_lastSaved!.hour}:${_lastSaved!.minute.toString().padLeft(2, '0')}',
                                  style: TextStyle(
                                    color: ColorManager.textMedium,
                                    fontSize: 14,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          LinearProgressIndicator(
                            value: ((_currentQuestionIndex + 1) /
                                questions.length),
                            backgroundColor: Colors.grey.shade200,
                            color: const Color(0xff321f73),
                          ),
                        ],
                      ),
                    ),

                    // Questions and Answers
                    Expanded(
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

                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Question mark display
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff321f73)
                                        .withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(
                                    '${question.marks} ${question.marks == 1 ? 'mark' : 'marks'}',
                                    style: const TextStyle(
                                      color: Color(0xff321f73),
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Question type
                                Text(
                                  question.type.toUpperCase(),
                                  style: TextStyle(
                                    color: ColorManager.textMedium,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 12),

                                // Question text
                                Text(
                                  question.questionText,
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: ColorManager.textDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Answer section
                                question.type == 'mcq'
                                    ? _buildMCQOptions(question)
                                    : _buildSubjectiveAnswer(question),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    // Navigation and Submit Buttons
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
                      child: Row(
                        children: [
                          if (_currentQuestionIndex > 0)
                            Expanded(
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.grey.shade200,
                                  foregroundColor: ColorManager.textDark,
                                ),
                                onPressed: _previousQuestion,
                                icon: const Icon(Icons.arrow_back),
                                label: const Text('Previous'),
                              ),
                            ),
                          if (_currentQuestionIndex > 0)
                            const SizedBox(width: 12),
                          Expanded(
                            child: _currentQuestionIndex < questions.length - 1
                                ? ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff321f73),
                                    ),
                                    onPressed: _nextQuestion,
                                    icon: const Icon(Icons.arrow_forward),
                                    label: const Text('Next'),
                                  )
                                : ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                    ),
                                    onPressed: () => _submitTest(false),
                                    icon: const Icon(Icons.check),
                                    label: const Text('Submit Test'),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
