import 'package:flutter/material.dart';

/// Responsive Helper for Admin Dashboard
/// Provides breakpoints and responsive utilities
class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  /// Check if screen is mobile
  static bool isMobile(BuildContext context) {
    return MediaQuery.of(context).size.width < mobileBreakpoint;
  }

  /// Check if screen is tablet
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= mobileBreakpoint && width < desktopBreakpoint;
  }

  /// Check if screen is desktop
  static bool isDesktop(BuildContext context) {
    return MediaQuery.of(context).size.width >= desktopBreakpoint;
  }

  /// Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else if (isTablet(context)) {
      return const EdgeInsets.all(16);
    } else {
      return const EdgeInsets.all(20);
    }
  }

  /// Get responsive card padding
  static EdgeInsets getCardPadding(BuildContext context) {
    if (isMobile(context)) {
      return const EdgeInsets.all(12);
    } else {
      return const EdgeInsets.all(16);
    }
  }

  /// Get responsive spacing
  static double getSpacing(BuildContext context) {
    if (isMobile(context)) {
      return 12;
    } else if (isTablet(context)) {
      return 16;
    } else {
      return 20;
    }
  }

  /// Get responsive font size for title
  static double getTitleFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 18;
    } else if (isTablet(context)) {
      return 20;
    } else {
      return 24;
    }
  }

  /// Get responsive font size for body
  static double getBodyFontSize(BuildContext context) {
    if (isMobile(context)) {
      return 13;
    } else {
      return 14;
    }
  }

  /// Get grid column count based on screen size
  static int getGridColumnCount(BuildContext context) {
    if (isMobile(context)) {
      return 1;
    } else if (isTablet(context)) {
      return 2;
    } else {
      return 3;
    }
  }

  /// Get stats card column count
  static int getStatsColumnCount(BuildContext context) {
    if (isMobile(context)) {
      return 2;
    } else if (isTablet(context)) {
      return 3;
    } else {
      return 4;
    }
  }

  /// Build responsive layout
  static Widget buildResponsive({
    required BuildContext context,
    required Widget mobile,
    Widget? tablet,
    required Widget desktop,
  }) {
    if (isMobile(context)) {
      return mobile;
    } else if (isTablet(context)) {
      return tablet ?? desktop;
    } else {
      return desktop;
    }
  }

  /// Get max width for content
  static double getMaxContentWidth(BuildContext context) {
    if (isMobile(context)) {
      return double.infinity;
    } else if (isTablet(context)) {
      return 900;
    } else {
      return 1200;
    }
  }

  /// Get dialog width
  static double getDialogWidth(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (isMobile(context)) {
      return screenWidth * 0.9;
    } else if (isTablet(context)) {
      return 600;
    } else {
      return 700;
    }
  }

  /// Get responsive row/column
  static Widget buildAdaptiveRowColumn({
    required BuildContext context,
    required List<Widget> children,
    MainAxisAlignment mainAxisAlignment = MainAxisAlignment.start,
    CrossAxisAlignment crossAxisAlignment = CrossAxisAlignment.start,
  }) {
    if (isMobile(context)) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    } else {
      return Row(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    }
  }
}
