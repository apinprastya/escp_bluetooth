import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef EscpBluetoothTurnOnCallback(bool status);
typedef EscpBluetoothPrinterDeviceDiscovered(PrinterDevice device);

class EscpBluetooth {
  static EscpBluetooth instance = EscpBluetooth._();
  static const MethodChannel _channel =
      const MethodChannel('com.lekapin.escp_bluetooth');

  EscpBluetoothTurnOnCallback _turnOnCallback;
  EscpBluetoothPrinterDeviceDiscovered _printerDiscoverCallback;
  List<PrinterDevice> _printerDivices;
  PrinterDevice _selectedDevices;
  SharedPreferences _pref;

  EscpBluetooth._() {
    _channel.setMethodCallHandler(channelHandler);
    SharedPreferences.getInstance().then((pref) {
      _pref = pref;
      final name = _pref.getString("EscpBlutooth_selectedName");
      final address = _pref.getString("EscpBlutooth_selectedAddress");
      if (name != null && name.isNotEmpty) {
        _selectedDevices = PrinterDevice(name, address);
      }
    });
  }

  PrinterDevice get selectedDevice {
    return _selectedDevices;
  }

  selectDevice(PrinterDevice device) {
    _selectedDevices = device;
    _pref.setString("EscpBlutooth_selectedName", device.name);
    _pref.setString("EscpBlutooth_selectedAddress", device.address);
  }

  Future<dynamic> channelHandler(MethodCall methodCall) async {
    if (methodCall.method == "turnOnStatus") {
      if (_turnOnCallback != null) _turnOnCallback(methodCall.arguments);
      _turnOnCallback = null;
    } else if (methodCall.method == "deviceDiscovered") {
      if (_printerDiscoverCallback != null) {
        final data = Map<String, dynamic>.from(methodCall.arguments);
        final pd = PrinterDevice(data['name'], data['mac_address']);
        _printerDiscoverCallback(pd);
        _printerDivices.add(pd);
      }
    }
  }

  static Future<String> get platformVersion async {
    final String version = await _channel.invokeMethod('getPlatformVersion');
    return version;
  }

  Future<bool> isOn() async {
    final isEnabled = await _channel.invokeMethod("isOn");
    return isEnabled;
  }

  turnOn({EscpBluetoothTurnOnCallback callback}) {
    _turnOnCallback = callback;
    _channel.invokeMethod("turnOn");
  }

  scan({EscpBluetoothPrinterDeviceDiscovered callback}) {
    _printerDivices = [];
    _printerDiscoverCallback = callback;
    _channel.invokeMethod("scan");
  }

  Future<List<PrinterDevice>> getBounded() async {
    final res = await _channel.invokeMethod("scanBounded");
    if (res != null) {
      List<PrinterDevice> ret = [];
      final list = List.from(res);
      list.forEach((v) {
        final m = Map<String, dynamic>.from(v);
        ret.add(PrinterDevice.fromJson(m));
      });
      return Future<List<PrinterDevice>>.value(ret);
    }
    return null;
  }

  Future<bool> printData(Uint8List data) {
    return _channel.invokeMethod("printData");
  }
}

class PrinterDevice {
  final String name;
  final String address;
  PrinterDevice(this.name, this.address);
  factory PrinterDevice.fromJson(Map<String, dynamic> json) {
    return PrinterDevice(json['name'], json['mac_address']);
  }
}
