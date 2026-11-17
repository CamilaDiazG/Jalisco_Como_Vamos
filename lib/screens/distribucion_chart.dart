import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../data/dimension_models.dart';

enum VistaDistribucion { barras, dona, puntos }

class DistribucionChart extends StatelessWidget {
  final List<CategoriaDistribucion> categorias;
  final VistaDistribucion vista;
  const DistribucionChart({super.key, required this.categorias, required this.vista});

  Color _color(int index) => Colors.primaries[index % Colors.primaries.length];

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      if (vista == VistaDistribucion.dona)
        Center(child: SizedBox.square(dimension: 160, child: CustomPaint(
          painter: _Dona(categorias, List.generate(categorias.length, _color)),
        ))),
      for (var i = 0; i < categorias.length; i++) ...[
        const SizedBox(height: 12),
        Row(children: [
          Container(width: 10, height: 10, color: _color(i)),
          const SizedBox(width: 8),
          Expanded(child: Text(categorias[i].etiqueta)),
          Text('${categorias[i].porcentaje!.toStringAsFixed(2)}%'),
        ]),
        if (vista == VistaDistribucion.barras)
          LinearProgressIndicator(value: categorias[i].porcentaje! / 100,
            color: _color(i), minHeight: 6),
        if (vista == VistaDistribucion.puntos)
          SizedBox(height: 22, child: LayoutBuilder(builder: (context, box) => Stack(
            children: [
              const Positioned(left: 6, right: 6, top: 10, child: Divider(height: 1)),
              Positioned(left: (box.maxWidth - 12) * categorias[i].porcentaje! / 100,
                top: 5, child: Container(width: 12, height: 12,
                  decoration: BoxDecoration(color: _color(i), shape: BoxShape.circle))),
            ],
          ))),
      ],
      if (vista == VistaDistribucion.puntos)
        const Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [Text('0%'), Text('100%')]),
    ],
  );
}

class _Dona extends CustomPainter {
  final List<CategoriaDistribucion> categorias;
  final List<Color> colores;
  _Dona(this.categorias, this.colores);
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 22;
    canvas.drawArc(rect.deflate(14), 0, math.pi * 2, false, paint..color = Colors.black12);
    var inicio = -math.pi / 2;
    for (var i = 0; i < categorias.length; i++) {
      // Porcentajes originales; nunca renormalizar categorías ni imputar nulos.
      final arco = categorias[i].porcentaje! / 100 * math.pi * 2;
      canvas.drawArc(rect.deflate(14), inicio, arco, false, paint..color = colores[i]);
      inicio += arco;
    }
  }
  @override
  bool shouldRepaint(covariant _Dona oldDelegate) => oldDelegate.categorias != categorias;
}
