import 'package:flutter_riverpod/flutter_riverpod.dart';
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

  Future<void> checkout(String addressId) async {
    try {
      await _repo.checkout(addressId);
      state = const CartState();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>((ref) {
  return CartNotifier();
});
