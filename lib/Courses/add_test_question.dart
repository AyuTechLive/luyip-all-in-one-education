import 'package:flutter/material.dart';
import 'package:luyip_website_edu/exams/test_model.dart';
import 'package:luyip_website_edu/helpers/utils.dart';

class AddQuestionAdmin extends StatefulWidget {
  const AddQuestionAdmin({super.key});

  @override
  State<AddQuestionAdmin> createState() => _AddQuestionAdminState();
}

class _AddQuestionAdminState extends State<AddQuestionAdmin> {
  final _formKey = GlobalKey<FormState>();

  final questionTextController = TextEditingController();
  final marksController = TextEditingController();
  final explanationController = TextEditingController();
  final correctAnswerController = TextEditingController();

  String questionType = 'mcq'; // Default type
  List<TextEditingController> optionControllers = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    questionTextController.dispose();
    marksController.dispose();
    explanationController.dispose();
    correctAnswerController.dispose();
    for (var controller in optionControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addOption() {
    setState(() {
      optionControllers.add(TextEditingController());
    });
  }

  void _removeOption(int index) {
    if (optionControllers.length > 2) {
      setState(() {
        optionControllers[index].dispose();
        optionControllers.removeAt(index);
      });
    } else {
      Utils().toastMessage('A minimum of 2 options is required');
    }
  }

  void _saveQuestion() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // For MCQ questions, validate that correct answer is one of the options
    if (questionType == 'mcq') {
      final correctAnswer = correctAnswerController.text.trim();
      final options = optionControllers.map((c) => c.text.trim()).toList();

      if (!options.contains(correctAnswer)) {
        Utils()
            .toastMessage('The correct answer must match one of the options');
        return;
      }
    }

    // Create question ID with timestamp
    final questionId = 'q_${DateTime.now().millisecondsSinceEpoch}';

    final question = TestQuestion(
      id: questionId,
      questionText: questionTextController.text.trim(),
      type: questionType,
      options: questionType == 'mcq'
          ? optionControllers.map((c) => c.text.trim()).toList()
          : null,
      correctAnswer: correctAnswerController.text.trim(),
      marks: int.parse(marksController.text),
      explanation: explanationController.text.isNotEmpty
          ? explanationController.text.trim()
          : null,
    );

    Navigator.pop(context, question);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xff321f73),
        foregroundColor: Colors.white,
        title: const Text('Add Question'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Question Type Selection
                const Text(
                  'Question Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),

                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('MCQ'),
                        value: 'mcq',
                        groupValue: questionType,
                        onChanged: (value) {
                          setState(() {
                            questionType = value!;
                          });
                        },
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<String>(
                        title: const Text('Subjective'),
                        value: 'subjective',
                        groupValue: questionType,
                        onChanged: (value) {
                          setState(() {
                            questionType = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Question Text
                TextFormField(
                  controller: questionTextController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Question Text',
                    hintText: 'Enter the question here',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter the question';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Marks
                TextFormField(
                  controller: marksController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Marks',
                    hintText: 'Enter marks for this question',
                    border: OutlineInputBorder(),
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

                const SizedBox(height: 20),

                // MCQ Options
                if (questionType == 'mcq') ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Options',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xff321f73),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: _addOption,
                        icon: const Icon(Icons.add),
                        label: const Text('Add Option'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: optionControllers.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: optionControllers[index],
                                decoration: InputDecoration(
                                  labelText: 'Option ${index + 1}',
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Please enter option ${index + 1}';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              onPressed: () => _removeOption(index),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],

                const SizedBox(height: 20),

                // Correct Answer
                TextFormField(
                  controller: correctAnswerController,
                  maxLines: questionType == 'mcq' ? 1 : 3,
                  decoration: InputDecoration(
                    labelText: questionType == 'mcq'
                        ? 'Correct Option (must match one of the options)'
                        : 'Correct Answer (for auto evaluation)',
                    hintText: questionType == 'mcq'
                        ? 'Enter the correct option exactly as written above'
                        : 'Enter the correct answer for automatic evaluation',
                    helperText: questionType == 'subjective'
                        ? 'Leave blank if teacher will manually evaluate'
                        : null,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (questionType == 'mcq' &&
                        (value == null || value.isEmpty)) {
                      return 'Please enter the correct option';
                    }
                    return null; // Optional for subjective
                  },
                ),

                const SizedBox(height: 20),

                // Explanation (Optional)
                TextFormField(
                  controller: explanationController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Explanation (Optional)',
                    hintText: 'Explain the correct answer',
                    border: OutlineInputBorder(),
                  ),
                ),

                const SizedBox(height: 30),

                // Save Button
                Center(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xff321f73),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(200, 50),
                    ),
                    onPressed: _saveQuestion,
                    child: const Text('Save Question'),
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
