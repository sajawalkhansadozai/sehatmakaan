import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../core/constants/types.dart';

/// Service class for managing shopping cart operations
/// Provides reusable methods for adding, removing, and updating cart items in Firestore
class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Adds an item to the user's cart
  /// If item already exists, increments quantity
  /// Saves to Firestore cart_items/{userId} collection
  Future<bool> addToCart({
    required BuildContext context,
    required String userId,
    required CartItem item,
    bool showSnackbar = true,
  }) async {
    try {
      debugPrint('🛒 Adding item to cart: ${item.name} (${item.type})');

      final cartDoc = _firestore.collection('cart_items').doc(userId);
      final snapshot = await cartDoc.get();

      List<Map<String, dynamic>> items = [];

      if (snapshot.exists && snapshot.data() != null) {
        items = List<Map<String, dynamic>>.from(
          snapshot.data()!['items'] ?? [],
        );
      }

      // Check if item already exists in cart
      final existingIndex = items.indexWhere((i) => i['id'] == item.id);

      if (existingIndex >= 0) {
        // Increment quantity if already in cart
        items[existingIndex]['quantity'] =
            (items[existingIndex]['quantity'] ?? 0) + 1;
        debugPrint('✅ Item already in cart, quantity increased');
      } else {
        // Add new item to cart
        items.add(item.toJson());
        debugPrint('✅ New item added to cart');
      }

      // Save to Firestore
      await cartDoc.set({
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Cart saved to Firestore for user: $userId');

      // Show success message
      if (showSnackbar && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '✅ ${item.name} added to cart!',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error adding item to cart: $e');

      if (showSnackbar && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding to cart: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }

      return false;
    }
  }

  /// Removes an item from the cart
  Future<bool> removeFromCart({
    required BuildContext context,
    required String userId,
    required String itemId,
    bool showSnackbar = true,
  }) async {
    try {
      debugPrint('🗑️ Removing item from cart: $itemId');

      final cartDoc = _firestore.collection('cart_items').doc(userId);
      final snapshot = await cartDoc.get();

      if (!snapshot.exists || snapshot.data() == null) {
        debugPrint('⚠️ Cart is empty or does not exist');
        return false;
      }

      List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
        snapshot.data()!['items'] ?? [],
      );

      // Remove item
      items.removeWhere((item) => item['id'] == itemId);

      // Save to Firestore
      await cartDoc.set({
        'items': items,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Item removed from cart');

      if (showSnackbar && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Item removed from cart'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error removing item from cart: $e');
      return false;
    }
  }

  /// Updates the quantity of a cart item
  Future<bool> updateQuantity({
    required String userId,
    required String itemId,
    required int newQuantity,
  }) async {
    try {
      debugPrint('🔄 Updating cart item quantity: $itemId -> $newQuantity');

      if (newQuantity < 1) {
        debugPrint('⚠️ Quantity must be at least 1');
        return false;
      }

      final cartDoc = _firestore.collection('cart_items').doc(userId);
      final snapshot = await cartDoc.get();

      if (!snapshot.exists || snapshot.data() == null) {
        debugPrint('⚠️ Cart is empty or does not exist');
        return false;
      }

      List<Map<String, dynamic>> items = List<Map<String, dynamic>>.from(
        snapshot.data()!['items'] ?? [],
      );

      // Find and update item
      final itemIndex = items.indexWhere((item) => item['id'] == itemId);
      if (itemIndex >= 0) {
        items[itemIndex]['quantity'] = newQuantity;

        // Save to Firestore
        await cartDoc.set({
          'items': items,
          'updatedAt': FieldValue.serverTimestamp(),
        });

        debugPrint('✅ Item quantity updated');
        return true;
      } else {
        debugPrint('⚠️ Item not found in cart');
        return false;
      }
    } catch (e) {
      debugPrint('❌ Error updating cart quantity: $e');
      return false;
    }
  }

  /// Clears all items from the cart
  Future<bool> clearCart({
    required BuildContext context,
    required String userId,
    bool showSnackbar = true,
  }) async {
    try {
      debugPrint('🗑️ Clearing cart for user: $userId');

      await _firestore.collection('cart_items').doc(userId).set({
        'items': [],
        'updatedAt': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Cart cleared');

      if (showSnackbar && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cart cleared'),
            backgroundColor: Colors.grey,
            duration: Duration(seconds: 2),
          ),
        );
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error clearing cart: $e');
      return false;
    }
  }

  /// Gets the current cart for a user
  /// Returns list of CartItem objects
  Future<List<CartItem>> getCart(String userId) async {
    try {
      debugPrint('📦 Loading cart for user: $userId');

      final snapshot = await _firestore
          .collection('cart_items')
          .doc(userId)
          .get();

      if (!snapshot.exists || snapshot.data() == null) {
        debugPrint('⚠️ Cart is empty or does not exist');
        return [];
      }

      final items = List<Map<String, dynamic>>.from(
        snapshot.data()!['items'] ?? [],
      );

      return items.map((item) => CartItem.fromJson(item)).toList();
    } catch (e) {
      debugPrint('❌ Error loading cart: $e');
      return [];
    }
  }

  /// Gets the total count of items in cart
  Future<int> getCartItemCount(String userId) async {
    try {
      final items = await getCart(userId);
      return items.fold<int>(0, (sum, item) => sum + item.quantity);
    } catch (e) {
      debugPrint('❌ Error getting cart count: $e');
      return 0;
    }
  }

  /// Calculates the total price of cart items
  Future<double> getCartTotal(String userId) async {
    try {
      final items = await getCart(userId);
      return items.fold<double>(
        0.0,
        (sum, item) => sum + (item.price * item.quantity),
      );
    } catch (e) {
      debugPrint('❌ Error calculating cart total: $e');
      return 0.0;
    }
  }

  /// Creates a CartItem from a workshop
  static CartItem createWorkshopCartItem(Map<String, dynamic> workshop) {
    return CartItem(
      id: workshop['id']?.toString() ?? '',
      type: CartItemType.addon,
      name: workshop['title']?.toString() ?? 'Workshop',
      price: (workshop['price'] ?? 0).toDouble(),
      quantity: 1,
      details: workshop['description']?.toString() ?? '',
    );
  }

  /// Creates a CartItem from a booking package
  static CartItem createPackageCartItem(Map<String, dynamic> package) {
    return CartItem(
      id: package['id']?.toString() ?? '',
      type: CartItemType.package,
      name: package['name']?.toString() ?? 'Package',
      price: (package['price'] ?? 0).toDouble(),
      quantity: 1,
      details: package['description']?.toString() ?? '',
    );
  }

  /// Creates a CartItem from an addon
  static CartItem createAddonCartItem(Map<String, dynamic> addon) {
    return CartItem(
      id: addon['id']?.toString() ?? '',
      type: CartItemType.addon,
      name: addon['name']?.toString() ?? 'Add-on',
      price: (addon['price'] ?? 0).toDouble(),
      quantity: 1,
      details: addon['description']?.toString() ?? '',
    );
  }
}
