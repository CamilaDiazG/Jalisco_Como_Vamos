import { createClient } from 'https://esm.sh/@supabase/supabase-js@2.49.8';
import { createHandler } from './handler.mjs';

Deno.serve(createHandler({ createClient, env: (name: string) => Deno.env.get(name) }));
