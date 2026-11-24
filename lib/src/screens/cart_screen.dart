part of '../../main.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});
  @override State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late Future<List<Map<String, dynamic>>> _future;
  @override void initState() { super.initState(); _future = AlmazCartStore.load(); }
  void _refresh() => setState(() => _future = AlmazCartStore.load());
  double _price(Map<String, dynamic> item) {
    final value = item['price'] ?? item['sale_price'] ?? item['display_price'];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().replaceAll(',', '.') ?? '') ?? 0;
  }
  @override Widget build(BuildContext context) => Column(children: [
    const BrandHeader(),
    Padding(padding: const EdgeInsets.fromLTRB(18, 0, 18, 12), child: Row(children: [
      const Expanded(child: Text('Сабади харид', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900))),
      IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh, color: green)),
    ])),
    Expanded(child: FutureBuilder<List<Map<String, dynamic>>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: green));
        final items = snapshot.data ?? [];
        if (items.isEmpty) return const EmptyState(icon: Icons.shopping_bag_outlined, title: 'Сабад холӣ аст', sub: 'Аз рӯйхати маҳсулоти сервер мол интихоб карда, ба сабад илова кун.');
        final total = items.fold<double>(0, (sum, item) => sum + _price(item) * ((item['quantity'] as num?)?.toInt() ?? 1));
        final currency = (items.first['currency'] ?? 'с').toString();
        return ListView(padding: const EdgeInsets.fromLTRB(15, 4, 15, 20), children: [
          ...items.map((item) {
            final id = (item['id'] ?? item['product_id']).toString();
            final name = (item['name'] ?? item['title'] ?? item['product_name'] ?? 'Маҳсулот').toString();
            final quantity = (item['quantity'] as num?)?.toInt() ?? 1;
            final price = _price(item);
            return Container(
              margin: const EdgeInsets.only(bottom: 10), padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: green.withOpacity(.2))),
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(13),
                  child: Container(
                    width: 58, height: 58,
                    color: green.withOpacity(.1),
                    child: ((item['image_url'] ?? item['image'] ?? item['thumbnail'])?.toString().startsWith('http') ?? false)
                      ? Image.network(
                          (item['image_url'] ?? item['image'] ?? item['thumbnail']).toString(),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: green),
                        )
                      : const Icon(Icons.inventory_2_outlined, color: green),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(price > 0 ? '${price.toStringAsFixed(2)} $currency' : 'Нарх дар маълумоти маҳсулот нест', style: const TextStyle(color: green, fontSize: 11)),
                  Row(children: [
                    IconButton(onPressed: () async { await AlmazCartStore.setQuantity(id, quantity - 1); _refresh(); }, icon: const Icon(Icons.remove_circle_outline, size: 20, color: muted), visualDensity: VisualDensity.compact),
                    Text('$quantity', style: const TextStyle(fontWeight: FontWeight.w900)),
                    IconButton(onPressed: () async { await AlmazCartStore.setQuantity(id, quantity + 1); _refresh(); }, icon: const Icon(Icons.add_circle_outline, size: 20, color: green), visualDensity: VisualDensity.compact),
                  ]),
                ])),
                IconButton(onPressed: () async { await AlmazCartStore.remove(id); _refresh(); }, icon: const Icon(Icons.delete_outline, color: Colors.redAccent)),
              ]),
            );
          }),
          Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: green.withOpacity(.25))), child: Column(children: [
            Row(children: [const Expanded(child: Text('Ҳамагӣ (ҳисоби тахминӣ)', style: TextStyle(fontWeight: FontWeight.w800))), Text('${total.toStringAsFixed(2)} $currency', style: const TextStyle(color: green, fontWeight: FontWeight.w900))]),
            const SizedBox(height: 9),
            const Text('Пардохт ва checkout то тасдиқи формати дақиқи API фаъол карда намешавад. Ин сабад ҳоло дар ҳамин дастгоҳ нигоҳ дошта мешавад.', style: TextStyle(color: gold, fontSize: 10, height: 1.5)),
          ])),
        ]);
      },
    )),
  ]);
}
