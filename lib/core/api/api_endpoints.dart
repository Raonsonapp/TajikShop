import '../constants/app_strings.dart';

class ApiEndpoints {
  static const base = AppStrings.baseUrl;

  // Auth
  static const register = '/auth/register';
  static const login = '/auth/login';
  static const refresh = '/auth/refresh';

  // Users
  static const me = '/users/me';
  static const updateProfile = '/users/me';
  static const uploadAvatar = '/users/me/avatar';
  static const becomeSeller = '/users/me/become-seller';
  static String follow(String id) => '/users/$id/follow';

  // Products
  static const products = '/products';
  static const trending = '/products/trending';
  static String product(String id) => '/products/$id';
  static String productImages(String id) => '/products/$id/images';

  // Categories
  static const categories = '/categories';

  // Cart
  static const cart = '/cart';
  static String cartItem(String id) => '/cart/$id';

  // Orders
  static const orders = '/orders';
  static const checkout = '/orders/checkout';
  static String order(String id) => '/orders/$id';

  // Favorites
  static const favorites = '/favorites';
  static String favoriteItem(String id) => '/favorites/$id';

  // Reviews
  static const reviews = '/reviews';
  static String productReviews(String id) => '/reviews/product/$id';

  // Stories
  static const stories = '/stories/feed';
  static const createStory = '/stories';

  // Messages
  static const messages = '/messages';
  static String conversation(String userId) => '/messages/$userId';

  // Notifications
  static const notifications = '/notifications';
  static const readNotifications = '/notifications/read-all';

  // Admin
  static const adminStats = '/admin/stats';
  static const adminUsers = '/admin/users';
  static const adminOrders = '/admin/orders';
}
