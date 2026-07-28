import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../data/models/cart_model.dart';
import '../data/repositories/cart_repository.dart';

class CartState {
  final List<CartItemModel> items;
  final bool isLoading;
  final String? error;

  const CartState({this.items = const [], this.isLoading = false, this.error});

  double get total => items.fold(0, (sum, item) => sum + item.total);
  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  CartState copyWith({List<CartItemModel>? items, bool? isLoading, String? error}) =>
      CartState(items: items ?? this.items, isLoading: isLoading ?? this.isLoading, error: error);
}

class CartNotifier extends StateNotifier<CartState> {
  final CartRepository _repo = CartRepository();
  CartNotifier() : super(const CartState());

  Future<void> loadCart() async {
    state = state.copyWith(isLoading: true);
    try {
      final items = await _repo.getCart();
      state = CartState(items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> addToCart(String productId, {int quantity = 1}) async {
    try {
      await _repo.addToCart(productId, quantity);
      await loadCart();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> removeItem(String itemId) async {
    try {
      await _repo.removeFromCart(itemId);
      state = state.copyWith(items: state.items.where((i) => i.id != itemId).toList());
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> updateQuantity(String itemId, int quantity) async {
    if (quantity <= 0) {
      await removeItem(itemId);
      return;
    }
    // Optimistic
    final updated = [
      for (final i in state.items)
        if (i.id == itemId)
          CartItemModel(id: i.id, productId: i.productId, title: i.title,
              image: i.image, price: i.price, quantity: quantity)
        else
          i
    ];
    state = state.copyWith(items: updated);
    try {
      await ApiClient.instance.dio.patch('/cart/$itemId', data: {'quantity': quantity});
    } catch (_) {
      await loadCart();
    }
  }

}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
