// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_printer/components/imageGenerator/ImageGenerator.dart';
import 'package:image/image.dart' as img;

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Bluetooth Printer App',
      home: BluetoothPrinterScreen(),
    );
  }
}

class BluetoothPrinterScreen extends StatefulWidget {
  const BluetoothPrinterScreen({Key? key}) : super(key: key);

  @override
  _BluetoothPrinterScreenState createState() => _BluetoothPrinterScreenState();
}

class _BluetoothPrinterScreenState extends State<BluetoothPrinterScreen> {
  List<ScanResult> scanResults = [];
  BluetoothDevice? selectedPrinter;
  GlobalKey repaintBoundaryKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Find Bluetooth Printers')),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                onPressed: startScan,
                child: const Text('Search Printers'),
              ),
              ElevatedButton(
                onPressed: selectedPrinter != null
                    ? () => printTestTicket(selectedPrinter!)
                    : null,
                child: const Text('Print Test Ticket'),
              ),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: scanResults.length,
              itemBuilder: (context, index) {
                var device = scanResults[index].device;
                return device.name.isNotEmpty
                    ? ListTile(
                        title: Text(device.name),
                        onTap: () => selectPrinter(device),
                      )
                    : Container();
              },
            ),
          ),
          RepaintBoundary(
            key: repaintBoundaryKey,
            child: CustomPaint(
              size: const Size(540, 500 + 70),
              painter: BankSlipPainter(),
            )
          ),
        ],
      ),
    );
  }

  void startScan() async {
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
    var subscription = FlutterBluePlus.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });

    await Future.delayed(const Duration(seconds: 4));
    await FlutterBluePlus.stopScan();
    await subscription.cancel();
  }

  void selectPrinter(BluetoothDevice device) {
    setState(() {
      selectedPrinter = device;
    });
  }

  Future<void> printTestTicket(BluetoothDevice printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    // Geração da imagem
    final img.Image image = await createImageFromCustomPaint();
    List<int> bytes = generator.image(image);

    try {
      if (!printer.isConnected) {
        await printer.connect();
      }

      List<BluetoothService> services = await printer.discoverServices();
      for (BluetoothService service in services) {
        if (service.uuid.toString() == "49535343-fe7d-4ae5-8fa9-9fafd205e455") {
          for (BluetoothCharacteristic characteristic
              in service.characteristics) {
            if (characteristic.properties.write) {
              const int maxChunkSize = 172; //182 //382 //
              for (int i = 0; i < bytes.length; i += maxChunkSize) {
                int end = (i + maxChunkSize > bytes.length)
                    ? bytes.length
                    : i + maxChunkSize;
                await characteristic.write(bytes.sublist(i, end),
                    withoutResponse: true);
              }
              break;
            }
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error printing: $e');
      }
    } finally {
      await printer.disconnect();
      if (kDebugMode) {
        print('Printer disconnected');
      }
    }
  }

  Future<img.Image> createImageFromCustomPaint() async {
    RenderRepaintBoundary boundary = repaintBoundaryKey.currentContext!
        .findRenderObject() as RenderRepaintBoundary;
    ui.Image uiImage = await boundary.toImage(pixelRatio: 3.0);
    final ByteData? byteData =
        await uiImage.toByteData(format: ui.ImageByteFormat.png);
    final Uint8List pngBytes = byteData!.buffer.asUint8List();
    img.Image originalImage = img.decodeImage(pngBytes)!;
    img.Image bwImage = img.grayscale(originalImage);
    img.Image resizedImage = img.copyResize(bwImage, width: 558);

    return resizedImage;
  }
}
