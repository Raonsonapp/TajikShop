import 'package:flutter/material.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6F8),

      body: SafeArea(
        child: Column(
          children: [

            // 🔹 HEADER
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text("Дӯстдоштаҳо",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold)),
                  Text("Тоза кардан",
                      style: TextStyle(color: Colors.green)),
                ],
              ),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("12 маҳсулот",
                    style: TextStyle(color: Colors.grey)),
              ),
            ),

            const SizedBox(height: 10),

            // 🔹 LIST
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: const [
                  _FavItem(),
                  _FavItem(),
                  _FavItem(),
                  _FavItem(),
                ],
              ),
            ),

            // 🔹 BOTTOM BUTTON
            Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {},
                child: const Text(
                  "Ҳамаро ба сабад гузоред",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// 🔹 ITEM
class _FavItem extends StatelessWidget {
  const _FavItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [

          // IMAGE
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              image: const DecorationImage(
                image: AssetImage("assets/product.png"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          const SizedBox(width: 10),

          // INFO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text("iPhone 15 Pro Max",
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                SizedBox(height: 4),
                Text("13 500 сомонӣ",
                    style: TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text("⭐ 4.8", style: TextStyle(fontSize: 12)),
              ],
            ),
          ),

          // ACTIONS
          Column(
            children: [
              const Icon(Icons.favorite, color: Colors.red),
              const SizedBox(height: 10),
              const Icon(Icons.delete_outline),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.shopping_cart,
                    color: Colors.green),
              )
            ],
          )
        ],
      ),
    );
  }
}
