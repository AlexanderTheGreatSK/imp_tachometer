import 'dart:core';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:imp_tachometer/TachometerScreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Tachometer App'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final FlutterBluePlus flutterBluePlus = FlutterBluePlus();
  Set<DeviceIdentifier> seenDevices = {};
  Set<String> seenDevicesNames = {};

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(widget.title),
    ),
    body: FutureBuilder(
      future: findDevices(),
      builder: (BuildContext context, AsyncSnapshot<List<BluetoothDevice>> asyncSnapshot) {
        if(asyncSnapshot.hasData) {
          List<BluetoothDevice> devices = asyncSnapshot.data!;
          return ListView.builder(
            itemCount: devices.length,
            itemBuilder: (BuildContext context, int index) {
              return getBTDeviceWidget(devices[index]);
            },
          );
        } else {
          return const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              Text("Searching...")
            ],
          );
        }
    },
    ),
    floatingActionButton: FloatingActionButton(
      backgroundColor: Colors.indigo,
      onPressed: findDevices,
      child: const Icon(Icons.search),
    ),
  );

  Future<bool> isBluetoothEnabled() async {
    final state = await FlutterBluePlus.adapterState.first;

    if(state == BluetoothAdapterState.on) {
      return true;
    }

    return false;
  }

  Future<void> turnOnBluetooth() async {
    if(Platform.isAndroid) {
      await FlutterBluePlus.turnOn();
    }
  }

  Future<void> turnOffBluetooth() async {
    if(Platform.isAndroid) {
      await FlutterBluePlus.turnOff();
    }
  }

  Future<List<BluetoothDevice>> findDevices() async {
    List<BluetoothDevice> devices = [];

    FlutterBluePlus.scanResults.listen((results) {
      List<ScanResult> scannedDevices = [];
      for(ScanResult r in results) {
        if(r.device.platformName.isNotEmpty) {
          scannedDevices.add(r);
        }
      }
      scannedDevices.sort((a, b) => b.rssi.compareTo(a.rssi));
      devices.clear();
      for(ScanResult element in scannedDevices) {
        devices.add(element.device);
      }

    });
    final isScanning = FlutterBluePlus.isScanningNow;

    if(!isScanning) {
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));
    }
    print("DEVICES: ${devices.length}");
    return devices;
  }

  Future searchDevices() async {
    if(await FlutterBluePlus.isSupported == false) {
      print("Bluetooth not supported by this device");
      return;
    }

    bool bleIsON = true;

    FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {
      print(state);
      if(state == BluetoothAdapterState.on) {
        // TODO add scanning
      } else {
        bleIsON = false;
      }
    });

    if(bleIsON == false) {
      if(Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      }
    }

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 5));

    FlutterBluePlus.scanResults.listen(
            (results) {
              for(ScanResult r in results) {
                if(seenDevices.contains(r.device.remoteId) == false) {
                  print('MY: ${r.device.remoteId}: "${r.advertisementData.localName}" found! rssi: ${r.rssi}');
                  seenDevices.add(r.device.remoteId);
                  seenDevicesNames.add(r.advertisementData.localName);
                }
              }
            },
    ).onDone(() {
      print(seenDevicesNames.length);
      for(int i = 0; i < seenDevices.length; i++) {
        print("++++++++++++++++++++++++++++++++++++++++++++++++");
        print("SAVED ID: ${seenDevices.elementAt(i)}");
        print("SAVED NAME: ${seenDevicesNames.elementAt(i)}");
      }
    });
  }

  void toTachometerPage(BluetoothDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => TachometerPage(device: device)),
    );
  }

  Widget getBTDeviceWidget(BluetoothDevice device) {
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: Card(
        clipBehavior: Clip.hardEdge,
        child: InkWell(
          splashColor: Colors.indigo,
          onTap: () {
            connect(device).whenComplete(() => toTachometerPage(device));
          },
          child: SizedBox(
            width: 300,
            height: 100,
            child: Column(
              children: [
                Text(device.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(device.name),
                    const Spacer(),
                    Text(device.remoteId.str)
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Future<void> connect(BluetoothDevice device) async {
    await device.connect(autoConnect: true);
    await device.requestMtu(517);
    print("CONNECTED");

  }


}
