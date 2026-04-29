import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF5F6F8),

      appBar: AppBar(
        title: const Text("Профил"),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: const [
          Padding(
            padding: EdgeInsets.all(12),
            child: Icon(Icons.settings),
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            // 👤 USER CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundImage: AssetImage("assets/user.png"),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text("Шохрух Назаров",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        SizedBox(height: 4),
                        Text("+992 90 123 45 67",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),

                  OutlinedButton(
                    onPressed: () {},
                    child: const Text("Таҳрири профил"),
                  )
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 📊 STATS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  _StatItem("24", "Заказҳо"),
                  _StatItem("56", "Дӯстдоштаҳо"),
                  _StatItem("18", "Маҳсулоти ман"),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 📋 MENU
            _menuItem(Icons.inventory, "Заказҳои ман"),
            _menuItem(Icons.store, "Маҳсулоти ман"),
            _menuItem(Icons.favorite, "Дӯстдоштаҳо"),
            _menuItem(Icons.payment, "Пардохтҳо"),
            _menuItem(Icons.location_on, "Суроғаҳо"),

            const SizedBox(height: 16),

            _menuItem(Icons.settings, "Танзимот"),
            _menuItem(Icons.help_outline, "Кӯмак"),

            const SizedBox(height: 16),

            // 🚪 LOGOUT
            _menuItem(Icons.logout, "Баромадан", color: Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _menuItem(IconData icon, String text, {Color? color}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.green),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
          const Icon(Icons.arrow_forward_ios, size: 14)
        ],
      ),
    );
  }
}

// 📊 STAT ITEM
class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.grey))
      ],
    );
  }
}
