import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_network/image_network.dart';

class Coursecardview extends StatelessWidget {
  final String courseName;
  final String courseDiscription;
  final VoidCallback ontap;
  final String courseImgLink;
  final String coursePrice;
  final bool loading;
  final String teacherName;

  const Coursecardview({
    super.key,
    required this.courseName,
    required this.courseDiscription,
    required this.ontap,
    required this.courseImgLink,
    required this.coursePrice,
    this.loading = false,
    this.teacherName = '',
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with web-specific handling
          AspectRatio(aspectRatio: 16 / 9, child: _buildImageWidget()),

          // Course details
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  courseName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xff321f73),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  courseDiscription,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0EAFB),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '₹ $coursePrice',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xff321f73),
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff321f73),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                      onPressed: loading ? null : ontap,
                      child:
                          loading
                              ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Explore',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Special handling for web images to fix CORS issues
  Widget _buildImageWidget() {
    if (kIsWeb) {
      return LayoutBuilder(
        builder: (context, constraints) {
          return ImageNetwork(
            image: courseImgLink,
            height: constraints.maxHeight,
            width: constraints.maxWidth,
            fitAndroidIos: BoxFit.cover,
            fitWeb: BoxFitWeb.cover,
            onLoading: const Center(
              child: CircularProgressIndicator(color: Color(0xff321f73)),
            ),
            onError: _buildImageErrorWidget(),
          );
        },
      );
    } else {
      return FadeInImage.assetNetwork(
        placeholder: 'assets/images/course_placeholder.png',
        image: courseImgLink,
        fit: BoxFit.cover,
        imageErrorBuilder: (context, error, stackTrace) {
          return _buildImageErrorWidget();
        },
      );
    }
  }

  Widget _buildImageErrorWidget() {
    return Container(
      color: Colors.grey.shade200,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 40,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8),
          Text(
            'Image not available',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
