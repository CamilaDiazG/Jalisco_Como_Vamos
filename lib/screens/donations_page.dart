import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../data/donations_api.dart';

class DonationsPage extends StatefulWidget {
  const DonationsPage({super.key});

  @override
  State<DonationsPage> createState() => _DonationsPageState();
}

class _DonationsPageState extends State<DonationsPage> {
  static const _blue = Color(0xFF003E79);
  static const _yellow = Color(0xFFFFC425);
  static const _stripeKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  late final DonationsApi _api = DonationsApi(Supabase.instance.client);
  final _custom = TextEditingController();
  int? _selected = 200;
  bool _receipt = false;
  bool _busy = false;
  String? _notice;
  late Future<List<DonationRecord>> _history = _api.history();

  @override
  void dispose() {
    _custom.dispose();
    super.dispose();
  }

  void _refresh() => setState(() => _history = _api.history());

  Future<void> _donate() async {
    if (_busy) return;
    final amount = _selected ?? int.tryParse(_custom.text);
    if (amount == null || amount < 20 || amount > 10000) {
      setState(() => _notice = r'Elige un monto entre $20 y $10,000 MXN.');
      return;
    }
    if (!_stripeKey.startsWith('pk_test_')) {
      setState(() => _notice = 'Donativos de prueba no configurados todavía.');
      return;
    }
    setState(() {
      _busy = true;
      _notice = null;
    });
    final attemptId = const Uuid().v4();
    try {
      Stripe.publishableKey = _stripeKey;
      Stripe.urlScheme = 'jcvstripe';
      await Stripe.instance.applySettings();
      if (!mounted) return;
      final clientSecret = await _api.createIntent(
        attemptId: attemptId, amountMxn: amount, sendReceipt: _receipt,
      );
      if (!mounted) return;
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          merchantDisplayName: 'Jalisco Cómo Vamos',
          paymentIntentClientSecret: clientSecret,
          returnURL: 'jcvstripe://redirect',
          googlePay: PaymentSheetGooglePay(merchantCountryCode: 'MX', testEnv: true),
        ),
      );
      if (!mounted) return;
      await Stripe.instance.presentPaymentSheet();
      if (!mounted) return;
      var status = await _api.status(attemptId);
      for (var i = 0; i < 3 && status != 'succeeded'; i++) {
        await Future<void>.delayed(const Duration(seconds: 2));
        status = await _api.status(attemptId);
      }
      if (!mounted) return;
      setState(() => _notice = status == 'succeeded'
          ? 'Donativo confirmado. ¡Gracias por apoyar!'
          : 'Pago enviado. La confirmación está pendiente; consulta el estado en tu historial.');
    } on StripeException {
      if (mounted) setState(() => _notice = 'El pago se canceló o no se completó. Revisa el historial antes de volver a intentar.');
    } catch (_) {
      if (mounted) setState(() => _notice = 'No se pudo completar la operación. Revisa el historial antes de intentar de nuevo.');
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
          _history = _api.history();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F6F9),
    appBar: AppBar(title: const Text('Apoya'), foregroundColor: _blue, backgroundColor: Colors.white),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text('APOYA AL OBSERVATORIO', style: TextStyle(color: _blue, fontSize: 12)),
            const SizedBox(height: 8),
            const Text('Ayuda a que más personas conozcan los datos de Jalisco.', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _blue)),
            const SizedBox(height: 16),
            _card([
              const Text('Donativo único · MXN', style: TextStyle(fontWeight: FontWeight.bold, color: _blue)),
              const SizedBox(height: 12),
              Wrap(spacing: 8, children: [100, 200, 500].map((value) => ChoiceChip(
                label: Text('\$$value'),
                selected: _selected == value,
                onSelected: _busy ? null : (_) => setState(() { _selected = value; _custom.clear(); }),
              )).toList()),
              const SizedBox(height: 12),
              TextField(
                controller: _custom,
                enabled: !_busy,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: 'Otro monto (MXN)', prefixText: '\$ ', border: OutlineInputBorder()),
                onChanged: (_) => setState(() => _selected = null),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _receipt,
                onChanged: _busy ? null : (value) => setState(() => _receipt = value ?? false),
                title: const Text('Enviar recibo a mi correo de la cuenta'),
                subtitle: const Text('Usaremos el correo de tu cuenta para solicitar un recibo en Stripe solo si activas esta opción.'),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _busy ? null : _donate,
                icon: const Icon(Icons.favorite_border),
                label: Text(_busy ? 'Procesando…' : 'Continuar al pago'),
                style: FilledButton.styleFrom(backgroundColor: _blue, minimumSize: const Size.fromHeight(52)),
              ),
              if (!_stripeKey.startsWith('pk_test_')) const Padding(
                padding: EdgeInsets.only(top: 12),
                child: Text('Pagos en modo de prueba pendientes de configurar; no se realizará ningún cobro.'),
              ),
            ]),
            if (_notice != null) Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(_notice!, style: const TextStyle(color: _blue))),
            const SizedBox(height: 20),
            Row(children: [
              const Expanded(child: Text('Mis donativos', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: _blue))),
              IconButton(onPressed: _refresh, tooltip: 'Actualizar estado', icon: const Icon(Icons.refresh, color: _blue)),
            ]),
            FutureBuilder<List<DonationRecord>>(
              future: _history,
              builder: (context, snapshot) {
                if (!snapshot.hasData && !snapshot.hasError) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return const Text('No se pudo cargar el historial. Pulsa actualizar.');
                final records = snapshot.data!;
                if (records.isEmpty) return _card([const Text('Todavía no hay donativos en esta cuenta.')]);
                return Column(children: records.map((record) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _card([Text('\$${record.amountMxn} MXN · ${_statusLabel(record.status)}', style: const TextStyle(fontWeight: FontWeight.bold, color: _blue)),
                    Text('${record.createdAt.day}/${record.createdAt.month}/${record.createdAt.year}')]),
                )).toList());
              },
            ),
            const SizedBox(height: 12),
            const Icon(Icons.lock_outline, color: _yellow),
            const Text('El pago se realiza con Stripe. La app no almacena datos de tu tarjeta.', textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );

  String _statusLabel(String status) => switch (status) {
    'succeeded' => 'Confirmado',
    'failed' => 'Fallido',
    'refunded' => 'Reembolsado',
    _ => 'Pendiente',
  };

  Widget _card(List<Widget> children) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
  );
}
