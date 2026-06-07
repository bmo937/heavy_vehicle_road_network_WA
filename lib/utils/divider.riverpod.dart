import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:roads_map/utils/app_themes.riverpod.dart';

part 'divider.riverpod.g.dart';

@riverpod
Widget divider(Ref ref) {
  final primaryColor = ref.watch(primaryColorProvider);
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8.0),
    child: Divider(
      indent: 10,
      endIndent: 10,
      height: 2,
      thickness: 2,
      color: primaryColor,
    ),
  );
}
