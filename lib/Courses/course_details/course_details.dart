import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:luyip_website_edu/Courses/course_details/course_detail_sections.dart';
import 'package:luyip_website_edu/Courses/course_details/course_membership_helper.dart';
import 'package:luyip_website_edu/Courses/course_details/course_payment_service.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

class CourseDetails extends StatefulWidget {
  final String coursename;
  final String userRole;

  const CourseDetails(
      {super.key, required this.coursename, required this.userRole});

  @override
  State<CourseDetails> createState() => _CourseDetailsState();
}

class _CourseDetailsState extends State<CourseDetails> {
  late Future<DocumentSnapshot> _courseFuture;
  final ScrollController _scrollController = ScrollController();
  bool _isScrolled = false;
  int _activeTab = 0;
  bool _isEnrolled = false;
  bool _isProcessingPayment = false;

  // Membership related states
  bool _isMember = false;
  double _discountedPrice = 0.0;
  double _originalPrice = 0.0;
  double _discountPercentage = 0.0;
  bool _isLoadingMembership = true;

  // Services
  late CoursePaymentService _paymentService;
  final CourseMembershipHelper _membershipHelper = CourseMembershipHelper();

  @override
  void initState() {
    super.initState();
    _courseFuture = FirebaseFirestore.instance
        .collection('All Courses')
        .doc(widget.coursename)
        .get();

    _scrollController.addListener(() {
      setState(() {
        _isScrolled = _scrollController.offset > 80;
      });
    });

    _paymentService = CoursePaymentService(
      context: context,
      onEnrollmentStatusChanged: (status) {
        setState(() {
          _isEnrolled = status;
        });
      },
      onProcessingStatusChanged: (status) {
        setState(() {
          _isProcessingPayment = status;
        });
      },
    );
    _paymentService.initialize();

    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      // Check enrollment status
      bool isEnrolled =
          await _paymentService.checkEnrollmentStatus(widget.coursename);

      // Check membership status
      final membershipData =
          await _membershipHelper.checkMembershipStatus(widget.coursename);

      setState(() {
        _isEnrolled = isEnrolled;
        _isMember = membershipData['isMember'] ?? false;
        _discountPercentage = membershipData['discountPercentage'] ?? 0.0;
        _originalPrice = membershipData['originalPrice'] ?? 0.0;
        _discountedPrice = membershipData['discountedPrice'] ?? 0.0;
        _isLoadingMembership = false;
      });
    } catch (e) {
      print("Error loading initial data: $e");
      setState(() {
        _isLoadingMembership = false;
      });
    }
  }

  void _handleEnrollment(double price) {
    print('Handling enrollment for ${widget.coursename}');
    print('Original price: $price');
    print('Is member: $_isMember');
    print('Discount percentage: $_discountPercentage');
    print('Discounted price: $_discountedPrice');

    _paymentService.handleEnrollment(
      widget.coursename,
      price,
      _isMember,
      _discountedPrice,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _paymentService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: ColorManager.background,
      body: FutureBuilder<DocumentSnapshot>(
        future: _courseFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: ColorManager.primary,
                strokeWidth: 3,
              ),
            );
          }

          if (snapshot.hasError ||
              !snapshot.hasData ||
              !snapshot.data!.exists) {
            return CourseDetailSections.buildErrorState(context);
          }

          var data = snapshot.data!.data() as Map<String, dynamic>;
          List teachers = data['Teachers'] ?? [];
          List notices = data['Notices'] ?? [];
          List<dynamic> keyDocuments = data['KeyDocuments'] ?? [];
          List<dynamic> learningObjectives = data['LearningObjectives'] ?? [];
          List<dynamic> featureCards = data['FeatureCards'] ?? [];
          String scheduleDocumentUrl = data['SchedulePDF'] ?? '';

          // Parse course price - ensure this matches the pricing logic in service
          String priceStr = data['Course Price'] ?? 'FREE';
          double price = 0.0;
          if (priceStr.toLowerCase() != 'free') {
            // Remove currency symbol and convert to double
            price =
                double.tryParse(priceStr.replaceAll(RegExp(r'[^\d.]'), '')) ??
                    0.0;
          }

          print('Course price parsed: $price from "$priceStr"');

          return NestedScrollView(
            controller: _scrollController,
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              CourseDetailSections.buildSliverAppBar(
                data,
                size,
                widget.coursename,
                _isScrolled,
                _isEnrolled,
                _isMember,
                _discountPercentage,
                _originalPrice,
                _discountedPrice,
                _isLoadingMembership,
                widget.userRole,
                context,
              ),
            ],
            body: Container(
              decoration: BoxDecoration(
                color: ColorManager.background,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CourseDetailSections.buildTabBar(_activeTab, (index) {
                      setState(() {
                        _activeTab = index;
                      });
                    }),
                    const SizedBox(height: 16),
                    _buildTabContent(
                      data,
                      teachers,
                      notices,
                      size,
                      price,
                      learningObjectives,
                      featureCards,
                      keyDocuments,
                      scheduleDocumentUrl,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      floatingActionButton:
          _isEnrolled || _isProcessingPayment || widget.userRole == 'franchise'
              ? null
              : AnimatedOpacity(
                  opacity: _isScrolled ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: FutureBuilder<DocumentSnapshot>(
                    future: _courseFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting ||
                          !snapshot.hasData ||
                          !snapshot.data!.exists) {
                        return Container();
                      }

                      var data = snapshot.data!.data() as Map<String, dynamic>;
                      String priceStr = data['Course Price'] ?? 'FREE';
                      double price = 0.0;
                      if (priceStr.toLowerCase() != 'free') {
                        price = double.tryParse(
                              priceStr.replaceAll(RegExp(r'[^\d.]'), ''),
                            ) ??
                            0.0;
                      }

                      double finalPrice = _isMember && _discountPercentage > 0
                          ? _discountedPrice
                          : price;
                      String buttonText = price > 0
                          ? finalPrice < price
                              ? 'PAY ₹${finalPrice.toStringAsFixed(0)} & ENROLL'
                              : 'PAY & ENROLL'
                          : 'ENROLL NOW';

                      return FloatingActionButton.extended(
                        onPressed: () => _handleEnrollment(price),
                        backgroundColor: ColorManager.primary,
                        label: Text(
                          buttonText,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        icon: price > 0
                            ? const Icon(Icons.payment)
                            : const Icon(Icons.school),
                      );
                    },
                  ),
                ),
    );
  }

  Widget _buildTabContent(
    Map<String, dynamic> data,
    List teachers,
    List notices,
    Size size,
    double price,
    List<dynamic> learningObjectives,
    List<dynamic> featureCards,
    List<dynamic> keyDocuments,
    String scheduleDocumentUrl,
  ) {
    switch (_activeTab) {
      case 0:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CourseDetailSections.buildCourseInfo(
                  data,
                  learningObjectives,
                  _isMember,
                  _discountPercentage,
                  context,
                  widget.userRole,
                  widget.coursename),
              const SizedBox(height: 24),
              CourseDetailSections.buildFeatureCards(featureCards),
              const SizedBox(height: 40),
              // Hide enrollment section for franchise users
              if (widget.userRole != 'franchise')
                CourseDetailSections.buildEnrollSection(
                  size,
                  price,
                  _isEnrolled,
                  _isProcessingPayment,
                  _isMember,
                  _discountPercentage,
                  _discountedPrice,
                  _handleEnrollment,
                ),
            ],
          ),
        );
      case 1:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CourseDetailSections.buildTeachersSection(teachers),
        );
      case 2:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CourseDetailSections.buildCourseTimeline(
              notices, scheduleDocumentUrl, context),
        );
      case 3:
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CourseDetailSections.buildMaterialsSection(
            data,
            keyDocuments,
            _isEnrolled,
            widget.coursename,
            widget.userRole, // Pass userRole here
            context,
          ),
        );
      default:
        return Container();
    }
  }
}
