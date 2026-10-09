import 'dart:async';
import 'dart:io';
import 'dart:math' as math;

import 'package:battery_plus/battery_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:disk_space_plus/disk_space_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------------------------------------
// Login
// ---------------------------------------------------------------------------
const kUser = 'SKYEXP1';
const kPass = 'FREE';

class C {
  static const bg = Color(0xFFEAF4FB);
  static const ink = Color(0xFF12263A);
  static const sky = Color(0xFF2F8FDB);
  static const sun = Color(0xFFF5A524);
  static const mute = Color(0xFF5B7186);
  static const ok = Color(0xFF2E9E6B);
  static const bad = Color(0xFFD64545);
}

void main() => runApp(const SkyApp());

class SkyApp extends StatelessWidget {
  const SkyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SKYEXP Tools',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: C.bg,
        colorScheme: ColorScheme.fromSeed(seedColor: C.sky),
      ),
      home: const Gate(),
    );
  }
}

class Gate extends StatefulWidget {
  const Gate({super.key});

  @override
  State<Gate> createState() => _GateState();
}

class _GateState extends State<Gate> {
  bool? _in;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final p = await SharedPreferences.getInstance();
    if (mounted) setState(() => _in = p.getBool('logged') ?? false);
  }

  Future<void> _set(bool v) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool('logged', v);
    if (mounted) setState(() => _in = v);
  }

  @override
  Widget build(BuildContext context) {
    if (_in == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _in!
        ? Home(onLogout: () => _set(false))
        : Login(onOk: () => _set(true));
  }
}

class Login extends StatefulWidget {
  final VoidCallback onOk;
  const Login({super.key, required this.onOk});

  @override
  State<Login> createState() => _LoginState();
}

class _LoginState extends State<Login> {
  final _u = TextEditingController();
  final _p = TextEditingController();
  bool _hide = true;
  String? _err;

  void _submit() {
    if (_u.text.trim() == kUser && _p.text == kPass) {
      widget.onOk();
    } else {
      setState(() => _err = 'Username atau password salah.');
    }
  }

  @override
  void dispose() {
    _u.dispose();
    _p.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cloud_rounded, size: 56, color: C.sky),
                  const SizedBox(height: 12),
                  const Text('SKYEXP Tools',
                      style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: C.ink)),
                  const SizedBox(height: 6),
                  const Text('Cek spek HP, bersihkan cache, uji FPS.',
                      style: TextStyle(color: C.mute, fontSize: 15)),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _u,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _p,
                    obscureText: _hide,
                    onSubmitted: (_) => _submit(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      filled: true,
                      fillColor: Colors.white,
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                  ),
                  if (_err != null) ...[
                    const SizedBox(height: 10),
                    Text(_err!, style: const TextStyle(color: C.bad)),
                  ],
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton(
                      onPressed: _submit,
                      child: const Text('Masuk',
                          style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Home
// ---------------------------------------------------------------------------
class Home extends StatefulWidget {
  final VoidCallback onLogout;
  const Home({super.key, required this.onLogout});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int _i = 0;
  static const _titles = ['Spesifikasi HP', 'Pembersih', 'Game Corner'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: C.bg,
        title: Text(_titles[_i],
            style: const TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: widget.onLogout,
          ),
        ],
      ),
      body: IndexedStack(
        index: _i,
        children: const [SpecPage(), CleanPage(), GamePage()],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _i,
        onDestinationSelected: (v) => setState(() => _i = v),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.phone_android), label: 'Spek'),
          NavigationDestination(
              icon: Icon(Icons.cleaning_services_outlined), label: 'Bersihkan'),
          NavigationDestination(
              icon: Icon(Icons.sports_esports_outlined), label: 'Game'),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Spesifikasi HP
// ---------------------------------------------------------------------------
class SpecPage extends StatefulWidget {
  const SpecPage({super.key});

  @override
  State<SpecPage> createState() => _SpecPageState();
}

class _SpecPageState extends State<SpecPage> {
  late Future<List<MapEntry<String, String>>> _f;

  @override
  void initState() {
    super.initState();
    _f = _load();
  }

  Future<List<MapEntry<String, String>>> _load() async {
    final r = <MapEntry<String, String>>[];
    void add(String k, String v) => r.add(MapEntry(k, v));

    if (Platform.isAndroid) {
      final a = await DeviceInfoPlugin().androidInfo;
      add('Perangkat', '${a.brand} ${a.model}');
      add('Produsen', a.manufacturer);
      add('Android', '${a.version.release} (SDK ${a.version.sdkInt})');
      add('Hardware', a.hardware);
      add('Board', a.board);
      add('Arsitektur CPU', a.supportedAbis.join(', '));
      add('RAM total', '${a.physicalRamSize} MB');
      add('RAM tersedia', '${a.availableRamSize} MB');
      add('Perangkat asli', a.isPhysicalDevice ? 'Ya' : 'Emulator');
    }
    add('Jumlah core CPU', '${Platform.numberOfProcessors}');

    try {
      final total = await DiskSpacePlus.getTotalDiskSpace;
      final free = await DiskSpacePlus.getFreeDiskSpace;
      if (total != null) add('Penyimpanan total', _gb(total));
      if (free != null) add('Penyimpanan kosong', _gb(free));
    } catch (_) {}

    try {
      final b = Battery();
      final lvl = await b.batteryLevel;
      final st = await b.batteryState;
      add('Baterai', '$lvl%');
      add('Status baterai', st.name);
    } catch (_) {}
    return r;
  }

  String _gb(double mb) => '${(mb / 1024).toStringAsFixed(1)} GB';

  @override
  Widget build(BuildContext context) {
    final v = View.of(context);
    final screen = <MapEntry<String, String>>[
      MapEntry('Resolusi layar',
          '${v.physicalSize.width.toInt()} x ${v.physicalSize.height.toInt()} px'),
      MapEntry('Kepadatan', '${v.devicePixelRatio.toStringAsFixed(2)}x'),
      MapEntry('Refresh rate', '${v.display.refreshRate.round()} Hz'),
    ];

    return FutureBuilder<List<MapEntry<String, String>>>(
      future: _f,
      builder: (c, s) {
        if (!s.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final rows = [...s.data!, ...screen];
        return RefreshIndicator(
          onRefresh: () async {
            setState(() => _f = _load());
            await _f;
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            children: [
              Card(
                color: Colors.white,
                elevation: 0,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      for (int i = 0; i < rows.length; i++) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                  flex: 4,
                                  child: Text(rows[i].key,
                                      style: const TextStyle(color: C.mute))),
                              Expanded(
                                  flex: 5,
                                  child: Text(rows[i].value,
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700,
                                          color: C.ink))),
                            ],
                          ),
                        ),
                        if (i != rows.length - 1) const Divider(height: 1),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                  child: Text('Tarik ke bawah untuk memuat ulang',
                      style: TextStyle(color: C.mute, fontSize: 12))),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Pembersih sampah & cache
// ---------------------------------------------------------------------------
String fmtBytes(num b) {
  if (b < 1024) return '${b.toInt()} B';
  if (b < 1048576) return '${(b / 1024).toStringAsFixed(1)} KB';
  if (b < 1073741824) return '${(b / 1048576).toStringAsFixed(1)} MB';
  return '${(b / 1073741824).toStringAsFixed(2)} GB';
}

class CleanPage extends StatefulWidget {
  const CleanPage({super.key});

  @override
  State<CleanPage> createState() => _CleanPageState();
}

class _CleanPageState extends State<CleanPage> {
  int? _size;
  bool _busy = false;
  String? _msg;

  @override
  void initState() {
    super.initState();
    _scan();
  }

  Future<List<Directory>> _dirs() async {
    final out = <Directory>[];
    final seen = <String>{};
    void add(Directory d) {
      if (seen.add(d.path)) out.add(d);
    }

    try {
      add(await getTemporaryDirectory());
    } catch (_) {}
    try {
      add(await getApplicationCacheDirectory());
    } catch (_) {}
    try {
      final e = await getExternalCacheDirectories();
      if (e != null) e.forEach(add);
    } catch (_) {}
    return out;
  }

  Future<int> _dirSize(Directory d) async {
    int t = 0;
    try {
      await for (final f in d.list(recursive: true, followLinks: false)) {
        if (f is File) {
          try {
            t += await f.length();
          } catch (_) {}
        }
      }
    } catch (_) {}
    return t;
  }

  Future<void> _wipe(Directory d) async {
    try {
      await for (final f in d.list()) {
        try {
          await f.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<int> _total() async {
    int t = 0;
    for (final d in await _dirs()) {
      t += await _dirSize(d);
    }
    return t;
  }

  Future<void> _scan() async {
    setState(() {
      _busy = true;
      _msg = null;
    });
    final t = await _total();
    if (!mounted) return;
    setState(() {
      _size = t;
      _busy = false;
    });
  }

  Future<void> _clean() async {
    setState(() => _busy = true);
    final before = _size ?? await _total();
    for (final d in await _dirs()) {
      await _wipe(d);
    }
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    final after = await _total();
    if (!mounted) return;
    setState(() {
      _size = after;
      _busy = false;
      _msg = 'Terhapus ${fmtBytes(math.max(0, before - after))}';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            color: Colors.white,
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 36),
              child: Column(
                children: [
                  const Text('File sampah & cache',
                      style: TextStyle(color: C.mute)),
                  const SizedBox(height: 8),
                  _busy
                      ? const SizedBox(
                          height: 56,
                          width: 56,
                          child: CircularProgressIndicator())
                      : Text(_size == null ? '-' : fmtBytes(_size!),
                          style: const TextStyle(
                              fontSize: 52,
                              fontWeight: FontWeight.w800,
                              color: C.ink)),
                  if (_msg != null) ...[
                    const SizedBox(height: 10),
                    Text(_msg!,
                        style: const TextStyle(
                            color: C.ok, fontWeight: FontWeight.w700)),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 52,
            child: FilledButton.icon(
              onPressed: _busy ? null : _clean,
              icon: const Icon(Icons.cleaning_services),
              label: const Text('Bersihkan sekarang'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              onPressed: _busy ? null : _scan,
              icon: const Icon(Icons.search),
              label: const Text('Pindai ulang'),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Yang dibersihkan: file sementara dan cache milik aplikasi ini, '
            'serta cache gambar. Android tidak mengizinkan aplikasi biasa '
            'menghapus cache aplikasi lain; untuk itu buka Pengaturan > '
            'Penyimpanan.',
            style: TextStyle(color: C.mute, fontSize: 13, height: 1.4),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Game Corner
// ---------------------------------------------------------------------------
class GamePage extends StatelessWidget {
  const GamePage({super.key});

  Widget _tile(BuildContext c, IconData icon, String title, String sub,
      Widget page) {
    return Card(
      color: Colors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Icon(icon, color: C.sky, size: 32),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
        subtitle: Text(sub),
        trailing: const Icon(Icons.chevron_right),
        onTap: () =>
            Navigator.push(c, MaterialPageRoute(builder: (_) => page)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _tile(context, Icons.speed, 'FPS Counter',
            'Pantau FPS layar secara langsung', const FpsPage(initialLoad: 0)),
        _tile(context, Icons.local_fire_department, 'Uji Beban',
            'Bebani GPU lalu lihat FPS turun atau stabil',
            const FpsPage(initialLoad: 1500)),
        _tile(context, Icons.star_rounded, 'Tap Bintang',
            'Mini game 20 detik, kejar skor tertinggi', const StarGame()),
      ],
    );
  }
}

class FpsPage extends StatefulWidget {
  final int initialLoad;
  const FpsPage({super.key, required this.initialLoad});

  @override
  State<FpsPage> createState() => _FpsPageState();
}

class _FpsPageState extends State<FpsPage> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  late int _load = widget.initialLoad;
  int _frames = 0;
  Duration _last = Duration.zero;
  double _fps = 0;
  double _t = 0;
  final List<double> _hist = [];

  @override
  void initState() {
    super.initState();
    _ticker = createTicker(_tick)..start();
  }

  void _tick(Duration e) {
    _frames++;
    _t = e.inMicroseconds / 1e6;
    final dt = e - _last;
    if (dt.inMilliseconds >= 500) {
      final v = _frames * 1e6 / dt.inMicroseconds;
      _frames = 0;
      _last = e;
      _hist.add(v);
      if (_hist.length > 60) _hist.removeAt(0);
      setState(() => _fps = v);
    } else if (_load > 0) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  Color _col(double f) => f >= 50 ? C.ok : (f >= 30 ? C.sun : C.bad);

  @override
  Widget build(BuildContext context) {
    final hz = View.of(context).display.refreshRate;
    final minV = _hist.isEmpty ? 0.0 : _hist.reduce(math.min);
    final maxV = _hist.isEmpty ? 0.0 : _hist.reduce(math.max);
    final avg =
        _hist.isEmpty ? 0.0 : _hist.reduce((a, b) => a + b) / _hist.length;

    Widget stat(String l, double v) => Column(children: [
          Text(v.toStringAsFixed(0),
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w800, color: C.ink)),
          Text(l, style: const TextStyle(color: C.mute, fontSize: 12)),
        ]);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: C.bg,
        title: Text(widget.initialLoad == 0 ? 'FPS Counter' : 'Uji Beban',
            style: const TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          children: [
            Text(_fps.toStringAsFixed(0),
                style: TextStyle(
                    fontSize: 84,
                    height: 1,
                    fontWeight: FontWeight.w900,
                    color: _col(_fps))),
            Text('FPS  (layar ${hz.round()} Hz)',
                style: const TextStyle(color: C.mute)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [stat('Min', minV), stat('Rata-rata', avg), stat('Maks', maxV)],
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: CustomPaint(
                    painter: _GraphPainter(List.of(_hist), math.max(hz, 60))),
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Tanpa beban')),
                ButtonSegment(value: 1500, label: Text('Sedang')),
                ButtonSegment(value: 6000, label: Text('Berat')),
              ],
              selected: {_load},
              onSelectionChanged: (s) => setState(() => _load = s.first),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12)),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CustomPaint(painter: _StressPainter(_load, _t)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  final List<double> h;
  final double maxY;
  _GraphPainter(this.h, this.maxY);

  @override
  void paint(Canvas c, Size s) {
    final grid = Paint()
      ..color = C.mute.withOpacity(0.2)
      ..strokeWidth = 1;
    c.drawLine(Offset(0, s.height / 2), Offset(s.width, s.height / 2), grid);
    if (h.length < 2) return;
    final line = Paint()
      ..color = C.sky
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    final path = Path();
    for (int i = 0; i < h.length; i++) {
      final x = s.width * i / 59;
      final y = s.height * (1 - (h[i] / maxY).clamp(0.0, 1.0));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    c.drawPath(path, line);
  }

  @override
  bool shouldRepaint(_GraphPainter o) => true;
}

class _StressPainter extends CustomPainter {
  final int n;
  final double t;
  _StressPainter(this.n, this.t);

  @override
  void paint(Canvas c, Size s) {
    final p = Paint();
    for (int i = 0; i < n; i++) {
      final a = t * (0.6 + (i % 7) * 0.15) + i;
      final x = s.width * (0.5 + 0.45 * math.sin(a * 1.3 + i * 0.37));
      final y = s.height * (0.5 + 0.45 * math.cos(a * 0.9 + i * 0.53));
      p.color = Color.lerp(C.sky, C.sun, (i % 10) / 10)!.withOpacity(0.6);
      c.drawCircle(Offset(x, y), 4 + (i % 5).toDouble(), p);
    }
  }

  @override
  bool shouldRepaint(_StressPainter o) => true;
}

class StarGame extends StatefulWidget {
  const StarGame({super.key});

  @override
  State<StarGame> createState() => _StarGameState();
}

class _StarGameState extends State<StarGame> {
  static const _secs = 20;
  int _score = 0, _left = _secs, _best = 0;
  bool _run = false;
  Timer? _timer;
  Offset _pos = const Offset(0.5, 0.5);
  final _r = math.Random();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      if (mounted) setState(() => _best = p.getInt('best_star') ?? 0);
    });
  }

  void _start() {
    setState(() {
      _score = 0;
      _left = _secs;
      _run = true;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      setState(() => _left--);
      if (_left <= 0) _end();
    });
  }

  Future<void> _end() async {
    _timer?.cancel();
    setState(() => _run = false);
    if (_score > _best) {
      _best = _score;
      final p = await SharedPreferences.getInstance();
      await p.setInt('best_star', _best);
      if (mounted) setState(() {});
    }
  }

  void _tap() {
    if (!_run) return;
    setState(() {
      _score++;
      _pos = Offset(_r.nextDouble(), _r.nextDouble());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget info(String l, String v) => Column(children: [
          Text(v,
              style: const TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w800, color: C.ink)),
          Text(l, style: const TextStyle(color: C.mute, fontSize: 12)),
        ]);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: C.bg,
        title: const Text('Tap Bintang',
            style: TextStyle(fontWeight: FontWeight.w800, color: C.ink)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                info('Skor', '$_score'),
                info('Waktu', '$_left'),
                info('Terbaik', '$_best'),
              ],
            ),
          ),
          Expanded(
            child: LayoutBuilder(builder: (c, box) {
              const sz = 64.0;
              return Stack(
                children: [
                  if (_run)
                    Positioned(
                      left: _pos.dx * (box.maxWidth - sz),
                      top: _pos.dy * (box.maxHeight - sz),
                      child: GestureDetector(
                        onTapDown: (_) => _tap(),
                        child: const Icon(Icons.star_rounded,
                            size: sz, color: C.sun),
                      ),
                    ),
                  if (!_run)
                    Center(
                      child: FilledButton(
                        onPressed: _start,
                        child: Text(_score == 0 && _left == _secs
                            ? 'Mulai'
                            : 'Main lagi'),
                      ),
                    ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }
}
