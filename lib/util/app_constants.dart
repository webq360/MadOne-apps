class AppConstants {
  static const String baseUrl = 'https://stage.medone.primeharvestbd.com/api';

  // Auth
  static const String login = '$baseUrl/login';
  static const String refresh = '$baseUrl/refresh';
  static const String logout = '$baseUrl/logout';
  static const String fcmToken = '$baseUrl/fcm-token';

  // Home
  static const String home = '$baseUrl';
  static const String settings = '$baseUrl/settings';
  static const String allProducts = '$baseUrl/all_products_list';
  static const String allOfferedProducts = '$baseUrl/all_offered_products';
  static const String allBrands = '$baseUrl/all_brands';
  static const String featuredCategories = '$baseUrl/featured_categories';
  static const String topSales = '$baseUrl/top-sales';
  static const String searchProduct = '$baseUrl/search_product';

  // Products
  static String categoryWiseProduct(int id) => '$baseUrl/category_wise_product/$id';
  static String brandWiseProduct(String id) => '$baseUrl/brand_wise_product/$id';
  static String searchBrandProduct(String id) => '$baseUrl/search_specific_brand_product/$id';

  // Cart & Orders
  static const String placeOrder = '$baseUrl/place_order';
  static const String orderList = '$baseUrl/order_list';
  static String orderDetails(int id) => '$baseUrl/order_details/$id';

  // Wishlist
  static const String wishlist = '$baseUrl/wishlist';
  static String addToWishlist(int id) => '$baseUrl/addToWishlist/$id';
  static String removeFromWishlist(int id) => '$baseUrl/removeFromWishlist/$id';

  // Notifications
  static const String notifications = '$baseUrl/notifications';

  // Account
  static const String profile = '$baseUrl/profile';
  static const String updateProfile = '$baseUrl/update_profile';
}
