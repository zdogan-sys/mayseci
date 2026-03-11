import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'device_state.dart';

// ================================================================
//  ble_service.dart — BrewMaster Pro
//  BLE bağlantı yöneticisi
//
//  ESP32 BLE GATT yapısı (firmware'e eklenecek):
//    Service UUID:      4fafc201-1fb5-459e-8fcc-c5c9c331914b
//    Char — Durum:      beb5483e-36e1-4688-b7f5-ea07361b26a8  (Notify)
//    Char — Komut:      beb5483e-36e1-4688-b7f5-ea07361b26a9  (Write)
// ================================================================

const String kServiceUUID  = '4fafc201-1fb5-459e-8fcc-c5c9c331914b';
const String kStatusCharUUID = 'beb5483e-36e1-4688-b7f5-ea07361b26a8';
const String kCmdCharUUID    = 'beb5483e-36e1-4688-b7f5-ea07361b26a9';

class BleService {
  final DeviceState state;

  BluetoothDevice?      _device;
  BluetoothCharacteristic? _statusChar;
  BluetoothCharacteristic? _cmdChar;
  StreamSubscription?   _notifySub;
  StreamSubscription?   _connSub;
  bool                  _scanning = false;

  BleService(this.state);

  // ----------------------------------------------------------------
  //  Tarama
  // ----------------------------------------------------------------
  Future<void> startScan({Duration timeout = const Duration(seconds: 10)}) async {
    if (_scanning) return;
    _scanning = true;
    state.addLog('BLE tarama başladı...', level: LogLevel.info);

    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        withNames: ['BrewMaster'],
      );
      _scanning = false;
    } catch (e) {
      _scanning = false;
      state.addLog('BLE tarama hatası: $e', level: LogLevel.error);
    }
  }

  void stopScan() {
    FlutterBluePlus.stopScan();
    _scanning = false;
  }

  // Tarama sonuçları stream
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.scanResults;
  bool get isScanning => _scanning;

  // ----------------------------------------------------------------
  //  Bağlanma
  // ----------------------------------------------------------------
  Future<bool> connectTo(BluetoothDevice device) async {
    try {
      _device = device;
      await device.connect(timeout: const Duration(seconds: 10));

      // Bağlantı durumu izle
      _connSub = device.connectionState.listen((s) {
        if (s == BluetoothConnectionState.disconnected) {
          state.setDisconnected();
          state.addLog('BLE bağlantısı kesildi', level: LogLevel.warn);
        }
      });

      // Servis ve karakteristikleri bul
      List<BluetoothService> services = await device.discoverServices();
      for (final svc in services) {
        if (svc.uuid.toString().toLowerCase() == kServiceUUID) {
          for (final char in svc.characteristics) {
            final uuid = char.uuid.toString().toLowerCase();
            if (uuid == kStatusCharUUID) {
              _statusChar = char;
              // Notify'ı aktif et
              await char.setNotifyValue(true);
              _notifySub = char.onValueReceived.listen(_onBleData);
            }
            if (uuid == kCmdCharUUID) {
              _cmdChar = char;
            }
          }
        }
      }

      if (_statusChar == null || _cmdChar == null) {
        state.addLog('BLE: Servis bulunamadı', level: LogLevel.error);
        await device.disconnect();
        return false;
      }

      state.setConnected(ConnMode.ble, name: device.platformName);
      state.addLog('BLE bağlandı: ${device.platformName}', level: LogLevel.ok);
      return true;

    } catch (e) {
      state.addLog('BLE bağlantı hatası: $e', level: LogLevel.error);
      return false;
    }
  }

  // ----------------------------------------------------------------
  void _onBleData(List<int> data) {
    try {
      final json = jsonDecode(utf8.decode(data)) as Map<String, dynamic>;
      state.updateFromJson(json);
    } catch (e) {
      debugPrint('BLE parse hatası: $e');
    }
  }

  // ----------------------------------------------------------------
  //  Komut gönder
  // ----------------------------------------------------------------
  Future<void> send(Map<String, dynamic> cmd) async {
    if (_cmdChar == null) return;
    try {
      final bytes = utf8.encode(jsonEncode(cmd));
      // BLE MTU genelde 512 byte — büyük mesajları böl
      const mtu = 500;
      for (int i = 0; i < bytes.length; i += mtu) {
        final chunk = bytes.sublist(i, (i + mtu).clamp(0, bytes.length));
        await _cmdChar!.write(chunk, withoutResponse: false);
      }
    } catch (e) {
      state.addLog('BLE gönderme hatası: $e', level: LogLevel.error);
    }
  }

  void disconnect() {
    _notifySub?.cancel();
    _connSub?.cancel();
    _device?.disconnect();
    _device = null;
    _statusChar = null;
    _cmdChar = null;
    state.setDisconnected();
  }

  bool get isConnected => state.connMode == ConnMode.ble;

  // ---- Komut kısayolları (WsService ile aynı API) ----
  void cmdSSRPower(int pct)    => send({'cmd': 'ssrPwr',  'val': pct});
  void cmdSirkSpd(int pct)     => send({'cmd': 'sirkSpd', 'val': pct});
  void cmdCoolSpd(int pct)     => send({'cmd': 'coolSpd', 'val': pct});
  void cmdMotor(int pct)       => send({'cmd': 'motor',   'val': pct});
  void cmdSolenoid(bool on)    => send({'cmd': 'solenoid','val': on});
  void cmdAllOff()             => send({'cmd': 'allOff'});
  void cmdManualStart(double temp, int sec) =>
      send({'cmd': 'manStart', 'temp': temp, 'sec': sec});
  void cmdManualStop()         => send({'cmd': 'manStop'});
  void cmdManualSetTemp(double t) => send({'cmd': 'manSetTemp', 'val': t});
  void cmdManualDevice(int dev, bool on, int pct) =>
      send({'cmd': 'manDev', 'dev': dev, 'on': on, 'pct': pct});
}
