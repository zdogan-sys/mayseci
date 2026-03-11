import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'device_state.dart';

// ================================================================
//  ws_service.dart — BrewMaster Pro
//  WebSocket bağlantı yöneticisi
// ================================================================

class WsService {
  final DeviceState state;
  WebSocketChannel? _channel;
  Timer?            _reconnectTimer;
  Timer?            _pingTimer;
  String            _url = '';
  bool              _intentionalClose = false;

  WsService(this.state);

  // ----------------------------------------------------------------
  Future<void> connect(String ip) async {
    _intentionalClose = false;
    _url = 'ws://$ip/ws';
    await _doConnect();

    // Son bağlanan IP'yi kaydet
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('lastIP', ip);
  }

  Future<void> _doConnect() async {
    try {
      _channel?.sink.close();
      _channel = WebSocketChannel.connect(Uri.parse(_url));

      _channel!.stream.listen(
        _onData,
        onError: _onError,
        onDone:  _onDone,
      );

      state.setConnected(ConnMode.wifi, ip: _url.split('/')[2]);
      state.addLog('WebSocket bağlandı: $_url', level: LogLevel.ok);

      // Ping her 10 saniyede
      _pingTimer?.cancel();
      _pingTimer = Timer.periodic(const Duration(seconds: 10), (_) {
        send({'cmd': 'ping'});
      });

    } catch (e) {
      state.addLog('WS bağlantı hatası: $e', level: LogLevel.error);
      _scheduleReconnect();
    }
  }

  // ----------------------------------------------------------------
  void _onData(dynamic data) {
    try {
      final json = jsonDecode(data as String) as Map<String, dynamic>;

      // Olay bildirimi mi, durum güncellemesi mi?
      if (json.containsKey('evt')) {
        _handleEvent(json['evt'] as String, json['msg'] as String? ?? '');
      } else {
        state.updateFromJson(json);
      }
    } catch (e) {
      debugPrint('WS parse hatası: $e');
    }
  }

  void _handleEvent(String evt, String msg) {
    final levelMap = <String, LogLevel>{
      'atTarget'   : LogLevel.ok,
      'mashDone'   : LogLevel.ok,
      'fermDone'   : LogLevel.ok,
      'dairyDone'  : LogLevel.ok,
      'distDone'   : LogLevel.ok,
      'manDone'    : LogLevel.ok,
      'distSafety' : LogLevel.error,
      'waitMalt'   : LogLevel.warn,
      'waitTransfer': LogLevel.warn,
      'hopAdd'     : LogLevel.warn,
      'distBalance': LogLevel.warn,
      'distUnbalance': LogLevel.warn,
    };
    state.addLog(msg, level: levelMap[evt] ?? LogLevel.info);
  }

  void _onError(dynamic error) {
    state.addLog('WS hata: $error', level: LogLevel.error);
    state.setDisconnected();
    _scheduleReconnect();
  }

  void _onDone() {
    if (_intentionalClose) return;
    state.setDisconnected();
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_intentionalClose) {
        state.addLog('Yeniden bağlanılıyor...', level: LogLevel.warn);
        _doConnect();
      }
    });
  }

  // ----------------------------------------------------------------
  void send(Map<String, dynamic> cmd) {
    if (_channel == null) return;
    try {
      _channel!.sink.add(jsonEncode(cmd));
    } catch (e) {
      debugPrint('WS gönderme hatası: $e');
    }
  }

  void disconnect() {
    _intentionalClose = true;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close();
    _channel = null;
    state.setDisconnected();
  }

  bool get isConnected => state.connMode == ConnMode.wifi;

  // ---- Komut kısayolları ----
  void cmdSSRPower(int pct)      => send({'cmd': 'ssrPwr',   'val': pct});
  void cmdSirkSpd(int pct)       => send({'cmd': 'sirkSpd',  'val': pct});
  void cmdCoolSpd(int pct)       => send({'cmd': 'coolSpd',  'val': pct});
  void cmdMotor(int pct)         => send({'cmd': 'motor',    'val': pct});
  void cmdSolenoid(bool on)      => send({'cmd': 'solenoid', 'val': on});
  void cmdAllOff()               => send({'cmd': 'allOff'});
  void cmdManualStart(double temp, int sec) =>
      send({'cmd': 'manStart', 'temp': temp, 'sec': sec});
  void cmdManualStop()           => send({'cmd': 'manStop'});
  void cmdManualSetTemp(double t)=> send({'cmd': 'manSetTemp', 'val': t});
  void cmdManualSetDuration(int s)=>send({'cmd': 'manSetDur',  'val': s});
  void cmdManualDevice(int dev, bool on, int pct) =>
      send({'cmd': 'manDev', 'dev': dev, 'on': on, 'pct': pct});
  void cmdMashConfirm()          => send({'cmd': 'mashConfirm'});
  void cmdMashStop()             => send({'cmd': 'mashStop'});
  void cmdFermStop()             => send({'cmd': 'fermStop'});
  void cmdDairyConfirm()         => send({'cmd': 'dairyConfirm'});
  void cmdDairyStop()            => send({'cmd': 'dairyStop'});
  void cmdDistStop()             => send({'cmd': 'distStop'});
  void cmdDistPower(int pct)     => send({'cmd': 'distPower', 'val': pct});
  void cmdDistPump(int pct)      => send({'cmd': 'distPump',  'val': pct});
  void cmdSetWifi(String ssid, String pass) =>
      send({'cmd': 'setWifi', 'ssid': ssid, 'pass': pass});
  void cmdLicense(String key)    => send({'cmd': 'license', 'key': key});
}
