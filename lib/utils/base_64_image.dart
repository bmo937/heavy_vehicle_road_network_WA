import 'dart:convert';
import 'package:flutter/material.dart';

class Base64Image extends StatelessWidget {
  final String? base64String;
  final double width;
  final double height;
  final Widget? placeholder;

  const Base64Image({
    super.key,
    required this.base64String,
    this.width = 24,
    this.height = 24,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    if (base64String == null || base64String!.isEmpty) {
      return placeholder ?? Container(
        width: width,
        height: height,
        color: Colors.grey.withValues(alpha:0.3),
        child: const Icon(Icons.image_not_supported, size: 16),
      );
    }

    try {
      return Image.memory(
        base64Decode(base64String!),
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading base64 image: $error');
          return placeholder ?? Container(
            width: width,
            height: height,
            color: Colors.grey.withValues(alpha:0.3),
            child: const Icon(Icons.broken_image, size: 16),
          );
        },
      );
    } catch (e) {
      debugPrint('Exception decoding base64 image: $e');
      return placeholder ?? Container(
        width: width,
        height: height,
        color: Colors.grey.withValues(alpha:0.3),
        child: const Icon(Icons.error_outline, size: 16),
      );
    }
  }
}