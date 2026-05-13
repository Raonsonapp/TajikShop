class RouteNames {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const phoneAuth = '/phone-auth';
  static const phoneOtp = '/phone-otp';
  static const home = '/home';
  static const upload = '/upload';
  static const favorites = '/favorites';
  static const cart = '/cart';
  static const profile = '/profile';
  static const search = '/search';
  static const categories = '/categories';
  static const orders = '/orders';
  static const notifications = '/notifications';
  static const editProfile = '/profile/edit';
  static const addresses = '/addresses';
  static const seller = '/seller';
  static const sellerDashboard = '/seller/dashboard';
  static const addProduct = '/seller/add-product';
  static const admin = '/admin';

  static String productPath(String id) => '/product/$id';
  static String chatPath(String userId) => '/chat/$userId';
}
