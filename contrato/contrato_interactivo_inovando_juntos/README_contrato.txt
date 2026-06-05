PAQUETE CONTRATO INTERACTIVO - INOVANDO JUNTOS

Archivos:
1. contrato.html
   - Página completa standalone.
   - Usa Supabase Auth igual que play.html.
   - Carga preguntas desde public.contract_questions.
   - Carga respuestas existentes desde public.contract_responses.
   - Guarda borrador con RPC public.save_contract_response.
   - Finaliza con p_submit=true y retorna a /play/{desafioSlug}.

2. contrato_support.sql
   - Crea/actualiza el item adicionales_link_contrato.
   - Lo asigna a desafio_20.
   - Usa video_url porque play.html abre links internos desde item.video/video_url para slugs adicionales_link_*.

Instalación:
- Copiar contrato.html a la raíz pública del sitio, al mismo nivel que play.html y login.html.
- Asegurar que images/logo.png exista.
- Asegurar que images/contrato.svg exista, o cambiar image_url en SQL.
- Ejecutar primero tus tablas/RPC/RLS/preguntas.
- Luego ejecutar contrato_support.sql.
- Probar desde /play/desafio_20 > Extras > Contrato.

Nota técnica:
El contrato no contiene lógica de contenido sensible. Todo el contenido editable viene de contract_questions.options/title/description.
