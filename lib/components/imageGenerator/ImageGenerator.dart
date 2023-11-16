import 'package:flutter/material.dart';

class BankSlipPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.0;

    final double centerX = size.width / 2;
    final double centerY = size.height / 2;

    canvas.drawLine(
        Offset(centerX - 50, centerY), Offset(centerX + 50, centerY), paint);
    TextSpan span = const TextSpan(
        style: TextStyle(color: Colors.black, fontSize: 24),
        text: "Hello, Flutter!");
    TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr);
    tp.layout();
    tp.paint(canvas, Offset(centerX - tp.width / 2, centerY + 20));
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}