// ignore_for_file: unnecessary_null_comparison, avoid_print

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:omnicare_app/Model/cart_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _cartItems = [];

  List<CartItem> get cartItems => _cartItems;

  CartProvider() {
    // Load cart items from SharedPreferences when the CartProvider is initialized
    _loadCartItems();
  }

  Future<void> _loadCartItems() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String cartItemsJson = prefs.getString('cartItems') ?? '[]';
      print('CartItems JSON: $cartItemsJson'); // Debug print
      if (cartItemsJson.isNotEmpty) {
        List<dynamic> decoded = jsonDecode(cartItemsJson);
        _cartItems = decoded
            .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      notifyListeners();
    } catch (error) {
      print('Error loading cart items: $error'); // Debug print
    }
  }

  void _saveCartItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<Map<String, dynamic>> cartItemsJsonList =
        _cartItems.map((item) => item.toJson()).toList();
    String cartItemsJson = jsonEncode(cartItemsJsonList);
    await prefs.setString('cartItems', cartItemsJson);
  }

  void addToCart(CartItem item) {
    _cartItems.add(item);
    _saveCartItems(); // Save cart items after adding
    notifyListeners();
  }

  void removeFromCart(CartItem item) {
    _cartItems.remove(item);
    _saveCartItems(); // Save cart items after removing
    notifyListeners();
  }

  void updateCartItemQuantity(CartItem item, int newQuantity) {
    int index = _cartItems.indexOf(item);
    if (index != -1) {
      _cartItems[index].quantity = newQuantity;
      _saveCartItems(); // Save cart items after updating quantity
      notifyListeners();
    }
  }

  ///for update cart quantity based on product id
  void updateQuantityById(int productId, int newQuantity) {
    int index = _cartItems.indexWhere((item) => item.id == productId);
    if (index != -1) {
      if (newQuantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = newQuantity;
      }
      _saveCartItems();
      notifyListeners();
    }
  }

  double getTotalSellPrice() {
    double totalSellPrice = 0.0;
    for (var item in _cartItems) {
      totalSellPrice += item.sell_price * item.quantity;
    }
    return totalSellPrice;
  }

  double getTotalAfterDiscountPrice() {
    double totalAfterDiscountPrice = 0.0;
    for (var item in _cartItems) {
      totalAfterDiscountPrice += item.after_discount_price * item.quantity;
    }
    return totalAfterDiscountPrice;
  }

  int getTotalCartItems() {
    if (_cartItems != null) {
      int totalItems = 0;
      for (var item in _cartItems) {
        totalItems += item.quantity;
      }
      return totalItems;
    } else {
      return 0;
    }
  }

  void updateQuantity(int productId, int newQuantity) {
    int index = _cartItems.indexWhere((item) => item.id == productId);

    if (index != -1) {
      if (newQuantity <= 0) {
        // If the new quantity is zero or negative, remove the item from the cart
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = newQuantity;
      }
      _saveCartItems(); // Save cart items after updating quantity or removing item
      notifyListeners();
    }
  }

  void removeFromCartById(int productId) {
    _cartItems.removeWhere((item) => item.id == productId);
    _saveCartItems(); // Save cart items after removing
    notifyListeners();
  }

  void clearCart() {
    _cartItems.clear();
    _saveCartItems(); // Save cart items after clearing
    notifyListeners();
  }

  int getProductQuantityById(int productId) {
    CartItem item = _cartItems.firstWhere((item) => item.id == productId,
        orElse: () => CartItem(
            id: productId,
            quantity: 0,
            image: '',
            name: '',
            company_name: '',
            sell_price: 0,
            after_discount_price: 0,
            subtitle: ''));
    return item != null ? item.quantity : 0;
  }
}
// class FavoriteProvider extends ChangeNotifier {
//   List<int> _favoriteIds = [];
//
//   // Method to toggle favorite status of a product by its ID
//   void toggleFavorite(int productId) {
//     if (_favoriteIds.contains(productId)) {
//       _favoriteIds.remove(productId); // Remove from favorites if already favorited
//     } else {
//       _favoriteIds.add(productId); // Add to favorites if not already favorited
//     }
//     notifyListeners(); // Notify listeners to update UI
//   }
//
//   // Method to check if a product is favorited by its ID
//   bool isFavorite(int productId) {
//     return _favoriteIds.contains(productId);
//   }
// }

class FavoriteProvider extends ChangeNotifier {
  List<int> _favoriteIds = [];

  List<int> get favoriteIds => _favoriteIds;

  FavoriteProvider() {
    // Load favorite IDs from SharedPreferences when the FavoriteProvider is initialized
    _loadFavoriteIds();
  }

  Future<void> _loadFavoriteIds() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String favoriteIdsJson = prefs.getString('favoriteIds') ?? '[]';
      List<dynamic> decoded = jsonDecode(favoriteIdsJson);
      _favoriteIds = List<int>.from(decoded);
    } catch (error) {
      print('Error loading favorite IDs: $error'); // Debug print
    }
  }

  Future<void> _saveFavoriteIds() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String favoriteIdsJson = jsonEncode(_favoriteIds);
      await prefs.setString('favoriteIds', favoriteIdsJson);
    } catch (error) {
      print('Error saving favorite IDs: $error'); // Debug print
    }
  }

  // Method to toggle favorite status of a product by its ID
  void toggleFavorite(int productId) {
    if (_favoriteIds.contains(productId)) {
      _favoriteIds
          .remove(productId); // Remove from favorites if already favorited
    } else {
      _favoriteIds.add(productId); // Add to favorites if not already favorited
    }
    _saveFavoriteIds(); // Save favorite IDs after toggling
    notifyListeners(); // Notify listeners to update UI
  }

  // Method to check if a product is favorited by its ID
  bool isFavorite(int productId) {
    return _favoriteIds.contains(productId);
  }
}
