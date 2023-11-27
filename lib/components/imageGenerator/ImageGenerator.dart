// ignore_for_file: file_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class BankSlipPainter extends CustomPainter {
  final ui.Image? image;
  final ui.Image? barcodeImage;

  BankSlipPainter(this.image, this.barcodeImage);

  void _drawText(Canvas canvas, String text, double x, double y,
      [double textsize = 15]) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.black,
          fontFamily: "Montserrat",
          fontWeight: textsize != 15 ? FontWeight.w600 : FontWeight.w700,
          fontSize: textsize,
          letterSpacing: -0.7,
        ),
      ),
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }

  void _drawReceipt(Canvas canvas, Size size, Offset offset) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    canvas.save();
    canvas.translate(0, 1850);

    Offset topLeft = Offset(offset.dx, offset.dy);
    Offset topRight = Offset(size.width + offset.dx - 140, offset.dy);
    Offset bottomLeft = Offset(offset.dx, size.height + offset.dy);
    Offset bottomRight =
        Offset(size.width + offset.dx - 140, size.height + offset.dy);

    canvas.drawLine(topLeft, topRight, linePaint); // Linha superior
    canvas.drawLine(topRight, bottomRight, linePaint); // Linha direita
    canvas.drawLine(bottomRight, bottomLeft, linePaint); // Linha inferior
    canvas.drawLine(bottomLeft, topLeft, linePaint); // Linha esquerda

    // Desenhar os textos dentro do boleto
    _drawText(canvas, "RECIBO DE ENTREGA", offset.dx + 15, offset.dy + 15);

    canvas.drawLine(
      Offset(offset.dx, offset.dy + 45),
      Offset(offset.dx + size.width - 140, offset.dy + 45),
      linePaint,
    );

    _drawText(canvas, "Confirmo que recebi o boleto".toUpperCase(),
        offset.dx + 15, offset.dy + 60);
    _drawText(
        canvas,
        "No valor de 199.99 com vencimento em 12/12/2024".toUpperCase(),
        offset.dx + 15,
        offset.dy + 80);
    _drawText(canvas, "Nosso numero 3456343436436434364".toUpperCase(),
        offset.dx + 15, offset.dy + 100);
    _drawText(canvas, "Numero documento 14100000".toUpperCase(), offset.dx + 15,
        offset.dy + 120);

    canvas.drawLine(
      Offset(offset.dx, offset.dy + 150),
      Offset(offset.dx + size.width - 140, offset.dy + 150),
      linePaint,
    );

    _drawText(canvas, "Seu cliente aqui - 20/11/2023 12:40".toUpperCase(),
        offset.dx + 15, offset.dy + 160);
  }

  Future<void> _drawBankSlip(Canvas canvas, Size size, Offset offset) async {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    canvas.save();
    canvas.translate(210, 1250); //1250
    canvas.rotate(1.5708);

    double halfWidth = 576;
    double halfHeight = 210;

    canvas.drawLine(Offset(-halfWidth, -halfHeight),
        Offset(-halfWidth, halfHeight), linePaint);
    canvas.drawLine(Offset(-halfWidth, halfHeight),
        Offset(halfWidth, halfHeight), linePaint);
    canvas.drawLine(Offset(halfWidth, halfHeight),
        Offset(halfWidth, -halfHeight), linePaint);
    canvas.drawLine(Offset(halfWidth, -halfHeight),
        Offset(-halfWidth, -halfHeight), linePaint);

    _drawText(
        canvas,
        "|104-0| 10495.82693 69761.111249 29610.000084 7 80210000012957",
        -halfWidth + 160, 
        -halfHeight + 7,
        25);

    if (barcodeImage != null) {
      final barcodeImagePaint = Paint();
      final src = Rect.fromLTWH(0, 0, barcodeImage!.width.toDouble(),
          barcodeImage!.height.toDouble());
      final dst = Rect.fromLTWH(-halfWidth + 15, halfHeight - 85, 700,
          80);
      canvas.drawImageRect(barcodeImage!, src, dst, barcodeImagePaint);
    }

    if (image != null) {
      final imagePaint = Paint();
      final src = Rect.fromLTWH(
          0, 0, image!.width.toDouble(), image!.height.toDouble());
      Rect dst = Rect.fromLTWH(-halfWidth + 15, -halfHeight + 8, 120, 30);
      canvas.drawImageRect(image!, src, dst, imagePaint);
    }

    // --------------- LINHA HORIZONTAL ---------------
    canvas.drawLine(
      Offset(-halfWidth, -halfHeight + 45),
      Offset(halfWidth, -halfHeight + 45),
      linePaint,
    );

    _drawText(canvas, "LOCAL PAGAMENTO", -halfWidth + 15, -halfHeight + 50);
    _drawText(canvas, "PAGÁVEL EM QUALQUER BANCO MESMO APÓS O VENCIMENTO",
        -halfWidth + 15, -halfHeight + 65);

    // --------------- LINHA HORIZONTAL ---------------
    canvas.drawLine(
      Offset(-halfWidth, -halfHeight + 85),
      Offset(halfWidth, -halfHeight + 85),
      linePaint,
    );

    _drawText(canvas, "BENEFICIÁRIO", -halfWidth + 15, -halfHeight + 90);
    _drawText(canvas, "SUA EMPRESA AQUI 99.999.999/9999-99", -halfWidth + 15,
        -halfHeight + 105);

    // --------------- LINHA HORIZONTAL ---------------
    canvas.drawLine(
      Offset(-halfWidth, -halfHeight + 125),
      Offset(halfWidth, -halfHeight + 125),
      linePaint,
    );

    _drawText(canvas, "DATA DOCUMENTO", -halfWidth + 15, -halfHeight + 130);
    _drawText(canvas, "20/11/2023", -halfWidth + 15, -halfHeight + 145);

    canvas.drawLine(
      Offset(-halfWidth + 170, -halfHeight + 125),
      Offset(-halfWidth + 170, -halfHeight + 165),
      linePaint,
    );

    _drawText(canvas, "NUMERO DOCUMENTO", -halfWidth + 180, -halfHeight + 130);
    _drawText(canvas, "1410000", -halfWidth + 180, -halfHeight + 145);

    canvas.drawLine(
      Offset(-halfWidth + 400, -halfHeight + 125),
      Offset(-halfWidth + 400, -halfHeight + 165),
      linePaint,
    );

    _drawText(canvas, "TIPO DOC", -halfWidth + 410, -halfHeight + 130);
    _drawText(canvas, "DM", -halfWidth + 410, -halfHeight + 145);

    canvas.drawLine(
      Offset(-halfWidth + 550, -halfHeight + 125),
      Offset(-halfWidth + 550, -halfHeight + 165),
      linePaint,
    );

    _drawText(canvas, "ACEITE", -halfWidth + 560, -halfHeight + 130);
    _drawText(canvas, "N", -halfWidth + 560, -halfHeight + 145);

    canvas.drawLine(
      Offset(-halfWidth + 650, -halfHeight + 125),
      Offset(-halfWidth + 650, -halfHeight + 165),
      linePaint,
    );

    _drawText(
        canvas, "DATA PROCESSAMENTO", -halfWidth + 660, -halfHeight + 130);
    _drawText(canvas, "20/11/2023", -halfWidth + 660, -halfHeight + 145);

    // --------------- LINHA HORIZONTAL ---------------
    canvas.drawLine(
      Offset(-halfWidth, -halfHeight + 165),
      Offset(halfWidth, -halfHeight + 165),
      linePaint,
    );

    _drawText(canvas, "USO DO BANCO", -halfWidth + 15, -halfHeight + 170);
    // _drawText(canvas, "PAGÁVEL EM QUALQUER BANCO MESMO APÓS O VENCIMENTO", -halfWidth + 15, -halfHeight + 185);

    canvas.drawLine(
      Offset(-halfWidth + 145, -halfHeight + 165),
      Offset(-halfWidth + 145, -halfHeight + 205),
      linePaint,
    );

    _drawText(canvas, "CIP", -halfWidth + 155, -halfHeight + 168);

    canvas.drawLine(
      Offset(-halfWidth + 245, -halfHeight + 165),
      Offset(-halfWidth + 245, -halfHeight + 205),
      linePaint,
    );

    _drawText(canvas, "CARTEIRA", -halfWidth + 255, -halfHeight + 168);
    _drawText(canvas, "RG", -halfWidth + 255, -halfHeight + 185);

    canvas.drawLine(
      Offset(-halfWidth + 385, -halfHeight + 165),
      Offset(-halfWidth + 385, -halfHeight + 205),
      linePaint,
    );

    _drawText(canvas, "ESPÉCIE MOEDA", -halfWidth + 395, -halfHeight + 168);
    _drawText(canvas, "RS", -halfWidth + 395, -halfHeight + 185);

    canvas.drawLine(
      Offset(-halfWidth + 535, -halfHeight + 165),
      Offset(-halfWidth + 535, -halfHeight + 205),
      linePaint,
    );

    _drawText(canvas, "QUANTIDADE", -halfWidth + 544, -halfHeight + 168);
    _drawText(canvas, "1", -halfWidth + 545, -halfHeight + 185);

    canvas.drawLine(
      Offset(-halfWidth + 685, -halfHeight + 165),
      Offset(-halfWidth + 685, -halfHeight + 205),
      linePaint,
    );

    _drawText(canvas, "VALOR", -halfWidth + 695, -halfHeight + 168);
    _drawText(canvas, "199.90", -halfWidth + 695, -halfHeight + 185);

    // --------------- LINHA HORIZONTAL ---------------
    canvas.drawLine(
      Offset(-halfWidth, -halfHeight + 205),
      Offset(halfWidth, -halfHeight + 205),
      linePaint,
    );
    canvas.restore();
  }

  void _drawReceiptToSaler(Canvas canvas, Size size, Offset offset) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    canvas.save();
    canvas.translate(210, 350);
    canvas.rotate(1.5708);

    double halfWidth = 300;
    double halfHeight = 210;
    canvas.drawLine(Offset(-halfWidth, -halfHeight),
        Offset(-halfWidth, halfHeight), linePaint);
    canvas.drawLine(Offset(-halfWidth, halfHeight),
        Offset(halfWidth, halfHeight), linePaint);
    canvas.drawLine(Offset(halfWidth, halfHeight),
        Offset(halfWidth, -halfHeight), linePaint);
    canvas.drawLine(Offset(halfWidth, -halfHeight),
        Offset(-halfWidth, -halfHeight), linePaint);

    _drawText(canvas, "RECIBO AO PAGADOR", -halfWidth + 15, -halfHeight + 10);

    if (image != null) {
      final imagePaint = Paint();
      final src = Rect.fromLTWH(
          0, 0, image!.width.toDouble(), image!.height.toDouble());
      Rect dst = Rect.fromLTWH(-halfWidth + 15, -halfHeight + 30, 180, 50);
      canvas.drawImageRect(image!, src, dst, imagePaint);
    }

    _drawText(canvas, "BENEFICIÁRIO", -halfWidth + 15, -halfHeight + 90);
    _drawText(canvas, "SUA EMPRESA AQUI 99.999.999/9999-99", -halfWidth + 15,
        -halfHeight + 115);
    _drawText(
        canvas, "RUA DOS SISTEMAS, 321", -halfWidth + 15, -halfHeight + 135);
    _drawText(canvas, "83000-000 VALE DO PINHAO - CURITIBA - PR",
        -halfWidth + 15, -halfHeight + 155);

    _drawText(canvas, "AGÊNCIA / CÓDIGO BENEFICIÁRIO", -halfWidth + 15,
        -halfHeight + 185);
    _drawText(canvas, "123654/9", -halfWidth + 15, -halfHeight + 205);

    _drawText(canvas, "DATA DOCUMENTO", halfWidth - 200, -halfHeight + 185);
    _drawText(canvas, "20/11/2023", halfWidth - 200, -halfHeight + 205);

    _drawText(canvas, "NOSSO NÚMERO", -halfWidth + 15, -halfHeight + 235);
    _drawText(
        canvas, "14186426485300000-5", -halfWidth + 15, -halfHeight + 255);

    _drawText(canvas, "NÚMERO DOCUMENTO", halfWidth - 200, -halfHeight + 235);
    _drawText(canvas, "1418000", halfWidth - 200, -halfHeight + 255);

    _drawText(canvas, "PAGADOR", -halfWidth + 15, -halfHeight + 285);
    _drawText(canvas, "SEU CLIENTE AQUI 99.999.999/9999-99", -halfWidth + 15,
        -halfHeight + 305);
    _drawText(
        canvas, "RUA DOS CLIENTES, 123", -halfWidth + 15, -halfHeight + 325);
    _drawText(canvas, "81000-321 CENTRO - CURITIBA - PR", -halfWidth + 15,
        -halfHeight + 345);

    _drawText(canvas, "VALOR DOCUMENTO", -halfWidth + 15, -halfHeight + 375);
    _drawText(canvas, "199.90", -halfWidth + 15, -halfHeight + 395);

    _drawText(canvas, "VENCIMENTO", halfWidth - 200, -halfHeight + 375);
    _drawText(canvas, "20/10/2023", halfWidth - 200, -halfHeight + 395);

    canvas.restore();
  }

  @override
  void paint(Canvas canvas, Size size) {
    double contentHeightBankSlip = 600;
    double horizontalSpacing = 20.0;

    _drawReceiptToSaler(
        canvas,
        Size(size.width / 2 - horizontalSpacing / 2, contentHeightBankSlip),
        const Offset(0, 0));

    _drawBankSlip(
        canvas,
        Size(size.width / 2 - horizontalSpacing / 2, contentHeightBankSlip),
        const Offset(0, 0));

    _drawReceipt(canvas, Size(size.width - 140, 190), const Offset(0, 0));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
