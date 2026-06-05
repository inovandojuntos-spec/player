-- Soporte para abrir contrato.html desde el menú Extras del player.
-- IMPORTANTE: el play.html actual reconoce links externos/internos de items cuyo slug empieza
-- por 'adicionales_link_' leyendo item.video / video_url.

-- 1) Crear/actualizar item adicional Contrato
insert into public.items (
  slug,
  name,
  category,
  description,
  image_url,
  video_url
)
values (
  'adicionales_link_contrato',
  'Contrato',
  'Instruções',
  'Contrato interativo do desafio',
  'images/contrato.svg',
  '/contrato.html?desafio=desafio_20'
)
on conflict (slug) do update set
  name = excluded.name,
  category = excluded.category,
  description = excluded.description,
  image_url = excluded.image_url,
  video_url = excluded.video_url;

-- 2) Asignar solo al desafio_20
insert into public.desafios_itens (
  desafio_id,
  item_id,
  sort_order
)
select
  d.id,
  i.id,
  99
from public.desafios d
join public.items i on i.slug = 'adicionales_link_contrato'
where d.slug = 'desafio_20'
on conflict do nothing;

-- 3) Verificación rápida
select
  d.slug as desafio_slug,
  i.slug as item_slug,
  i.name,
  i.category,
  i.video_url,
  di.sort_order
from public.desafios_itens di
join public.desafios d on d.id = di.desafio_id
join public.items i on i.id = di.item_id
where d.slug = 'desafio_20'
  and i.slug = 'adicionales_link_contrato';
