import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6F8),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // 🔹 HEADER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("TajikShop",
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.green)),
                    Stack(
                      children: [
                        const Icon(Icons.notifications_none, size: 28),
                        Positioned(
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: const Text("3",
                                style: TextStyle(
                                    color: Colors.white, fontSize: 10)),
                          ),
                        )
                      ],
                    )
                  ],
                ),
              ),

              // 🔹 SEARCH
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.search, color: Colors.grey),
                      SizedBox(width: 8),
                      Expanded(
                          child: Text("Ҷустуҷӯ дар TajikShop...",
                              style: TextStyle(color: Colors.grey))),
                      Icon(Icons.camera_alt_outlined)
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 BANNER
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    image: const DecorationImage(
                        image: AssetImage("assets/banner.jpg"),
                        fit: BoxFit.cover),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 QUICK ACTIONS
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    _ActionItem(icon: Icons.local_shipping, label: "Доставка"),
                    _ActionItem(icon: Icons.discount, label: "Аксияҳо"),
                    _ActionItem(icon: Icons.store, label: "Фурӯшандаҳо"),
                    _ActionItem(icon: Icons.new_releases, label: "Нав"),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 🔹 PRODUCTS TITLE
              _sectionTitle("Маҳсулоти маъмул"),

              // 🔹 PRODUCTS GRID
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.75,
                  children: const [
                    _ProductCard(),
                    _ProductCard(),
                    _ProductCard(),
                    _ProductCard(),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),

      // 🔻 BOTTOM NAV
      bottomNavigationBar: BottomNavigationBar(
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Хона"),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Дӯстдоштаҳо"),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: "Илова"),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Сабад"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Профил"),
        ],
      ),
    );
  }
}

// 🔹 SECTION TITLE
Widget _sectionTitle(String text) {
  return Padding(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    child: Text(text,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  );
}

// 🔹 ACTION ITEM
class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _ActionItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14)),
          child: Icon(icon, color: Colors.green),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12))
      ],
    );
  }
}

// 🔹 PRODUCT CARD
class _ProductCard extends StatelessWidget {
  const _ProductCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
              child: Image.asset("assets/product.png", fit: BoxFit.contain)),
          const SizedBox(height: 8),
          const Text("iPhone 15 Pro Max",
              maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          const Text("13 500 сомонӣ",
              style: TextStyle(
                  color: Colors.green, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
