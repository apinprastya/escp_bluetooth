import 'dart:async';

import 'package:flutter/material.dart';
import 'package:escp_bluetooth/escp_bluetooth.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isEnabled = false;
  List<PrinterDevice> _printerList = [];
  String _title = "";

  @override
  void initState() {
    super.initState();
    isOn();
    EscpBluetooth.instance
        .setPrinterDiscoveredCallback(printerDiscoveredCallback);
  }

  printerDiscoveredCallback(PrinterDevice device) {
    print(device.name);
    print(device.address);
    if (_printerList.isEmpty ||
        _printerList.firstWhere((v) => v.address == device.address) == null) {
      setState(() {
        _printerList = List<PrinterDevice>.from(_printerList)..add(device);
      });
    }
  }

  isOn() async {
    final x = await EscpBluetooth.instance.isOn();
    setState(() {
      _isEnabled = x;
    });
  }

  turnOn() {
    EscpBluetooth.instance.turnOn(callback: (status) {
      setState(() {
        _isEnabled = status;
      });
    });
  }

  scan() {
    EscpBluetooth.instance.scan();
  }

  getBounded() async {
    final ret = await EscpBluetooth.instance.getBounded();
    setState(() {
      _printerList = ret;
    });
    print(ret.toString());
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Escp Bluetooth Example'),
        ),
        body: Column(
          children: <Widget>[
            Center(
              child: RaisedButton(
                onPressed: _isEnabled
                    ? null
                    : () {
                        turnOn();
                      },
                child: Text("Turn ON Bluetooth"),
              ),
            ),
            Center(
              child: RaisedButton(
                onPressed: _isEnabled
                    ? () {
                        setState(() {
                          _title = "Scan Result";
                          _printerList = [];
                        });
                        scan();
                      }
                    : null,
                child: Text("Scan"),
              ),
            ),
            Center(
              child: RaisedButton(
                onPressed: _isEnabled
                    ? () {
                        setState(() {
                          _title = "Bounded List";
                          _printerList = [];
                        });
                        getBounded();
                      }
                    : null,
                child: Text("Get Bounded"),
              ),
            ),
            Divider(),
            Text(
              _title,
              style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            Divider(),
            Expanded(
              child: ListView(
                children: _printerList.map((v) {
                  return ListTile(
                    title: Text(v.name),
                    subtitle: Text(v.address),
                    onTap: () async {
                      await EscpBluetooth.instance.selectDevice(v);
                      await EscpBluetooth.instance.connect();
                      final escp = Escp();
                      escp.bold(true);
                      escp.text("TEST TEXT BOLD");
                      escp.lineFeed();
                      escp.bold(false);
                      escp.text("TEXT NORMAL");
                      escp.lineFeed();
                      escp.center();
                      escp.text("THIS IS CENTER TEXT");
                      escp.lineFeed();
                      escp.right();
                      escp.text("THIS IS RIGHT TEXT");
                      escp.lineFeed();
                      await EscpBluetooth.instance.printData(escp.data());
                      Timer(Duration(seconds: 20), () {
                        EscpBluetooth.instance.disconnect();
                      });
                      //await EscpBluetooth.instance.disconnect();
                    },
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
