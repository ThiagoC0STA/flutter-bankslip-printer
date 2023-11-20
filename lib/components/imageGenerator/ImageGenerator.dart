// ignore_for_file: file_names

import 'package:flutter/material.dart';

class BankSlipWidget extends StatelessWidget {
  const BankSlipWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: CustomPaint(
        painter: BankSlipPainter(),
        child: SizedBox(
          width: MediaQuery.of(context).size.width,
          height: 200,
        ),
      ),
    );
  }
}

class BankSlipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.black
      ..strokeWidth = 1.0;

    final textPainter = TextPainter(
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
        strutStyle: const StrutStyle(fontFamily: "Arial-Regular"));

    // Desenha as bordas do boleto
    Offset topLeft = const Offset(0, 0);
    Offset topRight = Offset(size.width, 0);
    Offset bottomLeft = Offset(0, size.height);
    Offset bottomRight = Offset(size.width, size.height);

    canvas.drawLine(topLeft, topRight, linePaint); // Linha superior
    canvas.drawLine(topRight, bottomRight, linePaint); // Linha direita
    canvas.drawLine(bottomRight, bottomLeft, linePaint); // Linha inferior
    canvas.drawLine(bottomLeft, topLeft, linePaint); // Linha esquerda

    // Exemplo: Desenhar um texto
    _drawText(canvas, textPainter, "RECIBO AO PAGADOR", 110, 10);

    // Exemplo: Desenhar uma linha interna
    canvas.drawLine(const Offset(0, 35), Offset(size.width, 35), linePaint);

    _drawText(canvas, textPainter, "Confirmo que recebi o boleto", 15, 50);
    _drawText(canvas, textPainter,
        "No valor de 199.99 com vencimento em 12/12/2024", 15, 70);
    _drawText(canvas, textPainter, "Nosso numero 3456343436436434364", 15, 90);
    _drawText(canvas, textPainter, "Numero documento 14100000", 15, 110);

    canvas.drawLine(const Offset(0, 145), Offset(size.width, 145), linePaint);

    _drawText(
        canvas, textPainter, "Seu cliente aqui - 20/11/2023 12:40", 15, 155);
  }

  void _drawText(
      Canvas canvas, TextPainter painter, String text, double x, double y) {
    painter.text = TextSpan(
        text: text,
        style: const TextStyle(
            color: Colors.black,
            fontFamily: "Roboto",
            fontWeight: FontWeight.w700,
            fontSize: 12));
    painter.layout();
    painter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
