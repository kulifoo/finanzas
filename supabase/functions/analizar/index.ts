// Función "analizar" de Finanzas Kulifay (Etapa 2: IA).
// Recibe el pedido de la app, verifica que quien lo hace sea miembro de la familia
// y se lo pasa a la API de Claude. La clave de Anthropic queda guardada en Supabase,
// nunca en el celular ni en GitHub.
//
// Secretos necesarios (Supabase > Edge Functions > Secrets):
//   ANTHROPIC_API_KEY  tu clave de console.anthropic.com
//   CLAUDE_MODEL       opcional; por defecto claude-sonnet-5-5

import { createClient } from "npm:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const responder = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), { status, headers: { ...cors, "Content-Type": "application/json" } });

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });
  if (req.method !== "POST") return responder({ error: "Método no permitido" }, 405);

  // 1. Solo miembros de la familia
  const auth = req.headers.get("Authorization") ?? "";
  const sb = createClient(Deno.env.get("SUPABASE_URL")!, Deno.env.get("SUPABASE_ANON_KEY")!, {
    global: { headers: { Authorization: auth } },
  });
  const { data: miembro, error: errMiembro } = await sb.rpc("es_miembro");
  if (errMiembro || !miembro) return responder({ error: "Tu usuario no está habilitado" }, 403);

  // 2. Armar el pedido para Claude
  const { prompt, json, imagen } = await req.json().catch(() => ({}));
  if (!prompt || typeof prompt !== "string") return responder({ error: "Falta el texto a analizar" }, 400);
  if (prompt.length > 400_000) return responder({ error: "El resumen es demasiado largo" }, 413);

  const content: unknown[] = [];
  if (imagen?.datos) {
    content.push({ type: "image", source: { type: "base64", media_type: imagen.tipo || "image/jpeg", data: imagen.datos } });
  }
  content.push({
    type: "text",
    text: prompt + (json ? "\n\nRespondé únicamente con el JSON pedido, sin texto antes ni después." : ""),
  });

  const apiKey = Deno.env.get("ANTHROPIC_API_KEY");
  if (!apiKey) return responder({ error: "Falta configurar ANTHROPIC_API_KEY en Supabase" }, 500);

  // 3. Llamar a la API de Claude
  const r = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: { "x-api-key": apiKey, "anthropic-version": "2023-06-01", "content-type": "application/json" },
    body: JSON.stringify({
      model: Deno.env.get("CLAUDE_MODEL") || "claude-sonnet-5-5",
      max_tokens: 12000,
      messages: [{ role: "user", content }],
    }),
  });
  const data = await r.json().catch(() => ({}));
  if (!r.ok) return responder({ error: data?.error?.message || "La API de Claude respondió con un error" }, 502);

  const text = (data.content ?? []).filter((b: { type: string }) => b.type === "text").map((b: { text: string }) => b.text).join("");
  return responder({ text, uso: data.usage });
});
