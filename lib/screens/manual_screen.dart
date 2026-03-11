import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/device_state.dart';
import '../services/ws_service.dart';
import '../widgets/widgets.dart';

// ================================================================
//  manual_screen.dart — BrewMaster Pro
// ================================================================

class ManualScreen extends StatefulWidget {
  const ManualScreen({super.key});
  @override
  State<ManualScreen> createState() => _ManualScreenState();
}

class _ManualScreenState extends State<ManualScreen> {
  double _targetTemp = 65.0;
  int    _durationMin = 60;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DeviceState>();
    final ws    = context.read<WsService>();
    final color = BmColors.orange;
    final running = state.manualStatus == ModuleStatus.running;

    return Scaffold(
      backgroundColor: BmColors.bg,
      body: running ? _buildRunning(state, ws, color)
                    : _buildSetup(state, ws, color),
    );
  }

  // ----------------------------------------------------------------
  //  SETUP
  // ----------------------------------------------------------------
  Widget _buildSetup(DeviceState state, WsService ws, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        // Modül başlığı
        _header('E. MANUEL MOD', color, state.manualStatus),
        const SizedBox(height: 16),

        // Hedef sıcaklık
        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: TempAdjRow(
            label: 'HEDEF SICAKLIK',
            value: _targetTemp,
            color: color,
            onChanged: (v) => setState(() => _targetTemp = v),
          ),
        )),
        const SizedBox(height: 12),

        // Süre
        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SÜRE (DAKİKA)', style: BmTextStyles.label),
              const SizedBox(height: 8),
              Row(children: [
                for (final d in [-10, -5, -1, 1, 5, 10])
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: OutlinedButton(
                      onPressed: () => setState(() =>
                          _durationMin = (_durationMin + d).clamp(1, 1440)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: BmColors.border),
                        foregroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(fontSize: 10),
                      ),
                      child: Text(d > 0 ? '+$d' : '$d'),
                    ),
                  )),
              ]),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: color),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: TextField(
                  controller: TextEditingController(
                      text: _durationMin.toString())
                    ..selection = TextSelection.collapsed(
                        offset: _durationMin.toString().length),
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'BebasNeue',
                    fontSize: 28,
                    color: color,
                    letterSpacing: 2,
                  ),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 6),
                    suffixText: 'dk',
                    suffixStyle: TextStyle(color: BmColors.dim),
                  ),
                  onSubmitted: (v) => setState(() =>
                      _durationMin = (int.tryParse(v) ?? 60).clamp(1, 1440)),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 20),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: state.connected
                ? () => ws.cmdManualStart(_targetTemp, _durationMin * 60)
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                  fontFamily: 'BebasNeue', fontSize: 20, letterSpacing: 3),
            ),
            child: const Text('▶  BAŞLAT'),
          ),
        ),
      ]),
    );
  }

  // ----------------------------------------------------------------
  //  ÇALIŞIYOR
  // ----------------------------------------------------------------
  Widget _buildRunning(DeviceState state, WsService ws, Color color) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _header('E. MANUEL MOD', color, state.manualStatus),
        const SizedBox(height: 12),

        // Üst göstergeler — 2 sütun
        Row(children: [
          Expanded(child: Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              const Text('MEVCUT SICAKLIK', style: BmTextStyles.label),
              const SizedBox(height: 4),
              BigTempDisplay(temp: state.tempQ1, color: color, fontSize: 56),
            ]),
          ))),
          const SizedBox(width: 10),
          Expanded(child: Card(child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(children: [
              const Text('KALAN SÜRE', style: BmTextStyles.label),
              const SizedBox(height: 4),
              Text(
                state.manualTimeRemaining,
                style: BmTextStyles.timer.copyWith(color: color),
              ),
              Text(
                state.manualAtTarget ? 'Tutma süresi' : 'Hedefe ulaşılıyor...',
                style: const TextStyle(fontSize: 10, color: BmColors.dim),
              ),
            ]),
          ))),
        ]),
        const SizedBox(height: 10),

        // İlerleme
        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: TimerProgressBar(
            elapsedSec: state.manualElapsedSec,
            totalSec:   state.manualHoldSec,
            color:      color,
            label:      'İLERLEME',
          ),
        )),
        const SizedBox(height: 10),

        // Anlık hedef sıcaklık ayarı
        Card(child: Padding(
          padding: const EdgeInsets.all(14),
          child: TempAdjRow(
            label: 'HEDEF SICAKLIK (ANLK)',
            value: state.manualTargetTemp,
            color: color,
            onChanged: (v) => ws.cmdManualSetTemp(v),
          ),
        )),
        const SizedBox(height: 10),

        // Süre ayarı
        Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SÜRE EKLE / ÇIKAR', style: BmTextStyles.label),
              const SizedBox(height: 8),
              Row(children: [
                for (final d in [-10, -5, -1, 1, 5, 10])
                  Expanded(child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: OutlinedButton(
                      onPressed: () {
                        final newSec = (state.manualHoldSec + d * 60)
                            .clamp(60, 86400);
                        ws.cmdManualSetDuration(newSec);
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: BmColors.border),
                        foregroundColor: color,
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(fontSize: 10),
                      ),
                      child: Text(d > 0 ? '+${d}dk' : '${d}dk'),
                    ),
                  )),
              ]),
            ],
          ),
        )),
        const SizedBox(height: 10),

        // Cihaz kontrolleri
        const Text('CİHAZ KONTROL', style: BmTextStyles.label),
        const SizedBox(height: 8),
        _deviceGrid(state, ws, color),
        const SizedBox(height: 16),

        // Olay kaydı
        Card(child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('OLAY KAYDI', style: BmTextStyles.label),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 180),
                child: SingleChildScrollView(
                  child: LogList(entries: state.log),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 16),

        EmergencyStopButton(onPressed: () {
          ws.cmdManualStop();
          ws.cmdAllOff();
        }),
        const SizedBox(height: 24),
      ]),
    );
  }

  Widget _deviceGrid(DeviceState state, WsService ws, Color color) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.2,
      children: [
        DeviceCard(
          title: 'Rezistans', icon: '🔥',
          isOn: state.ssrOn, speed: state.ssrPower,
          color: BmColors.amber,
          onToggleOn:  () => ws.cmdSSRPower(100),
          onToggleOff: () => ws.cmdSSRPower(0),
          onSpeedChanged: (v) => ws.cmdSSRPower(v.toInt()),
        ),
        DeviceCard(
          title: 'Sirkülasyon', icon: '🔄',
          isOn: state.pumpSirkSpd > 0, speed: state.pumpSirkSpd,
          color: BmColors.green,
          onToggleOn:  () => ws.cmdSirkSpd(60),
          onToggleOff: () => ws.cmdSirkSpd(0),
          onSpeedChanged: (v) => ws.cmdSirkSpd(v.toInt()),
        ),
        DeviceCard(
          title: 'Soğutma', icon: '❄️',
          isOn: state.pumpCoolSpd > 0, speed: state.pumpCoolSpd,
          color: BmColors.cyan,
          onToggleOn:  () => ws.cmdCoolSpd(70),
          onToggleOff: () => ws.cmdCoolSpd(0),
          onSpeedChanged: (v) => ws.cmdCoolSpd(v.toInt()),
        ),
        DeviceCard(
          title: 'Karıştırıcı', icon: '🔃',
          isOn: state.motorSpd > 0, speed: state.motorSpd,
          color: BmColors.purple,
          onToggleOn:  () => ws.cmdMotor(40),
          onToggleOff: () => ws.cmdMotor(0),
          onSpeedChanged: (v) => ws.cmdMotor(v.toInt()),
        ),
        DeviceCard(
          title: 'Selenoid Vana', icon: '🚰',
          isOn: state.solenoidOn, speed: -1,
          color: BmColors.red,
          onToggleOn:  () => ws.cmdSolenoid(true),
          onToggleOff: () => ws.cmdSolenoid(false),
        ),
      ],
    );
  }

  Widget _header(String title, Color color, ModuleStatus status) {
    return Row(children: [
      Text(title, style: TextStyle(
        fontFamily: 'BebasNeue', fontSize: 18,
        letterSpacing: 3, color: color,
      )),
      const Spacer(),
      StatusBadge(status: status, color: color),
    ]);
  }
}
