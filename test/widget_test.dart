import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:jalisco_como_vamos/screens/preguntas_page.dart';

void main() {
  Future<void> send(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField), '  ¿Cómo está la salud?  ');
    await tester.tap(find.text('Enviar pregunta'));
    await tester.pump();
  }

  testWidgets(
    'envía contrato ask, bloquea durante carga y muestra respuesta y citas',
    (tester) async {
      final pending = Completer<FunctionResponse>();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: PreguntasPage(
            invoke: (name, body) {
              calls++;
              expect(name, 'ask');
              expect(body.keys.toSet(), {'question', 'case_id'});
              expect(body['question'], '¿Cómo está la salud?');
              expect(
                body['case_id'],
                matches(RegExp(r'^[A-Za-z0-9_-]{1,100}$')),
              );
              return pending.future;
            },
          ),
        ),
      );
      expect(find.byIcon(Icons.mic), findsOneWidget);
      await send(tester);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNull,
      );
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
      pending.complete(
        FunctionResponse(
          status: 200,
          data: {
            'answer': 'Resultado de salud',
            'citations': ['fuente-1'],
            'retrieved_source_ids': ['fuente-1', 'fuente-no-citada'],
          },
        ),
      );
      await tester.pumpAndSettle();
      expect(calls, 1);
      expect(find.text('Resultado de salud'), findsOneWidget);
      expect(find.text('fuente-1'), findsOneWidget);
      expect(find.text('fuente-no-citada'), findsNothing);
      expect(find.byType(LinearProgressIndicator), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        contains('¿Cómo está la salud?'),
      );
    },
  );

  testWidgets('muestra abstención sin inventar fuentes', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: PreguntasPage(
          invoke: (_, _) async => FunctionResponse(
            status: 200,
            data: {
              'answer': 'No tengo datos suficientes.',
              'citations': [],
              'retrieved_source_ids': [],
            },
          ),
        ),
      ),
    );
    await send(tester);
    await tester.pumpAndSettle();
    expect(find.text('No tengo datos suficientes.'), findsOneWidget);
    expect(
      find.text('Sin fuentes citadas para esta respuesta.'),
      findsOneWidget,
    );
  });

  for (final status in [401, 403, 429, 502, 503]) {
    testWidgets('error $status permite reintentar y conserva pregunta', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PreguntasPage(
            invoke: (_, _) async => throw FunctionException(status: status),
          ),
        ),
      );
      await send(tester);
      await tester.pumpAndSettle();
      expect(
        find.text(
          status == 401 || status == 403
              ? 'Tu sesión necesita acceso autorizado a los agregados.'
              : status == 429
              ? 'La cuota de IA está agotada temporalmente. Tu pregunta se conserva; intenta más tarde.'
              : 'No se pudo consultar. Reintenta; si persiste, falta configurar el servicio.',
        ),
        findsOneWidget,
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        contains('salud'),
      );
    });
  }

  for (final data in [
    {'respuesta': 'contrato anterior'},
    {
      'answer': 'Dato',
      'citations': ['inventada'],
      'retrieved_source_ids': [],
    },
  ]) {
    testWidgets('rechaza respuesta inválida $data', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: PreguntasPage(
            invoke: (_, _) async => FunctionResponse(status: 200, data: data),
          ),
        ),
      );
      await send(tester);
      await tester.pumpAndSettle();
      expect(
        find.text(
          'El servicio devolvió una respuesta inválida. Intenta de nuevo.',
        ),
        findsOneWidget,
      );
      expect(find.text('Fuentes citadas'), findsNothing);
    });
  }
}
