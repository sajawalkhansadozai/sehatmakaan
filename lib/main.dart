import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/network/firebase_options.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/auth/screens/landing_page.dart';
import 'features/auth/screens/login_page.dart';
import 'features/auth/screens/registration_page_new.dart';
import 'features/auth/screens/agreement_page.dart';
import 'features/auth/screens/verification_page.dart';
import 'features/auth/screens/account_suspended_page.dart';

import 'features/subscriptions/screens/packages_page.dart';
import 'features/subscriptions/screens/dashboard_page.dart';
import 'features/subscriptions/screens/monthly_dashboard_page.dart';
import 'features/bookings/screens/analytics_page.dart';
import 'features/auth/screens/settings_page.dart';
import 'features/workshops/screens/user/workshops_page.dart';
import 'features/workshops/screens/user/create_workshop_page.dart';
import 'features/auth/screens/help_and_support_page.dart';
import 'features/admin/screens/admin_dashboard_page.dart';
import 'features/bookings/screens/user/booking_workflow_page.dart';
import 'features/workshops/screens/user/workshop_registration_page.dart';
import 'features/workshops/screens/user/workshop_checkout_page.dart';
import 'features/workshops/screens/user/workshop_creation_fee_checkout_page.dart';
import 'features/auth/screens/credentials_page.dart';
import 'features/payments/screens/checkout_page.dart';
import 'features/bookings/screens/my_schedule_page.dart';
import 'features/bookings/screens/live_slot_booking_page.dart';
import 'core/common_widgets/not_found_page.dart';
import 'services/session_storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: SehatMakaanApp()));
}

class SehatMakaanApp extends StatelessWidget {
  const SehatMakaanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sehat Makaan',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF006876),
          primary: const Color(0xFF006876),
          secondary: const Color(0xFFFF6B35),
        ),
        fontFamily: 'Inter',
        scaffoldBackgroundColor: const Color(0xFFE6F7F9),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF006876),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFFF6B35),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
        ),
        cardTheme: const CardThemeData(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
        ),
      ),
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
    );
  }

  Route<dynamic>? _generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());

      case '/landing':
        return MaterialPageRoute(
          builder: (context) => LandingPage(
            onLoginClick: () {
              Navigator.pushNamed(context, '/login');
            },
          ),
        );

      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case '/registration':
        return MaterialPageRoute(builder: (_) => const RegistrationPage());

      case '/agreement':
        return MaterialPageRoute(builder: (_) => const AgreementPage());

      case '/verification':
        final Map<String, dynamic> userSession =
            args as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) =>
              VerificationPage(userId: userSession['id']?.toString()),
        );

      case '/account-suspended':
        final String reason = args is String
            ? args
            : 'Terms and Conditions Violation';
        return MaterialPageRoute(
          builder: (_) => AccountSuspendedPage(reason: reason),
        );

      case '/packages':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => PackagesPage(
              userSession: args['userSession'],
              selectedSuite: args['selectedSuite'],
            ),
          );
        }
        return MaterialPageRoute(builder: (_) => const PackagesPage());

      case '/dashboard':
        final userSession = args is Map<String, dynamic>
            ? args
            : <String, dynamic>{};
        return MaterialPageRoute(
          builder: (_) => DashboardPage(userSession: userSession),
        );

      case '/analytics':
        final userSession = args is Map<String, dynamic>
            ? args
            : <String, dynamic>{};
        return MaterialPageRoute(
          builder: (_) => AnalyticsPage(userSession: userSession),
        );

      case '/settings':
        final userSession = args is Map<String, dynamic>
            ? args
            : <String, dynamic>{};
        return MaterialPageRoute(
          builder: (_) => SettingsPage(userSession: userSession),
        );

      case '/monthly-dashboard':
        final userSession = args is Map<String, dynamic>
            ? args
            : <String, dynamic>{};
        return MaterialPageRoute(
          builder: (_) => MonthlyDashboardPage(userSession: userSession),
        );

      case '/workshops':
        final userSession = args is Map<String, dynamic>
            ? args
            : <String, dynamic>{};
        return MaterialPageRoute(
          builder: (_) => WorkshopsPage(userSession: userSession),
        );

      case '/create-workshop':
        final userSession = args is Map<String, dynamic>
            ? args
            : <String, dynamic>{};
        return MaterialPageRoute(
          builder: (_) => CreateWorkshopPage(userSession: userSession),
        );

      case '/admin-login':
        // Reuse the shared login flow for admins
        return MaterialPageRoute(builder: (_) => const LoginPage());

      case '/admin-dashboard':
        debugPrint('🔍 Admin Dashboard Route - Raw args: $args');
        final Map<String, dynamic> adminSession =
            args as Map<String, dynamic>? ?? {'username': 'admin'};
        debugPrint('🔍 Admin Dashboard Route - adminSession: $adminSession');
        return MaterialPageRoute(
          builder: (_) => AdminDashboardPage(adminSession: adminSession),
        );

      case '/booking-workflow':
        final userSession = args is Map<String, dynamic>
            ? args
            : <String, dynamic>{};
        return MaterialPageRoute(
          builder: (_) => BookingWorkflowPage(userSession: userSession),
        );

      case '/live-slot-booking':
        final userSession = args is Map<String, dynamic>
            ? args
            : <String, dynamic>{};
        return MaterialPageRoute(
          builder: (_) => LiveSlotBookingPage(userSession: userSession),
        );

      case '/workshop-registration':
        if (args is Map<String, dynamic>) {
          final userSession = args['userSession'] is Map<String, dynamic>
              ? args['userSession'] as Map<String, dynamic>
              : <String, dynamic>{};
          return MaterialPageRoute(
            builder: (_) => WorkshopRegistrationPage(
              workshop: args['workshop'],
              userSession: userSession,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Workshop Registration')),
            body: const Center(child: Text('Missing workshop data')),
          ),
        );

      case '/workshop-checkout':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => const WorkshopCheckoutPage(),
            settings: RouteSettings(arguments: args),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Workshop Checkout')),
            body: const Center(child: Text('Missing checkout data')),
          ),
        );

      case '/workshop-creation-fee-checkout':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => const WorkshopCreationFeeCheckoutPage(),
            settings: RouteSettings(arguments: args),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Workshop Creation Fee')),
            body: const Center(child: Text('Missing workshop data')),
          ),
        );

      case '/credentials':
        if (args is Map<String, dynamic>) {
          return MaterialPageRoute(
            builder: (_) => CredentialsPage(
              username: args['username'] ?? 'N/A',
              password: args['password'] ?? 'N/A',
              userId: args['userId']?.toString(),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('Missing credentials data')),
          ),
        );

      case '/checkout':
        if (args is Map<String, dynamic>) {
          final userSession = args['userSession'] is Map<String, dynamic>
              ? args['userSession'] as Map<String, dynamic>
              : <String, dynamic>{};
          return MaterialPageRoute(
            builder: (_) => CheckoutPage(
              cartItems: args['cartItems'] ?? [],
              userSession: userSession,
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Checkout')),
            body: const Center(child: Text('Missing cart data')),
          ),
        );

      case '/my-schedule':
        final userSession = args is Map<String, dynamic>
            ? args
            : <String, dynamic>{};
        return MaterialPageRoute(
          builder: (_) => MySchedulePage(userSession: userSession),
        );

      case '/help-support':
        final userSession = args is Map<String, dynamic>
            ? args
            : <String, dynamic>{};
        return MaterialPageRoute(
          builder: (_) => HelpAndSupportPage(userSession: userSession),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => NotFoundPage(attemptedRoute: settings.name),
        );
    }
  }

  /// Get stored user session from secure encrypted storage
  /// Uses SessionStorageService for encrypted session persistence
  // ignore: unused_element
  Future<Map<String, dynamic>> _getStoredUserSession() async {
    try {
      final sessionService = SessionStorageService();
      final session = await sessionService.getUserSession();
      debugPrint(
        '📱 Loaded session from secure storage: ${session.isNotEmpty}',
      );
      return session;
    } catch (e) {
      debugPrint('⚠️ Error loading session: $e');
      return {};
    }
  }
}
