part of '../../main.dart';

class ProfileRow extends StatelessWidget {
  final IconData icon; final String title; final VoidCallback onTap;
  const ProfileRow({super.key, required this.icon, required this.title, required this.onTap});
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white10)),
    child: ListTile(
      onTap: onTap, leading: Icon(icon, color: green),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      trailing: const Icon(Icons.chevron_right, color: muted),
    ),
  );
}
