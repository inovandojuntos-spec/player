-- 20260605_contract_signature_pdf.sql
-- Ejecutar en Supabase SQL Editor.
-- Objetivo:
-- 1) Agregar firma y PDF al contrato.
-- 2) Crear bucket de Storage para PDFs.
-- 3) Actualizar RPC save_contract_response para aceptar firma/pdf.

alter table public.contract_responses
  add column if not exists signature_image text,
  add column if not exists signed_at timestamptz,
  add column if not exists pdf_url text;

-- Necesario para upsert por usuario + desafío.
create unique index if not exists contract_responses_user_desafio_uidx
on public.contract_responses (user_id, desafio_slug);

-- Bucket público para poder abrir el PDF desde el link devuelto por getPublicUrl().
-- Si prefieres bucket privado, cambia public=false y genera signed URLs desde backend.
insert into storage.buckets (id, name, public)
values ('contracts', 'contracts', true)
on conflict (id) do update set public = excluded.public;

-- Políticas Storage: cada usuario escribe/actualiza/lee solo dentro de su carpeta auth.uid().
-- Nota: si ya tienes políticas con nombres iguales, elimina o ajusta antes de ejecutar.
drop policy if exists "contracts_select_own_folder" on storage.objects;
drop policy if exists "contracts_insert_own_folder" on storage.objects;
drop policy if exists "contracts_update_own_folder" on storage.objects;
drop policy if exists "contracts_delete_own_folder" on storage.objects;

create policy "contracts_select_own_folder"
on storage.objects for select
to authenticated
using (
  bucket_id = 'contracts'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "contracts_insert_own_folder"
on storage.objects for insert
to authenticated
with check (
  bucket_id = 'contracts'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "contracts_update_own_folder"
on storage.objects for update
to authenticated
using (
  bucket_id = 'contracts'
  and (storage.foldername(name))[1] = auth.uid()::text
)
with check (
  bucket_id = 'contracts'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create policy "contracts_delete_own_folder"
on storage.objects for delete
to authenticated
using (
  bucket_id = 'contracts'
  and (storage.foldername(name))[1] = auth.uid()::text
);

create or replace function public.save_contract_response(
  p_desafio_slug text,
  p_answers jsonb,
  p_rendered_text text,
  p_submit boolean default false,
  p_signature_image text default null,
  p_pdf_url text default null
)
returns public.contract_responses
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid;
  v_result public.contract_responses;
begin
  v_user_id := auth.uid();

  if v_user_id is null then
    raise exception 'Usuario no autenticado';
  end if;

  insert into public.contract_responses (
    user_id,
    desafio_slug,
    answers,
    rendered_text,
    status,
    submitted_at,
    signature_image,
    signed_at,
    pdf_url,
    updated_at
  )
  values (
    v_user_id,
    p_desafio_slug,
    coalesce(p_answers, '{}'::jsonb),
    coalesce(p_rendered_text, ''),
    case when p_submit then 'submitted' else 'draft' end,
    case when p_submit then now() else null end,
    p_signature_image,
    case when p_signature_image is not null and length(p_signature_image) > 0 then now() else null end,
    p_pdf_url,
    now()
  )
  on conflict (user_id, desafio_slug)
  do update set
    answers = excluded.answers,
    rendered_text = excluded.rendered_text,
    status = case when p_submit then 'submitted' else public.contract_responses.status end,
    submitted_at = case when p_submit then now() else public.contract_responses.submitted_at end,
    signature_image = coalesce(p_signature_image, public.contract_responses.signature_image),
    signed_at = case
      when p_signature_image is not null and length(p_signature_image) > 0 then now()
      else public.contract_responses.signed_at
    end,
    pdf_url = coalesce(p_pdf_url, public.contract_responses.pdf_url),
    updated_at = now()
  returning * into v_result;

  return v_result;
end;
$$;

grant execute on function public.save_contract_response(
  text,
  jsonb,
  text,
  boolean,
  text,
  text
) to authenticated;
