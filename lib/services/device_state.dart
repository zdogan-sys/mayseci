import 'package:flutter/foundation.dart';

// ================================================================
//  device_state.dart — BrewMaster Pro
//  Tüm ekranların paylaştığı merkezi durum (ChangeNotifier)
// ================================================================

enum ConnMode { none, wifi, ble }
enum ModuleStatus { idle, running, paused, done, error }

class DeviceState extends ChangeNotifier {
  // ---- Bağlantı ----
  ConnMode  connMode      = ConnMode.none;
  bool      get connected => connMode != ConnMode.none;
  String    deviceName    = 'BrewMaster Pro';
  String    deviceIP      = '';
  int       rssi          = 0;

  // ---- Sensörler ----
  double    tempQ1        = 0.0;
  double    tempQ2        = 0.0;
  double    tempQ3        = 0.0;
  double    tempIspindel  = 0.0;
  double    sgIspindel    = 1.000;
  bool      ispindelOnline= false;

  // ---- Çıkışlar ----
  bool      ssrOn         = false;
  int       ssrPower      = 0;
  int       pumpSirkSpd   = 0;
  int       pumpCoolSpd   = 0;
  int       motorSpd      = 0;
  bool      solenoidOn    = false;

  // ---- Aktif modül (0=home,1=mash,2=ferm,3=dairy,4=dist,5=manual) ----
  int       activeModule  = 0;

  // ---- Mayşeleme ----
  ModuleStatus  mashStatus    = ModuleStatus.idle;
  int           mashStepIdx   = 0;
  double        mashTargetTemp= 0.0;
  int           mashHoldSec   = 0;
  int           mashElapsedSec= 0;
  bool          mashAtTarget  = false;
  String        mashPhaseName = '';

  // ---- Fermentasyon ----
  ModuleStatus  fermStatus    = ModuleStatus.idle;
  double        fermTargetTemp= 19.0;
  double        fermOG        = 1.000;
  double        fermSG        = 1.000;
  double        fermABV       => fermOG > fermSG
      ? ((fermOG - fermSG) * 131.25).clamp(0, 100)
      : 0.0;
  bool          fermHeaterOn  = false;
  bool          fermCoolOn    = false;

  // ---- Süt ürünleri ----
  ModuleStatus  dairyStatus   = ModuleStatus.idle;
  int           dairyStepIdx  = 0;
  double        dairyTargetTemp = 0.0;
  int           dairyHoldSec  = 0;
  int           dairyElapsedSec = 0;

  // ---- Distilasyon ----
  ModuleStatus  distStatus    = ModuleStatus.idle;
  int           distPhase     = 0;
  int           distFrac      = 0;
  double        distX1        = 76.0;
  double        distX2        = 78.25;
  bool          distBalanced  = false;

  // ---- Manuel mod ----
  ModuleStatus  manualStatus  = ModuleStatus.idle;
  double        manualTargetTemp = 65.0;
  int           manualHoldSec = 3600;
  int           manualElapsedSec = 0;
  bool          manualAtTarget = false;
  bool          manualHeaterAuto = true;

  // ---- Sıcaklık geçmişi (grafik) ----
  final List<double> tempHistory = [];
  static const int   maxHistory  = 120;

  // ---- Olay kaydı ----
  final List<LogEntry> log = [];
  static const int maxLog = 200;

  // ================================================================
  //  WebSocket'ten gelen JSON ile güncelle
  // ================================================================
  void updateFromJson(Map<String, dynamic> j) {
    tempQ1        = (j['q1']       ?? tempQ1).toDouble();
    tempQ2        = (j['q2']       ?? tempQ2).toDouble();
    tempQ3        = (j['q3']       ?? tempQ3).toDouble();
    sgIspindel    = (j['sg']       ?? sgIspindel).toDouble();
    ispindelOnline= j['isp']       ?? ispindelOnline;
    ssrOn         = j['ssrOn']     ?? ssrOn;
    ssrPower      = j['ssrPwr']    ?? ssrPower;
    pumpSirkSpd   = j['sirkSpd']   ?? pumpSirkSpd;
    pumpCoolSpd   = j['coolSpd']   ?? pumpCoolSpd;
    motorSpd      = j['motorSpd']  ?? motorSpd;
    solenoidOn    = j['solenoid']  ?? solenoidOn;
    activeModule  = j['module']    ?? activeModule;
    deviceIP      = j['ip']        ?? deviceIP;

    // Sıcaklık geçmişi
    tempHistory.add(tempQ1);
    if (tempHistory.length > maxHistory) tempHistory.removeAt(0);

    notifyListeners();
  }

  // ================================================================
  //  Olay / log ekle
  // ================================================================
  void addLog(String msg, {LogLevel level = LogLevel.info}) {
    log.insert(0, LogEntry(
      time: DateTime.now(),
      msg: msg,
      level: level,
    ));
    if (log.length > maxLog) log.removeLast();
    notifyListeners();
  }

  // ================================================================
  //  Kalan süre yardımcıları
  // ================================================================
  String get manualTimeRemaining {
    int rem = (manualHoldSec - manualElapsedSec).clamp(0, manualHoldSec);
    return _fmtTime(rem);
  }

  String get mashTimeRemaining {
    int rem = (mashHoldSec - mashElapsedSec).clamp(0, mashHoldSec);
    return _fmtTime(rem);
  }

  int get manualProgressPct => manualHoldSec > 0
      ? ((manualElapsedSec / manualHoldSec) * 100).clamp(0, 100).toInt()
      : 0;

  int get mashProgressPct => mashHoldSec > 0
      ? ((mashElapsedSec / mashHoldSec) * 100).clamp(0, 100).toInt()
      : 0;

  static String _fmtTime(int sec) {
    final m = sec ~/ 60;
    final s = sec % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ================================================================
  //  Bağlantı durumu
  // ================================================================
  void setConnected(ConnMode mode, {String ip = '', String name = ''}) {
    connMode   = mode;
    deviceIP   = ip;
    deviceName = name.isNotEmpty ? name : 'BrewMaster Pro';
    addLog('Bağlandı (${mode.name.toUpperCase()}) $ip', level: LogLevel.ok);
    notifyListeners();
  }

  void setDisconnected() {
    connMode = ConnMode.none;
    addLog('Bağlantı kesildi', level: LogLevel.warn);
    notifyListeners();
  }
}

// ----------------------------------------------------------------
enum LogLevel { info, ok, warn, error }

class LogEntry {
  final DateTime time;
  final String   msg;
  final LogLevel level;
  const LogEntry({required this.time, required this.msg, required this.level});

  String get timeStr {
    final t = time;
    return '${t.hour.toString().padLeft(2,'0')}:'
           '${t.minute.toString().padLeft(2,'0')}:'
           '${t.second.toString().padLeft(2,'0')}';
  }
}
