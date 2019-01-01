import 'package:flutter/material.dart';
import 'package:escp_bluetooth/escp_bluetooth.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isEnabled = false;

  @override
  void initState() {
    super.initState();
    isOn();
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
    EscpBluetooth.instance.scan(callback: (device) {
      print(device.name);
      print(device.address);
    });
  }

  getBounded() async {
    final ret = await EscpBluetooth.instance.getBounded();
    print(ret);
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
                          getBounded();
                        }
                      : null,
                  child: Text("Get Bounded"),
                ),
              ),
            ],
          )),
    );
  }
}
