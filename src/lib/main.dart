import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Auto Clicker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;

  void _login() {
    if (_user.text.trim() == 'admin' && _pass.text == 'admin123') {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomePage()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Username atau password salah')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.touch_app, size: 80, color: Colors.indigo),
              const SizedBox(height: 8),
              const Text('Auto Clicker',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 32),
              TextField(
                controller: _user,
                decoration: const InputDecoration(
                    labelText: 'Username',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pass,
                obscureText: _hide,
                onSubmitted: (_) => _login(),
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock),
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(onPressed: _login, child: const Text('LOGIN')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _ch = MethodChannel('autoclicker');
  final _x = TextEditingController(text: '500');
  final _y = TextEditingController(text: '1000');
  final _interval = TextEditingController(text: '1000');
  final _max = TextEditingController(text: '0');
  bool _enabled = false;
  bool _running = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refresh();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    try {
      final e = await _ch.invokeMethod<bool>('isEnabled') ?? false;
      final r = await _ch.invokeMethod<bool>('isRunning') ?? false;
      if (mounted) setState(() {
        _enabled = e;
        _running = r;
      });
    } catch (_) {}
  }

  Future<void> _start() async {
    final ok = await _ch.invokeMethod<bool>('start', {
      'x': double.tryParse(_x.text) ?? 500.0,
      'y': double.tryParse(_y.text) ?? 1000.0,
      'interval': int.tryParse(_interval.text) ?? 1000,
      'max': int.tryParse(_max.text) ?? 0,
    });
    if (ok != true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aktifkan dulu Accessibility Service')));
    }
    _refresh();
  }

  Future<void> _stop() async {
    await _ch.invokeMethod('stop');
    _refresh();
  }

  Widget _field(String label, TextEditingController c) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: c,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
              labelText: label, border: const OutlineInputBorder()),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto Clicker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const LoginPage())),
          )
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: _enabled ? Colors.green.shade100 : Colors.red.shade100,
            child: ListTile(
              leading: Icon(_enabled ? Icons.check_circle : Icons.warning),
              title: Text(_enabled
                  ? 'Accessibility Service aktif'
                  : 'Accessibility Service belum aktif'),
              trailing: _enabled
                  ? null
                  : TextButton(
                      onPressed: () => _ch.invokeMethod('openSettings'),
                      child: const Text('AKTIFKAN')),
            ),
          ),
          const SizedBox(height: 16),
          _field('Posisi X (px)', _x),
          _field('Posisi Y (px)', _y),
          _field('Interval (ms)', _interval),
          _field('Jumlah klik (0 = tanpa batas)', _max),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: _running
                ? FilledButton.icon(
                    style: FilledButton.styleFrom(backgroundColor: Colors.red),
                    onPressed: _stop,
                    icon: const Icon(Icons.stop),
                    label: const Text('STOP'))
                : FilledButton.icon(
                    onPressed: _start,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('START')),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tekan START lalu buka aplikasi/game target. '
            'Tombol STOP melayang akan muncul di layar.',
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
