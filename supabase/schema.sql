-- =========================================================
-- Finanzas Kulifay: estructura de la base de datos
-- Pegá TODO este archivo en Supabase > SQL Editor > New query y tocá "Run".
-- ANTES de correrlo, cambiá el correo de Belu en la sección 4.
-- =========================================================

-- 1. Tabla única de registros (grupos, conceptos, movimientos, resúmenes y análisis)
create table if not exists public.registros (
  coleccion   text        not null,
  id          text        not null,
  datos       jsonb       not null default '{}'::jsonb,
  actualizado timestamptz not null default now(),
  primary key (coleccion, id)
);

-- 2. Quiénes pueden usar la app
create table if not exists public.miembros (
  email text primary key
);

create or replace function public.es_miembro()
returns boolean
language sql
security definer
stable
set search_path = public
as $$
  select exists (
    select 1 from public.miembros
    where lower(email) = lower(coalesce(auth.jwt() ->> 'email', ''))
  );
$$;

-- 3. Seguridad: solo los miembros con sesión iniciada leen y escriben
alter table public.registros enable row level security;
alter table public.miembros  enable row level security;

drop policy if exists "miembros usan registros" on public.registros;
create policy "miembros usan registros" on public.registros
  for all to authenticated
  using (public.es_miembro())
  with check (public.es_miembro());

drop policy if exists "cada uno ve su fila" on public.miembros;
create policy "cada uno ve su fila" on public.miembros
  for select to authenticated
  using (lower(email) = lower(auth.jwt() ->> 'email'));

-- Cambios en vivo entre los dos celulares
do $$ begin
  alter publication supabase_realtime add table public.registros;
exception when duplicate_object then null; end $$;

-- 4. Los dos usuarios de la familia (CAMBIÁ el correo de Belu)
insert into public.miembros (email) values
  ('kulifaymatias@outlook.com'),
  ('belu.beluna@hotmail.com.ar')
on conflict do nothing;

-- 5. Datos actuales de la app (grupos, conceptos y movimientos cargados hasta hoy)
insert into public.registros (coleccion, id, datos) values
  ('rubros', 'alimentacion', '{"nombre":"Alimentación","orden":2,"tipo":"gasto"}'::jsonb),
  ('rubros', 'auto', '{"nombre":"Auto","orden":5,"tipo":"gasto"}'::jsonb),
  ('rubros', 'cuotas', '{"nombre":"Cuotas","orden":8,"tipo":"gasto"}'::jsonb),
  ('rubros', 'familia', '{"nombre":"Familia","orden":3,"tipo":"gasto"}'::jsonb),
  ('rubros', 'impuestos', '{"nombre":"Impuestos y bancos","orden":6,"tipo":"gasto"}'::jsonb),
  ('rubros', 'ingresos', '{"nombre":"Ingresos","orden":0,"tipo":"ingreso"}'::jsonb),
  ('rubros', 'ofrenda', '{"nombre":"Ofrenda","orden":9,"tipo":"gasto"}'::jsonb),
  ('rubros', 'salud', '{"nombre":"Salud y bienestar","orden":4,"tipo":"gasto"}'::jsonb),
  ('rubros', 'servicios', '{"nombre":"Servicios del hogar","orden":1,"tipo":"gasto"}'::jsonb),
  ('rubros', 'suscripciones', '{"nombre":"Suscripciones","orden":7,"tipo":"gasto"}'::jsonb),
  ('conceptos', 'actividad', '{"naturaleza":"flexible","nombre":"Actividad física","orden":2,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"salud","tipo":"gasto"}'::jsonb),
  ('conceptos', 'adobe', '{"naturaleza":"esencial","nombre":"Paquete de Adobe","orden":4,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"suscripciones","tipo":"gasto"}'::jsonb),
  ('conceptos', 'agua', '{"naturaleza":"esencial","nombre":"Servicio de agua","orden":4,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"servicios","tipo":"gasto"}'::jsonb),
  ('conceptos', 'carniceria', '{"naturaleza":"esencial","nombre":"Comida (carnicería)","orden":2,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"alimentacion","tipo":"gasto"}'::jsonb),
  ('conceptos', 'claude', '{"naturaleza":"flexible","nombre":"Suscripción de Claude","orden":5,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"suscripciones","tipo":"gasto"}'::jsonb),
  ('conceptos', 'comida-varios', '{"naturaleza":"flexible","nombre":"Comida (varios)","orden":4,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"alimentacion","tipo":"gasto"}'::jsonb),
  ('conceptos', 'cuota-1', '{"naturaleza":"flexible","nombre":"Cuota 1","orden":1,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"cuotas","tipo":"gasto"}'::jsonb),
  ('conceptos', 'cuota-2', '{"naturaleza":"flexible","nombre":"Cuota 2","orden":2,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"cuotas","tipo":"gasto"}'::jsonb),
  ('conceptos', 'cuota-3', '{"naturaleza":"flexible","nombre":"Cuota 3","orden":3,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"cuotas","tipo":"gasto"}'::jsonb),
  ('conceptos', 'cuota-4', '{"naturaleza":"flexible","nombre":"Cuota 4","orden":4,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"cuotas","tipo":"gasto"}'::jsonb),
  ('conceptos', 'cuota-5', '{"naturaleza":"flexible","nombre":"Cuota 5","orden":5,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"cuotas","tipo":"gasto"}'::jsonb),
  ('conceptos', 'cuota-6', '{"naturaleza":"flexible","nombre":"Cuota 6","orden":6,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"cuotas","tipo":"gasto"}'::jsonb),
  ('conceptos', 'gas', '{"naturaleza":"esencial","nombre":"Servicio de gas","orden":5,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"servicios","tipo":"gasto"}'::jsonb),
  ('conceptos', 'hbo', '{"naturaleza":"prescindible","nombre":"HBO","orden":2,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"suscripciones","tipo":"gasto"}'::jsonb),
  ('conceptos', 'imp-tarjeta', '{"naturaleza":"prescindible","nombre":"Impuestos de tarjeta","orden":2,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"impuestos","tipo":"gasto"}'::jsonb),
  ('conceptos', 'ing-belu', '{"nombre":"Ingresos Belu","orden":2,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"ingresos","tipo":"ingreso"}'::jsonb),
  ('conceptos', 'ing-mati', '{"nombre":"Ingresos Mati","orden":1,"presupuestoBanco":10000000,"presupuestoEfectivo":0,"rubroId":"ingresos","tipo":"ingreso"}'::jsonb),
  ('conceptos', 'luz', '{"naturaleza":"esencial","nombre":"Servicio de luz","orden":3,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"servicios","tipo":"gasto"}'::jsonb),
  ('conceptos', 'medico', '{"naturaleza":"esencial","nombre":"Servicio médico","orden":1,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"salud","tipo":"gasto"}'::jsonb),
  ('conceptos', 'monotributo', '{"naturaleza":"esencial","nombre":"Monotributo","orden":1,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"impuestos","tipo":"gasto"}'::jsonb),
  ('conceptos', 'nafta', '{"naturaleza":"esencial","nombre":"Nafta","orden":2,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"auto","tipo":"gasto"}'::jsonb),
  ('conceptos', 'nala', '{"naturaleza":"flexible","nombre":"Gastos de Nala","orden":1,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"familia","tipo":"gasto"}'::jsonb),
  ('conceptos', 'nube', '{"naturaleza":"flexible","nombre":"Nube","orden":3,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"suscripciones","tipo":"gasto"}'::jsonb),
  ('conceptos', 'ofrenda', '{"naturaleza":"esencial","nombre":"Ofrenda","orden":1,"porcentajeIngreso":10,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"ofrenda","tipo":"gasto"}'::jsonb),
  ('conceptos', 'oli', '{"naturaleza":"flexible","nombre":"Gastos de Oli","orden":2,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"familia","tipo":"gasto"}'::jsonb),
  ('conceptos', 'paramount', '{"naturaleza":"prescindible","nombre":"Paramount","orden":1,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"suscripciones","tipo":"gasto"}'::jsonb),
  ('conceptos', 'patente', '{"naturaleza":"esencial","nombre":"Patente","orden":1,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"auto","tipo":"gasto"}'::jsonb),
  ('conceptos', 'seguro-auto', '{"naturaleza":"esencial","nombre":"Seguro de auto","orden":3,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"auto","tipo":"gasto"}'::jsonb),
  ('conceptos', 'super', '{"naturaleza":"esencial","nombre":"Supermercado","orden":1,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"alimentacion","tipo":"gasto"}'::jsonb),
  ('conceptos', 'tel-belu', '{"naturaleza":"esencial","nombre":"Servicio de telefonía Belu","orden":2,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"servicios","tipo":"gasto"}'::jsonb),
  ('conceptos', 'tel-mati', '{"naturaleza":"esencial","nombre":"Servicio de telefonía Mati","orden":1,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"servicios","tipo":"gasto"}'::jsonb),
  ('conceptos', 'verduleria', '{"naturaleza":"esencial","nombre":"Comida (verdulería)","orden":3,"presupuestoBanco":0,"presupuestoEfectivo":0,"rubroId":"alimentacion","tipo":"gasto"}'::jsonb),
  ('movimientos', 'kb5in16c9samoxxwwfc4', '{"conceptoId":"agua","creado":1792000076535,"descripcion":"","fecha":"2026-10-14","medio":"banco","monto":100000,"origen":"manual","persona":"Belu","tipo":"gasto"}'::jsonb)
on conflict (coleccion, id) do nothing;
