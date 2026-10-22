import 'package:flutter/material.dart';

enum ScreenType { compact, medium, expanded }

ScreenType getScreenType(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < 600) {
    return ScreenType.compact;
  } else if (width < 840) {
    return ScreenType.medium;
  } else {
    return ScreenType.expanded;
  }
}

bool isCompact(BuildContext context) => getScreenType(context) == ScreenType.compact;
bool isMedium(BuildContext context) => getScreenType(context) == ScreenType.medium;
bool isExpanded(BuildContext context) => getScreenType(context) == ScreenType.expanded;
