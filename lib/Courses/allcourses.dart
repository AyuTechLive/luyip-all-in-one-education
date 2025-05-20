import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:luyip_website_edu/Courses/addcourse.dart';
import 'package:luyip_website_edu/Courses/course_deatils.dart';
import 'package:luyip_website_edu/Courses/widget/coursecardview.dart';
import 'package:luyip_website_edu/helpers/userauthtype.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

class AllCoursesScreen extends StatefulWidget {
  final String userType;
  const AllCoursesScreen({super.key, required this.userType});

  @override
  State<AllCoursesScreen> createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  final searchfiltercontroller = TextEditingController();
  final auth = FirebaseAuth.instance;
  bool loading = false;
  bool isAdmin = false;
  final fireStore =
      FirebaseFirestore.instance.collection('All Courses').snapshots();

  // For responsive grid view
  int _calculateCrossAxisCount(double width) {
    if (width > 1200) return 4;
    if (width > 900) return 3;
    if (width > 600) return 2;
    return 1;
  }

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    try {
      if (widget.userType == 'admin') {
        setState(() {
          isAdmin = true;
        });
      }
    } catch (e) {
      print("Error checking admin status: $e");
    }
  }

  void _refreshCourses() {
    setState(() {});
  }

  void _showAddCourseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.add_circle,
                  color: ColorManager.primary,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add New Course',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Would you like to add a new course to the platform?',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorManager.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                AddCourse(onCourseAdded: _refreshCourses),
                          ),
                        );
                      },
                      child: const Text('Add Course'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual,
      overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
    );
    final Size screensize = MediaQuery.of(context).size;
    final double height = screensize.height;
    final double width = screensize.width;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showAddCourseDialog,
              backgroundColor: ColorManager.primary,
              icon: const Icon(Icons.add),
              label: const Text('Add Course'),
              tooltip: 'Add New Course',
            )
          : null,
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TextFormField(
                      controller: searchfiltercontroller,
                      cursorColor: ColorManager.primary,
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.search,
                          color: ColorManager.primary,
                        ),
                        hintText: 'Search for courses...',
                        hintStyle: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                if (isAdmin && width > 600) ...[
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Add Course'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onPressed: _showAddCourseDialog,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Text(
                  'All Courses',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const Spacer(),
                // Could add filter/sort options here
              ],
            ),
          ),
          const SizedBox(height: 8),
          StreamBuilder<QuerySnapshot>(
            stream: fireStore,
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(
                      color: ColorManager.primary,
                    ),
                  ),
                );
              }

              if (snapshot.hasError) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Colors.red,
                          size: 60,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.library_books,
                          color: Colors.grey.shade400,
                          size: 80,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No courses available',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (isAdmin) ...[
                          ElevatedButton.icon(
                            icon: const Icon(Icons.add),
                            label: const Text('Add your first course'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: ColorManager.primary,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: _showAddCourseDialog,
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              // Filter courses based on search text
              final filteredDocs = snapshot.data!.docs.where((doc) {
                final coursename = doc['Course Name'].toString().toLowerCase();
                final searchText = searchfiltercontroller.text.toLowerCase();
                return searchText.isEmpty || coursename.contains(searchText);
              }).toList();

              if (filteredDocs.isEmpty) {
                return Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off,
                          color: Colors.grey.shade400,
                          size: 80,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'No courses match your search',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton(
                          onPressed: () {
                            searchfiltercontroller.clear();
                            setState(() {});
                          },
                          child: const Text('Clear search'),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final crossAxisCount = _calculateCrossAxisCount(
                        constraints.maxWidth,
                      );

                      return GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: width > 600 ? 0.9 : 0.8,
                        ),
                        itemCount: filteredDocs.length,
                        itemBuilder: (context, index) {
                          final doc = filteredDocs[index];
                          return Coursecardview(
                            loading: loading,
                            courseName: doc['Course Name'].toString(),
                            coursePrice: doc['Course Price'].toString(),
                            courseImgLink: doc['Course Img Link'].toString(),
                            courseDiscription:
                                doc['Course Discription'].toString(),
                            ontap: () {
                              setState(() {
                                loading = true;
                              });

                              searchAndCreateCourse1(
                                doc['Course Name'].toString(),
                                doc['Course Price'].toString(),
                                doc['Course Img Link'].toString(),
                                doc['Course Discription'].toString(),
                              ).then((value) {
                                setState(() {
                                  loading = false;
                                });
                              }).onError((error, stackTrace) {
                                setState(() {
                                  loading = false;
                                });
                              });
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> searchAndCreateCourse1(
    String coursename,
    String courseprice,
    String courseimg,
    String coursediscription,
  ) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String usersCollectionPath = 'Users';
    String? userEmailsDocumentId = checkUserAuthenticationType();
    String courseFieldKey = coursename;

    DocumentReference emailsDocumentRef = firestore
        .collection(usersCollectionPath)
        .doc(widget.userType)
        .collection("accounts")
        .doc(userEmailsDocumentId);

    DocumentSnapshot emailsSnapshot = await emailsDocumentRef.get();

    Map<String, dynamic> emailsData =
        emailsSnapshot.data() as Map<String, dynamic>;

    if (emailsData.containsKey(courseFieldKey) &&
        emailsData[courseFieldKey] is List) {
      List<dynamic> courseList = emailsData[courseFieldKey];
      if (courseList[0] == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CourseDetails(
              userRole: widget.userType,
              coursename: coursename,
              // courseprice: courseprice,
              // courseImage: courseimg,
              // coursediscription: coursediscription,
            ),
          ),
        );
      }
      if (courseList[0] == 2) {
        // Navigator.push for subject list would go here
      }
    } else {
      await emailsDocumentRef.set({
        courseFieldKey: [0],
      }, SetOptions(merge: true));
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CourseDetails(
            userRole: widget.userType,
            coursename: coursename,
            // courseprice: courseprice,
            // courseImage: courseimg,
            // coursediscription: coursediscription,
          ),
        ),
      );
    }
  }
}
