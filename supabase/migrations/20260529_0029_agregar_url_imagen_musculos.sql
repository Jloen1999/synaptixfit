-- Migration: 0029_agregar_url_imagen_musculos
-- Objetivo: Agregar columna url_imagen a la tabla musculos y
--           poblarla con las rutas R2 de las imagenes ilustrativas.

alter table public.musculos
  add column if not exists url_imagen text;

update public.musculos
  set url_imagen = case
  when nombre = 'abdomen' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/abdomen_abdominales.png'
  when nombre = 'abdomen inferior' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/abdomen_inferior.png'
  when nombre = 'abductores' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/abductores.png'
  when nombre = 'aductores' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/aductores.png'
  when nombre = 'antebrazos' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/antebrazos.png'
  when nombre = 'braquial' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/braquial.png'
  when nombre = 'braquiorradial' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/braquiorradial.png'
  when nombre = 'bíceps' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/biceps.png'
  when nombre = 'columna' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/columna.png'
  when nombre = 'coracobraquial' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/coracobraquial.png'
  when nombre = 'core' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/core.png'
  when nombre = 'cuádriceps' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/cuadriceps.png'
  when nombre = 'deltoides' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/deltoides.png'
  when nombre = 'deltoides anterior' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/deltoides_anterior.png'
  when nombre = 'deltoides medio' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/deltoides_medio.png'
  when nombre = 'deltoides posteriores' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/deltoide_posterior.png'
  when nombre = 'dorsal ancho' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/dorsal_ancho.png'
  when nombre = 'elevador de la escápula' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/elevador_escapula.png'
  when nombre = 'espalda' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/espalda.png'
  when nombre = 'espalda alta' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/espalda_alta.png'
  when nombre = 'estabilizadores de tobillo' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/estabilizador_tobillo.png'
  when nombre = 'esternocleidomastoideo' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/esternocleidomastoideo.png'
  when nombre = 'extensores de muñeca' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/extensores_muneca.png'
  when nombre = 'flexores de la cadera' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/flexor_cadera.png'
  when nombre = 'flexores de muñeca' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/flexor_muneca.png'
  when nombre = 'gemelos' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/gemelos.png'
  when nombre = 'glúteo mayor' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/gluteo_mayor.png'
  when nombre = 'glúteo medio' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/gluteo_medio.png'
  when nombre = 'ingle' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/ingle.png'
  when nombre = 'isquiotibiales' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/isquiotibiales.png'
  when nombre = 'manguito rotador' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/manguito_rotador.png'
  when nombre = 'manos' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/manos.png'
  when nombre = 'muñecas' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/muneca.png'
  when nombre = 'músculos de agarre' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/agarre.png'
  when nombre = 'oblicuos' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/oblicuos.png'
  when nombre = 'pecho' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/pecho.png'
  when nombre = 'pecho superior' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/pecho_superior.png'
  when nombre = 'pectíneo' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/pectineo.png'
  when nombre = 'pies' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/pies.png'
  when nombre = 'redondo mayor' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/redondo_mayor.png'
  when nombre = 'redondo menor' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/redondo_menor.png'
  when nombre = 'romboides' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/romboides.png'
  when nombre = 'serrato anterior' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/serrato_anterior.png'
  when nombre = 'sistema cardiovascular' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/sistema_cardiovascular.png'
  when nombre = 'supraespinoso' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/supraespinoso.png'
  when nombre = 'sóleo' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/soleo.png'
  when nombre = 'tensor de la fascia lata' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/tensor_fascia_lata.png'
  when nombre = 'tibial anterior' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/tibial_anterior.png'
  when nombre = 'trapecios' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/trapecios.png'
  when nombre = 'tríceps' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/triceps.png'
  when nombre = 'zona lumbar' then 'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/musculos/zona_lumbar.png'
  end
  where url_imagen is null;

