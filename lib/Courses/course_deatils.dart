import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:luyip_website_edu/helpers/userauthtype.dart';

import 'package:firebase_auth/firebase_auth.dart';

class CourseDetails extends StatefulWidget {
  final String coursename;
  final String courseprice;
  final String courseImage;
  final String coursediscription;

  const CourseDetails({
    super.key,
    required this.coursename,
    required this.courseprice,
    required this.courseImage,
    required this.coursediscription,
  });

  @override
  State<CourseDetails> createState() => _CourseDetailsState();
}

class _CourseDetailsState extends State<CourseDetails> {
  final auth = FirebaseAuth.instance;
  final fireStore = FirebaseFirestore.instance.collection('Users').snapshots();
  CollectionReference ref = FirebaseFirestore.instance.collection('Users');

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final Size screensize = MediaQuery.of(context).size;
    final double height = screensize.height;
    final double width = screensize.width;

    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(height: height * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: width * 0.1),
                          child: Text(
                            widget.coursename,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 24,
                              fontFamily: 'Lato',
                              fontWeight: FontWeight.w800,
                              height: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.03),

                    Container(
                      height: height * 0.20,
                      width: width * 0.8,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          widget.courseImage,
                          scale: 1.0,
                          fit: BoxFit.fill,
                        ),
                      ),
                    ),

                    SizedBox(height: height * 0.03),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [Spacer(), Spacer()],
                    ),
                    SizedBox(height: height * 0.063),
                    Row(
                      children: [
                        SizedBox(width: width * 0.07),
                        Text(
                          'Course contents :',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontFamily: 'Lato',
                            fontWeight: FontWeight.w800,
                            height: 0,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: height * 0.03),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: width * 0.05),
                        SizedBox(width: width * 0.05),
                        Column(
                          children: [
                            SizedBox(
                              width: width * 0.8,
                              child: Text(
                                widget.coursediscription,
                                style: TextStyle(
                                  color: Color(0xFF3F434A),
                                  fontSize: 15,
                                  fontFamily: 'Lato',
                                  fontWeight: FontWeight.w500,
                                  height: 0,
                                ),
                                softWrap: true,
                                maxLines: 100,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    SizedBox(height: 50),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(0, 0, 0, height * 0.02),
              child: Container(
                width: width * 0.833,
                height: height * 0.075,
                decoration: ShapeDecoration(
                  color: Color(0xff321f73),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
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
                child: Center(
                  child: Text(
                    'View Course Details',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontFamily: 'Lato',
                      fontWeight: FontWeight.w900,
                      height: 0,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> addCourseToUserProfile(String coursename) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    String usersCollectionPath = 'Users';
    String? userEmailsDocumentId = checkUserAuthenticationType();
    String courseFieldKey = coursename;

    DocumentReference emailsDocumentRef = firestore
        .collection(usersCollectionPath)
        .doc(userEmailsDocumentId);

    try {
      DocumentSnapshot emailsSnapshot = await emailsDocumentRef.get();

      if (emailsSnapshot.exists) {
        Map<String, dynamic> emailsData =
            emailsSnapshot.data() as Map<String, dynamic>;

        if (emailsData.containsKey(courseFieldKey) &&
            emailsData[courseFieldKey] is List) {
          List<dynamic> courseList = emailsData[courseFieldKey];
          if (courseList[0] == 0) {
            await emailsDocumentRef.update({
              courseFieldKey: [2],
            });
            List<dynamic> myCourseList =
                (emailsData['My Courses'] ?? []) as List<dynamic>;

            List<String> updatedCourseList =
                myCourseList
                    .map((dynamic course) => course.toString())
                    .toList();

            updatedCourseList.add(coursename);

            await emailsDocumentRef.update({'My Courses': updatedCourseList});
          }
        }
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }
}
