import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme.dart';
import 'services/device_state.dart';
import 'services/ws_service.dart';
import 'services/ble_service.dart';
import 'widgets/widgets.dart';
import 'screens/home_screen.dart';
import 'screens/manual_screen.dart';
// Diğer ekranlar eklendikçe buraya import edilecek:
// import 'screens/mash_screen.dart';
// import 'screens/ferm_screen.dart';
// import 'screens/dairy_screen.dart';
// import 'screens/distill_screen.dart';
// import 'screens/settings_screen.dart';

// ================================================================
//  main.dart — BrewMaster Pro
// ================================================================

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Yatay mod kilitle (isteğe bağlı — dikey daha kullanışlı olabilir)
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const BrewMasterApp());
}

class BrewMasterApp extends StatelessWidget {
  const BrewMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Servisleri ve state'i en üstte oluştur
    final deviceState = DeviceState();
    final wsService   = WsService(deviceState);
    final bleService  = BleService(deviceState);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: deviceState),
        Provider.value(value: wsService),
        Provider.value(value: bleService),
      ],
      child: MaterialApp(
        title: 'BrewMaster Pro',
        theme: buildAppTheme(),
        debugShowCheckedModeBanner: false,
        home: const MainScaffold(),
      ),
    );
  }
}

// ================================================================
//  Ana scaffold — alt navigasyon + ekranlar
// ================================================================
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});
  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedTab = 0;

  // Tab tanımları
  static const _tabs = [
    _TabDef(icon: '🏠', label: 'Ana'),
    _TabDef(icon: '🍺', label: 'Mayşe',   color: BmColors.amber),
    _TabDef(icon: '🧪', label: 'Ferm.',   color: BmColors.green),
    _TabDef(icon: '🧀', label: 'Süt',     color: BmColors.cyan),
    _TabDef(icon: '⚗️', label: 'Dist.',   color: BmColors.purple),
    _TabDef(icon: '🎛', label: 'Manuel',  color: BmColors.orange),
  ];

  // Her tab için ekran widget'ı
  Widget _buildScreen(int idx) {
    return switch (idx) {
      0 => const HomeScreen(),
      // 1 => const MashScreen(),    // TODO
      // 2 => const FermScreen(),    // TODO
      // 3 => const DairyScreen(),   // TODO
      // 4 => const DistillScreen(), // TODO
      5 => const ManualScreen(),
      _ => _PlaceholderScreen(tab: _tabs[idx]),
    };
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DeviceState>();

    return Scaffold(
      backgroundColor: BmColors.bg,
      // Üst bağlantı çubuğu
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(36),
        child: ConnectionBar(
          state: state,
          onTap: () => showDialog(
            context: context,
            builder: (_) => const ConnectDialog(),
          ),
        ),
      ),
      // İçerik — IndexedStack ile tüm ekranlar bellekte tutuluyor
      body: IndexedStack(
        index: _selectedTab,
        children: List.generate(_tabs.length, _buildScreen),
      ),
      // Alt navigasyon
      bottomNavigationBar: _buildNavBar(),
    );
  }

  Widget _buildNavBar() {
    return Container(
      decoration: const BoxDecoration(
        color: BmColors.panel,
        border: Border(top: BorderSide(color: BmColors.border)),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 56,
          child: Row(
            children: List.generate(_tabs.length, (i) {
              final t      = _tabs[i];
              final active = _selectedTab == i;
              final color  = t.color ?? BmColors.dim;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedTab = i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(
                          color: active ? color : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(t.icon,
                            style: TextStyle(
                                fontSize: active ? 20 : 18,
                                color: active ? color : BmColors.dim)),
                        const SizedBox(height: 2),
                        Text(t.label,
                          style: TextStyle(
                            fontSize: 9,
                            letterSpacing: 0.5,
                            color: active ? color : BmColors.dim,
                            fontWeight: active
                                ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------
class _TabDef {
  final String  icon;
  final String  label;
  final Color?  color;
  const _TabDef({required this.icon, required this.label, this.color});
}

// Henüz yazılmamış ekranlar için placeholder
class _PlaceholderScreen extends StatelessWidget {
  final _TabDef tab;
  const _PlaceholderScreen({super.key, required this.tab});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(tab.icon, style: const TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text(tab.label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'BebasNeue', fontSize: 24,
            letterSpacing: 4,
            color: tab.color ?? BmColors.dim,
          )),
        const SizedBox(height: 8),
        const Text('Yakında...', style: TextStyle(color: BmColors.dim)),
      ]),
    );
  }
}
