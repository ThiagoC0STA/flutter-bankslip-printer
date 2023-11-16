import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';
import 'package:image/image.dart' as img;

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
  List<ScanResult> scanResults = [];
  BluetoothDevice? selectedPrinter;

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
                var device = scanResults[index].device;
                return ListTile(
                  title: Text(device.name ?? 'Unknown device'),
                  onTap: () => selectPrinter(device),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: selectedPrinter != null
                ? () => printTestTicket(selectedPrinter!)
                : null,
            child: const Text('Print Test Ticket'),
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

    // Para o scan após um tempo ou baseado em alguma condição
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

    Uint8List imageBytes = await loadImage('assets/receipt2.jpg');
    img.Image image = img.decodeImage(imageBytes)!;
    List<int> bytes = generator.image(image);

    try {
      await printer.connect();
      List<BluetoothService> services = await printer.discoverServices();
      for (BluetoothService service in services) {
        for (BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.write) {
            await characteristic.write(bytes, withoutResponse: true);
            break;
          }
        }
      }
    } catch (e) {
      print('Erro ao imprimir: $e');
    } finally {
      await printer.disconnect();
    }
  }

  Future<Uint8List> loadImage(String path) async {
    final ByteData data = await rootBundle.load(path);
    Uint8List bytes = data.buffer.asUint8List();
    return bytes;
  }
}
