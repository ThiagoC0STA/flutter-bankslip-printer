// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Bluetooth Printer App',
      home: BluetoothPrinterScreen(),
    );
  }
}

class BluetoothPrinterScreen extends StatefulWidget {
  const BluetoothPrinterScreen({super.key});

  @override
  _BluetoothPrinterScreenState createState() => _BluetoothPrinterScreenState();
}

class _BluetoothPrinterScreenState extends State<BluetoothPrinterScreen> {
  FlutterBlue flutterBlue = FlutterBlue.instance;
  List<ScanResult> scanResults = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Bluetooth Printers')),
      body: Column(
        children: [
          ElevatedButton(
            child: const Text('Search Printers'),
            onPressed: () => startScan(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(scanResults[index].device.name),
                  onTap: () => connectAndPrint(scanResults[index].device),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void startScan() {
    flutterBlue.startScan(timeout: const Duration(seconds: 4));
    flutterBlue.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });
    flutterBlue.stopScan();
  }

  void connectAndPrint(BluetoothDevice device) async {
    try {
      await device.connect();
      List<BluetoothService> services = await device.discoverServices();
      BluetoothCharacteristic? targetCharacteristic;
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.write) {
            targetCharacteristic = characteristic;
            break;
          }
        }
        if (targetCharacteristic != null) break;
      }
      if (targetCharacteristic != null) {
        Uint8List pdfBytes = await generateBoletoAndReciboBytes();
        await targetCharacteristic.write(pdfBytes);
      }
      await device.disconnect();
    } catch (e) {
      if (kDebugMode) {
        print('Error connecting or printing: $e');
      }
    }
  }

  Future<Uint8List> generateBoletoAndReciboBytes() async {
    final doc = pw.Document();
    doc.addPage(pw.Page(
      pageFormat: PdfPageFormat.roll80,
      build: (pw.Context context) {
        return pw.Column(
          children: [
            pw.Text('Boleto Bancário', style: const pw.TextStyle(fontSize: 20)),
            // ...
          ],
        );
      },
    ));
    return doc.save();
  }
}
