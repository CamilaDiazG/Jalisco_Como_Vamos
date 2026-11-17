import 'package:supabase_flutter/supabase_flutter.dart';

class DonationRecord {
  const DonationRecord({required this.amountMxn, required this.status, required this.createdAt});

  final int amountMxn;
  final String status;
  final DateTime createdAt;

  factory DonationRecord.fromJson(Map<String, dynamic> json) => DonationRecord(
    amountMxn: (json['amount_mxn'] as num).toInt(),
    status: json['status'] as String,
    createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
  );
}

class DonationsApi {
  DonationsApi(this.client);
  final SupabaseClient client;

  Future<String> createIntent({required String attemptId, required int amountMxn, required bool sendReceipt}) async {
    if (client.auth.currentSession == null) throw StateError('Inicia sesión para donar.');
    final result = await client.functions.invoke('create-donation-intent', body: {
      'attemptId': attemptId,
      'amountMxn': amountMxn,
      'sendReceipt': sendReceipt,
    });
    final data = result.data;
    if (result.status != 200 || data is! Map || data['clientSecret'] is! String) {
      throw StateError('No se pudo preparar el donativo. Intenta más tarde.');
    }
    return data['clientSecret'] as String;
  }

  Future<String?> status(String attemptId) async {
    final row = await client.from('donation_intents').select('status').eq('attempt_id', attemptId).maybeSingle();
    return row?['status'] as String?;
  }

  Future<List<DonationRecord>> history() async {
    final rows = await client.from('donation_intents')
        .select('amount_mxn,status,created_at')
        .order('created_at', ascending: false)
        .limit(10);
    return (rows as List).map((row) => DonationRecord.fromJson(Map<String, dynamic>.from(row as Map))).toList();
  }
}
