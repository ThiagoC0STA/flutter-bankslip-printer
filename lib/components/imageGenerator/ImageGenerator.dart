// ignore_for_file: file_names, unused_local_variable

import 'package:flutter/material.dart';

class BankSlipPainter extends CustomPainter {
  void _drawText(Canvas canvas, String text, double x, double y) {
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.black,
        fontFamily: "Montserrat",
        fontWeight: FontWeight.w800,
        fontSize: 14,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(canvas, Offset(x, y));
  }

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    final textPainter = TextPainter(
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
        strutStyle: const StrutStyle(fontFamily: "Montserrat"));

    // Desenha as bordas do boleto
    Offset topLeft = const Offset(0, 0);
    Offset topRight = Offset(size.width, 0);
    Offset bottomLeft = Offset(0, size.height - 60);
    Offset bottomRight = Offset(size.width, size.height - 60);

    canvas.drawLine(topLeft, topRight, linePaint); // Linha superior
    canvas.drawLine(topRight, bottomRight, linePaint); // Linha direita
    canvas.drawLine(bottomRight, bottomLeft, linePaint); // Linha inferior
    canvas.drawLine(bottomLeft, topLeft, linePaint); // Linha esquerda

    // Exemplo: Desenhar um texto
    _drawText(canvas, "RECIBO AO PAGADOR", 15, 10);

    // Exemplo: Desenhar uma linha interna
    canvas.drawLine(const Offset(0, 35), Offset(size.width, 35), linePaint);

    _drawText(canvas, "Confirmo que recebi o boleto", 15, 50);
    _drawText(canvas,
        "No valor de 199.99 com vencimento em 12/12/2024", 15, 70);
    _drawText(canvas, "Nosso numero 3456343436436434364", 15, 90);
    _drawText(canvas, "Numero documento 14100000", 15, 110);

    canvas.drawLine(const Offset(0, 145), Offset(size.width, 145), linePaint);

    _drawText(
        canvas, "Seu cliente aqui - 20/11/2023 12:40", 15, 155);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
