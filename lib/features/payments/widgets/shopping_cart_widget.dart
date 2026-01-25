import 'package:flutter/material.dart';
import 'package:sehat_makaan_flutter/core/constants/types.dart';
import 'package:sehat_makaan_flutter/core/constants/constants.dart';

/// Shopping Cart Widget
/// Displays cart items in a dropdown with add/remove/quantity controls
class ShoppingCartWidget extends StatefulWidget {
  final Map<String, dynamic> userSession;
  final VoidCallback? onCheckout;
  final VoidCallback? onCartUpdated;

  const ShoppingCartWidget({
    super.key,
    required this.userSession,
    this.onCheckout,
    this.onCartUpdated,
  });

  @override
  State<ShoppingCartWidget> createState() => _ShoppingCartWidgetState();
}

class _ShoppingCartWidgetState extends State<ShoppingCartWidget> {
  final List<CartItem> _cartItems = [];

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      // In real implementation, load from user's cart in Firestore
      // For now, using local state
      // TODO: Implement persistent cart in Firestore
    } catch (e) {
      debugPrint('Error loading cart: $e');
    }
  }

  void _updateQuantity(String itemId, int delta) {
    setState(() {
      final index = _cartItems.indexWhere((i) => i.id == itemId);
      if (index >= 0) {
        final newQuantity = _cartItems[index].quantity + delta;
        if (newQuantity <= 0) {
          _cartItems.removeAt(index);
        } else {
          _cartItems[index] = _cartItems[index].copyWith(quantity: newQuantity);
        }
      }
    });
    widget.onCartUpdated?.call();
  }

  void _removeItem(String itemId) {
    setState(() {
      _cartItems.removeWhere((i) => i.id == itemId);
    });
    widget.onCartUpdated?.call();
  }

  void _clearCart() {
    setState(() {
      _cartItems.clear();
    });
    widget.onCartUpdated?.call();
  }

  double get _totalAmount {
    return _cartItems.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
  }

  int get _totalItems {
    return _cartItems.fold(0, (sum, item) => sum + item.quantity);
  }

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Stack(
        children: [
          const Icon(Icons.shopping_cart, size: 28),
          if (_totalItems > 0)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                child: Text(
                  _totalItems > 99 ? '99+' : _totalItems.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
      tooltip: 'Shopping Cart',
      offset: const Offset(0, 50),
      itemBuilder: (context) {
        if (_cartItems.isEmpty) {
          return [
            PopupMenuItem(
              enabled: false,
              child: SizedBox(
                width: 350,
                child: Column(
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add services to get started',
                      style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),
            ),
          ];
        }

        return [
          // Header
          PopupMenuItem(
            enabled: false,
            child: SizedBox(
              width: 350,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shopping_cart, color: Color(0xFF14B8A6)),
                      const SizedBox(width: 8),
                      Text(
                        'Cart ($_totalItems ${_totalItems == 1 ? 'item' : 'items'})',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _showClearCartDialog();
                    },
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text('Clear'),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),

          // Cart Items
          ..._cartItems.map(
            (item) => PopupMenuItem(
              enabled: false,
              child: SizedBox(width: 350, child: _buildCartItem(item)),
            ),
          ),

          const PopupMenuDivider(),

          // Total and Checkout
          PopupMenuItem(
            enabled: false,
            child: SizedBox(
              width: 350,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Total:',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Text(
                        AppConstants.formatCurrency(_totalAmount),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF14B8A6),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        widget.onCheckout?.call();
                      },
                      icon: const Icon(Icons.payment),
                      label: const Text('Proceed to Checkout'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B8A6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ];
      },
    );
  }

  Widget _buildCartItem(CartItem item) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Item Type Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getItemColor(item.type).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getItemIcon(item.type),
                    color: _getItemColor(item.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),

                // Item Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (item.description != null &&
                          item.description!.isNotEmpty)
                        Text(
                          item.description!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            AppConstants.formatCurrency(item.price),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF14B8A6),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.type.displayName,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Remove Button
                IconButton(
                  onPressed: () => _removeItem(item.id),
                  icon: const Icon(Icons.close, size: 20),
                  color: Colors.red,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Quantity Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      onPressed: () => _updateQuantity(item.id, -1),
                      icon: const Icon(Icons.remove_circle_outline),
                      color: const Color(0xFF14B8A6),
                      iconSize: 28,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Text(
                        item.quantity.toString(),
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => _updateQuantity(item.id, 1),
                      icon: const Icon(Icons.add_circle_outline),
                      color: const Color(0xFF14B8A6),
                      iconSize: 28,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                Text(
                  'Subtotal: ${AppConstants.formatCurrency(item.price * item.quantity)}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ],
        ),
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

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cart?'),
        content: const Text(
          'Are you sure you want to remove all items from your cart?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _clearCart();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Cart cleared'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Clear Cart'),
          ),
        ],
      ),
    );
  }
}
