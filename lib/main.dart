// ignore_for_file: library_private_types_in_public_api

import 'package:esc_pos_printer/esc_pos_printer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_blue/flutter_blue.dart';
import 'package:esc_pos_utils/esc_pos_utils.dart';

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
                  title: Text(device.name),
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

  void startScan() {
    flutterBlue.startScan(timeout: const Duration(seconds: 4));
    flutterBlue.scanResults.listen((results) {
      setState(() {
        scanResults = results;
      });
    });
  }

  void selectPrinter(BluetoothDevice device) {
    setState(() {
      selectedPrinter = device;
    });
  }

  Future<void> printTestTicket(BluetoothDevice printer) async {
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm80, profile);

    // Gerar um ticket simples
    List<int> bytes = [];
    bytes += generator.text('TESTE STRING');

    final List<int> barData = [1, 2, 3, 4, 5, 6, 7, 8, 9, 0, 4];
    generator.barcode(Barcode.upcA(barData));

    bytes += generator.text(
        'Regular: aA bB cC dD eE fF gG hH iI jJ kK lL mM nN oO pP qQ rR sS tT uU vV wW xX yY zZ');

    bytes += generator.text('Bold text', styles: const PosStyles(bold: true));
    bytes +=
        generator.text('Reverse text', styles: const PosStyles(reverse: true));
    bytes += generator.text('Underlined text',
        styles: const PosStyles(underline: true), linesAfter: 1);
    bytes += generator.text('Align left',
        styles: const PosStyles(align: PosAlign.left));
    bytes += generator.text('Align center',
        styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text('Align right',
        styles: const PosStyles(align: PosAlign.right), linesAfter: 1);

    bytes += generator.text('Text size 200%',
        styles: const PosStyles(
          height: PosTextSize.size2,
          width: PosTextSize.size2,
        ));

    generator.row([
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col6',
        width: 6,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
      PosColumn(
        text: 'col3',
        width: 3,
        styles: const PosStyles(align: PosAlign.center, underline: true),
      ),
    ]);

    bytes += generator.feed(2);
    bytes += generator.cut();

    try {
      // Conectar à impressora
      await printer.connect();

      // Obter o serviço que corresponde à impressão
      final List<BluetoothService> services = await printer.discoverServices();
      for (final BluetoothService service in services) {
        for (final BluetoothCharacteristic characteristic
            in service.characteristics) {
          if (characteristic.properties.write) {
            // Enviar os dados do ticket
            await characteristic.write(bytes);
            break;
          }
        }
      }
    } catch (e) {
      print('Erro ao imprimir: $e');
    } finally {
      // Desconectar da impressora
      printer.disconnect();
    }
  }
}
