import 'package:flutter/material.dart';

/// Responsive Helper for adaptive layouts across platforms
class ResponsiveHelper {
  // Breakpoints
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // Check device type
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileBreakpoint;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileBreakpoint &&
      MediaQuery.of(context).size.width < desktopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= desktopBreakpoint;

  // Get responsive value based on screen size
  static T getResponsiveValue<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context)) return desktop ?? tablet ?? mobile;
    if (isTablet(context)) return tablet ?? mobile;
    return mobile;
  }

  // Get max width for content
  static double getMaxContentWidth(BuildContext context) {
    if (isDesktop(context)) return 1200;
    if (isTablet(context)) return 900;
    return double.infinity;
  }

  // Get responsive padding
  static EdgeInsets getResponsivePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: getResponsiveValue(
        context,
        mobile: 16,
        tablet: 24,
        desktop: 32,
      ),
      vertical: getResponsiveValue(
        context,
        mobile: 16,
        tablet: 20,
        desktop: 24,
      ),
    );
  }

  // Get responsive font size
  static double getResponsiveFontSize(
    BuildContext context,
    double baseFontSize,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < mobileBreakpoint) return baseFontSize;
    if (screenWidth < desktopBreakpoint) return baseFontSize * 1.1;
    return baseFontSize * 1.2;
  }

  // Get number of columns for grid
  static int getGridColumns(BuildContext context) {
    return getResponsiveValue(context, mobile: 1, tablet: 2, desktop: 3);
  }

  // Check if landscape
  static bool isLandscape(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.landscape;

  // Get responsive spacing
  static double getResponsiveSpacing(BuildContext context) {
    return getResponsiveValue(context, mobile: 8, tablet: 12, desktop: 16);
  }
}

/// Responsive Container Widget
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        constraints: BoxConstraints(
          maxWidth: maxWidth ?? ResponsiveHelper.getMaxContentWidth(context),
        ),
        padding: padding ?? ResponsiveHelper.getResponsivePadding(context),
        child: child,
      ),
    );
  }
}

/// Responsive Builder Widget
class ResponsiveBuilder extends StatelessWidget {
  final Widget Function(BuildContext context, BoxConstraints constraints)
  builder;

  const ResponsiveBuilder({super.key, required this.builder});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => builder(context, constraints),
    );
  }
}

/// Adaptive Layout Widget
class AdaptiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const AdaptiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= ResponsiveHelper.desktopBreakpoint) {
          return desktop ?? tablet ?? mobile;
        } else if (constraints.maxWidth >= ResponsiveHelper.mobileBreakpoint) {
          return tablet ?? mobile;
        }
        return mobile;
      },
    );
  }
}
