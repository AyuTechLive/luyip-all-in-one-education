import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:luyip_website_edu/Courses/helper/add_course_teacher.dart';
import 'package:luyip_website_edu/Courses/helper/file_upload_handler.dart';
import 'package:luyip_website_edu/Courses/helper/image_upload_handler.dart';
import 'package:luyip_website_edu/helpers/roundbutton.dart';
import 'package:luyip_website_edu/helpers/utils.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

// Import the new components
// import 'image_upload_handler.dart';
// import 'add_course_teachers.dart';

class AddCourse extends StatefulWidget {
  final Function? onCourseAdded;
  const AddCourse({super.key, this.onCourseAdded});

  @override
  State<AddCourse> createState() => _AddCourseState();
}

class _AddCourseState extends State<AddCourse> {
  bool loading = false;
  final coursediscriptioncontroller = TextEditingController();
  final coursenamecontroller = TextEditingController();
  final coursepricecontroller = TextEditingController();
  final courseimglinkcontroller = TextEditingController();
  final discountPercentageController = TextEditingController();
  final durationController = TextEditingController();
  final prerequisitesController = TextEditingController();
  final previewPdfController = TextEditingController();
  final previewVideoController = TextEditingController();
  final syllabusPdfController = TextEditingController();
  late FileUploadHandler previewPdfHandler;
  late FileUploadHandler syllabusPdfHandler;

  bool isFeaturesCourse = false;
  String selectedCategory = 'Programming';
  List<String> categories = [
    'Programming',
    'Design',
    'Business',
    'Marketing',
    'Finance',
    'Personal Development',
    'Other',
  ];

  // Replace single teacher with list of teachers
  List<Map<String, dynamic>> selectedTeachers = [];

  final fireStore = FirebaseFirestore.instance.collection('All Courses');

  // Use the ImageUploadHandler instead of direct File handling
  late ImageUploadHandler imageHandler;
  Future<void> _handleFileUpload({
    required FileUploadHandler handler,
    required TextEditingController controller,
    required String storagePath,
  }) async {
    final success = await handler.pickFile();
    if (!success) return;

    setState(() => loading = true);
    try {
      final url = await handler.uploadFile(storagePath);
      controller.text = url;
      Utils().toastMessage('File uploaded successfully!');
    } catch (e) {
      Utils().toastMessage('Upload failed: ${e.toString()}');
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    previewPdfHandler = FileUploadHandler(); // No need for fileType parameter
    syllabusPdfHandler = FileUploadHandler();
    imageHandler = ImageUploadHandler();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add New Course',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: ColorManager.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        padding: EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Course Information',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: ColorManager.textDark,
                ),
              ),
              SizedBox(height: 16),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Basic Details'),
                        SizedBox(height: 16),

                        // Course name field
                        _buildTextField(
                          controller: coursenamecontroller,
                          labelText: 'Course Name',
                          hintText: 'Enter course name',
                          prefixIcon: Icons.title,
                          maxLines: 1,
                        ),
                        SizedBox(height: 16),

                        // Course category dropdown
                        _buildDropdownField(
                          labelText: 'Category',
                          value: selectedCategory,
                          items:
                              categories.map((category) {
                                return DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                );
                              }).toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedCategory = value!;
                            });
                          },
                          prefixIcon: Icons.category,
                        ),
                        SizedBox(height: 16),

                        // Course description field
                        _buildTextField(
                          controller: coursediscriptioncontroller,
                          labelText: 'Course Description',
                          hintText: 'Provide a detailed description',
                          prefixIcon: Icons.description,
                          maxLines: 5,
                        ),
                        SizedBox(height: 24),

                        _buildSectionTitle('Pricing Information'),
                        SizedBox(height: 16),

                        // Course price field
                        _buildTextField(
                          controller: coursepricecontroller,
                          labelText: 'Price (\$)',
                          hintText: 'Enter course price',
                          prefixIcon: Icons.attach_money,
                          keyboardType: TextInputType.number,
                          maxLines: 1,
                        ),
                        SizedBox(height: 16),

                        // Discount percentage field
                        _buildTextField(
                          controller: discountPercentageController,
                          labelText: 'Membership Discount (%)',
                          hintText: 'Enter discount percentage for members',
                          prefixIcon: Icons.discount,
                          keyboardType: TextInputType.number,
                          maxLines: 1,
                        ),
                        SizedBox(height: 24),

                        _buildSectionTitle('Additional Information'),
                        SizedBox(height: 16),

                        // Duration field
                        _buildTextField(
                          controller: durationController,
                          labelText: 'Course Duration',
                          hintText: 'e.g., 8 weeks, 12 hours',
                          prefixIcon: Icons.timer,
                          maxLines: 1,
                        ),
                        SizedBox(height: 16),

                        // Prerequisites field
                        _buildTextField(
                          controller: prerequisitesController,
                          labelText: 'Prerequisites',
                          hintText: 'Any requirements or prerequisites',
                          prefixIcon: Icons.list_alt,
                          maxLines: 3,
                        ),
                        SizedBox(height: 16),
                        _buildSectionTitle('Additional Materials'),
                        SizedBox(height: 16),
                        // Preview Video Link
                        _buildTextField(
                          controller: previewVideoController,
                          labelText: 'Preview Video Link',
                          hintText: 'Enter YouTube/Vimeo URL',
                          prefixIcon: Icons.video_library,
                        ),
                        SizedBox(height: 16),

                        // Preview PDF Upload
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: previewPdfController,
                                labelText: 'Preview PDF',
                                hintText: 'Upload course preview PDF',
                                prefixIcon: Icons.picture_as_pdf,
                                // readOnly: true,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.upload),
                              onPressed:
                                  () async => _handleFileUpload(
                                    handler: previewPdfHandler,
                                    controller: previewPdfController,
                                    storagePath: 'course_previews',
                                  ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),

                        // Syllabus PDF Upload
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextField(
                                controller: syllabusPdfController,
                                labelText: 'Syllabus PDF',
                                hintText: 'Upload course syllabus',
                                prefixIcon: Icons.assignment,
                                // readOnly: true,
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.upload),
                              onPressed:
                                  () async => _handleFileUpload(
                                    handler: syllabusPdfHandler,
                                    controller: syllabusPdfController,
                                    storagePath: 'course_syllabi',
                                  ),
                            ),
                          ],
                        ),

                        // Featured course checkbox
                        CheckboxListTile(
                          title: Text('Featured Course'),
                          value: isFeaturesCourse,
                          onChanged: (value) {
                            setState(() {
                              isFeaturesCourse = value!;
                            });
                          },
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 32),

                  // Right column
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Course Banner Image'),
                        SizedBox(height: 16),

                        // Image upload section using the new handler
                        imageHandler.getImagePreview(
                          height: 200,
                          width: double.infinity,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        SizedBox(height: 16),

                        ElevatedButton.icon(
                          icon: Icon(Icons.upload),
                          label: Text('Select Banner Image'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: ColorManager.primary,
                            foregroundColor: Colors.white,
                            minimumSize: Size(double.infinity, 48),
                          ),
                          onPressed: () async {
                            final success = await imageHandler.pickImage();
                            if (success) {
                              setState(() {
                                loading = true;
                              });
                              try {
                                final imageUrl = await imageHandler
                                    .uploadImageToFirebase('/course_banners');
                                courseimglinkcontroller.text = imageUrl;
                              } catch (e) {
                                Utils().toastMessage(
                                  'Failed to upload image: $e',
                                );
                              } finally {
                                setState(() {
                                  loading = false;
                                });
                              }
                            }
                          },
                        ),
                        SizedBox(height: 24),

                        // Replace single teacher selection with multiple teachers component
                        AddCourseTeachers(
                          selectedTeachers: selectedTeachers,
                          onTeachersChanged: (teachers) {
                            setState(() {
                              selectedTeachers = teachers;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              SizedBox(height: 32),

              // Submit button
              Center(
                child: SizedBox(
                  width: 300,
                  height: 50,
                  child: Roundbuttonnew(
                    loading: loading,
                    title: 'Create Course',
                    ontap: _createCourse,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: ColorManager.primary,
          ),
        ),
        Divider(color: ColorManager.primary.withOpacity(0.5)),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData prefixIcon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdownField({
    required String labelText,
    required String value,
    required List<DropdownMenuItem<String>> items,
    required Function(String?) onChanged,
    required IconData prefixIcon,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          isExpanded: true,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _createCourse() async {
    // Validate required fields
    if (coursenamecontroller.text.isEmpty ||
        coursediscriptioncontroller.text.isEmpty ||
        coursepricecontroller.text.isEmpty ||
        courseimglinkcontroller.text.isEmpty) {
      Utils().toastMessage('Please fill in all required fields');
      return;
    }

    if (selectedTeachers.isEmpty) {
      Utils().toastMessage(
        'Please select at least one teacher for this course',
      );
      return;
    }

    setState(() {
      loading = true;
    });

    String id = coursenamecontroller.text.toString();
    try {
      // Prepare teachers data structure
      List<Map<String, dynamic>> teachersData =
          selectedTeachers
              .map(
                (teacher) => {
                  'Name': teacher['Name'],
                  'Email': teacher['Email'],
                  'ProfilePicURL': teacher['ProfilePicURL'],
                  'Subject': teacher['Subject'],
                },
              )
              .toList();

      await fireStore.doc(id).set({
        'Course Name': coursenamecontroller.text.toString(),
        'Course Discription': coursediscriptioncontroller.text.toString(),
        'Course Price': coursepricecontroller.text,
        'Course Img Link': courseimglinkcontroller.text.toString(),
        'Category': selectedCategory,
        'Membership Discount':
            discountPercentageController.text.isEmpty
                ? "0"
                : discountPercentageController.text,
        'Duration': durationController.text,
        'Prerequisites': prerequisitesController.text,
        if (previewVideoController.text.isNotEmpty)
          'PreviewVideo': previewVideoController.text,
        if (previewPdfController.text.isNotEmpty)
          'PreviewPDF': previewPdfController.text,
        if (syllabusPdfController.text.isNotEmpty)
          'SyllabusPDF': syllabusPdfController.text,
        'Is Featured': isFeaturesCourse,
        'Teachers': teachersData, // Store as array instead of single teacher
        'Created At': FieldValue.serverTimestamp(),
      });

      // Also add the course to each teacher's My Courses list
      for (var teacher in selectedTeachers) {
        final teacherRef = FirebaseFirestore.instance
            .collection('Users')
            .doc('teacher')
            .collection('accounts')
            .where('Email', isEqualTo: teacher['Email'])
            .limit(1);

        final teacherDocs = await teacherRef.get();
        if (teacherDocs.docs.isNotEmpty) {
          final teacherDoc = teacherDocs.docs.first;
          List<dynamic> currentCourses = teacherDoc.data()['My Courses'] ?? [];
          if (!currentCourses.contains(coursenamecontroller.text.toString())) {
            currentCourses.add(coursenamecontroller.text.toString());
            await teacherDoc.reference.update({'My Courses': currentCourses});
          }
        }
      }

      Utils().toastMessage('Course Created Successfully');

      if (widget.onCourseAdded != null) {
        widget.onCourseAdded!();
      }

      Navigator.pop(context);
    } catch (error) {
      Utils().toastMessage(error.toString());
    } finally {
      setState(() {
        loading = false;
      });
    }
  }
}
