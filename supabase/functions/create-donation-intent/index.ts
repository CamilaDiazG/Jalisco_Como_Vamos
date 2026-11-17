import Stripe from 'npm:stripe@^22';
import { withSupabase } from 'npm:@supabase/server@^1';

const secret = Deno.env.get('STRIPE_SECRET_KEY') ?? '';
// This deliverable intentionally accepts only Stripe test-mode payments.
if (!secret.startsWith('sk_test_')) throw new Error('Stripe test secret required');
const stripe = new Stripe(secret);

export default {
  fetch: withSupabase({ auth: 'user' }, async (request, ctx) => {
    if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });
    const userId = ctx.userClaims?.id;
    if (typeof userId !== 'string') return new Response('Unauthorized', { status: 401 });

    let payload: Record<string, unknown>;
    try {
      payload = await request.json();
      if (!payload || typeof payload !== 'object' || Array.isArray(payload)) {
        return new Response('Invalid JSON', { status: 400 });
      }
    }
    catch { return new Response('Invalid JSON', { status: 400 }); }
    const { attemptId, amountMxn, sendReceipt } = payload;
    if (typeof attemptId !== 'string' || !/^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(attemptId)
        || typeof amountMxn !== 'number' || !Number.isInteger(amountMxn)
        || amountMxn < 20 || amountMxn > 10000
        || typeof sendReceipt !== 'boolean') {
      return new Response('Invalid donation', { status: 400 });
    }
    const admin = ctx.supabaseAdmin;
    const { data: existing, error: lookupError } = await admin.from('donation_intents')
      .select('user_id,amount_mxn,stripe_payment_intent_id')
      .eq('attempt_id', attemptId).maybeSingle();
    if (lookupError) return new Response('Storage unavailable', { status: 503 });
    if (existing && (existing.user_id !== userId || existing.amount_mxn !== amountMxn)) {
      return new Response('Invalid donation', { status: 409 });
    }
    if (!existing) {
      const { error } = await admin.from('donation_intents').insert({
        attempt_id: attemptId, user_id: userId, amount_mxn: amountMxn,
      });
      if (error) return new Response('Try again', { status: 409 });
    }
    try {
      const intent = existing?.stripe_payment_intent_id
        ? await stripe.paymentIntents.retrieve(existing.stripe_payment_intent_id)
        : await stripe.paymentIntents.create({
          amount: amountMxn * 100,
          currency: 'mxn',
          payment_method_types: ['card'],
          receipt_email: sendReceipt === true ? ctx.userClaims?.email : undefined,
          metadata: { attempt_id: attemptId, user_id: userId },
        }, { idempotencyKey: `jcv-donation-${attemptId}` });
      if (intent.amount !== amountMxn * 100 || intent.metadata.user_id !== userId) {
        return new Response('Payment mismatch', { status: 409 });
      }
      if (!intent.client_secret) return new Response('Payment unavailable', { status: 503 });
      const { error } = await admin.from('donation_intents')
        .update({ stripe_payment_intent_id: intent.id })
        .eq('attempt_id', attemptId).eq('user_id', userId);
      if (error) return new Response('Payment unavailable', { status: 503 });
      return Response.json({ clientSecret: intent.client_secret });
    } catch (_error) {
      return new Response('Payment unavailable', { status: 503 });
    }
  }),
};
