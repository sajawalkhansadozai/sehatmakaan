import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class PayFastWebViewScreen extends StatefulWidget {
  final String paymentUrl;
  final VoidCallback? onPaymentSuccess;
  final VoidCallback? onPaymentCancel;

  const PayFastWebViewScreen({
    super.key,
    required this.paymentUrl,
    this.onPaymentSuccess,
    this.onPaymentCancel,
  });

  @override
  State<PayFastWebViewScreen> createState() => _PayFastWebViewScreenState();
}

class _PayFastWebViewScreenState extends State<PayFastWebViewScreen> {
  WebViewController? _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      _launchPaymentUrlOnWeb();
    } else {
      _initializeWebView();
    }
  }

  Future<void> _launchPaymentUrlOnWeb() async {
    // For web platform, open payment URL in new browser tab
    final uri = Uri.parse(widget.paymentUrl);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);

        // Show loading dialog while waiting for payment
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (context) => WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: const Text('Processing Payment'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Please complete your payment in the new browser window.\n\n'
                      'This dialog will close automatically once payment is detected.',
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      widget.onPaymentCancel?.call();
                      Navigator.pop(context);
                      Navigator.pop(context, false);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Cancel Payment'),
                  ),
                ],
              ),
            ),
          );
        }
      } else {
        debugPrint('❌ Cannot launch URL: ${widget.paymentUrl}');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Unable to open payment page'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context, false);
        }
      }
    } catch (e) {
      debugPrint('❌ Error launching URL: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
        Navigator.pop(context, false);
      }
    }
  }

  void _initializeWebView() {
    try {
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(Colors.white)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (!mounted) return;
              setState(() => _isLoading = true);
              debugPrint('🌐 Page started: $url');

              // ✅ Robust redirect detection using startsWith
              if (url.startsWith('https://sehatmakaan.com/payment/success')) {
                debugPrint('✅ Payment Success detected from URL');
                widget.onPaymentSuccess?.call();
                if (mounted) Navigator.of(context).pop(true);
              } else if (url.startsWith(
                'https://sehatmakaan.com/payment/cancel',
              )) {
                debugPrint('❌ Payment Cancelled detected from URL');
                widget.onPaymentCancel?.call();
                if (mounted) Navigator.of(context).pop(false);
              }
            },
            onPageFinished: (String url) {
              if (!mounted) return;
              setState(() => _isLoading = false);
              debugPrint('✅ Page finished: $url');
            },
            onWebResourceError: (WebResourceError error) {
              debugPrint('❌ WebView error: ${error.description}');
              debugPrint('❌ Error code: ${error.errorCode}');
              debugPrint('❌ Error type: ${error.errorType}');

              // Don't crash on errors, just log them
              if (!mounted) return;
              setState(() => _isLoading = false);
            },
            onNavigationRequest: (NavigationRequest request) {
              debugPrint('🔄 Navigation to: ${request.url}');
              return NavigationDecision.navigate;
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.paymentUrl)).catchError((error) {
          debugPrint('❌ Failed to load payment URL: $error');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to load payment page: $error'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.of(context).pop(false);
          }
        });
    } catch (e) {
      debugPrint('❌ WebView initialization error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error initializing payment: $e'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.of(context).pop(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // For web, show loading indicator while opening external payment
    if (kIsWeb) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(0xFF006876),
          foregroundColor: Colors.white,
          title: const Text('Opening Payment Page'),
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF006876)),
              SizedBox(height: 16),
              Text(
                'Opening payment page in new window...',
                style: TextStyle(fontSize: 16, color: Color(0xFF006876)),
              ),
            ],
          ),
        ),
      );
    }

    // For mobile, use WebView
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF006876),
        foregroundColor: Colors.white,
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancel Payment?'),
                content: const Text(
                  'Are you sure you want to cancel the payment?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Continue Payment'),
                  ),
                  TextButton(
                    onPressed: () {
                      widget.onPaymentCancel?.call();
                      Navigator.pop(context);
                      Navigator.pop(context, false);
                    },
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_isLoading)
            Container(
              color: Colors.white,
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF006876)),
                    SizedBox(height: 16),
                    Text(
                      'Loading payment page...',
                      style: TextStyle(fontSize: 16, color: Color(0xFF006876)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
