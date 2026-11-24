import { withSupabase } from 'npm:@supabase/server@^1';

export default {
  fetch: withSupabase({ auth: 'user' }, async (request, ctx) => {
    if (request.method !== 'POST') return new Response('Method not allowed', { status: 405 });
    // The id comes only from the verified session, never from the request body.
    const userId = ctx.userClaims?.id;
    if (typeof userId !== 'string') return new Response('Unauthorized', { status: 401 });

    const admin = ctx.supabaseAdmin;
    const { error: dataError } = await admin.rpc('jcv_delete_account_data', { p_user_id: userId });
    if (dataError) return new Response('Account data unavailable', { status: 503 });
    const { error: authError } = await admin.auth.admin.deleteUser(userId);
    if (authError) return new Response('Account unavailable', { status: 503 });
    return Response.json({ deleted: true });
  }),
};
