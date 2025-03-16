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
  const AllCoursesScreen({super.key});

  @override
  State<AllCoursesScreen> createState() => _AllCoursesScreenState();
}

class _AllCoursesScreenState extends State<AllCoursesScreen> {
  final searchfiltercontroller = TextEditingController();
  final auth = FirebaseAuth.instance;
  bool loading = false;
  bool isAdmin = false; // Flag to determine if user has admin privileges
  final fireStore =
      FirebaseFirestore.instance.collection('All Courses').snapshots();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  // Function to check if current user has admin privileges
  Future<void> _checkAdminStatus() async {
    try {
      String? userType = checkUserAuthenticationType();
      if (userType == 'admin') {
        setState(() {
          isAdmin = true;
        });
      }
    } catch (e) {
      // Handle error
      print("Error checking admin status: $e");
    }
  }

  // Function to refresh course list
  void _refreshCourses() {
    setState(() {
      // This will trigger a rebuild and fetch the latest data
    });
  }

  // Function to show Add Course dialog
  void _showAddCourseDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Course'),
          content: Text('Would you like to add a new course?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorManager.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (context) => AddCourse(onCourseAdded: _refreshCourses),
                  ),
                );
              },
              child: Text('Add Course'),
            ),
          ],
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
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCourseDialog,
        backgroundColor: ColorManager.primary,
        child: Icon(Icons.add),
        tooltip: 'Add New Course',
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    width: width * 0.833,
                    height: height * 0.04875,
                    decoration: ShapeDecoration(
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      shadows: [
                        BoxShadow(
                          color: Color(0x3F000000),
                          blurRadius: 4,
                          offset: Offset(0, 4),
                          spreadRadius: 0,
                        ),
                      ],
                    ),
                    child: TextFormField(
                      textAlign: TextAlign.justify,
                      controller: searchfiltercontroller,
                      cursorColor: Color(0xff7455F7),
                      decoration: InputDecoration(
                        icon: Padding(
                          padding: EdgeInsets.fromLTRB(
                            width * 0.03,
                            height * 0.001,
                            0,
                            height * 0.001,
                          ),
                          child: Icon(Icons.search),
                        ),
                        hintText: 'Search For The Course',
                        iconColor: Color(0xff7455F7),
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                    ),
                  ),
                ),
                if (isAdmin) ...[
                  SizedBox(width: 16),
                  ElevatedButton.icon(
                    icon: Icon(Icons.add),
                    label: Text('Add Course'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.primary,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _showAddCourseDialog,
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: 10),
          StreamBuilder<QuerySnapshot>(
            stream: fireStore,
            builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return Center(child: CircularProgressIndicator());

              if (snapshot.hasError)
                return Center(child: Text('Error: ${snapshot.error}'));

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                return Center(child: Text('No courses available'));

              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.separated(
                    separatorBuilder: (context, index) {
                      return SizedBox(height: height * 0.0125);
                    },
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final coursename =
                          snapshot.data!.docs[index]['Course Name'].toString();
                      if (searchfiltercontroller.text.isEmpty) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: height * 0.02),
                          child: Coursecardview(
                            loading: loading,
                            courseName:
                                snapshot.data!.docs[index]['Course Name']
                                    .toString(),
                            coursePrice:
                                snapshot.data!.docs[index]['Course Price']
                                    .toString(),
                            courseImgLink:
                                snapshot.data!.docs[index]['Course Img Link']
                                    .toString(),
                            courseDiscription:
                                snapshot.data!.docs[index]['Course Discription']
                                    .toString(),
                            // teacherName: snapshot.data!.docs[index]['Teacher'] != null ?
                            //     snapshot.data!.docs[index]['Teacher']['Name']?.toString() : 'Not Assigned',
                            ontap: () {
                              setState(() {
                                loading = true;
                              });

                              searchAndCreateCourse1(
                                    snapshot.data!.docs[index]['Course Name']
                                        .toString(),
                                    snapshot.data!.docs[index]['Course Price']
                                        .toString(),
                                    snapshot
                                        .data!
                                        .docs[index]['Course Img Link']
                                        .toString(),
                                    snapshot
                                        .data!
                                        .docs[index]['Course Discription']
                                        .toString(),
                                  )
                                  .then((value) {
                                    setState(() {
                                      loading = false;
                                    });
                                  })
                                  .onError((error, stackTrace) {
                                    setState(() {
                                      loading = false;
                                    });
                                  });
                            },
                          ),
                        );
                      } else if (coursename.toLowerCase().toString().contains(
                        searchfiltercontroller.text.toLowerCase().toString(),
                      )) {
                        return Coursecardview(
                          loading: loading,
                          courseName:
                              snapshot.data!.docs[index]['Course Name']
                                  .toString(),
                          coursePrice:
                              snapshot.data!.docs[index]['Course Price']
                                  .toString(),
                          courseImgLink:
                              snapshot.data!.docs[index]['Course Img Link']
                                  .toString(),
                          courseDiscription:
                              snapshot.data!.docs[index]['Course Discription']
                                  .toString(),
                          // teacherName: snapshot.data!.docs[index]['Teacher'] != null ?
                          //     snapshot.data!.docs[index]['Teacher']['Name']?.toString() : 'Not Assigned',
                          ontap: () {
                            setState(() {
                              loading = true;
                            });

                            searchAndCreateCourse1(
                                  snapshot.data!.docs[index]['Course Name']
                                      .toString(),
                                  snapshot.data!.docs[index]['Course Price']
                                      .toString(),
                                  snapshot.data!.docs[index]['Course Img Link']
                                      .toString(),
                                  snapshot
                                      .data!
                                      .docs[index]['Course Discription']
                                      .toString(),
                                )
                                .then((value) {
                                  setState(() {
                                    loading = false;
                                  });
                                })
                                .onError((error, stackTrace) {
                                  setState(() {
                                    loading = false;
                                  });
                                });
                          },
                        );
                      } else {
                        return Container();
                      }
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
    String usersCollectionPath = 'Users'; // The collection name
    String? userEmailsDocumentId =
        checkUserAuthenticationType(); // The document name
    String courseFieldKey =
        coursename; // The field key for the course data within the emails document

    // Reference to the emails document in the users collection
    DocumentReference emailsDocumentRef = firestore
        .collection(usersCollectionPath)
        .doc(userEmailsDocumentId);

    // Get the current snapshot of the emails document
    DocumentSnapshot emailsSnapshot = await emailsDocumentRef.get();

    Map<String, dynamic> emailsData =
        emailsSnapshot.data() as Map<String, dynamic>;

    // Check if the courseFieldKey already exists and is a list
    if (emailsData.containsKey(courseFieldKey) &&
        emailsData[courseFieldKey] is List) {
      // CourseFieldKey exists and is a list, print its values
      List<dynamic> courseList = emailsData[courseFieldKey];
      if (courseList[0] == 0) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => CourseDetails(
                  coursename: coursename,
                  courseprice: courseprice,
                  courseImage: courseimg,
                  coursediscription: coursediscription,
                ),
          ),
        );
      } // commented for while testing
      if (courseList[0] == 2) {
        // Navigator.push(
        //     context,
        //     MaterialPageRoute(
        //       builder: (context) => NewSubjectList(
        //           coursename: coursename, courseimglink: courseimg),
        //     )); // commeted till Newsubject list not created//
      }
    } else {
      // CourseFieldKey does not exist as a list, add it as an empty list
      await emailsDocumentRef.set(
        {
          courseFieldKey: [0],

          // Initialize with a list containing the value 0
        },
        SetOptions(merge: true),
      ); // Using merge to update the document without overwriting other fields
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => CourseDetails(
                coursename: coursename,
                courseprice: courseprice,
                courseImage: courseimg,
                coursediscription: coursediscription,
              ),
        ),
      );
      ///////
    }
  }
}
