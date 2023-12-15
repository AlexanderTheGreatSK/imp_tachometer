import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:google_fonts/google_fonts.dart';

class TachometerPage extends StatefulWidget {
  const TachometerPage({super.key, required this.device});
  final BluetoothDevice device;

  @override
  State<TachometerPage> createState() => TachometerPageState();
}

class TachometerPageState extends State<TachometerPage> {
    double speed = 0.0;
    double averageSpeed0 = 0.0;
    double distance = 0.0;

  @override
  void initState() {
    getData();
    super.initState();
  }

  Future<void> getData() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    late BluetoothCharacteristic char;
    services.forEach((service) {
      service.characteristics.forEach((characteristic) async {
        if(characteristic.characteristicUuid.toString() == "f1072dd4-9b60-11ee-b9d1-0242ac120002") {
          char = characteristic;
        }
      });
    });

    await char.setNotifyValue(true);
    final sub = char.onValueReceived.listen((value) {
      var dataMap = json.decode(String.fromCharCodes(value));
      setState(() {
        speed = dataMap["speed"]!;
        averageSpeed0 = dataMap["averageSpeed"]!;
        distance = dataMap["distance"]!;
      });
    });

  }

  Future<void> getTrips() async {
    List<BluetoothService> services = await widget.device.discoverServices();
    late BluetoothCharacteristic char;
    services.forEach((service) {
      service.characteristics.forEach((characteristic) async {
        if(characteristic.characteristicUuid.toString() == "f1072dd4-9b60-11ee-b9d1-0242ac120001") {
          List<int> dataLInt = await characteristic.read();
          String stringData = String.fromCharCodes(dataLInt);
          print(characteristic.characteristicUuid.toString());
          dataLInt.forEach((element) {
            print("DATA: $element");
          });
          print(stringData);
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(widget.device.name, style: GoogleFonts.dotGothic16(textStyle: const TextStyle(color: Colors.white))),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.red,
        onPressed: getTrips,
      ),
      backgroundColor: Colors.black,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text("Speed:", style: GoogleFonts.dotGothic16(textStyle: const TextStyle(fontSize: 40, color: Colors.white))),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(speed.toString(), style: GoogleFonts.dotGothic16(textStyle: const TextStyle(fontSize: 60, color: Colors.white))),
              ),
              Text("km/h", style: GoogleFonts.dotGothic16(textStyle: const TextStyle(fontSize: 40, color: Colors.white))),
            ],
          ),

          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text("Distance:", style: GoogleFonts.dotGothic16(textStyle: const TextStyle(fontSize: 40, color: Colors.white))),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(distance.toString(), style: GoogleFonts.dotGothic16(textStyle: const TextStyle(fontSize: 60, color: Colors.white))),
              ),
              Text("km", style: GoogleFonts.dotGothic16(textStyle: const TextStyle(fontSize: 40, color: Colors.white))),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Text("Average speed:", style: GoogleFonts.dotGothic16(textStyle: const TextStyle(fontSize: 40, color: Colors.white))),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(averageSpeed0.toString(), style: GoogleFonts.dotGothic16(textStyle: const TextStyle(fontSize: 60, color: Colors.white))),
              ),
              Text("km/h", style: GoogleFonts.dotGothic16(textStyle: const TextStyle(fontSize: 40, color: Colors.white))),
            ],
          ),
        ],
      ),
    );
  }

}
