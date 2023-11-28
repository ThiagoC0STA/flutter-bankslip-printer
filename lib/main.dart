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
    final generator = Generator(PaperSize.mm80, profile, spaceBetweenRows: 0);

    List<List<int>> testCommands = [
      [0x1B, 0x40], // Inicializa a impressora
      [0x1B, 0x33, 0x30], // Define espaçamento vertical mínimo
      [0x1D, 0x21, 0x30], // Define espaçamento horizontal mínimo
    ];

    List<List<int>> resetCommands = [
      [0x1B, 0x40], // Inicializa a impressora
      [0x1B, 0x61, 0x00], // Alinha à esquerda
      [0x1B, 0x21, 0x00], // Desativa negrito, itálico, sublinhado, etc.
      [
        0x1B,
        0x21,
        0x08
      ], // Define a página de código para a página padrão (ISO 8859-1)
      [0x1B, 0x33, 0x00], // Define espaçamento entre linhas mínimo
      [0x1D, 0x57, 0x80],
      [0x1D, 0x2A, 0x00],
      [0x1D, 0x2F, 0x00],
      [0x1D, 0x28, 0x41, 0x02, 0x00, 0x00, 0x31],
    ];

    List<List<int>> escPosCommands = [
      // [0x09], // Tabulação horizontal
      // [0x0A], // Imprimir e avançar linha
      // [0x0D], // Imprimir e retornar carro
      // [0x0C], // Imprimir rótulo de posição de término para iniciar a impressão
      // [0x18, 0x03], // Cancelar dados de impressão em modo de página
      // [0x10, 0x04], // Transmissão de status em tempo real
      // [0x10, 0x05], // Solicitação em tempo real para a impressora
      // [0x10, 0x14], // Gerar pulso em tempo real
      // [0x1C, 0x0C], // Imprimir dados em modo de página
      // [0x1B, 0x20, 0x01], // Definir espaçamento à direita do caractere
      // [0x1B, 0x21, 0x08], // Definir modo de impressão
      // [0x1B, 0x24, 0x00], // Definir posição de impressão absoluta
      // [
      //   0x1B,
      //   0x25,
      //   0x00
      // ], // Selecionar/cancelar conjunto de caracteres definido pelo usuário
      // [0x1B, 0x26], // Definir caracteres definidos pelo usuário
      // [0x1B, 0x2A, 0x21, 0x11], // Definir modo de imagem de bits (1x1)
      // [0x1B, 0x2D, 0x01], // Ativar modo de sublinhado
      // [0x1B, 0x2D, 0x00], // Desativar modo de sublinhado
      // [0x1B, 0x33, 0x00], // Definir espaçamento entre linhas mínimo
      // [0x1D, 0x56, 0x00], // Corte completo
      // [0x1B, 0x40], // Inicializar impressora
      // [0x1B, 0x44, 0x08, 0x00], // Definir posições de tabulação horizontal
      // [0x1B, 0x45, 0x01], // Selecionar modo enfatizado
      // [0x1B, 0x47], // Selecionar modo de duplo traço
      // [
      //   0x1B,
      //   0x4A,
      //   0x04
      // ], // Imprimir alimentação de papel no final usando unidades mínimas
      // [0x1B, 0x4C], // Selecionar modo de página
      // [0x1B, 0x4D, 0x00], // Selecionar fonte de caractere
      // [0x1B, 0x52], // Selecionar conjunto de caracteres internacional
      // [0x1B, 0x53], // Selecionar modo padrão
      // [0x1B, 0x54], // Selecionar direção de impressão em modo de página
      // [0x1B, 0x56, 0x42], // Definir/cancelar caractere rotacionado em 90 graus
      // [0x1B, 0x57], // Definir área de impressão em modo de página
      // [0x1B, 0x5C], // Definir posição relativa
      // [0x1B, 0x61], // Alinhar posição
      // [
      //   0x1B,
      //   0x63,
      //   0x30
      // ], // Selecionar sensor(es) de papel para emitir sinais de fim de papel
      // [
      //   0x1B,
      //   0x63,
      //   0x31
      // ], // Selecionar sensor(es) de papel para parar a impressão
      // [0x1B, 0x63, 0x35], // Ativar/desativar botões do painel
      // [0x1B, 0x64, 0x01], // Imprimir e alimentar papel n linhas
      // [0x1B, 0x70, 0x00, 0x50, 0x50], // Pulso geral
      // [0x1B, 0x74, 0x00], // Selecionar tabela de código de caractere
      // [
      //   0x1B,
      //   0x7B,
      //   0x01
      // ], // Definir/cancelar impressão de caractere de cabeça para baixo
      // [0x1D, 0x28, 0x41, 0x02, 0x00, 0x00, 0x30], // Imprimir imagem de bit NV
      // [0x1D, 0x28, 0x41, 0x02, 0x00, 0x00, 0x31], // Definir imagem de bit NV
      // [0x1D, 0x21, 0x11], // Selecionar tamanho de caractere
      // [
      //   0x1D,
      //   0x24,
      //   0x80
      // ], // Definir posição de impressão vertical absoluta em modo de página
      // [0x1D, 0x2A, 0x00], // Definir imagem de bit transferida
      // [0x1D, 0x2F, 0x00], // Imprimir imagem de bit transferida
      // [0x1D, 0x3A, 0x52], // Iniciar/encerrar definição de macro
      // [
      //   0x1D,
      //   0x42,
      //   0x03
      // ], // Ativar/desativar modo de impressão reversa preto/branco
      // [0x1D, 0x48, 0x02], // Selecionar posição de impressão de caracteres HRI
      // [0x1D, 0x49, 0x30], // Transmitir ID da impressora
      // [0x1D, 0x4C, 0x10], // Definir margem esquerda
      // [0x1D, 0x50, 0x02], // Definir unidades de movimento horizontal e vertical
      // [0x1D, 0x56, 0x00], // Cortar papel
      // [0x1D, 0x57, 0x80], // Definir largura da área de impressão
      // [
      //   0x1D,
      //   0x5C,
      //   0x00
      // ], // Definir posição vertical relativa de impressão em modo de página
      // [0x1D, 0x5E], // Executar macro
      // [0x1D, 0x61], // Ativar/desativar Automatic Status Back (ASB)
      // [0x1D, 0x61, 0x01], // Ativar/desativar modo de suavização
      // [0x1D, 0x66, 0x01], // Selecionar fonte para caracteres HRI
      // [0x1D, 0x68, 0x64], // Definir altura do código de barras
      // [0x1D, 0x6B, 0x02, 0x49, 0x4E, 0x20], // Imprimir código de barras
      // [0x1D, 0x72, 0x01], // Transmitir status
      // [0x1D, 0x76, 0x00], // Imprimir imagem de bit raster
      // [0x1D, 0x77, 0x01], // Definir largura do código de barras
    ];

    //{0x1D, 0X50, 0x00, 0x00}

    // const testCommands = [
    //   [0x1B, 0x40], // Initialize printer
    //   [0x1B, 0x61, 0x01], // Centralize
    //   [0x1B, 0x4D, 0x01], // Font B
    //   [0x1D, 0x21, 0x11], // Double height and width
    //   [0x1B, 0x45, 0x01], // Bold on
    //   [0x1D, 0x42, 0x01], // Reverse on
    //   [0x1B, 0x2D, 0x01], // Underline on
    //   [0x1B, 0x21, 0x10], // Italic on
    //   [0x1B, 0x56, 0x42], // Partial cut
    //   [0x1D, 0x56, 0x42], // Print and feed paper
    //   [0x1B, 0x69], // Full cut
    //   [0x1B, 0x7B, 0x01], // Upside down on
    //   [0x1B, 0x21, 0x20], // Double strike on
    //   [0x1D, 0x42, 0x00], // Reverse off
    //   [0x1B, 0x45, 0x00], // Bold off
    //   [0x1B, 0x2D, 0x00], // Underline off
    //   [0x1B, 0x21, 0x00], // Italic off
    //   [0x1B, 0x21, 0x00], // Double strike off
    //   [0x1B, 0x61, 0x00], // Left align
    // ];

    List<int> flatTestCommands =
        escPosCommands.expand((command) => command).toList();

    // Geração da imagem
    final img.Image image = await createImageForPrinting();
    List<int> imageData = generator.image(image);

    print('flatTestCommands $flatTestCommands');

    // Combinar comandos ESC/POS com dados da imagem
    List<int> bytes = [...flatTestCommands, ...imageData];

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
              const int maxChunkSize = 505;
              const int chunkDelayMs = 17;

              for (int i = 0; i < bytes.length; i += maxChunkSize) {
                int end = (i + maxChunkSize > bytes.length)
                    ? bytes.length
                    : i + maxChunkSize;
                await characteristic.write(bytes.sublist(i, end),
                    withoutResponse: true);
                await Future.delayed(
                    const Duration(milliseconds: chunkDelayMs));
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
    final barcodeImage = img.Image(3500, 100);

    img.fill(barcodeImage, img.getColor(255, 255, 255));
    drawBarcode(barcodeImage, bc.Barcode.itf(), data);
    final png = img.encodePng(barcodeImage);

    final uint8list = Uint8List.fromList(png);

    ui.Codec codec = await ui.instantiateImageCodec(uint8list);
    ui.FrameInfo frameInfo = await codec.getNextFrame();
    return frameInfo.image;
  }

  Future<img.Image> createImageForPrinting() async {
    const double pixelRatio = 1.3; // Aumento da densidade de pixels 1.37
    const int targetWidth = 560; // Largura padrão para impressoras de 80mm
    const int targetHeight = 1500; // 3000 boleto

    ByteData data = await rootBundle.load('assets/caixalogo.png');
    final ui.Image barcodeImage = await generateBarcodeImage(
        "03397955400001035059023579026637184617780101");

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
