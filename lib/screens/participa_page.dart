import 'package:flutter/material.dart';

class ParticipaPage extends StatelessWidget {
  const ParticipaPage({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Participa · Tec')),
    body: ListView(padding: const EdgeInsets.all(20), children: const [
      Text('Tu participación comienza con información clara.', style: TextStyle(fontSize: 24)),
      SizedBox(height: 16),
      Text('Este espacio está preparado para la encuesta Tec. La captura aún no está habilitada porque no hay un instrumento aprobado disponible en el proyecto.'),
      SizedBox(height: 20),
      Text('1. Introducción', style: TextStyle(fontWeight: FontWeight.bold)),
      Text('Pendiente: objetivo aprobado, población elegible, duración y responsable del estudio.'),
      SizedBox(height: 16),
      Text('2. Consentimiento informado', style: TextStyle(fontWeight: FontWeight.bold)),
      Text('Pendiente: texto y versión aprobados, aviso de privacidad, finalidad, datos recolectados, conservación, retiro, contacto y reglas para menores de edad. No se solicita aceptación de un texto provisional.'),
      CheckboxListTile(value: false, onChanged: null,
        title: Text('Consentimiento pendiente de aprobación')),
      SizedBox(height: 16),
      Text('3. Instrumento versionado', style: TextStyle(fontWeight: FontWeight.bold)),
      Text('Pendiente: identificador y versión aprobados; preguntas literales, opciones y códigos, tipos, obligatoriedad, saltos, validaciones y criterios de elegibilidad. No se han creado preguntas de ejemplo.'),
      SizedBox(height: 16),
      Text('4. Envío privado', style: TextStyle(fontWeight: FontWeight.bold)),
      Text('La estructura de almacenamiento privado está preparada para asociar la versión del instrumento y del consentimiento con cada envío. Falta aprobar el instrumento y habilitar su validación de servidor. No se envía ni almacena información desde esta pantalla.'),
      SizedBox(height: 20),
      FilledButton(onPressed: null, child: Text('Encuesta pendiente de aprobación')),
    ]),
  );
}
