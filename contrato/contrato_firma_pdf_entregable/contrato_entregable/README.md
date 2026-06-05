# Contrato con firma táctil y PDF

## Archivos incluidos

- `public/contrato.html`: versión implementada con:
  - firma con dedo/mouse usando `signature_pad`
  - guardado de `signature_image`
  - generación PDF usando `pdf-lib`
  - subida a Supabase Storage bucket `contracts`
  - actualización de `pdf_url`
- `public/play.html`: copia sin cambios del archivo original.
- `supabase/migrations/20260605_contract_signature_pdf.sql`: columnas, Storage policies y RPC actualizado.
- `supabase/functions/generate-contract-pdf/index.ts`: alternativa backend opcional.

## Instalación rápida

1. Ejecuta en Supabase SQL Editor:
   `supabase/migrations/20260605_contract_signature_pdf.sql`

2. Sube/reemplaza tu `contrato.html` por:
   `public/contrato.html`

3. Verifica que el item adicional del contrato apunte a:
   `/contrato.html?desafio=desafio_19`
   o a la ruta equivalente que ya usas.

4. Prueba flujo:
   - abrir contrato
   - responder preguntas
   - firmar
   - revisión final
   - finalizar y generar PDF
   - abrir link “Baixar contrato em PDF”

## Validaciones técnicas

- El bucket `contracts` está configurado público para que el link PDF funcione directo.
- Si necesitas PDFs privados, cambia el bucket a privado y usa signed URLs desde backend.
- La firma se guarda como base64 PNG en `contract_responses.signature_image`.
- Para producción con mayor control legal/auditoría, mover generación PDF al backend y registrar IP/user-agent/hash del PDF.
