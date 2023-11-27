// ignore_for_file: deprecated_member_use, library_private_types_in_public_api

import 'dart:io';
import 'dart:ui' as ui;
import 'package:barcode_image/barcode_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:flutter_printer/components/imageGenerator/ImageGenerator.dart';
import 'package:image/image.dart' as img;
import 'package:barcode_image/barcode_image.dart' as bc;
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
  List<dynamic> scanResultsPaired = [];
  List<ScanResult> scanResults = [];
  dynamic selectedPrinter;
  ui.Image? image;
  GlobalKey repaintBoundaryKey = GlobalKey();
  bool isPairedDevice = false;

  static const platform =
      MethodChannel('com/example/flutter_printer/bluetooth');

  @override
  void initState() {
    super.initState();
    if (Platform.isAndroid) {
      startBluetoothDevices();
    }
  }

  Future<ui.Image> loadImage(String assetPath) async {
    ByteData data = await rootBundle.load(assetPath);
    Uint8List bytes = data.buffer.asUint8List();
    ui.Codec codec = await ui.instantiateImageCodec(bytes);
    ui.FrameInfo fi = await codec.getNextFrame();
    return fi.image;
  }

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
                onPressed: () => isPairedDevice
                    ? printImageNativeAndroid(selectedPrinter!)
                    : printImageFromFlutter(selectedPrinter!),
                child: const Text('Print Test Ticket'),
              ),
            ],
          ),
          Column(
            children: scanResultsPaired.map((device) {
              return device['name'].isNotEmpty
                  ? ListTile(
                      title: Text(device['name']),
                      onTap: () => {
                        selectPrinter(device),
                        setState(() {
                          isPairedDevice = true;
                        })
                      },
                    )
                  : Container();
            }).toList(),
          ),
          Column(
            children: scanResults.map((element) {
              var device = element.device;
              return device.name.isNotEmpty
                  ? ListTile(
                      title: Text(device.name),
                      onTap: () => {
                        selectPrinter(device),
                        setState(() {
                          isPairedDevice = false;
                        })
                      },
                    )
                  : Container();
            }).toList(),
          ),
          // Offstage(
          //   offstage: false, // Isso torna o widget "invisível"
          //   child: RepaintBoundary(
          //     key: repaintBoundaryKey,
          //     child: CustomPaint(
          //       size: const Size(540, 1500),
          //       painter: BankSlipPainter(image, null),
          //     ),
          //   ),
          // )
        ],
      ),
    );
  }

  void startBluetoothDevices() async {
    try {
      var devices = await platform.invokeMethod('getBluetoothDevices');

      setState(() {
        scanResultsPaired = devices;
      });
    // ignore: unused_catch_clause, empty_catches
    } on PlatformException catch (e) {}
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

  void selectPrinter(dynamic device) {
    setState(() {
      selectedPrinter = device;
    });
  }

  Future<void> printImageNativeAndroid(dynamic printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    // Geração da imagem
    final img.Image image = await createImageForPrinting();
    List<int> bytes = generator.image(image);

    try {
      if (!printer['isConnected']) {
        await platform.invokeMethod('connectToDeviceByAddress',
            {"address": printer['address'], "data": bytes});
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error printing: $e');
      }
    } finally {
      if (kDebugMode) {
        print('Printer disconnected');
      }
    }
  }

  Future<void> printImageFromFlutter(BluetoothDevice printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    // Geração da imagem
    final img.Image image = await createImageForPrinting();
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
              const int maxChunkSize = 450;
              const int chunkDelayMs = 20;

              for (int i = 0; i < bytes.length; i += maxChunkSize) {
                int end = (i + maxChunkSize > bytes.length)
                    ? bytes.length
                    : i + maxChunkSize;
                await characteristic.write(bytes.sublist(i, end),
                    withoutResponse: true);
                await Future.delayed(const Duration(
                    milliseconds:
                        chunkDelayMs));
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
      await Future.delayed(const Duration(milliseconds: 10));
      await printer.disconnect();
      if (kDebugMode) {
        print('Printer disconnected');
      }
    }
  }

    Future<ui.Image> generateBarcodeImage(String data) async {
    final barcodeImage = img.Image(3000, 100);

    img.fill(barcodeImage, img.getColor(255, 255, 255));
    drawBarcode(barcodeImage, bc.Barcode.itf(), data);
    final png = img.encodePng(barcodeImage);

    final uint8list = Uint8List.fromList(png);

    ui.Codec codec = await ui.instantiateImageCodec(uint8list);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  Future<img.Image> createImageForPrinting() async {
    const double pixelRatio = 1.25; // Aumento da densidade de pixels 1.37
    const int targetWidth = 560; // Largura padrão para impressoras de 80mm
    const int targetHeight = 3000; // Altura desejada 3000

    ByteData data = await rootBundle.load('assets/caixalogo.png');
    final ui.Image barcodeImage = await generateBarcodeImage("75691964300000072501336001081887940114947004");

    Uint8List bytes = data.buffer.asUint8List();
    ui.Codec codec = await ui.instantiateImageCodec(bytes);
    ui.FrameInfo fi = await codec.getNextFrame();

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder,
        Rect.fromLTWH(0, 0, targetWidth.toDouble(), targetHeight.toDouble()));

    canvas.scale(pixelRatio, pixelRatio); // Aumentando a densidade de pixels

    final bankSlipPainter = BankSlipPainter(fi.image, barcodeImage);
    bankSlipPainter.paint(
        canvas, Size(targetWidth.toDouble(), targetHeight.toDouble()));

    final picture = recorder.endRecording();
    final uiImage = await picture.toImage(
        targetWidth, targetHeight); // Criando a imagem no tarmanho originalå

    final byteData = await uiImage.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) {
      throw Exception('Failed to convert image to PNG bytes.');
    }
    final pngBytes = byteData.buffer.asUint8List();
    return img
        .decodeImage(pngBytes)!; // Decodificando os bytes PNG para uma imagem
  }
}
