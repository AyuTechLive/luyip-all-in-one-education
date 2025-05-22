import 'package:flutter/material.dart';
import 'package:luyip_website_edu/helpers/colors.dart';

class ComingSoonScreen extends StatelessWidget {
  final String pageName;

  const ComingSoonScreen({Key? key, required this.pageName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.of(context).size;
    final bool isLargeScreen = screenSize.width > 900;
    final bool isMediumScreen =
        screenSize.width > 600 && screenSize.width <= 900;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              ColorManager.background,
              Colors.white,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom app bar
              _buildCustomAppBar(context),

              // Main content
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: isLargeScreen
                        ? _buildLargeScreenLayout(screenSize, context)
                        : isMediumScreen
                            ? _buildMediumScreenLayout(screenSize, context)
                            : _buildSmallScreenLayout(screenSize, context),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          // Back button
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(
                Icons.arrow_back_ios_new,
                color: ColorManager.primary,
                size: 20,
              ),
              padding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(width: 16),
          // Page title
          Expanded(
            child: Text(
              pageName,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: ColorManager.textDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLargeScreenLayout(Size screenSize, BuildContext context) {
    return Container(
      width: screenSize.width * 0.7,
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          // Left side with illustration
          Expanded(
            flex: 4,
            child: Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: ColorManager.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  bottomLeft: Radius.circular(24),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildIllustration(120),
                  const SizedBox(height: 32),
                  _buildFeaturesList(),
                ],
              ),
            ),
          ),

          // Right side with content
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: _buildMainContent(context, false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMediumScreenLayout(Size screenSize, BuildContext context) {
    return Container(
      width: screenSize.width * 0.85,
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            spreadRadius: 3,
          ),
        ],
      ),
      child: Column(
        children: [
          // Top section with illustration
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                _buildIllustration(100),
                const SizedBox(height: 24),
                _buildFeaturesList(),
              ],
            ),
          ),

          // Content section
          Padding(
            padding: const EdgeInsets.all(32),
            child: _buildMainContent(context, false),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallScreenLayout(Size screenSize, BuildContext context) {
    return Container(
      width: screenSize.width * 0.9,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header section
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: _buildIllustration(80),
          ),

          // Content section
          Padding(
            padding: const EdgeInsets.all(24),
            child: _buildMainContent(context, true),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(double size) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Background circle
        Container(
          width: size + 40,
          height: size + 40,
          decoration: BoxDecoration(
            color: ColorManager.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
        ),
        // Secondary circle
        Container(
          width: size + 20,
          height: size + 20,
          decoration: BoxDecoration(
            color: ColorManager.primary.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
        ),
        // Main icon container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: ColorManager.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.construction_outlined,
            size: size * 0.5,
            color: Colors.white,
          ),
        ),
        // Animated dots
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: ColorManager.primaryLight,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Positioned(
          bottom: 15,
          left: 15,
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: ColorManager.primary.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesList() {
    return Column(
      children: [
        _buildFeatureItem(Icons.rocket_launch_outlined, 'Advanced Features'),
        const SizedBox(height: 12),
        _buildFeatureItem(Icons.timeline_outlined, 'Enhanced User Experience'),
        const SizedBox(height: 12),
        _buildFeatureItem(Icons.security_outlined, 'Secure & Reliable'),
      ],
    );
  }

  Widget _buildFeatureItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ColorManager.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: ColorManager.primary,
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: ColorManager.textMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildMainContent(BuildContext context, bool isSmallScreen) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Main heading
        Text(
          'Coming Soon',
          style: TextStyle(
            fontSize: isSmallScreen ? 28 : 36,
            fontWeight: FontWeight.bold,
            color: ColorManager.textDark,
            letterSpacing: 1.0,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),

        // Page name with accent
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: ColorManager.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: ColorManager.primary.withOpacity(0.3),
            ),
          ),
          child: Text(
            pageName,
            style: TextStyle(
              fontSize: isSmallScreen ? 16 : 18,
              fontWeight: FontWeight.w600,
              color: ColorManager.primary,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Description
        Text(
          'We\'re working hard to bring you an amazing experience.\nThis feature will be available soon with enhanced functionality.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: ColorManager.textMedium,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 32),

        // Progress indicator
        _buildProgressIndicator(),
        const SizedBox(height: 32),

        // Action buttons
        _buildActionButtons(context, isSmallScreen),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Column(
      children: [
        Text(
          'Development Progress',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: ColorManager.textDark,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: 200,
          height: 8,
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              Container(
                width: 120, // 60% progress
                height: 8,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      ColorManager.primary,
                      ColorManager.primaryLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '60% Complete',
          style: TextStyle(
            fontSize: 12,
            color: ColorManager.textMedium,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isSmallScreen) {
    return Column(
      children: [
        // Primary button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 18),
            label: Text(
              'Go Back',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorManager.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Secondary button
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton.icon(
            onPressed: () {
              // Add notification functionality here
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('You\'ll be notified when $pageName is ready!'),
                  backgroundColor: ColorManager.primary,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              );
            },
            icon: const Icon(Icons.notifications_outlined, size: 18),
            label: Text(
              'Notify Me',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: ColorManager.primary,
              side: BorderSide(color: ColorManager.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
