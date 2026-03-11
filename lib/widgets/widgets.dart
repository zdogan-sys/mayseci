import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/device_state.dart';

// ================================================================
//  widgets.dart — BrewMaster Pro
//  Tüm ekranlarda kullanılan ortak widget'lar
// ================================================================

// ----------------------------------------------------------------
//  Büyük sıcaklık göstergesi
// ----------------------------------------------------------------
class BigTempDisplay extends StatelessWidget {
  final double temp;
  final Color  color;
  final String label;
  final double fontSize;

  const BigTempDisplay({
    super.key,
    required this.temp,
    required this.color,
    this.label = '',
    this.fontSize = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Text(label, style: BmTextStyles.label),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              temp.toStringAsFixed(2),
              style: BmTextStyles.bigTemp.copyWith(
                fontSize: fontSize,
                color: color,
                shadows: [Shadow(color: color.withOpacity(0.4), blurRadius: 12)],
              ),
            ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text('°C',
                  style: TextStyle(
                      fontSize: fontSize * 0.3,
                      color: color.withOpacity(0.7))),
            ),
          ],
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------
//  Cihaz kontrol kartı (AÇ/KAPAT + slider)
// ----------------------------------------------------------------
class DeviceCard extends StatelessWidget {
  final String   title;
  final String   icon;
  final bool     isOn;
  final int      speed;       // 0-100, -1 = slider yok
  final Color    color;
  final VoidCallback  onToggleOn;
  final VoidCallback  onToggleOff;
  final ValueChanged<double>? onSpeedChanged;

  const DeviceCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isOn,
    required this.color,
    required this.onToggleOn,
    required this.onToggleOff,
    this.speed = -1,
    this.onSpeedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 13)),
              ),
              // Durum göstergesi
              Container(
                width: 8, height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isOn ? color : BmColors.border,
                  boxShadow: isOn
                      ? [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)]
                      : null,
                ),
              ),
            ]),
            const SizedBox(height: 8),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onToggleOn,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: isOn ? color : BmColors.border),
                    foregroundColor: isOn ? color : BmColors.dim,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(fontSize: 12, letterSpacing: 1),
                  ),
                  child: const Text('AÇ'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: OutlinedButton(
                  onPressed: onToggleOff,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: !isOn ? BmColors.red : BmColors.border),
                    foregroundColor: !isOn ? BmColors.red : BmColors.dim,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    textStyle: const TextStyle(fontSize: 12, letterSpacing: 1),
                  ),
                  child: const Text('KAPAT'),
                ),
              ),
            ]),
            if (speed >= 0 && onSpeedChanged != null) ...[
              const SizedBox(height: 4),
              Row(children: [
                Expanded(
                  child: SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: color,
                      thumbColor: color,
                    ),
                    child: Slider(
                      value: speed.toDouble(),
                      min: 0, max: 100,
                      onChanged: onSpeedChanged,
                    ),
                  ),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '%$speed',
                    style: BmTextStyles.mono.copyWith(fontSize: 11),
                    textAlign: TextAlign.right,
                  ),
                ),
              ]),
            ],
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------
//  İlerleme çubuğu + kalan süre
// ----------------------------------------------------------------
class TimerProgressBar extends StatelessWidget {
  final int     elapsedSec;
  final int     totalSec;
  final Color   color;
  final String? label;

  const TimerProgressBar({
    super.key,
    required this.elapsedSec,
    required this.totalSec,
    required this.color,
    this.label,
  });

  String get _remaining {
    final rem = (totalSec - elapsedSec).clamp(0, totalSec);
    final m = rem ~/ 60;
    final s = rem % 60;
    return '${m.toString().padLeft(2,'0')}:${s.toString().padLeft(2,'0')}';
  }

  double get _progress =>
      totalSec > 0 ? (elapsedSec / totalSec).clamp(0.0, 1.0) : 0.0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Text(label!, style: BmTextStyles.label),
        const SizedBox(height: 4),
        Row(children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: _progress,
                minHeight: 6,
                backgroundColor: BmColors.border,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _remaining,
            style: BmTextStyles.mono.copyWith(color: color, fontSize: 13),
          ),
        ]),
        const SizedBox(height: 2),
        Text(
          '${(_progress * 100).toInt()}%',
          style: BmTextStyles.label,
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------
//  Bağlantı durum çubuğu
// ----------------------------------------------------------------
class ConnectionBar extends StatelessWidget {
  final DeviceState state;
  final VoidCallback onTap;

  const ConnectionBar({super.key, required this.state, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final conn = state.connected;
    final color = conn ? BmColors.green : BmColors.red;
    final icon  = state.connMode == ConnMode.ble ? '🔵' : '📶';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: BmColors.panel,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(children: [
          Container(
            width: 8, height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 6)],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            conn
                ? '$icon  ${state.deviceName}  •  ${state.deviceIP}'
                : 'Bağlı değil — Bağlanmak için dokunun',
            style: TextStyle(
              fontSize: 11,
              color: conn ? BmColors.text : BmColors.dim,
              letterSpacing: 0.5,
            ),
          ),
          const Spacer(),
          if (conn)
            Text(
              'Q1: ${state.tempQ1.toStringAsFixed(1)}°',
              style: const TextStyle(
                fontFamily: 'JetBrainsMono',
                fontSize: 11,
                color: BmColors.amber,
              ),
            ),
        ]),
      ),
    );
  }
}

// ----------------------------------------------------------------
//  Modül durum rozeti
// ----------------------------------------------------------------
class StatusBadge extends StatelessWidget {
  final ModuleStatus status;
  final Color color;

  const StatusBadge({super.key, required this.status, required this.color});

  static const _labels = {
    ModuleStatus.idle:    'BEKLIYOR',
    ModuleStatus.running: 'ÇALIŞIYOR',
    ModuleStatus.paused:  'DURAKLATILDI',
    ModuleStatus.done:    'TAMAMLANDI',
    ModuleStatus.error:   'HATA',
  };

  @override
  Widget build(BuildContext context) {
    final isRunning = status == ModuleStatus.running;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isRunning ? color.withOpacity(0.15) : BmColors.panel,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isRunning ? color : BmColors.border),
      ),
      child: Text(
        _labels[status] ?? '—',
        style: TextStyle(
          fontSize: 10,
          letterSpacing: 2,
          color: isRunning ? color : BmColors.dim,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ----------------------------------------------------------------
//  Olay kaydı listesi
// ----------------------------------------------------------------
class LogList extends StatelessWidget {
  final List<LogEntry> entries;
  final int maxVisible;

  const LogList({super.key, required this.entries, this.maxVisible = 50});

  @override
  Widget build(BuildContext context) {
    final visible = entries.take(maxVisible).toList();
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visible.length,
      itemBuilder: (_, i) {
        final e = visible[i];
        final color = switch (e.level) {
          LogLevel.ok    => BmColors.green,
          LogLevel.warn  => BmColors.amber,
          LogLevel.error => BmColors.red,
          _              => BmColors.dim,
        };
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(e.timeStr,
                  style: BmTextStyles.mono.copyWith(fontSize: 10)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(e.msg,
                    style: TextStyle(fontSize: 11, color: color)),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ----------------------------------------------------------------
//  Sıcaklık + ayar butonu satırı
// ----------------------------------------------------------------
class TempAdjRow extends StatelessWidget {
  final double  value;
  final Color   color;
  final String  label;
  final void Function(double) onChanged;
  final List<double> steps;

  const TempAdjRow({
    super.key,
    required this.value,
    required this.color,
    required this.label,
    required this.onChanged,
    this.steps = const [-5, -1, -0.25, 0.25, 1, 5],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: BmTextStyles.label),
        const SizedBox(height: 6),
        Row(children: [
          for (final s in steps)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: OutlinedButton(
                  onPressed: () => onChanged(
                      (value + s).clamp(0.0, 105.0)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: BmColors.border),
                    foregroundColor: color,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(fontSize: 10),
                  ),
                  child: Text(
                    s > 0 ? '+${s % 1 == 0 ? s.toInt() : s}'
                          : '${s % 1 == 0 ? s.toInt() : s}',
                  ),
                ),
              ),
            ),
        ]),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(6),
          ),
          child: TextField(
            controller: TextEditingController(
                text: value.toStringAsFixed(2))
              ..selection = TextSelection.collapsed(
                  offset: value.toStringAsFixed(2).length),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
            ),
            onSubmitted: (v) {
              final parsed = double.tryParse(v.replaceAll(',', '.'));
              if (parsed != null) onChanged(parsed.clamp(0.0, 105.0));
            },
          ),
        ),
      ],
    );
  }
}

// ----------------------------------------------------------------
//  Acil durdur butonu
// ----------------------------------------------------------------
class EmergencyStopButton extends StatelessWidget {
  final VoidCallback onPressed;

  const EmergencyStopButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: BmColors.panel,
            title: const Text('⚠️ Acil Durdur',
                style: TextStyle(color: BmColors.red)),
            content: const Text(
                'Tüm cihazlar kapatılacak. Emin misiniz?',
                style: TextStyle(color: BmColors.dim)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('İPTAL',
                    style: TextStyle(color: BmColors.dim)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: BmColors.red),
                onPressed: () {
                  Navigator.pop(context);
                  onPressed();
                },
                child: const Text('DURDUR'),
              ),
            ],
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: BmColors.darkRed,
          foregroundColor: BmColors.red,
          side: const BorderSide(color: BmColors.red),
          padding: const EdgeInsets.symmetric(vertical: 14),
          textStyle: const TextStyle(
            fontFamily: 'BebasNeue',
            fontSize: 18,
            letterSpacing: 3,
          ),
        ),
        icon: const Text('🛑', style: TextStyle(fontSize: 18)),
        label: const Text('ACİL DURDUR'),
      ),
    );
  }
}
