class RouteNames {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const search = '/search';
  static const categories = '/categories';
  static const productDetail = '/product/:id';
  static const cart = '/cart';
  static const orders = '/orders';
  static const favorites = '/favorites';
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const editProfile = '/profile/edit';
  static const seller = '/seller';
  static const addProduct = '/seller/add-product';
  static const admin = '/admin';
  static const chat = '/chat/:userId';

  static String productPath(String id) => '/product/$id';
  static String chatPath(String userId) => '/chat/$userId';
}