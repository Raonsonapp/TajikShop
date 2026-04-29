import 'package:flutter/material.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  List cart = [
    {"title": "iPhone 15 Pro Max", "price": 13500, "qty": 1},
    {"title": "Smart Watch T900", "price": 350, "qty": 1},
    {"title": "Куртка зимистона", "price": 280, "qty": 1},
    {"title": "Nike Air Run", "price": 199, "qty": 1},
  ];

  int get subtotal {
    int total = 0;
    for (var item in cart) {
      total += (item["price"] as int) * (item["qty"] as int);
    }
    return total;
  }

  int delivery = 20;

  @override
  Widget build(BuildContext context) {
    int total = subtotal + delivery;

    return Scaffold(
      backgroundColor: const Color(0xffF5F6F8),

      appBar: AppBar(
        title: const Text("Сабад"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.all(12),
            child: Text("Тоза кардан",
                style: TextStyle(color: Colors.green)),
          )
        ],
      ),

      body: Column(
        children: [

          // 🧾 LIST
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: cart.length,
              itemBuilder: (context, index) {
                var item = cart[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
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
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.image),
                      ),

                      const SizedBox(width: 10),

                      // INFO
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item["title"]),
                            const SizedBox(height: 6),
                            Text(
                              "${item["price"]} сомонӣ",
                              style: const TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      // ➖ ➕
                      Column(
                        children: [

                          Row(
                            children: [
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    if (item["qty"] > 1) {
                                      item["qty"]--;
                                    }
                                  });
                                },
                                icon: const Icon(Icons.remove),
                              ),

                              Text("${item["qty"]}"),

                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    item["qty"]++;
                                  });
                                },
                                icon: const Icon(Icons.add),
                              ),
                            ],
                          ),

                          // 🗑 DELETE
                          IconButton(
                            onPressed: () {
                              setState(() {
                                cart.removeAt(index);
                              });
                            },
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),

          // 💰 SUMMARY
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [

                row("Чамъ", "$subtotal сомонӣ"),
                row("Доставка", "$delivery сомонӣ"),
                row("Ҳамагӣ", "$total сомонӣ", bold: true),

                const SizedBox(height: 10),

                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "$total сомонӣ",
                        style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 14),
                      ),
                      child: const Text("Ба фармоиш гузар"),
                    )
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget row(String title, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: TextStyle(
                fontWeight: bold ? FontWeight.bold : FontWeight.normal),
          ),
        ],
      ),
    );
  }
}
