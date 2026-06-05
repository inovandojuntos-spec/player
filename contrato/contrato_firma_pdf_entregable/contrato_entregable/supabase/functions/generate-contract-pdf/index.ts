// supabase/functions/generate-contract-pdf/index.ts
// Opción backend alternativa. El contrato.html entregado ya genera PDF en navegador.
// Esta función queda lista si luego decides mover generación de PDF al servidor.
//
// Deploy:
//   supabase functions deploy generate-contract-pdf
//
// Requiere variables:
//   SUPABASE_URL
//   SUPABASE_SERVICE_ROLE_KEY

import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";
import { PDFDocument, StandardFonts, rgb } from "https://esm.sh/pdf-lib@1.17.1";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

function splitLines(text: string, maxChars = 88): string[] {
  const out: string[] = [];
  for (const line of String(text || "").split("\n")) {
    const words = line.split(/\s+/);
    let current = "";
    for (const word of words) {
      if (`${current} ${word}`.trim().length > maxChars) {
        if (current) out.push(current);
        current = word;
      } else {
        current = `${current} ${word}`.trim();
      }
    }
    out.push(current || "");
  }
  return out;
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const { response_id } = await req.json();

    if (!response_id) {
      return new Response(JSON.stringify({ error: "response_id requerido" }), {
        status: 400,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,
    );

    const { data: response, error: readError } = await supabase
      .from("contract_responses")
      .select("id,user_id,desafio_slug,rendered_text,signature_image")
      .eq("id", response_id)
      .single();

    if (readError) throw readError;

    const pdfDoc = await PDFDocument.create();
    const font = await pdfDoc.embedFont(StandardFonts.Helvetica);
    const bold = await pdfDoc.embedFont(StandardFonts.HelveticaBold);

    const pageWidth = 595.28;
    const pageHeight = 841.89;
    const margin = 48;
    let page = pdfDoc.addPage([pageWidth, pageHeight]);
    let y = pageHeight - margin;

    function drawLine(text: string, size = 10, useBold = false) {
      if (y < margin + 70) {
        page = pdfDoc.addPage([pageWidth, pageHeight]);
        y = pageHeight - margin;
      }

      page.drawText(String(text || ""), {
        x: margin,
        y,
        size,
        font: useBold ? bold : font,
        color: rgb(0.08, 0.08, 0.08),
      });
      y -= size + 7;
    }

    drawLine("INOVANDO JUNTOS", 18, true);
    drawLine("Contrato interativo assinado eletronicamente", 13, true);
    y -= 8;

    for (const line of splitLines(response.rendered_text || "")) {
      const isTitle = /^(\d+\.|CONTRATO|Desafio:|Data:|Assinatura|Status:)/.test(line);
      drawLine(line, isTitle ? 10.8 : 9.8, isTitle);
    }

    if (response.signature_image) {
      const signatureBytes = Uint8Array.from(
        atob(response.signature_image.split(",")[1]),
        (c) => c.charCodeAt(0),
      );
      const sig = await pdfDoc.embedPng(signatureBytes);

      if (y < 170) {
        page = pdfDoc.addPage([pageWidth, pageHeight]);
        y = pageHeight - margin;
      }

      y -= 10;
      drawLine("Assinatura:", 11, true);

      const imgWidth = 260;
      const imgHeight = Math.min(105, (sig.height / sig.width) * imgWidth);

      page.drawRectangle({
        x: margin,
        y: y - imgHeight - 10,
        width: imgWidth + 20,
        height: imgHeight + 18,
        borderColor: rgb(0.75, 0.75, 0.75),
        borderWidth: 1,
        color: rgb(1, 1, 1),
      });

      page.drawImage(sig, {
        x: margin + 10,
        y: y - imgHeight - 1,
        width: imgWidth,
        height: imgHeight,
      });
    }

    const pdfBytes = await pdfDoc.save();
    const filePath = `${response.user_id}/${response.desafio_slug}-${Date.now()}.pdf`;

    const { error: uploadError } = await supabase.storage
      .from("contracts")
      .upload(filePath, pdfBytes, {
        contentType: "application/pdf",
        upsert: true,
      });

    if (uploadError) throw uploadError;

    const { data: publicData } = supabase.storage.from("contracts").getPublicUrl(filePath);
    const pdfUrl = publicData.publicUrl;

    const { error: updateError } = await supabase
      .from("contract_responses")
      .update({ pdf_url: pdfUrl })
      .eq("id", response.id);

    if (updateError) throw updateError;

    return new Response(JSON.stringify({ ok: true, pdf_url: pdfUrl }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (err) {
    console.error(err);
    return new Response(JSON.stringify({ ok: false, error: String(err?.message || err) }), {
      status: 500,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
