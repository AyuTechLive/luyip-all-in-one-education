import 'package:flutter/material.dart';
import 'package:luyip_website_edu/exams/test_model.dart';
import 'package:luyip_website_edu/helpers/colors.dart';
import 'package:luyip_website_edu/helpers/roundbutton.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class EditTestQuestionPage extends StatefulWidget {
  final TestQuestion question;

  const EditTestQuestionPage({
    Key? key,
    required this.question,
  }) : super(key: key);

  @override
  State<EditTestQuestionPage> createState() => _EditTestQuestionPageState();
}

class _EditTestQuestionPageState extends State<EditTestQuestionPage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _questionTextController;
  late TextEditingController _marksController;
  late TextEditingController _explanationController;
  String _questionType = 'mcq';
  List<TextEditingController> _optionControllers = [];
  int _correctAnswerIndex = 0;
  late TextEditingController _correctAnswerController;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    // Initialize main controllers
    _questionTextController =
        TextEditingController(text: widget.question.questionText);
    _marksController =
        TextEditingController(text: widget.question.marks.toString());
    _explanationController =
        TextEditingController(text: widget.question.explanation ?? '');
    _questionType = widget.question.type;

    // Initialize option controllers for MCQ
    if (_questionType == 'mcq' && widget.question.options != null) {
      // Create controllers for each option
      _optionControllers = List.generate(
        widget.question.options!.length,
        (index) => TextEditingController(text: widget.question.options![index]),
      );

      // Find the correct answer index
      if (widget.question.correctAnswer != null) {
        int index =
            widget.question.options!.indexOf(widget.question.correctAnswer!);
        _correctAnswerIndex = index != -1 ? index : 0;
      }
    } else {
      // Default to 4 options for MCQ if none provided
      _optionControllers = List.generate(
        4,
        (index) => TextEditingController(),
      );
    }

    // For subjective questions
    _correctAnswerController = TextEditingController(
      text: _questionType == 'subjective'
          ? widget.question.correctAnswer ?? ''
          : '',
    );
  }

  @override
  void dispose() {
    _questionTextController.dispose();
    _marksController.dispose();
    _explanationController.dispose();
    for (var controller in _optionControllers) {
      controller.dispose();
    }
    _correctAnswerController.dispose();
    super.dispose();
  }

  void _addOption() {
    setState(() {
      _optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    // Don't allow fewer than 2 options
    if (_optionControllers.length <= 2) {
      Utils().toastMessage('MCQ questions must have at least 2 options');
      return;
    }

    // Adjust correct answer index if needed
    if (index == _correctAnswerIndex) {
      _correctAnswerIndex = 0; // Reset to first option
    } else if (index < _correctAnswerIndex) {
      _correctAnswerIndex -=
          1; // Shift down if removed option was before the correct one
    }

    setState(() {
      _optionControllers[index].dispose();
      _optionControllers.removeAt(index);
    });
  }

  void _saveQuestion() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // For MCQ, validate that there are at least 2 options
    if (_questionType == 'mcq' && _optionControllers.length < 2) {
      Utils().toastMessage('MCQ questions must have at least 2 options');
      return;
    }

    // For MCQ, check that all options have text
    if (_questionType == 'mcq') {
      for (int i = 0; i < _optionControllers.length; i++) {
        if (_optionControllers[i].text.trim().isEmpty) {
          Utils().toastMessage('Option ${i + 1} cannot be empty');
          return;
        }
      }
    }

    // Create the updated question
    List<String>? options;
    String? correctAnswer;

    if (_questionType == 'mcq') {
      options = _optionControllers.map((c) => c.text.trim()).toList();
      correctAnswer = options[_correctAnswerIndex];
    } else if (_questionType == 'subjective') {
      correctAnswer = _correctAnswerController.text.trim();
    }

    final updatedQuestion = TestQuestion(
      id: widget.question.id,
      questionText: _questionTextController.text.trim(),
      type: _questionType,
      options: options,
      correctAnswer: correctAnswer,
      marks: int.tryParse(_marksController.text) ?? 1,
      explanation: _explanationController.text.trim().isNotEmpty
          ? _explanationController.text.trim()
          : null,
    );

    Navigator.pop(context, updatedQuestion);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: ColorManager.secondary,
        foregroundColor: Colors.white,
        title: const Text('Edit Question'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question ID information
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: ColorManager.textMedium),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Question ID:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: ColorManager.textMedium,
                              ),
                            ),
                            Text(
                              widget.question.id,
                              style: TextStyle(
                                color: ColorManager.textDark,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Question Type Selector
                Text(
                  'Question Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Multiple Choice'),
                        value: 'mcq',
                        groupValue: _questionType,
                        onChanged: (value) {
                          setState(() {
                            _questionType = value!;
                          });
                        },
                        activeColor: ColorManager.secondary,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Subjective'),
                        value: 'subjective',
                        groupValue: _questionType,
                        onChanged: (value) {
                          setState(() {
                            _questionType = value!;
                          });
                        },
                        activeColor: ColorManager.secondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Question Text
                TextFormField(
                  controller: _questionTextController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Question Text',
                    hintText: 'Enter your question here',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.help_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the question text';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Marks
                TextFormField(
                  controller: _marksController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Marks',
                    hintText: 'Enter marks for this question',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: const Icon(Icons.star_outline),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter marks';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Options for MCQ
                if (_questionType == 'mcq') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Options',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: ColorManager.textDark,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _addOption,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add Option'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.secondary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _optionControllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Radio<int>(
                              value: index,
                              groupValue: _correctAnswerIndex,
                              onChanged: (value) {
                                setState(() {
                                  _correctAnswerIndex = value!;
                                });
                              },
                              activeColor: ColorManager.secondary,
                            ),
                            Expanded(
                              child: TextFormField(
                                controller: _optionControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Option ${index + 1}',
                                  hintText: 'Enter option text',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 16,
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter option text';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _removeOption(index),
                              tooltip: 'Remove Option',
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle,
                            color: Colors.green.shade700, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Selected correct answer: ' +
                                (_correctAnswerIndex <
                                            _optionControllers.length &&
                                        _optionControllers[_correctAnswerIndex]
                                            .text
                                            .isNotEmpty
                                    ? _optionControllers[_correctAnswerIndex]
                                        .text
                                    : 'Option ${_correctAnswerIndex + 1}'),
                            style: TextStyle(color: Colors.green.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // For Subjective Questions
                if (_questionType == 'subjective') ...[
                  Text(
                    'Sample Answer (Optional)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: ColorManager.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _correctAnswerController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      labelText: 'Sample/Expected Answer',
                      hintText: 'Enter a sample answer (for teacher reference)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                // Explanation
                Text(
                  'Explanation (Optional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: ColorManager.textDark,
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _explanationController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Explanation',
                    hintText: 'Enter explanation for the correct answer',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  height: 55,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.save),
                    label: const Text(
                      'Save Question',
                      style: TextStyle(
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
                    ),
                    onPressed: _saveQuestion,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
