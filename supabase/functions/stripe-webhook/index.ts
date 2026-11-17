import Stripe from 'npm:stripe@^22';
import { withSupabase } from 'npm:@supabase/server@^1';

const secret = Deno.env.get('STRIPE_SECRET_KEY') ?? '';
if (!secret.startsWith('sk_test_')) throw new Error('Stripe test secret required');
const stripe = new Stripe(secret);
const cryptoProvider = Stripe.createSubtleCryptoProvider();

export default {
  fetch: withSupabase({ auth: 'none' }, async (request, ctx) => {
    if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });
    const signature = request.headers.get('stripe-signature') ?? '';
    const body = await request.text();
    let event: Stripe.Event;
    try {
      event = await stripe.webhooks.constructEventAsync(
        body, signature, Deno.env.get('STRIPE_WEBHOOK_SECRET')!, undefined, cryptoProvider,
      );
    } catch (_) {
      return new Response('Bad signature', { status: 400 });
    }
    const handled = [
      'payment_intent.succeeded', 'payment_intent.payment_failed',
      'payment_intent.canceled', 'payment_intent.processing', 'charge.refunded',
    ];
    if (!handled.includes(event.type)) {
      return Response.json({ received: true });
    }
    let intent: Stripe.PaymentIntent;
    let status: 'pending' | 'succeeded' | 'failed' | 'refunded';
    if (event.type === 'charge.refunded') {
      const charge = event.data.object as Stripe.Charge;
      if (!charge.payment_intent || charge.amount_refunded !== charge.amount) {
        return Response.json({ received: true });
      }
      intent = await stripe.paymentIntents.retrieve(
        typeof charge.payment_intent === 'string' ? charge.payment_intent : charge.payment_intent.id,
      );
      status = 'refunded';
    } else {
      intent = event.data.object as Stripe.PaymentIntent;
      status = event.type === 'payment_intent.succeeded' ? 'succeeded'
        : event.type === 'payment_intent.payment_failed' || event.type === 'payment_intent.canceled' ? 'failed'
        : 'pending';
    }
    if (intent.currency !== 'mxn' || intent.metadata.attempt_id == null) {
      return new Response('Unknown donation', { status: 400 });
    }
    const { error } = await ctx.supabaseAdmin.rpc('apply_donation_payment_event', {
      p_event_id: event.id,
      p_payment_intent_id: intent.id,
      p_amount_cents: intent.amount,
      p_currency: intent.currency,
      p_status: status,
      p_event_type: event.type,
    });
    if (error) return new Response('Retry later', { status: 500 });
    return Response.json({ received: true });
  }),
};
