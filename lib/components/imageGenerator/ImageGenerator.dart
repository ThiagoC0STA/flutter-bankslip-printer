import 'package:flutter/material.dart';

class BankSlipPainter extends CustomPainter {
  void _drawText(Canvas canvas, String text, double x, double y) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: const TextStyle(
          color: Colors.black,
          fontFamily: "Montserrat",
          fontWeight: FontWeight.w700,
          fontSize: 14,
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

    // Desenha as bordas do boleto
    Offset topLeft = Offset(offset.dx, offset.dy);
    Offset topRight = Offset(size.width + offset.dx, offset.dy);
    Offset bottomLeft = Offset(offset.dx, size.height + offset.dy);
    Offset bottomRight =
        Offset(size.width + offset.dx, size.height + offset.dy);

    canvas.drawLine(topLeft, topRight, linePaint); // Linha superior
    canvas.drawLine(topRight, bottomRight, linePaint); // Linha direita
    canvas.drawLine(bottomRight, bottomLeft, linePaint); // Linha inferior
    canvas.drawLine(bottomLeft, topLeft, linePaint); // Linha esquerda

    // Desenhar os textos dentro do boleto
    _drawText(canvas, "RECIBO AO PAGADOR", offset.dx + 15, offset.dy + 15);

        canvas.drawLine(
      Offset(offset.dx, offset.dy + 45),
      Offset(offset.dx + size.width, offset.dy + 45),
      linePaint,
    );

    _drawText(
        canvas, "Confirmo que recebi o boleto".toUpperCase(), offset.dx + 15, offset.dy + 60);
    _drawText(canvas, "No valor de 199.99 com vencimento em 12/12/2024".toUpperCase(),
        offset.dx + 15, offset.dy + 80);
    _drawText(canvas, "Nosso numero 3456343436436434364".toUpperCase(), offset.dx + 15,
        offset.dy + 100);
    _drawText(
        canvas, "Numero documento 14100000".toUpperCase(), offset.dx + 15, offset.dy + 120);

    canvas.drawLine(
      Offset(offset.dx, offset.dy + 150),
      Offset(offset.dx + size.width, offset.dy + 150),
      linePaint,
    );

    _drawText(canvas, "Seu cliente aqui - 20/11/2023 12:40".toUpperCase(), offset.dx + 15,
        offset.dy + 160);
  }


  void _drawBankSlip(Canvas canvas, Size size, Offset offset) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    // Desenha as bordas do boleto
    Offset topLeft = Offset(offset.dx, offset.dy);
    Offset topRight = Offset(size.width + offset.dx, offset.dy);
    Offset bottomLeft = Offset(offset.dx, size.height + offset.dy);
    Offset bottomRight =
        Offset(size.width + offset.dx, size.height + offset.dy);

    canvas.drawLine(topLeft, topRight, linePaint); // Linha superior
    canvas.drawLine(topRight, bottomRight, linePaint); // Linha direita
    canvas.drawLine(bottomRight, bottomLeft, linePaint); // Linha inferior
    canvas.drawLine(bottomLeft, topLeft, linePaint); // Linha esquerda


  }

  @override
  void paint(Canvas canvas, Size size) {
    double contentHeightBankSlip = 200;
    double contentReceipt = 190;

    // Primeiro boleto
    // _drawBankSlip(canvas, Size(size.width, contentHeightBankSlip), const Offset(0, 0));

    // Espaço entre os boletos
    double spacing = 20.0;

    // Segundo boleto
    _drawReceipt(canvas, Size(size.width, contentReceipt),
        Offset(0, contentReceipt));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
