part of '../../main.dart';

class LiveProductsSection extends StatefulWidget {
  const LiveProductsSection({super.key});
  @override
  State<LiveProductsSection> createState() => _LiveProductsSectionState();
}

class _LiveProductsSectionState extends State<LiveProductsSection> {
  late Future<dynamic> _future;
  @override
  void initState() {
    super.initState();
    _future = AlmazApi.instance.getProducts(limit: 8);
  }

  List<Map<String, dynamic>> _items(dynamic value) {
    dynamic raw = value;
    if (raw is Map) {
      raw = raw['items'] ?? raw['products'] ?? raw['data'] ?? raw['results'] ?? [];
      if (raw is Map) raw = raw['items'] ?? raw['products'] ?? raw['results'] ?? [];
    }
    if (raw is! List) return [];
    return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  String _text(Map<String, dynamic> item, List<String> keys, String fallback) {
    for (final key in keys) {
      final value = item[key];
      if (value != null && value.toString().trim().isNotEmpty) return value.toString();
    }
    return fallback;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<dynamic>(
    future: _future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: Padding(
          padding: EdgeInsets.all(12),
          child: CircularProgressIndicator(color: green, strokeWidth: 2),
        ));
      }
      if (snapshot.hasError) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(15)),
          child: const Row(children: [
            Icon(Icons.cloud_off_outlined, color: muted),
            SizedBox(width: 9),
            Expanded(child: Text('Каталоги сервер ҳоло дастрас нест. Баъдтар аз нав санҷ.', style: TextStyle(color: muted, fontSize: 11))),
          ]),
        );
      }
      final products = _items(snapshot.data);
      if (products.isEmpty) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(15)),
          child: const Text('Дар сервер ҳоло маҳсулот нашр нашудааст.', style: TextStyle(color: muted, fontSize: 11)),
        );
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle('Маҳсулоти сервер', 'LIVE'),
          const SizedBox(height: 10),
          SizedBox(
            height: 154,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: products.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = products[index];
                final name = _text(item, ['name', 'title', 'product_name'], 'Маҳсулот');
                final price = _text(item, ['price', 'display_price', 'sale_price'], 'Нарх дастрас нест');
                final currency = _text(item, ['currency'], 'с');
                final image = _text(item, ['image_url', 'image', 'thumbnail'], '');
                return Container(
                  width: 158,
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(.08)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Center(
                          child: image.startsWith('http')
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: Image.network(image, fit: BoxFit.cover, width: 92, height: 72,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.inventory_2_outlined, color: green, size: 34)),
                              )
                            : const Icon(Icons.inventory_2_outlined, color: green, size: 34),
                        ),
                      ),
                      Row(children: [
                        Expanded(child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800))),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints.tightFor(width: 30, height: 30),
                          tooltip: 'Ба сабад илова кун',
                          onPressed: () async {
                            try {
                              await AlmazCartStore.add(item);
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ба сабад илова шуд')));
                            } catch (e) {
                              if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
                            }
                          },
                          icon: const Icon(Icons.add_shopping_cart, color: green, size: 18),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('$price $currency', maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: green, fontSize: 10, fontWeight: FontWeight.w900)),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      );
    },
  );
}
