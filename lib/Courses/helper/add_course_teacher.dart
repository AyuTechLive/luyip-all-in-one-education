import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddCourseTeachers extends StatefulWidget {
  final List<Map<String, dynamic>> selectedTeachers;
  final Function(List<Map<String, dynamic>>) onTeachersChanged;

  const AddCourseTeachers({
    Key? key,
    required this.selectedTeachers,
    required this.onTeachersChanged,
  }) : super(key: key);

  @override
  State<AddCourseTeachers> createState() => _AddCourseTeachersState();
}

class _AddCourseTeachersState extends State<AddCourseTeachers> {
  List<Map<String, dynamic>> availableTeachers = [];
  bool isLoadingTeachers = true;

  @override
  void initState() {
    super.initState();
    _fetchTeachers();
  }

  Future<void> _fetchTeachers() async {
    try {
      setState(() {
        isLoadingTeachers = true;
      });

      final QuerySnapshot teacherSnapshot =
          await FirebaseFirestore.instance
              .collection('Users')
              .doc('teacher')
              .collection('accounts')
              .get();

      final List<Map<String, dynamic>> teachersList =
          teacherSnapshot.docs
              .map((doc) => doc.data() as Map<String, dynamic>)
              .toList();

      setState(() {
        availableTeachers = teachersList;
        isLoadingTeachers = false;
      });
    } catch (error) {
      setState(() {
        isLoadingTeachers = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load teachers: $error')),
      );
    }
  }

  bool isTeacherSelected(Map<String, dynamic> teacher) {
    return widget.selectedTeachers.any(
      (selectedTeacher) => selectedTeacher['Email'] == teacher['Email'],
    );
  }

  void toggleTeacherSelection(Map<String, dynamic> teacher) {
    List<Map<String, dynamic>> updatedTeachers = [...widget.selectedTeachers];

    if (isTeacherSelected(teacher)) {
      // Remove teacher if already selected
      updatedTeachers.removeWhere((t) => t['Email'] == teacher['Email']);
    } else {
      // Add teacher if not selected
      updatedTeachers.add(teacher);
    }

    widget.onTeachersChanged(updatedTeachers);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Assign Teachers',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Divider(color: Theme.of(context).primaryColor.withOpacity(0.5)),
        SizedBox(height: 8),

        // Selected teachers chips
        if (widget.selectedTeachers.isNotEmpty) ...[
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children:
                widget.selectedTeachers.map((teacher) {
                  return Chip(
                    avatar: CircleAvatar(
                      backgroundImage:
                          teacher['ProfilePicURL'] != null
                              ? NetworkImage(teacher['ProfilePicURL'])
                              : null,
                      child:
                          teacher['ProfilePicURL'] == null
                              ? Icon(Icons.person, size: 16)
                              : null,
                    ),
                    label: Text(teacher['Name'] ?? 'Unknown'),
                    deleteIcon: Icon(Icons.close, size: 16),
                    onDeleted: () => toggleTeacherSelection(teacher),
                  );
                }).toList(),
          ),
          SizedBox(height: 16),
        ],

        // Teacher selection list
        isLoadingTeachers
            ? Center(child: CircularProgressIndicator())
            : availableTeachers.isEmpty
            ? Center(child: Text('No teachers available'))
            : Container(
              height: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: ListView.builder(
                itemCount: availableTeachers.length,
                itemBuilder: (context, index) {
                  final teacher = availableTeachers[index];
                  final isSelected = isTeacherSelected(teacher);

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          teacher['ProfilePicURL'] != null
                              ? NetworkImage(teacher['ProfilePicURL'])
                              : null,
                      child:
                          teacher['ProfilePicURL'] == null
                              ? Icon(Icons.person)
                              : null,
                    ),
                    title: Text(teacher['Name'] ?? 'Unknown'),
                    subtitle: Text(
                      teacher['Subject'] ?? 'No subject specified',
                    ),
                    trailing:
                        isSelected
                            ? Icon(
                              Icons.check_circle,
                              color: Theme.of(context).primaryColor,
                            )
                            : null,
                    selected: isSelected,
                    selectedTileColor: Theme.of(
                      context,
                    ).primaryColor.withOpacity(0.1),
                    onTap: () => toggleTeacherSelection(teacher),
                  );
                },
              ),
            ),
      ],
    );
  }
}
