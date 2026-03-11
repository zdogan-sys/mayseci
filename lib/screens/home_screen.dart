import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../theme.dart';
import '../services/device_state.dart';
import '../services/ws_service.dart';
import '../services/ble_service.dart';
import '../widgets/widgets.dart';

// ================================================================
//  home_screen.dart — BrewMaster Pro
// ================================================================

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DeviceState>();

    return Scaffold(
      backgroundColor: BmColors.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          const SizedBox(height: 8),

          // Logo
          Text('BrewMaster Pro',
            style: TextStyle(
              fontFamily: 'BebasNeue', fontSize: 28,
              letterSpacing: 4, color: BmColors.amber,
              shadows: [Shadow(color: BmColors.amber.withOpacity(0.4), blurRadius: 12)],
            )),
          const SizedBox(height: 4),
          const Text('v1.0.0', style: BmTextStyles.label),
          const SizedBox(height: 20),

          // Sıcaklık kartları
          Row(children: [
            _tempCard('Q1', 'Kazan', state.tempQ1, BmColors.amber),
            const SizedBox(width: 8),
            _tempCard('Q2', 'Kolon', state.tempQ2, BmColors.cyan),
            const SizedBox(width: 8),
            _tempCard('Q3', 'Soğutucu', state.tempQ3, BmColors.cyan),
          ]),
          const SizedBox(height: 8),

          // iSpindel kartı
          if (state.ispindelOnline) ...[
            Card(child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(children: [
                const Text('🌀', style: TextStyle(fontSize: 20)),
                const SizedBox(width: 10),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Text('iSPİNDEL', style: BmTextStyles.label),
                  Text('SG: ${state.sgIspindel.toStringAsFixed(3)}',
                    style: const TextStyle(fontFamily: 'JetBrainsMono',
                        fontSize: 14, color: BmColors.green)),
                ]),
                const Spacer(),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  const Text('ABV', style: BmTextStyles.label),
                  Text('${state.fermABV.toStringAsFixed(2)}%',
                    style: const TextStyle(fontFamily: 'JetBrainsMono',
                        fontSize: 14, color: BmColors.green)),
                ]),
              ]),
            )),
            const SizedBox(height: 8),
          ],

          // Aktif modül özeti
          if (state.activeModule > 0) _activeModuleCard(state),
          if (state.activeModule > 0) const SizedBox(height: 8),

          // Modül hızlı erişim grid
          _moduleGrid(context),
          const SizedBox(height: 16),

          // Son olay kaydı
          Card(child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SON OLAYLAR', style: BmTextStyles.label),
                const SizedBox(height: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 140),
                  child: SingleChildScrollView(
                    child: LogList(entries: state.log, maxVisible: 20),
                  ),
                ),
              ],
            ),
          )),
        ]),
      ),
    );
  }

  Widget _tempCard(String id, String name, double temp, Color color) {
    return Expanded(child: Card(child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(children: [
        Text(id, style: BmTextStyles.label),
        const SizedBox(height: 2),
        Text(temp.toStringAsFixed(1),
          style: TextStyle(
            fontFamily: 'BebasNeue', fontSize: 26, color: color,
            shadows: [Shadow(color: color.withOpacity(0.4), blurRadius: 8)],
          )),
        Text('°C', style: TextStyle(fontSize: 10, color: color.withOpacity(0.7))),
        Text(name, style: const TextStyle(fontSize: 9, color: BmColors.dim)),
      ]),
    )));
  }

  Widget _activeModuleCard(DeviceState state) {
    final color = BmColors.forModule(state.activeModule);
    final names = ['', 'Mayşeleme', 'Fermentasyon',
                   'Süt Ürünleri', 'Distilasyon', 'Manuel Mod'];
    final name  = state.activeModule < names.length
        ? names[state.activeModule] : '—';
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: color),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Container(width: 4, height: 36,
              decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('AKTİF MODÜL', style: BmTextStyles.label),
            Text(name, style: TextStyle(
              fontFamily: 'BebasNeue', fontSize: 16,
              letterSpacing: 2, color: color,
            )),
          ]),
          const Spacer(),
          // Aktif modüle git butonu
          OutlinedButton(
            onPressed: () {},  // Ana navigasyon controller'dan yönetilecek
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: color),
              foregroundColor: color,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              textStyle: const TextStyle(fontSize: 11, letterSpacing: 1),
            ),
            child: const Text('GİT →'),
          ),
        ]),
      ),
    );
  }

  Widget _moduleGrid(BuildContext context) {
    final modules = [
      (icon: '🍺', label: 'Mayşeleme',    color: BmColors.amber,  idx: 1),
      (icon: '🧪', label: 'Fermentasyon', color: BmColors.green,  idx: 2),
      (icon: '🧀', label: 'Süt Ürünleri', color: BmColors.cyan,   idx: 3),
      (icon: '⚗️', label: 'Distilasyon',  color: BmColors.purple, idx: 4),
      (icon: '🎛', label: 'Manuel Mod',   color: BmColors.orange, idx: 5),
    ];
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.4,
      children: [
        for (final m in modules)
          GestureDetector(
            onTap: () {
              // Ana scaffolddan tab geçişi yapılacak (main.dart)
              // Bu callback'i dışarıdan enjekte edebilirsiniz
            },
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: m.color.withOpacity(0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(m.icon, style: const TextStyle(fontSize: 22)),
                  const SizedBox(height: 4),
                  Text(m.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 10, color: m.color, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
          ),
        // Ayarlar
        GestureDetector(
          child: Card(child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text('⚙️', style: TextStyle(fontSize: 22)),
              SizedBox(height: 4),
              Text('Ayarlar',
                style: TextStyle(fontSize: 10, color: BmColors.dim)),
            ],
          )),
        ),
      ],
    );
  }
}

// ================================================================
//  Bağlantı ekranı / dialog
// ================================================================
class ConnectDialog extends StatefulWidget {
  const ConnectDialog({super.key});
  @override
  State<ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<ConnectDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _ipController = TextEditingController();
  bool _connecting = false;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _loadLastIP();
  }

  Future<void> _loadLastIP() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _ipController.text = prefs.getString('lastIP') ?? '192.168.4.1';
    });
  }

  @override
  Widget build(BuildContext context) {
    final ws  = context.read<WsService>();
    final ble = context.read<BleService>();
    final state = context.watch<DeviceState>();

    return Dialog(
      backgroundColor: BmColors.panel,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('BAĞLAN', style: TextStyle(
            fontFamily: 'BebasNeue', fontSize: 20,
            letterSpacing: 3, color: BmColors.amber,
          )),
          const SizedBox(height: 12),
          TabBar(
            controller: _tabs,
            indicatorColor: BmColors.amber,
            labelColor: BmColors.amber,
            unselectedLabelColor: BmColors.dim,
            tabs: const [Tab(text: '📶  WiFi'), Tab(text: '🔵  BLE')],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: TabBarView(
              controller: _tabs,
              children: [
                // WiFi sekmesi
                Column(children: [
                  TextField(
                    controller: _ipController,
                    decoration: const InputDecoration(
                      labelText: 'ESP32 IP Adresi',
                      hintText: '192.168.4.1',
                      prefixIcon: Icon(Icons.wifi, color: BmColors.dim),
                    ),
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'AP modu: 192.168.4.1\nEv ağı: Ayarlar\'dan öğrenin',
                    style: TextStyle(fontSize: 11, color: BmColors.dim),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _connecting ? null : () async {
                        setState(() => _connecting = true);
                        await ws.connect(_ipController.text.trim());
                        if (mounted) Navigator.pop(context);
                      },
                      child: _connecting
                          ? const SizedBox(width: 18, height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: BmColors.bg))
                          : const Text('BAĞLAN'),
                    ),
                  ),
                ]),

                // BLE sekmesi
                Column(children: [
                  Expanded(
                    child: StreamBuilder<List<ScanResult>>(
                      stream: ble.scanResults,
                      builder: (_, snap) {
                        final results = snap.data ?? [];
                        if (results.isEmpty) {
                          return const Center(
                            child: Text('Cihaz bulunamadı...',
                                style: TextStyle(color: BmColors.dim)));
                        }
                        return ListView.builder(
                          itemCount: results.length,
                          itemBuilder: (_, i) {
                            final r = results[i];
                            return ListTile(
                              title: Text(
                                r.device.platformName.isNotEmpty
                                    ? r.device.platformName
                                    : r.device.remoteId.str,
                                style: const TextStyle(fontSize: 13)),
                              subtitle: Text('RSSI: ${r.rssi} dBm',
                                  style: const TextStyle(
                                      fontSize: 10, color: BmColors.dim)),
                              onTap: () async {
                                ble.stopScan();
                                setState(() => _connecting = true);
                                final ok = await ble.connectTo(r.device);
                                if (mounted && ok) Navigator.pop(context);
                                if (mounted) setState(() => _connecting = false);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => ble.startScan(),
                    icon: const Icon(Icons.search),
                    label: const Text('TARA'),
                  ),
                ]),
              ],
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İPTAL', style: TextStyle(color: BmColors.dim)),
          ),
        ]),
      ),
    );
  }

  @override
  void dispose() {
    _tabs.dispose();
    _ipController.dispose();
    super.dispose();
  }
}
