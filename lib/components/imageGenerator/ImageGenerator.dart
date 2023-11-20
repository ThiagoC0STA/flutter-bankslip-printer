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
    );

    // Desenha as bordas do boleto
    Offset topLeft = const Offset(0, 0);
    Offset topRight = Offset(size.width, 0);
    Offset bottomLeft = Offset(0, size.height);
    Offset bottomRight = Offset(size.width, size.height);

    canvas.drawLine(topLeft, topRight, linePaint); // Linha superior
    canvas.drawLine(topRight, bottomRight, linePaint); // Linha direita
    canvas.drawLine(bottomRight, bottomLeft, linePaint); // Linha inferior
    canvas.drawLine(bottomLeft, topLeft, linePaint); // Linha esquerda

    // Exemplo: Desenhar uma linha interna
    canvas.drawLine(const Offset(0, 100), Offset(size.width, 100), linePaint);

    // Exemplo: Desenhar um texto
    _drawText(canvas, textPainter, "RECIBO AO PAGADOR", 15, 30);

    // Continue adicionando outras linhas e textos conforme seu código C#
  }

  void _drawText(
      Canvas canvas, TextPainter painter, String text, double x, double y) {
    painter.text = TextSpan(text: text, style: const TextStyle(color: Colors.black));
    painter.layout();
    painter.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
