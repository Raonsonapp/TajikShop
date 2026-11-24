part of '../../main.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});
  @override
  State<AuthPage> createState() => _AuthPageState();
}
class _AuthPageState extends State<AuthPage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _register = false, _busy = false, _hidePassword = true;
  String? _error;
  @override
  void dispose() { _name.dispose(); _email.dispose(); _password.dispose(); super.dispose(); }
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      if (_register) {
        await AlmazApi.instance.register(name: _name.text, email: _email.text, password: _password.text);
      } else {
        await AlmazApi.instance.login(email: _email.text, password: _password.text);
      }
      if (!mounted) return;
      if (await AlmazApi.instance.hasAccessToken()) { Navigator.pop(context, true); }
      else { setState(() => _error = 'Сервер токени воридшавиро нафиристод.'); }
    } catch (e) { if (mounted) setState(() => _error = e.toString()); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(_register ? 'Сабти ном' : 'Воридшавӣ')),
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Form(key: _formKey, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const AlmazMark(size: 76), const SizedBox(height: 18),
        Text(_register ? 'Ҳисоби нав соз' : 'Ба TAJ DONATE ворид шав', textAlign: TextAlign.center, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
        const SizedBox(height: 22),
        if (_register) ...[
          TextFormField(controller: _name, decoration: const InputDecoration(labelText: 'Ном', prefixIcon: Icon(Icons.person_outline)), validator: (v) => (v == null || v.trim().isEmpty) ? 'Номро ворид кун' : null),
          const SizedBox(height: 12),
        ],
        TextFormField(controller: _email, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Почтаи электронӣ', prefixIcon: Icon(Icons.email_outlined)), validator: (v) => (v == null || !v.contains('@') || !v.contains('.')) ? 'Почтаи электрониро дуруст ворид кун' : null),
        const SizedBox(height: 12),
        TextFormField(controller: _password, obscureText: _hidePassword, decoration: InputDecoration(labelText: 'Рамз', prefixIcon: const Icon(Icons.lock_outline), suffixIcon: IconButton(onPressed: () => setState(() => _hidePassword = !_hidePassword), icon: Icon(_hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined))), validator: (v) => (v == null || v.length < 8) ? 'Рамз бояд камаш 8 аломат бошад' : null),
        if (_error != null) ...[const SizedBox(height: 12), Text(_error!, style: const TextStyle(color: Colors.redAccent))],
        const SizedBox(height: 20),
        SizedBox(height: 50, child: FilledButton(onPressed: _busy ? null : _submit, style: FilledButton.styleFrom(backgroundColor: green, foregroundColor: bg), child: _busy ? const CircularProgressIndicator(color: bg) : Text(_register ? 'Сабти ном' : 'Ворид шудан'))),
        TextButton(onPressed: _busy ? null : () => setState(() { _register = !_register; _error = null; }), child: Text(_register ? 'Аллакай ҳисоб дорӣ? Ворид шав' : 'Ҳисоб надорӣ? Сабти ном кун')),
      ])),
    ))),
  );
}
