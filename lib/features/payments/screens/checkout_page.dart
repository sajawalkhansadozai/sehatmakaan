import 'package:flutter/material.dart';
import 'package:sehatmakaan/core/utils/responsive_helper.dart';
import 'package:sehatmakaan/core/constants/constants.dart';
import 'package:sehatmakaan/core/constants/types.dart';
import 'package:sehatmakaan/features/payments/services/payfast_service.dart';
import 'package:sehatmakaan/features/payments/screens/payfast_webview_screen.dart';

/// Unified Checkout Page
/// Complete checkout flow with cart summary, payment method, and order confirmation
class CheckoutPage extends StatefulWidget {
  final Map<String, dynamic> userSession;
  final List<CartItem> cartItems;

  const CheckoutPage({
    super.key,
    required this.userSession,
    required this.cartItems,
  });

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  String _selectedPaymentMethod = 'payfast';
  bool _termsAccepted = false;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'payfast',
      'name': 'PayFast',
      'icon': Icons.credit_card,
      'description': 'Secure online payment',
    },
    {
      'id': 'jazzcash',
      'name': 'JazzCash',
      'icon': Icons.phone_android,
      'description': 'Mobile wallet payment',
    },
    {
      'id': 'easypaisa',
      'name': 'EasyPaisa',
      'icon': Icons.phone_android,
      'description': 'Mobile wallet payment',
    },
    {
      'id': 'bank',
      'name': 'Bank Transfer',
      'icon': Icons.account_balance,
      'description': 'Direct bank transfer',
    },
  ];

  double get _subtotal {
    return widget.cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  double get _tax {
    return _subtotal * 0.0; // 0% tax for now
  }

  double get _total {
    return _subtotal + _tax;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
        elevation: 0,
      ),
      body: widget.cartItems.isEmpty
          ? _buildEmptyCart()
          : ResponsiveContainer(
              maxWidth: 900,
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    // Order Summary Section
                    _buildOrderSummarySection(),

                    const Divider(height: 32, thickness: 8),

                    // Payment Method Section
                    _buildPaymentMethodSection(),

                    const Divider(height: 32, thickness: 8),

                    // Terms and Conditions
                    _buildTermsSection(),

                    const Divider(height: 32, thickness: 8),

                    // Price Summary
                    _buildPriceSummary(),

                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
      bottomNavigationBar: widget.cartItems.isEmpty
          ? null
          : _buildBottomCheckoutButton(),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 120,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Add items to your cart to checkout',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back),
            label: const Text('Continue Shopping'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderSummarySection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.shopping_bag, color: Color(0xFF14B8A6)),
              const SizedBox(width: 8),
              const Text(
                'Order Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF14B8A6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${widget.cartItems.length} items',
                  style: const TextStyle(
                    color: Color(0xFF14B8A6),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...widget.cartItems.map((item) => _buildCartItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildCartItemCard(CartItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Item Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: _getItemColor(item.type).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getItemIcon(item.type),
                color: _getItemColor(item.type),
                size: 32,
              ),
            ),
            const SizedBox(width: 16),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.type.displayName,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  if (item.hours != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${item.hours} hour${item.hours! > 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),

            // Price and Quantity
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppConstants.formatCurrency(item.price),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF14B8A6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  'Subtotal: ${AppConstants.formatCurrency(item.price * item.quantity)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.payment, color: Color(0xFF14B8A6)),
              SizedBox(width: 8),
              Text(
                'Payment Method',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._paymentMethods.map((method) => _buildPaymentMethodCard(method)),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard(Map<String, dynamic> method) {
    final isSelected = _selectedPaymentMethod == method['id'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isSelected
          ? const Color(0xFF14B8A6).withValues(alpha: 0.05)
          : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? const Color(0xFF14B8A6) : Colors.grey[300]!,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedPaymentMethod = method['id'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Radio<String>(
                value: method['id'],
                groupValue: _selectedPaymentMethod,
                onChanged: (value) {
                  setState(() {
                    _selectedPaymentMethod = value!;
                  });
                },
                activeColor: const Color(0xFF14B8A6),
              ),
              const SizedBox(width: 12),
              Icon(
                method['icon'],
                color: isSelected ? const Color(0xFF14B8A6) : Colors.grey[600],
                size: 32,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected
                            ? const Color(0xFF14B8A6)
                            : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      method['description'],
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle,
                  color: Color(0xFF14B8A6),
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTermsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.description, color: Color(0xFF14B8A6)),
              SizedBox(width: 8),
              Text(
                'Terms & Conditions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'By completing this purchase, you agree to:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const SizedBox(height: 12),
                _buildTermItem('Our cancellation and refund policy'),
                _buildTermItem('Service terms and conditions'),
                _buildTermItem('Privacy policy and data usage'),
                _buildTermItem('Booking policies and guidelines'),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Checkbox(
                      value: _termsAccepted,
                      onChanged: (value) {
                        setState(() {
                          _termsAccepted = value ?? false;
                        });
                      },
                      activeColor: const Color(0xFF14B8A6),
                    ),
                    Expanded(
                      child: Text(
                        'I have read and agree to all terms and conditions',
                        style: TextStyle(fontSize: 14, color: Colors.grey[800]),
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

  Widget _buildTermItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.receipt_long, color: Color(0xFF14B8A6)),
              SizedBox(width: 8),
              Text(
                'Price Summary',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF14B8A6).withValues(alpha: 0.05),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF14B8A6).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                _buildPriceRow('Subtotal', _subtotal),
                const Divider(height: 24),
                _buildPriceRow('Tax', _tax),
                const Divider(height: 24),
                _buildPriceRow('Total', _total, isTotal: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, double amount, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isTotal ? 20 : 16,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            color: isTotal ? const Color(0xFF14B8A6) : Colors.black87,
          ),
        ),
        Text(
          AppConstants.formatCurrency(amount),
          style: TextStyle(
            fontSize: isTotal ? 24 : 18,
            fontWeight: FontWeight.bold,
            color: isTotal ? const Color(0xFF14B8A6) : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomCheckoutButton() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _termsAccepted && !_isProcessing
                    ? _processCheckout
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B8A6),
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                ),
                child: _isProcessing
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.lock, size: 24),
                          const SizedBox(width: 12),
                          Text(
                            'Complete Payment - ${AppConstants.formatCurrency(_total)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            if (!_termsAccepted)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Please accept terms and conditions to continue',
                  style: TextStyle(fontSize: 12, color: Colors.red[700]),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _processCheckout() async {
    setState(() => _isProcessing = true);

    try {
      final payFastService = PayFastService();
      final registrationId = 'REG-${DateTime.now().millisecondsSinceEpoch}';

      // Process payment with PayFast Pakistan
      final result = await payFastService.processWorkshopPayment(
        registrationId: registrationId,
        workshopId: 'cart-${DateTime.now().millisecondsSinceEpoch}',
        workshopTitle: widget.cartItems.map((item) => item.name).join(', '),
        amount: _total,
        userId: widget.userSession['userId'] ?? 'unknown',
        userEmail: widget.userSession['email'] ?? '',
        userName: widget.userSession['fullName'] ?? 'Customer',
      );

      if (mounted && result['success']) {
        final success = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (context) => PayFastWebViewScreen(
              paymentUrl: result['paymentUrl'],
              onPaymentSuccess: () {
                debugPrint('✅ Payment completed successfully');
              },
              onPaymentCancel: () {
                debugPrint('❌ Payment cancelled by user');
              },
            ),
          ),
        );

        if (success == true) {
          _showSuccessDialog();
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment cancelled'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Checkout Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 32),
            SizedBox(width: 12),
            Text('Payment Successful!'),
          ],
        ),
        content: const Text(
          'Your payment has been processed successfully. '
          'You will receive a confirmation email shortly.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.pushReplacementNamed(
                context,
                '/dashboard',
                arguments: widget.userSession,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF14B8A6)),
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  IconData _getItemIcon(CartItemType type) {
    switch (type) {
      case CartItemType.package:
        return Icons.card_giftcard;
      case CartItemType.addon:
        return Icons.extension;
      case CartItemType.hourly:
        return Icons.schedule;
    }
  }

  Color _getItemColor(CartItemType type) {
    switch (type) {
      case CartItemType.package:
        return Colors.purple;
      case CartItemType.addon:
        return Colors.orange;
      case CartItemType.hourly:
        return const Color(0xFF14B8A6);
    }
  }
}
