-- Migration: 0038_insertar_ejercicios_final
-- Objetivo: Insertar 909 ejercicios del dataset final
--           y recrear v_ejercicios_completos con url_preview.

drop view if exists public.v_ejercicios_completos cascade;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl femoral asistido en prono',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00161201-Assisted-Prone-Hamstring_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00161201-Assisted-Prone-Hamstring_Thighs_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00251201-Barbell-Bench-Press_Chest-FIX2_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00251201-Barbell-Bench-Press_Chest-FIX2_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00331201-Barbell-Decline-Bench-Press_Chest-FIX_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00331201-Barbell-Decline-Bench-Press_Chest-FIX_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00511201-Barbell-Jefferson-Squat_Thighs-FIX_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00511201-Barbell-Jefferson-Squat_Thighs-FIX_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00531201-Barbell-Jump-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00531201-Barbell-Jump-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press en el suelo con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00651201-Barbell-One-Arm-Floor-Press_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00651201-Barbell-One-Arm-Floor-Press_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Peso muerto con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00661201-Barbell-One-Arm-Side-Deadlift_Thighs-FIX_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00661201-Barbell-One-Arm-Side-Deadlift_Thighs-FIX_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00691201-Barbell-Overhead-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00691201-Barbell-Overhead-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancada con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00781201-Barbell-Rear-Lunge_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/00781201-Barbell-Rear-Lunge_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Step-up con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01141201-Barbell-Step-up_Hips_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01141201-Barbell-Step-up_Hips_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Fondos en banco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01291201-Bench-Dip-(knees-bent)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01291201-Bench-Dip-(knees-bent)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01491201-Cable-Alternate-Triceps-Extension_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01491201-Cable-Alternate-Triceps-Extension_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01581201-Cable-Decline-Fly_Chest-FIX_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01581201-Cable-Decline-Fly_Chest-FIX_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01641201-Cable-Front-Shoulder-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01641201-Cable-Front-Shoulder-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01691201-Cable-Incline-Bench-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01691201-Cable-Incline-Bench-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01731201-Cable-Incline-Triceps-Extension_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01731201-Cable-Incline-Triceps-Extension_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01871201-Cable-Lying-Triceps-Extension_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01871201-Cable-Lying-Triceps-Extension_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01881201-Cable-Middle-Fly_Chest-FIX_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01881201-Cable-Middle-Fly_Chest-FIX_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01951201-Cable-Preacher-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/01951201-Cable-Preacher-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Posterior drive con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/02041201-Cable-Rear-Drive_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/02041201-Cable-Rear-Drive_Upper-Arms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Jalón de tríceps con agarre supino con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/02071201-Cable-Reverse-grip-Pushdown_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/02071201-Cable-Reverse-grip-Pushdown_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/02251201-Cable-Standing-Cross-over-High-Reverse-Fly_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/02251201-Cable-Standing-Cross-over-High-Reverse-Fly_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Jalón al pecho con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/02321201-Cable-Standing-Pulldown-(with-rope)_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/02321201-Cable-Standing-Pulldown-(with-rope)_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/02891201-Dumbbell-Bench-Press_Chest-FIX_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/02891201-Dumbbell-Bench-Press_Chest-FIX_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03011201-Dumbbell-Decline-Bench-Press_Chest-FIX_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03011201-Dumbbell-Decline-Bench-Press_Chest-FIX_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Declinado hammer press con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03031201-Dumbbell-Decline-Hammer-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03031201-Dumbbell-Decline-Hammer-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03071201-Dumbbell-Decline-Twist-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03071201-Dumbbell-Decline-Twist-Fly_Chest_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Inclinado curl con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03181201-Dumbbell-Incline-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03181201-Dumbbell-Incline-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03251201-Dumbbell-Incline-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03251201-Dumbbell-Incline-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación frontal con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03351201-Dumbbell-Lateral-to-Front-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03351201-Dumbbell-Lateral-to-Front-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tumbado una arm deltoid posterior con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03411201-Dumbbell-Lying-One-Arm-Deltoid-Rear_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03411201-Dumbbell-Lying-One-Arm-Deltoid-Rear_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tumbado una arm press con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03431201-Dumbbell-Lying-One-Arm-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03431201-Dumbbell-Lying-One-Arm-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Una arm kickback con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03541201-Dumbbell-One-Arm-Kickback_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03541201-Dumbbell-One-Arm-Kickback_Upper-Arms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de tracción para desarrollar la espalda y mejorar la postura.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03631201-Dumbbell-One-Arm-Upright-Row_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03631201-Dumbbell-One-Arm-Upright-Row_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de muñeca con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03681201-Dumbbell-Over-Bench-Revers-Wrist-Curl_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03681201-Dumbbell-Over-Bench-Revers-Wrist-Curl_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03841201-Dumbbell-Reverse-Preacher-Curl_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03841201-Dumbbell-Reverse-Preacher-Curl_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press sentado alterno con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03881201-Dumbbell-Seated-Alternate-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/03881201-Dumbbell-Seated-Alternate-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de concentración con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04031201-Dumbbell-Seated-Revers-grip-Concentration-Curl_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04031201-Dumbbell-Seated-Revers-grip-Concentration-Curl_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04101201-Dumbbell-Single-Leg-Split-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04101201-Dumbbell-Single-Leg-Split-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04231201-Dumbbell-Standing-One-Arm-Extension_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04231201-Dumbbell-Standing-One-Arm-Extension_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl inverso con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04251201-Dumbbell-Standing-One-Arm-Reverse-Curl_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04251201-Dumbbell-Standing-One-Arm-Reverse-Curl_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De pie palms in press con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04271201-Dumbbell-Standing-Palms-In-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04271201-Dumbbell-Standing-Palms-In-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl inverso con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04291201-Dumbbell-Standing-Reverse-Curl_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04291201-Dumbbell-Standing-Reverse-Curl_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zottman curl con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04391201-Dumbbell-Zottman-Curl_Upper-Arms-FIX_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04391201-Dumbbell-Zottman-Curl_Upper-Arms-FIX_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl con agarre cerrado con barra EZ',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04461201-EZ-Barbell-Close-grip-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04461201-EZ-Barbell-Close-grip-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con barra EZ',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04501201-EZ-Barbell-JM-Bench-Press_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04501201-EZ-Barbell-JM-Bench-Press_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con agarre supino con barra EZ',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04521201-EZ-Barbell-Reverse-grip-Preacher-Curl_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04521201-EZ-Barbell-Reverse-grip-Preacher-Curl_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps con barra EZ',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04531201-EZ-Barbell-Seated-Triceps-Extension_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04531201-EZ-Barbell-Seated-Triceps-Extension_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04621201-Front-and-Back-Neck-Stretch_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04621201-Front-and-Back-Neck-Stretch_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio de tracción para desarrollar la espalda y mejorar la postura.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04711201-Handstand-Push-Up_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/04711201-Handstand-Push-Up_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'avanzado',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05131201-Jump-Squat-II_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05131201-Jump-Squat-II_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Alterno press con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05201201-Kettlebell-Alternating-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05201201-Kettlebell-Alternating-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Jerk con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05271201-Kettlebell-Double-Jerk_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05271201-Kettlebell-Double-Jerk_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Snatch con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05291201-Kettlebell-Double-Snatch_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05291201-Kettlebell-Double-Snatch_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Clean con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05371201-Kettlebell-One-Arm-Clean-and-Jerk_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05371201-Kettlebell-One-Arm-Clean-and-Jerk_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Push press con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05401201-Kettlebell-One-Arm-Push-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05401201-Kettlebell-One-Arm-Push-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Snatch con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05421201-Kettlebell-One-Arm-Snatch_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05421201-Kettlebell-One-Arm-Snatch_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentado press con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05461201-Kettlebell-Seated-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05461201-Kettlebell-Seated-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Thruster con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05501201-Kettlebell-Thruster_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05501201-Kettlebell-Thruster_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Clean con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05521201-Kettlebell-Two-Arm-Clean_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05521201-Kettlebell-Two-Arm-Clean_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press militar con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05531201-Kettlebell-Two-Arm-Military-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05531201-Kettlebell-Two-Arm-Military-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05751201-Lever-Bicep-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05751201-Lever-Bicep-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05921201-Lever-Preacher-Curl_Upper-Arms-FIX_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/05921201-Lever-Preacher-Curl_Upper-Arms-FIX_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/06131201-Lying-(side)-Quadriceps-Stretch_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/06131201-Lying-(side)-Quadriceps-Stretch_Thighs_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'March sit (wall)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/06241201-March-Sit-(wall)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/06241201-March-Sit-(wall)_Thighs_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/06471201-Plyo-Sit-Squat-(wall)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/06471201-Plyo-Sit-Squat-(wall)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/06531201-Push-up-(bosu-ball)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/06531201-Push-up-(bosu-ball)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/06591201-Push-up-(wall)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/06591201-Push-up-(wall)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/06911201-Seated-Side-Crunch-(Wall)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/06911201-Seated-Side-Crunch-(Wall)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/07131201-Side-Neck-Stretch_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/07131201-Side-Neck-Stretch_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/07161201-Side-Push-Neck-Stretch_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/07161201-Side-Push-Neck-Stretch_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con máquina smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/07481201-Smith-Bench-Press_Chest-FIX_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/07481201-Smith-Bench-Press_Chest-FIX_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con agarre cerrado con máquina smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/07511201-Smith-Close-Grip-Bench-Press_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/07511201-Smith-Close-Grip-Bench-Press_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con máquina smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/07571201-Smith-Incline-Bench-Press_Chest-FIX_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/07571201-Smith-Incline-Bench-Press_Chest-FIX_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press militar con máquina smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/07741201-Smith-Standing-Military-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/07741201-Smith-Standing-Military-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Toe touch sit (wall)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/08101201-Toe-Touch-Sit-(wall)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/08101201-Toe-Touch-Sit-(wall)_Thighs_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/08351201-Weighted-Hyperextension-(on-stability-ball)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/08351201-Weighted-Hyperextension-(on-stability-ball)_Waist_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Apretón de manos de pie',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/08541201-Weighted-Standing-Hand-Squeeze_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/08541201-Weighted-Standing-Hand-Squeeze_Forearms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo específico de antebrazo y agarre para reforzar la muñeca y la prensión.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Con rodillo de muñeca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/08591201-Wrist-Roller_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/08591201-Wrist-Roller_Forearms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo específico de antebrazo y agarre para reforzar la muñeca y la prensión.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/08681201-Cable-Curl-(male)_Upper-Arms-FIX_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/08681201-Cable-Curl-(male)_Upper-Arms-FIX_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación frontal con banda elástica',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/09781201-Band-front-raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/09781201-Band-front-raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal con banda elástica',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/09851201-Band-Kneeling-Twisting-Crunch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/09851201-Band-Kneeling-Twisting-Crunch_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal con banda elástica',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/10071201-Band-standing-twisting-crunch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/10071201-Band-standing-twisting-crunch_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de pecho con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/10291201-Lever-Parallel-Chest-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/10291201-Lever-Parallel-Chest-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/10301201-Lever-Pec-Deck-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/10301201-Lever-Pec-Deck-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/10321201-Lever-Alternate-Biceps-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/10321201-Lever-Alternate-Biceps-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Pinch con disco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/10441201-Plate-Pinch_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/10441201-Plate-Pinch_Forearms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo específico de antebrazo y agarre para reforzar la muñeca y la prensión.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/10591201-Standing-Quadriceps-Stretch_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/10591201-Standing-Quadriceps-Stretch_Thighs_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/11681201-Lying-(prone)-Abdominal-Stretch-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/11681201-Lying-(prone)-Abdominal-Stretch-(male)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12281201-Dumbbell-Standing-Inner-Biceps-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12281201-Dumbbell-Standing-Inner-Biceps-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl martillo con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12331201-Dumbbell-Incline-Alternate-Hammer-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12331201-Dumbbell-Incline-Alternate-Hammer-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'I',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12461201-Hollow-Hold_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12461201-Hollow-Hold_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Half wipers (bent leg)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12481201-Half-Wipers-(bent-leg)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12481201-Half-Wipers-(bent-leg)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con banda elástica',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12541201-Band-Bench-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12541201-Band-Bench-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Declinado press con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12611201-Cable-Decline-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12611201-Cable-Decline-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12621201-Cable-One-Arm-Decline-Chest-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12621201-Cable-One-Arm-Decline-Chest-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12631201-Cable-One-Arm-Fly-on-Exercise-Ball_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12631201-Cable-One-Arm-Fly-on-Exercise-Ball_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12641201-Cable-One-Arm-Incline-Fly-on-Exercise-Ball_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12641201-Cable-One-Arm-Incline-Fly-on-Exercise-Ball_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Superior pecho crossovers con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12701201-Cable-Upper-Chest-Crossovers_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12701201-Cable-Upper-Chest-Crossovers_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12711201-Chest-and-Front-of-Shoulder-Stretch_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12711201-Chest-and-Front-of-Shoulder-Stretch_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12761201-Dumbbell-Decline-One-Arm-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12761201-Dumbbell-Decline-One-Arm-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12791201-Dumbbell-Incline-One-Arm-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12791201-Dumbbell-Incline-One-Arm-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Inclinado una arm press con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12811201-Dumbbell-Incline-One-Arm-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12811201-Dumbbell-Incline-One-Arm-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Inclinado press en ejercicio fitball con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12831201-Dumbbell-Incline-Press-on-Exercise-Ball_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12831201-Dumbbell-Incline-Press-on-Exercise-Ball_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tumbado pullover en ejercicio fitball con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12841201-Dumbbell-Lying-Pullover-on-Exercise-Ball_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12841201-Dumbbell-Lying-Pullover-on-Exercise-Ball_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12851201-Dumbbell-One-Arm-Bench-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12851201-Dumbbell-One-Arm-Bench-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'En pica flexión con fitball',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12961201-Exercise-Ball-Pike-Pushup_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12961201-Exercise-Ball-Pike-Pushup_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press en el suelo con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12981201-Kettlebell-One-Arm-Floor-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/12981201-Kettlebell-One-Arm-Floor-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13061201-Plyo-Push-Up_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13061201-Plyo-Push-Up_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Ankle circles',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13681201-Ankle-Circles_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13681201-Ankle-Circles_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13701201-Barbell-Floor-Calf-Raise_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13701201-Barbell-Floor-Calf-Raise_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13761201-Cable-Standing-One-Leg-Calf-Raise_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13761201-Cable-Standing-One-Leg-Calf-Raise_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13771201-Calf-Stretch-With-Hands-Against-Wall_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13771201-Calf-Stretch-With-Hands-Against-Wall_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13831201-Hack-Calf-Raise_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13831201-Hack-Calf-Raise_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13861201-One-Leg-Donkey-Calf-Raise_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13861201-One-Leg-Donkey-Calf-Raise_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de piernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13921201-Sled-One-Leg-Calf-Press-on-Leg-Press_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/13921201-Sled-One-Leg-Calf-Press-on-Leg-Press_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14071201-Calf-Push-Stretch-With-Hands-Against-Wall_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14071201-Calf-Push-Stretch-With-Hands-Against-Wall_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14141201-Dumbbell-One-Arm-Reverse-Preacher-Curl_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14141201-Dumbbell-One-Arm-Reverse-Preacher-Curl_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con máquina smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14331201-Smith-Front-Squat-(Clean-Grip)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14331201-Smith-Front-Squat-(Clean-Grip)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14361201-Barbell-High-Bar-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14361201-Barbell-High-Bar-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de hombros con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14541201-Lever-Seated-Shoulder-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14541201-Lever-Seated-Shoulder-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14891201-Sissy-Squat-Bodyweight_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14891201-Sissy-Squat-Bodyweight_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14901201-Standing-Calf-Raise-(On-a-staircase)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/14901201-Standing-Calf-Raise-(On-a-staircase)_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo con banda elástica',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15001201-Band-Upright-Row-(Under-two-feet)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15001201-Band-Upright-Row-(Under-two-feet)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Jalón apart con banda elástica',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15031201-Band-Pull-Apart_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15031201-Band-Pull-Apart_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15461201-Bodyweight-Wall-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15461201-Bodyweight-Wall-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancada con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15571201-Dumbbell-Walking-Lunges_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15571201-Dumbbell-Walking-Lunges_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con fitball',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15621201-Exercise-Ball-Wall-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15621201-Exercise-Ball-Wall-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de piernas con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15711201-Lever-One-Leg-Extension_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15711201-Lever-One-Leg-Extension_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl femoral con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15861201-Lever-Seated-One-Leg-Curl_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15861201-Lever-Seated-One-Leg-Curl_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl femoral con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15901201-Lever-Lying-Single-Leg-Curl_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15901201-Lever-Lying-Single-Leg-Curl_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con máquina smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15951201-Smith-Front-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/15951201-Smith-Front-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Detrás espalda finger curl con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16101201-Barbell-Behind-Back-Finger-Curl_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16101201-Barbell-Behind-Back-Finger-Curl_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16151201-Lever-Hammer-Grip-Preacher-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16151201-Lever-Hammer-Grip-Preacher-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16241201-Dumbbell-Reverse-Bench-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16241201-Dumbbell-Reverse-Bench-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl con agarre cerrado con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16301201-Cable-Close-Grip-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16301201-Cable-Close-Grip-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Drag curl con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16321201-Cable-Drag-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16321201-Cable-Drag-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16331201-Cable-One-Arm-Preacher-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16331201-Cable-One-Arm-Preacher-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16341201-Cable-Lying-Bicep-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16341201-Cable-Lying-Bicep-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16391201-Cable-Rope-Hammer-Preacher-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16391201-Cable-Rope-Hammer-Preacher-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl sentado por encima de la cabeza con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16431201-Cable-Seated-Overhead-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16431201-Cable-Seated-Overhead-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl martillo con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16481201-Dumbbell-Alternate-Seated-Hammer-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16481201-Dumbbell-Alternate-Seated-Hammer-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16541201-Dumbbell-Biceps-Curl-Reverse_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16541201-Dumbbell-Biceps-Curl-Reverse_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16581201-Dumbbell-Lunge-with-Bicep-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16581201-Dumbbell-Lunge-with-Bicep-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16631201-Dumbbell-One-Arm-Hammer-Preacher-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16631201-Dumbbell-One-Arm-Hammer-Preacher-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Alto curl con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16641201-Dumbbell-High-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16641201-Dumbbell-High-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Una arm de pie curl con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16701201-Dumbbell-One-Arm-Standing-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16701201-Dumbbell-One-Arm-Standing-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl martillo con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16711201-Dumbbell-One-Arm-Standing-Hammer-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16711201-Dumbbell-One-Arm-Standing-Hammer-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Inverso spider curl con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16751201-Dumbbell-Reverse-Spider-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16751201-Dumbbell-Reverse-Spider-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl martillo con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16781201-Dumbbell-Seated-Hammer-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16781201-Dumbbell-Seated-Hammer-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Z',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16881201-Lunge-with-Twist_Thighs_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/16881201-Lunge-with-Twist_Thighs_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Push press con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17001201-Dumbbell-Push-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17001201-Dumbbell-Push-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17051201-Squat-On-Bosu-Ball_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17051201-Squat-On-Bosu-Ball_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17081201-Assisted-Lying-Gastrocnemius-Stretch_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17081201-Assisted-Lying-Gastrocnemius-Stretch_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Jalón de tríceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17231201-Cable-One-Arm-Tricep-Pushdown_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17231201-Cable-One-Arm-Tricep-Pushdown_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17251201-Cable-Rope-Incline-Tricep-Extension_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17251201-Cable-Rope-Incline-Tricep-Extension_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo con balón medicinal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17501201-Medicine-Ball-Supine-Chest-Throw_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17501201-Medicine-Ball-Supine-Chest-Throw_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps con máquina smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17521201-Smith-Machine-Incline-Tricep-Extension_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17521201-Smith-Machine-Incline-Tricep-Extension_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Fondos en banco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17541201-Weighted-Three-Bench-Dips_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17541201-Weighted-Three-Bench-Dips_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'F',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17551201-Weighted-Tricep-Dips_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17551201-Weighted-Tricep-Dips_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17691201-Bodyweight-Side-Lying-Biceps-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17691201-Bodyweight-Side-Lying-Biceps-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17781201-Assisted-Standing-Chest-Stretch_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17781201-Assisted-Standing-Chest-Stretch_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17791201-Assisted-Seated-Chest-Stretch_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17791201-Assisted-Seated-Chest-Stretch_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17801201-Bent-Arm-Chest-Stretch_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17801201-Bent-Arm-Chest-Stretch_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17811201-Coner-Wall-Chest-Stretch_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17811201-Coner-Wall-Chest-Stretch_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17841201-Assisted-Pulling-Backs-Chest-Stretch_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17841201-Assisted-Pulling-Backs-Chest-Stretch_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17891201-Assisted-Straight-Arms-Lying-Stretch_Chest_Back_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/17891201-Assisted-Straight-Arms-Lying-Stretch_Chest_Back_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18161201-Extension-Of-Arms-In-Vertical-Stretch_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18161201-Extension-Of-Arms-In-Vertical-Stretch_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18261201-Finger-Flexor-Stretch_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18261201-Finger-Flexor-Stretch_Forearms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio de agarre y mano para mejorar la fuerza de prensión.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18311201-Rotating-Neck-Stretch_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18311201-Rotating-Neck-Stretch_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18361201-Forward-Flexion-Neck-Stretch_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18361201-Forward-Flexion-Neck-Stretch_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18381201-Neck-Extensor-And-Rotational-Stretch_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18381201-Neck-Extensor-And-Rotational-Stretch_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18401201-Neck-Flexor-And-Rotational-Stretch_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18401201-Neck-Flexor-And-Rotational-Stretch_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18441201-Extension-And-Inclination-Neck-Stretch_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18441201-Extension-And-Inclination-Neck-Stretch_Neck_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl con multipurpose V bar con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18611201-Cable-Curl-with-Multipurpose-V-bar_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18611201-Cable-Curl-with-Multipurpose-V-bar_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18911201-Toe-Squat-Stretch_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18911201-Toe-Squat-Stretch_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18931201-Squatting-Achilles-Stretch_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/18931201-Squatting-Achilles-Stretch_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Estiramiento de isquiotibiales',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19081201-Standing-Toe-Down-Hamstring-Stretch_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19081201-Standing-Toe-Down-Hamstring-Stretch_Thighs_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Estiramiento de isquiotibiales',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19131201-Kneeling-Toe-Up-Hamstring-Stretch_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19131201-Kneeling-Toe-Up-Hamstring-Stretch_Thighs_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Estiramiento de isquiotibiales',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19231201-Assisted-Lying-Hamstring-Stretch_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19231201-Assisted-Lying-Hamstring-Stretch_Thighs_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19301201-Crouching-Heel-Back-Calf-Stretch_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19301201-Crouching-Heel-Back-Calf-Stretch_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19591201-Raised-Foot-Shin-Stretch_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19591201-Raised-Foot-Shin-Stretch_Calves_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19611201-Squatting-Toe-Stretch_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19611201-Squatting-Toe-Stretch_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19701201-Standing-Upright-Shoulders-Stretch_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19701201-Standing-Upright-Shoulders-Stretch_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19741201-Standing-Reverse-Shoulder-Stretch_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19741201-Standing-Reverse-Shoulder-Stretch_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19801201-Across-Chest-Shoulder-Stretch_Back_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19801201-Across-Chest-Shoulder-Stretch_Back_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19861201-Arm-Up-Rotator-Stretch_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/19861201-Arm-Up-Rotator-Stretch_Shoulders_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/20911201-Fingers-Down-Forearm-Stretch_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/20911201-Fingers-Down-Forearm-Stretch_Forearms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo específico de antebrazo y agarre para reforzar la muñeca y la prensión.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21021201-Sitting-Toe-Pull-Calf-Stretch_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21021201-Sitting-Toe-Pull-Calf-Stretch_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21071201-Cow-Stretch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21071201-Cow-Stretch_Waist_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21161201-Lying-Knee-Roll-Over-Stretch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21161201-Lying-Knee-Roll-Over-Stretch_Waist_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21191201-Standing-Side-Stretch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21191201-Standing-Side-Stretch_Waist_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Lateral bend tumbado down',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21211201-Lateral-Bend-Lying-Down_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21211201-Lateral-Bend-Lying-Down_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Assisted side bent',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21221201-Assisted-Side-Bent_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21221201-Assisted-Side-Bent_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21231201-Assisted-Obliques-Stretch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21231201-Assisted-Obliques-Stretch_Waist_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21351201-Weighted-Front-Plank_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21351201-Weighted-Front-Plank_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps con mancuernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21891201-Dumbbells-Seated-Triceps-Extension_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/21891201-Dumbbells-Seated-Triceps-Extension_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22061201-Roll-Reverse-Crunch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22061201-Roll-Reverse-Crunch_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancada con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22191201-Dumbbell-Rear-Lunge-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22191201-Dumbbell-Rear-Lunge-(female)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Step-up con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22211201-Dumbbell-Step-Up-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22211201-Dumbbell-Step-Up-(female)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de piernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22241201-Sled-45-degrees-Leg-Press-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22241201-Sled-45-degrees-Leg-Press-(female)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancada con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22261201-Barbell-Rear-Lunge-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22261201-Barbell-Rear-Lunge-(female)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancada con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22281201-Barbell-Lateral-Lunge-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22281201-Barbell-Lateral-Lunge-(female)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22321201-Cable-Upright-Row-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22321201-Cable-Upright-Row-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22511201-Dumbbell-Lying-Triceps-Extension-(female)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22511201-Dumbbell-Lying-Triceps-Extension-(female)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22521201-Cable-Low-Fly-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22521201-Cable-Low-Fly-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22551201-Lever-Seated-Fly-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22551201-Lever-Seated-Fly-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Gripper de manos (cargado con disco) con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22881201-Lever-Gripper-Hands-(plate-loaded)_Hands_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/22881201-Lever-Gripper-Hands-(plate-loaded)_Hands_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo específico de antebrazo y agarre para reforzar la muñeca y la prensión.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23291201-Spine-Twist_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23291201-Spine-Twist_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Arm slingers colgado straight legs',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23331201-Arm-slingers-Hanging-Straight-Legs_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23331201-Arm-slingers-Hanging-Straight-Legs_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23381201-Chest-Bench-Press---Butt-(WRONG-RIGHT)_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23381201-Chest-Bench-Press---Butt-(WRONG-RIGHT)_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23471201-Front-Plank---Butt-(WRONG-RIGHT)_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23471201-Front-Plank---Butt-(WRONG-RIGHT)_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23481201-Preacher-Curl---Wrists-(WRONG-RIGHT)_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23481201-Preacher-Curl---Wrists-(WRONG-RIGHT)_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23491201-Side-Plank---Butt-(WRONG-RIGHT)_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23491201-Side-Plank---Butt-(WRONG-RIGHT)_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de concentración',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23531201-Concentration-Curl---Arms-(WRONG-RIGHT)_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23531201-Concentration-Curl---Arms-(WRONG-RIGHT)_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23561201-Kettlebell-Goblet-Squat-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23561201-Kettlebell-Goblet-Squat-(female)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23581201-Plank---Butt-(WRONG-RIGHT)_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23581201-Plank---Butt-(WRONG-RIGHT)_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'F',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23631201-Wide-Grip-Chest-Dip-on-High-Parallel-Bars_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23631201-Wide-Grip-Chest-Dip-on-High-Parallel-Bars_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancada con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23671201-Dumbbell-Rear-Lunge-from-Step-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23671201-Dumbbell-Rear-Lunge-from-Step-(female)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Una arm kickback con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23731201-Dumbbell-One-Arm-Kickback-(female)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23731201-Dumbbell-One-Arm-Kickback-(female)_Upper-Arms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de tracción para desarrollar la espalda y mejorar la postura.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De pie por encima de la cabeza press con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23801201-Dumbbell-Standing-Overhead-Press-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23801201-Dumbbell-Standing-Overhead-Press-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23851201-Dumbbell-Preacher-Curl-(female)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23851201-Dumbbell-Preacher-Curl-(female)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23891201-Barbell-Narrow-Stance-Squat-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23891201-Barbell-Narrow-Stance-Squat-(female)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23961201-Cable-Lying-Biceps-Curl-(VERSION-2)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23961201-Cable-Lying-Biceps-Curl-(VERSION-2)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23981201-Close-grip-Push-up-(on-knees)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/23981201-Close-grip-Push-up-(on-knees)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Superior pecho crossovers con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24421201-Cable-Upper-Chest-Crossovers-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24421201-Cable-Upper-Chest-Crossovers-(female)_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24441201-Lever-Seated-Twist-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24441201-Lever-Seated-Twist-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24471201-Lying-leg-hip-raise-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24471201-Lying-leg-hip-raise-(female)_Waist_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24511201-Cable-Twist-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24511201-Cable-Twist-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de pecho con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24571201-Lever-Chest-Press-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24571201-Lever-Chest-Press-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24641201-Cable-Thibaudeau-Kayak-Row_Back_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24641201-Cable-Thibaudeau-Kayak-Row_Back_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Step-up con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24681201-Dumbbell-Lateral-Step-Up-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24681201-Dumbbell-Lateral-Step-Up-(female)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación posterior con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24701201-Dumbbell-Lying-on-Floor-Rear-Delt-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24701201-Dumbbell-Lying-on-Floor-Rear-Delt-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24971201-Barbell-Preacher-Curl-(female)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/24971201-Barbell-Preacher-Curl-(female)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Peso muerto con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25171201-Barbell-Sumo-Deadlift-(female)_Hips_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25171201-Barbell-Sumo-Deadlift-(female)_Hips_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Jalón de tríceps con agarre supino con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25201201-Cable-Reverse-grip-Pushdown-(female)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25201201-Cable-Reverse-grip-Pushdown-(female)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Por encima de la cabeza slam con balón medicinal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25451201-Medicine-Ball-Overhead-Slam-(female)_Back_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25451201-Medicine-Ball-Overhead-Slam-(female)_Back_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25511201-Hanging-Leg-Hip-Raise-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25511201-Hanging-Leg-Hip-Raise-(female)_Waist_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de gemelos con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25581201-Lever-Seated-Calf-Press-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25581201-Lever-Seated-Calf-Press-(female)_Calves_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Side bend con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25761201-Cable-Side-Bend-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25761201-Cable-Side-Bend-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Alterno side press con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25921201-Dumbbell-Alternate-Side-Press-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/25921201-Dumbbell-Alternate-Side-Press-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26001201-Dumbbell-One-Arm-Upright-Row-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26001201-Dumbbell-One-Arm-Upright-Row-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26141201-Push-up-(wall)-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26141201-Push-up-(wall)-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Rollout con banda elástica',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26491201-Band-Assisted-Wheel-Rollout-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26491201-Band-Assisted-Wheel-Rollout-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26561201-Cable-One-Arm-Biceps-Curl-(VERSION-2)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26561201-Cable-One-Arm-Biceps-Curl-(VERSION-2)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26681201-Barbell-Standing-Calf-Raise-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26681201-Barbell-Standing-Calf-Raise-(female)_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos con máquina smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26721201-Smith-One-Leg-Floor-Calf-Raise-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26721201-Smith-One-Leg-Floor-Calf-Raise-(female)_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26761201-Barbell-Seated-Calf-Raise-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26761201-Barbell-Seated-Calf-Raise-(female)_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26791201-Push-Up-(on-stability-ball)-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26791201-Push-Up-(on-stability-ball)-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tumbado una arm press con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26801201-Dumbbell-Lying-One-Arm-Press-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26801201-Dumbbell-Lying-One-Arm-Press-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26921201-Barbell-Lying-Triceps-Extension-(female)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/26921201-Barbell-Lying-Triceps-Extension-(female)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/27001201-Cable-Seated-Crunch-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/27001201-Cable-Seated-Crunch-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/27011201-Crunch-(on-stability-ball)-(female)_waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/27011201-Crunch-(on-stability-ball)-(female)_waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tumbado pronation en suelo con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/27051201-Dumbbell-Lying-Pronation-on-Floor_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/27051201-Dumbbell-Lying-Pronation-on-Floor_Forearms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo específico de antebrazo y agarre para reforzar la muñeca y la prensión.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'I',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/27181201-StrongMan-Front-Hold_Weightlifting_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/27181201-StrongMan-Front-Hold_Weightlifting_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de potencia y coordinación para el desarrollo atlético global.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/27401201-Wide-Push-up-(wall)-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/27401201-Wide-Push-up-(wall)-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de piernas con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/27991201-Barbell-Sitted-Alternate-Leg-Raise_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/27991201-Barbell-Sitted-Alternate-Leg-Raise_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de piernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28021201-Twisted-Leg-Raise_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28021201-Twisted-Leg-Raise_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'V up down (with stability ball)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28161201-V-Up-Down-(with-Stability-ball)-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28161201-V-Up-Down-(with-Stability-ball)-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Skier con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28171201-Barbell-Skier-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28171201-Barbell-Skier-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con máquina smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28241201-Smith-Front-Squat-(Clean-Grip)-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28241201-Smith-Front-Squat-(Clean-Grip)-(female)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Pecho lift con rotation',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28391201-Chest-Lift-with-Rotation_Pilates_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28391201-Chest-Lift-with-Rotation_Pilates_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'C',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28421201-Crab_Pilates_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28421201-Crab_Pilates_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28451201-Hip-Twist-Supported-Arms_Pilates_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28451201-Hip-Twist-Supported-Arms_Pilates_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de hombros con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28831201-Lever-Seated-Shoulder-Press-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28831201-Lever-Seated-Shoulder-Press-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de piernas con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28871201-Cable-Hanging-Leg-Raise_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28871201-Cable-Hanging-Leg-Raise_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28961201-Front-Plank-with-Arm-and-Leg-Lift-(female)_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/28961201-Front-Plank-with-Arm-and-Leg-Lift-(female)_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de hombros con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29341201-Kettlebell-Half-Kneeling-Shoulder-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29341201-Kettlebell-Half-Kneeling-Shoulder-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll pectoral foam rolling',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29481201-Roll-Pec-Foam-Rolling_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29481201-Roll-Pec-Foam-Rolling_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29601201-Dumbbell-Split-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29601201-Dumbbell-Split-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con landmine',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29761201-Landmine-Squat-and-Press_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29761201-Landmine-Squat-and-Press_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press en el suelo con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29821201-Dumbbell-Alternating-Floor-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29821201-Dumbbell-Alternating-Floor-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press en el suelo con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29831201-Dumbbell-Alternating-Floor-Press-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29831201-Dumbbell-Alternating-Floor-Press-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29891201-Squat-mobility-Complex_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29891201-Squat-mobility-Complex_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29931201-Kettlebell-Goblet-Squat-Mobility_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29931201-Kettlebell-Goblet-Squat-Mobility_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29981201-Seated-Ankle-Stretch_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/29981201-Seated-Ankle-Stretch_Calves_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Stair up',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30091201-Stair-Up-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30091201-Stair-Up-(female)_Thighs_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30211201-Scapula-Push-Up_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30211201-Scapula-Push-Up_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30251201-Barbell-Bench-Front-Squat-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30251201-Barbell-Bench-Front-Squat-(female)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de muñeca con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30291201-Barbell-Reverse-Wrist-Curl-(female)_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30291201-Barbell-Reverse-Wrist-Curl-(female)_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30301201-Barbell-Split-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30301201-Barbell-Split-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30501201-Cable-Incline-Fly-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30501201-Cable-Incline-Fly-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30551201-Cable-Lying-Bicep-Curl-(female)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30551201-Cable-Lying-Bicep-Curl-(female)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de pecho con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30611201-Cable-Seated-Chest-Press-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30611201-Cable-Seated-Chest-Press-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30721201-Decline-Bent-Leg-Reverse-Crunch-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/30721201-Decline-Bent-Leg-Reverse-Crunch-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Rotary gemelo con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31051201-Lever-Rotary-Calf-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31051201-Lever-Rotary-Calf-(female)_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31181201-Potty-Squat-(female)_Hips_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31181201-Potty-Squat-(female)_Hips_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31191201-Potty-Squat_Hips_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31191201-Potty-Squat_Hips_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31201201-Standing-Calf-Raise-with-Support-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31201201-Standing-Calf-Raise-with-Support-(female)_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31461201-Push-Up-Plus-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31461201-Push-Up-Plus-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Assisted chin tuck',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31501201-Assisted-Chin-Tuck_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31501201-Assisted-Chin-Tuck_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Chin tuck',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31511201-Chin-Tuck-(female)_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31511201-Chin-Tuck-(female)_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Assisted chin tuck',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31521201-Assisted-Chin-Tuck-(female)_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/31521201-Assisted-Chin-Tuck-(female)_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'A',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32341201-Hyght-Dumbbell-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32341201-Hyght-Dumbbell-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación lateral con landmine',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32371201-Landmine-Lateral-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32371201-Landmine-Lateral-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32791201-Floor-Crunch-Feet-on-Bench-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32791201-Floor-Crunch-Feet-on-Bench-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con máquina smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32811201-Smith-Full-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32811201-Smith-Full-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Frontal máquina de palanca reps',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32951201-Front-Lever-Reps_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32951201-Front-Lever-Reps_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Frontal máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32961201-Front-Lever_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32961201-Front-Lever_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Full planche',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32991201-Full-planche_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/32991201-Full-planche_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Frog planche',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33011201-Frog-planche_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33011201-Frog-planche_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'H',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33021201-Handstand_Upper-arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33021201-Handstand_Upper-arms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Ejercicio de agarre y mano para mejorar la fuerza de prensión.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33331201-Dumbbell-One-Arm-Wide-Grip-Bench-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33331201-Dumbbell-One-Arm-Wide-Grip-Bench-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33341201-Dumbbell-One-Arm-Floor-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33341201-Dumbbell-One-Arm-Floor-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Puente con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33371201-Dumbbell-Side-Bridge_Hips_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33371201-Dumbbell-Side-Bridge_Hips_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33421201-Cable-Y-raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33421201-Cable-Y-raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de muñeca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33451201-Hand-Spring-Wrist-Curl_Hands_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33451201-Hand-Spring-Wrist-Curl_Hands_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33541201-Cable-Front-Squat-(VERSION-2)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33541201-Cable-Front-Squat-(VERSION-2)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de pecho con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33591201-Cable-Standing-Chest-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33591201-Cable-Standing-Chest-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de piernas con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33851201-Lever-Seated-Leg-Press-(VERSION-2)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/33851201-Lever-Seated-Leg-Press-(VERSION-2)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34011201-Pike-Push-up-(between-Benches)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34011201-Pike-Push-up-(between-Benches)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'avanzado',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34021201-Pike-Push-up-(between-Chairs)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34021201-Pike-Push-up-(between-Chairs)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'avanzado',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl femoral',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34151201-Assisted-Inverse-Leg-Curl_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34151201-Assisted-Inverse-Leg-Curl_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'D',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34181201-L-Pull-Up_Back_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34181201-L-Pull-Up_Back_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de tracción para desarrollar la espalda y mejorar la postura.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34221201-Crunch-with-Medicine-Ball_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34221201-Crunch-with-Medicine-Ball_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'A',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34241201-Hyght-Dumbbell-Fly-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34241201-Hyght-Dumbbell-Fly-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press svend',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34261201-Weighted-Svend-Press-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34261201-Weighted-Svend-Press-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación posterior con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34291201-Dumbbell-Rear-Delt-Raise-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34291201-Dumbbell-Rear-Delt-Raise-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34381201-Decline-Leg-Hip-Raise_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34381201-Decline-Leg-Hip-Raise_Waist_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'F',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34431201-Dip-on-Floor-with-Chair_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34431201-Dip-on-Floor-with-Chair_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'V up con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34461201-Dumbbell-V-up-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34461201-Dumbbell-V-up-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancada con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34471201-Dumbbell-Side-Lunge-(VERSION 3)-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34471201-Dumbbell-Side-Lunge-(VERSION 3)-(female)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34491201-Dumbbell-Russian-Twist_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34491201-Dumbbell-Russian-Twist_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press svend con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34521201-Dumbbell-Svend-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34521201-Dumbbell-Svend-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Pulse up',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34591201-Pulse-Up_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/34591201-Pulse-Up_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35001201-Full-Squat-Mobility_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35001201-Full-Squat-Mobility_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35011201-Front-Plank-with-Leg-Lift-(male)_Hips_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35011201-Front-Plank-with-Leg-Lift-(male)_Hips_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35041201-Standing-Balance-Quadriceps-Stretch_Stretching_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35041201-Standing-Balance-Quadriceps-Stretch_Stretching_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl femoral',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35071201-Self-Assisted-Inverse-Leg-Curl-(VERSION-2)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35071201-Self-Assisted-Inverse-Leg-Curl-(VERSION-2)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35101201-Crunchy-Frog-on-Floor_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35101201-Crunchy-Frog-on-Floor_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Resistance banda elástica superior body dead bug',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35121201-Resistance-Band-Upper-Body-Dead-Bug_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35121201-Resistance-Band-Upper-Body-Dead-Bug_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35131201-Resistance-Band-Shoulder-Stretch-Behind-the-Back_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35131201-Resistance-Band-Shoulder-Stretch-Behind-the-Back_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35141201-Single-Leg-Sliding-Floor-Bridge-Curl-on-Towel_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35141201-Single-Leg-Sliding-Floor-Bridge-Curl-on-Towel_Thighs_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Oblique V up en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35151201-Oblique-V-up-on-Floor_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35151201-Oblique-V-up-on-Floor_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35161201-Shoulder-Backbend-Stretch_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35161201-Shoulder-Backbend-Stretch_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35411201-Dumbbell-Incline-Y-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35411201-Dumbbell-Incline-Y-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35421201-Dumbbell-Incline-T-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35421201-Dumbbell-Incline-T-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Inclinado alterno press con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35451201-Dumbbell-Incline-Alternate-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35451201-Dumbbell-Incline-Alternate-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35531201-Rotational-Push-Up_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35531201-Rotational-Push-Up_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35571201-Kneeling-Wide-Hand-Push-Up_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35571201-Kneeling-Wide-Hand-Push-Up_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll fitball pectorial release',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35691201-Roll-Ball-Pectorial-Release_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35691201-Roll-Ball-Pectorial-Release_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Swing con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35711201-Kettlebell-Full-Swing_Hips_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35711201-Kettlebell-Full-Swing_Hips_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Strict press con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35721201-Kettlebell-Strict-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35721201-Kettlebell-Strict-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancada con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35751201-Kettlebell-Backward-Lunge_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35751201-Kettlebell-Backward-Lunge_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Z',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35821201-Lunge-with-Jump_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35821201-Lunge-with-Jump_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Peso muerto',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35851201-Single-Leg-Deadlift-with-Knee-Lift_Hips_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35851201-Single-Leg-Deadlift-with-Knee-Lift_Hips_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Scissors (advanced)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35861201-Scissors-(advanced)-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35861201-Scissors-(advanced)-(male)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Con lastre unilateral leg lift',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35871201-Weighted-Single-Leg-Lift_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/35871201-Weighted-Single-Leg-Lift_Thighs_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Z',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36441201-Weighted-Lunge-with-Swing_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36441201-Weighted-Lunge-with-Swing_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36631201-Reverse-Plank-with-Leg-Lift_Hips_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36631201-Reverse-Plank-with-Leg-Lift_Hips_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36701201-Weighted-Decline-Sit-up_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36701201-Weighted-Decline-Sit-up_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36821201-Dumbbell-Incline-Alternate-Bicep-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36821201-Dumbbell-Incline-Alternate-Bicep-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancada con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36831201-Dumbbell-Gobelt-Curtsey-Lunge_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36831201-Dumbbell-Gobelt-Curtsey-Lunge_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación lateral con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36851201-Dumbbell-Chest-Supported-Lateral-Raises_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36851201-Dumbbell-Chest-Supported-Lateral-Raises_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Isométrico con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36861201-Dumbbell-Kneeling-Hold-to-Stand_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36861201-Dumbbell-Kneeling-Hold-to-Stand_Thighs_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36941201-Dumbbell-Incline-Alternate-Reverse-Fly_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36941201-Dumbbell-Incline-Alternate-Reverse-Fly_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36951201-Dumbbell-Alternate-Bench-Press-(high-start)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/36951201-Dumbbell-Alternate-Bench-Press-(high-start)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37131201-Dumbbell-Standing-Single-Leg-Calf-Raise_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37131201-Dumbbell-Standing-Single-Leg-Calf-Raise_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37181201-Split-Lateral-Squat-with-Roll_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37181201-Split-Lateral-Squat-with-Roll_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancada con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37231201-Barbell-Curtsey-Lunge_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37231201-Barbell-Curtsey-Lunge_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de pecho con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37241201-Barbell-Floor-Chest-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37241201-Barbell-Floor-Chest-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancada con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37251201-Barbell-Overhead-Lunge_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37251201-Barbell-Overhead-Lunge_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación frontal con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37261201-Barbell-Seated-Front-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37261201-Barbell-Seated-Front-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37271201-Barbell-Front-Bench-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37271201-Barbell-Front-Bench-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de pecho con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37291201-Barbell-Chest-Press-on-Stability-Ball_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37291201-Barbell-Chest-Press-on-Stability-Ball_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación lateral con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37401201-Kettlebell-Lateral-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37401201-Kettlebell-Lateral-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación lateral',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37411201-Lateral-Raise-with-Towel_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37411201-Lateral-Raise-with-Towel_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37841201-Cross-Arms-Push-up_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/37841201-Cross-Arms-Push-up_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/38681201-Cable-Fly-with-Chest-Supported_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/38681201-Cable-Fly-with-Chest-Supported_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/38691201-Cable-Seated-Chest-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/38691201-Cable-Seated-Chest-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación lateral con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/38791201-Dumbbell-Poliquin-Lateral-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/38791201-Dumbbell-Poliquin-Lateral-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/38841201-Jack-knife-Sit-up-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/38841201-Jack-knife-Sit-up-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Colgado toes to bar',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/38911201-Hanging-Toes-to-Bar_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/38911201-Hanging-Toes-to-Bar_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39111201-Dumbbell-Low-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39111201-Dumbbell-Low-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación lateral con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39121201-Cable-Bent-Over-One-Arm-Lateral-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39121201-Cable-Bent-Over-One-Arm-Lateral-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación frontal con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39131201-Dumbbell-One-Arm-Front-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39131201-Dumbbell-One-Arm-Front-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39141201-Cable-Rear-Delt-Row_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39141201-Cable-Rear-Delt-Row_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancada con landmine',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39191201-Landmine-Rear-Lunge_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39191201-Landmine-Rear-Lunge_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Jalón de tríceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39201201-Cable-Triceps-Pushdown-on-Floor_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39201201-Cable-Triceps-Pushdown-on-Floor_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De rodillas apretón press con landmine',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39211201-Landmine-Kneeling-Squeeze-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39211201-Landmine-Kneeling-Squeeze-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con landmine',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39231201-Landmine-Floor-One-Arm-Chest-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39231201-Landmine-Floor-One-Arm-Chest-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39441201-Seated-Alternate-Crunch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39441201-Seated-Alternate-Crunch_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39471201-Hands-Release-Push-up-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39471201-Hands-Release-Push-up-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Windmill con peso corporal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39491201-Bodyweight-Windmill-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39491201-Bodyweight-Windmill-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Z',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39661201-Static-Lunge-Kick_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39661201-Static-Lunge-Kick_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39811201-Finger-Push-up_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39811201-Finger-Push-up_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39831201-One-Arm-Front-Plank_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39831201-One-Arm-Front-Plank_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación frontal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39891201-EZ-bar-Incline-Front-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39891201-EZ-bar-Incline-Front-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de hombros',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39901201-EZ-bar-Seated-Close-grip-Shoulder-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/39901201-EZ-bar-Seated-Close-grip-Shoulder-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de hombros con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40101201-Cable-Kneeling-Shoulder-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40101201-Cable-Kneeling-Shoulder-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación lateral con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40131201-Cable-Lying-Cross-Lateral-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40131201-Cable-Lying-Cross-Lateral-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación frontal con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40141201-Cable-Standing-Front-Raise-Variation_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40141201-Cable-Standing-Front-Raise-Variation_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dead bug con stability fitball',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40561201-Dead-Bug-with-Stability-Ball_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40561201-Dead-Bug-with-Stability-Ball_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40601201-Bird-Dog-Push-Up_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40601201-Bird-Dog-Push-Up_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con banda elástica',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40631201-Band-Biceps-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40631201-Band-Biceps-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40701201-Barbell-Bench-Press-with-1-board_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40701201-Barbell-Bench-Press-with-1-board_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'R',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40931201-Wheel-Rollout-with-Wall-Support-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40931201-Wheel-Rollout-with-Wall-Support-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40951201-Crunch-with-Leg-Lift-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/40951201-Crunch-with-Leg-Lift-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41001201-Sled-Wide-Hack-Squat-(male)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41001201-Sled-Wide-Hack-Squat-(male)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De pie arnold press con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41081201-Dumbbell-Standing-Arnold-Press-(male)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41081201-Dumbbell-Standing-Arnold-Press-(male)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41151201-Cable-Overhead-Tricep-Extension-Straight-Bar-(male)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41151201-Cable-Overhead-Tricep-Extension-Straight-Bar-(male)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Con lastre dead bug',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41271201-Weighted-Dead-Bug-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41271201-Weighted-Dead-Bug-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41281201-Weighted-Counterbalanced-Squat-(male)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41281201-Weighted-Counterbalanced-Squat-(male)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con banda elástica',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41371201-Band-Squat-Twist_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41371201-Band-Squat-Twist_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'A',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41721201-Bodyweight-Bent-Over-Rear-Delt-Fly_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41721201-Bodyweight-Bent-Over-Rear-Delt-Fly_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press sentado cuban con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41831201-Dumbbell-Seated-Cuban-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41831201-Dumbbell-Seated-Cuban-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'R',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41891201-EZ-Bar-Knelling-Rollout_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41891201-EZ-Bar-Knelling-Rollout_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Resistance banda elástica half de rodillas face jalón',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41951201-Resistance-Band-Half-Kneeling-Face-Pull_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/41951201-Resistance-Band-Half-Kneeling-Face-Pull_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/42181201-Safety-Bar-Front-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/42181201-Safety-Bar-Front-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press sentado con agarre cerrado con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/42371201-Dumbbell-Seated-Close-Grip-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/42371201-Dumbbell-Seated-Close-Grip-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Resistance banda elástica horizontal pallof press',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/42401201-Resistance-Band-Horizontal-Pallof-Press_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/42401201-Resistance-Band-Horizontal-Pallof-Press_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con landmine',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/42461201-Landmine-Front-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/42461201-Landmine-Front-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De pie air bike',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/42751201-Standing-Air-Bike-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/42751201-Standing-Air-Bike-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43331201-Bench-Reverse-Crunch-Circle_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43331201-Bench-Reverse-Crunch-Circle_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43361201-Lever-Biceps-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43361201-Lever-Biceps-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43371201-Dumbbell-Hammer-Preacher-Curl-(female)_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43371201-Dumbbell-Hammer-Preacher-Curl-(female)_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación frontal con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43411201-Dumbbell-Alternate-Front-Raise-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43411201-Dumbbell-Alternate-Front-Raise-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press militar',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43461201-Bodyweight-Standing-Military-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43461201-Bodyweight-Standing-Military-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43541201-Alternate-Oblique-Crunch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43541201-Alternate-Oblique-Crunch_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Horizontal pallof press con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43561201-Cable-horizontal-Pallof-Press-(VERSION-2)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43561201-Cable-horizontal-Pallof-Press-(VERSION-2)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos con máquina smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43701201-Smith-Seated-Calf-Raise_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43701201-Smith-Seated-Calf-Raise_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Around head rotation con balón medicinal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43751201-Medicine-Ball-Around-Head-Rotation_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43751201-Medicine-Ball-Around-Head-Rotation_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Handstand walk',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43761201-Handstand-Walk_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43761201-Handstand-Walk_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Ejercicio de agarre y mano para mejorar la fuerza de prensión.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43841201-Body-Saw-Plank_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43841201-Body-Saw-Plank_Shoulders_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de piernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43861201-Leg-Extension-Plank_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/43861201-Leg-Extension-Plank_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44081201-Kettlebell-Upright-Row_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44081201-Kettlebell-Upright-Row_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Step-up con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44401201-Kettlebell-Step-up-(VERSION-2)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44401201-Kettlebell-Step-up-(VERSION-2)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44561201-Glute-Ham-Raise-(VERSION-2)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44561201-Glute-Ham-Raise-(VERSION-2)_Thighs_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tumbado ab press',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44591201-Lying-Ab-Press-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44591201-Lying-Ab-Press-(male)_Waist_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll fitball foot',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44621201-Roll-Ball-Foot_Feet_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44621201-Roll-Ball-Foot_Feet_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo de pie y tobillo para reforzar la estabilidad distal.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll fitball tibialis posterior',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44671201-Roll-Ball-Tibialis-Posterior_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44671201-Roll-Ball-Tibialis-Posterior_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll fitball pectoralis major sternal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44831201-Roll-Ball-Pectoralis-Major---Sternal_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44831201-Roll-Ball-Pectoralis-Major---Sternal_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll fitball antebrazo extensors',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44961201-Roll-Ball-Forearm-Extensors_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44961201-Roll-Ball-Forearm-Extensors_Forearms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo específico de antebrazo y agarre para reforzar la muñeca y la prensión.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll fitball bíceps brachii',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44981201-Roll-Ball-Bicep-Brachii_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/44981201-Roll-Ball-Bicep-Brachii_Upper-Arms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Windmill con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45191201-Kettlebell-Windmill-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45191201-Kettlebell-Windmill-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De pie slingshots con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45341201-Kettlebell-Standing-Slingshots-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45341201-Kettlebell-Standing-Slingshots-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Diamond press',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45391201-Diamond-Press_Back_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45391201-Diamond-Press_Back_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45551201-Dynamic-90-90-Hip-Twist_Stretching_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45551201-Dynamic-90-90-Hip-Twist_Stretching_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Resistance banda elástica jalón apart',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45681201-Resistance-Band-Pull-Apart_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45681201-Resistance-Band-Pull-Apart_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Half de rodillas lift and chop con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45721201-Dumbbell-Half-Kneeling-Lift-and-Chop_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45721201-Dumbbell-Half-Kneeling-Lift-and-Chop_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Half de rodillas chop con banda elástica',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45731201-Band-Half-Kneeling-Chop_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45731201-Band-Half-Kneeling-Chop_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press militar con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45771201-Dumbbell-Half-Kneeling-Military-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/45771201-Dumbbell-Half-Kneeling-Military-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Plancha con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/46221201-Dumbbell-Front-Plank-Arm-Raise_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/46221201-Dumbbell-Front-Plank-Arm-Raise_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/46231201-Weighted-Seated-Tuck-Crunch-on-Floor_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/46231201-Weighted-Seated-Tuck-Crunch-on-Floor_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de piernas con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/46271201-Dumbbell-Front-Plank-Arm-Leg-Raise_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/46271201-Dumbbell-Front-Plank-Arm-Leg-Raise_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Jalón de tríceps',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/46881201-Resistance-Band-Triceps-Pushdown_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/46881201-Resistance-Band-Triceps-Pushdown_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'D',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47261201-Commando-Pull-up_Back_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47261201-Commando-Pull-up_Back_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de tracción para desarrollar la espalda y mejorar la postura.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sit-up con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47351201-Dumbbell-Decline-Sit-up_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47351201-Dumbbell-Decline-Sit-up_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47361201-Dumbbell-Deep-Push-up-and-Renegade-Row_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47361201-Dumbbell-Deep-Push-up-and-Renegade-Row_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Bajo windmill con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47461201-Dumbbell-Low-Windmill_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47461201-Dumbbell-Low-Windmill_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sit-up con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47481201-Dumbbell-Overhead-Sit-up_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47481201-Dumbbell-Overhead-Sit-up_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Suspender alterno superman',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47981201-Suspender-Alternate-Superman_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47981201-Suspender-Alternate-Superman_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de tracción para desarrollar la espalda y mejorar la postura.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'R',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47991201-Suspender-Rollout-(VERSION-2)-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/47991201-Suspender-Rollout-(VERSION-2)-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De pie side bend',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48101201-Standing-Side-Bend-(VERSION-2)-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48101201-Standing-Side-Bend-(VERSION-2)-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48111201-Side-Plank-(VERSION-2)-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48111201-Side-Plank-(VERSION-2)-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Rollout con anillas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48201201-Ring-Reverse-Ab-Rollout_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48201201-Ring-Reverse-Ab-Rollout_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48301201-Push-up-in-Child-Pose_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48301201-Push-up-in-Child-Pose_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación lateral',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48321201-Lying-Rear-Lateral-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48321201-Lying-Rear-Lateral-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48381201-Cable-Unilateral-Bicep-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48381201-Cable-Unilateral-Bicep-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de pecho con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48451201-Kettlebell-Lying-on-Floor-Chest-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48451201-Kettlebell-Lying-on-Floor-Chest-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48481201-Barbell-Pin-Front-Squat_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48481201-Barbell-Pin-Front-Squat_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press Z con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48661201-Barbell-Z-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48661201-Barbell-Z-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prayer push',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48761201-Prayer-Push-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48761201-Prayer-Push-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48861201-Lying-Flat-Hip-Raise-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48861201-Lying-Flat-Hip-Raise-(female)_Waist_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Colgado half windmill',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48911201-Hanging-Half-Windmill_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/48911201-Hanging-Half-Windmill_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con anillas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49221201-Ring-Chest-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49221201-Ring-Chest-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49291201-Lying-Calf-Stretch-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49291201-Lying-Calf-Stretch-(female)_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49311201-Single-Leg-Calve-Stretch-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49311201-Single-Leg-Calve-Stretch-(female)_Calves_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tumbado around the world',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49431201-Lying-Around-the-World-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49431201-Lying-Around-the-World-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'I',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49451201-Chest-Out-Hands-Behind-(Hold)-(female)_Stretching_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49451201-Chest-Out-Hands-Behind-(Hold)-(female)_Stretching_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentado pecho clam',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49461201-Seated-Chest-Clam_Stretching_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49461201-Seated-Chest-Clam_Stretching_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentado sky look',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49471201-Seated-Sky-Look_Stretching_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49471201-Seated-Sky-Look_Stretching_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49601201-Cable-High-Triceps-Extension_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49601201-Cable-High-Triceps-Extension_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'En prono tríceps kickback con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49611201-Dumbbell-Prone-Triceps-Kickback_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49611201-Dumbbell-Prone-Triceps-Kickback_Upper-Arms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de piernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49751201-Lying-Leg-Raise-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49751201-Lying-Leg-Raise-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Negative dragon flag',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49821201-Negative-Dragon-Flag_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49821201-Negative-Dragon-Flag_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49841201-Kneeling-Modified-Hindu-Push-up-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49841201-Kneeling-Modified-Hindu-Push-up-(male)_Waist_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'V sit cruzado punch',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49891201-V-Sit-Cross-Punch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49891201-V-Sit-Cross-Punch_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49901201-Knee-Tuck-Oblique-Crunch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49901201-Knee-Tuck-Oblique-Crunch_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49921201-Opposite-Crunch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49921201-Opposite-Crunch_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tumbado leg cruzado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49941201-Lying-Leg-Cross_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49941201-Lying-Leg-Cross_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49961201-Kneeling-Plank-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/49961201-Kneeling-Plank-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50001201-Straight-Leg-Sit-Up-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50001201-Straight-Leg-Sit-Up-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50091201-Elevated-Standing-Calf-Raise_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50091201-Elevated-Standing-Calf-Raise_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50101201-Barbell-Pause-Decline-Bench-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50101201-Barbell-Pause-Decline-Bench-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50111201-Barbell-Pause-Incline-Bench-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50111201-Barbell-Pause-Incline-Bench-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50131201-Barbell-Pause-Bench-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50131201-Barbell-Pause-Bench-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50301201-Push-Up-Jack_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50301201-Push-Up-Jack_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de piernas con balón medicinal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50311201-Medicine-Ball-Lying-Leg-Raise_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50311201-Medicine-Ball-Lying-Leg-Raise_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50321201-Leg-Raise-Oblique-Crunch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50321201-Leg-Raise-Oblique-Crunch_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50451201-Reverse-Plank-on-Elbows_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50451201-Reverse-Plank-on-Elbows_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'V sit toe tap',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50461201-V-Sit-Toe-Tap_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50461201-V-Sit-Toe-Tap_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50511201-Glute-Ham-Twist_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50511201-Glute-Ham-Twist_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50521201-Single-Leg-Calf-Raise-Off-Step_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50521201-Single-Leg-Calf-Raise-Off-Step_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50601201-Prone-Cervical-Extension_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50601201-Prone-Cervical-Extension_Neck_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'I',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50611201-Prone-Cervical-Extension-Isometric-Hold_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50611201-Prone-Cervical-Extension-Isometric-Hold_Neck_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tumbado chin tucks',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50621201-Lying-Chin-Tucks_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50621201-Lying-Chin-Tucks_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentado chin tuck',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50631201-Seated-Chin-Tuck_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50631201-Seated-Chin-Tuck_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Inclinado apretón press con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50671201-Dumbbell-Incline-Squeeze-Press_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50671201-Dumbbell-Incline-Squeeze-Press_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sit-up con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50721201-Kettlebell-Sit-Up-Press_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50721201-Kettlebell-Sit-Up-Press_Waist_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press con landmine',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50741201-Landmine-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50741201-Landmine-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press svend',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50771201-Bodyweight-Svend-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50771201-Bodyweight-Svend-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'A',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50791201-Lying-Floor-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50791201-Lying-Floor-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Palm up palm down rotation',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50801201-Palm-up---Palm-down-Rotation-(male)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50801201-Palm-up---Palm-down-Rotation-(male)_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Leg frontal kick',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50821201-Leg-Front-Kick-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50821201-Leg-Front-Kick-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de cadena posterior para potenciar glúteos y cadera.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50851201-Standing-Ab-Twist-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50851201-Standing-Ab-Twist-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Hombro internal rotation con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50881201-Cable-Shoulder-Internal-Rotation_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50881201-Cable-Shoulder-Internal-Rotation_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50911201-Barbell-Reverse-Grip-Bench-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50911201-Barbell-Reverse-Grip-Bench-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press en el suelo con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50931201-Dumbbell-Single-Arm-Floor-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50931201-Dumbbell-Single-Arm-Floor-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Unilateral arm press con landmine',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50941201-Landmine-Single-Arm-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50941201-Landmine-Single-Arm-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50981201-Dumbbell-Single-Arm-Alternate-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/50981201-Dumbbell-Single-Arm-Alternate-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51081201-Dumbbell-Wood-Chop-Squat_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51081201-Dumbbell-Wood-Chop-Squat_Waist_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'F',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51101201-Triceps-Dip-Floor-(female)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51101201-Triceps-Dip-Floor-(female)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51261201-Standing-Ab-Twist-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51261201-Standing-Ab-Twist-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentado superior body rotation',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51291201-Seated-Upper-Body-Rotation-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51291201-Seated-Upper-Body-Rotation-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51301201-Seated-Back-Twist-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51301201-Seated-Back-Twist-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentado ballerina',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51341201-Seated-Ballerina-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51341201-Seated-Ballerina-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Pecho pass against pared con balón medicinal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51441201-Medicine-Ball-Chest-Pass-against-Wall_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51441201-Medicine-Ball-Chest-Pass-against-Wall_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Posterior cuello isometric',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51451201-Posterior-Neck-Isometric_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51451201-Posterior-Neck-Isometric_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51511201-Kipping-Handstand-Push-Up_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51511201-Kipping-Handstand-Push-Up_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'avanzado',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51541201-Lateral-Step-Up_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51541201-Lateral-Step-Up_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51551201-Lateral-Step-Up-with-Knee-Drive_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51551201-Lateral-Step-Up-with-Knee-Drive_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51581201-Plank-Jack-Slide-with-Towel_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51581201-Plank-Jack-Slide-with-Towel_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51591201-Plank-on-Hands_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51591201-Plank-on-Hands_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51601201-Incline-Close-Grip-Push-Up_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51601201-Incline-Close-Grip-Push-Up_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo con balón medicinal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51611201-Medicine-Ball-Throw-Squat-with-Wall_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51611201-Medicine-Ball-Throw-Squat-with-Wall_Shoulders_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51621201-Seated-Neck-Stretch_Stretching_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51621201-Seated-Neck-Stretch_Stretching_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Arm crossover',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51721201-Arm-Crossover-(male)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51721201-Arm-Crossover-(male)_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'A',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51731201-Bodyweight-Standing-Fly-(male)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51731201-Bodyweight-Standing-Fly-(male)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Pared pulse',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51741201-Wall-Pulse-(male)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51741201-Wall-Pulse-(male)_Upper-Arms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de piernas con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51781201-Lever-Single-Leg-Extension-(plate-loaded)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/51781201-Lever-Single-Leg-Extension-(plate-loaded)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52011201-Dumbbell-Waiter-Biceps-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52011201-Dumbbell-Waiter-Biceps-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de hombros',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52051201-Resistance-Band-Overhead-Shoulder-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52051201-Resistance-Band-Overhead-Shoulder-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con balón medicinal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52381201-Medicine-Ball-Lunge-with-Biceps-Curl_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52381201-Medicine-Ball-Lunge-with-Biceps-Curl_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52401201-EZ-bar-Deadlift-with-Biceps-Curl_Hips_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52401201-EZ-bar-Deadlift-with-Biceps-Curl_Hips_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52411201-Old-School-Reverse-Extensions_Upeer-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52411201-Old-School-Reverse-Extensions_Upeer-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De rodillas abdominal draw in',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52421201-Kneeling-Abdominal-Draw-In_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52421201-Kneeling-Abdominal-Draw-In_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52431201-Cable-Lying-Triceps-Extension-(Low)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52431201-Cable-Lying-Triceps-Extension-(Low)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52501201-Lying-Bicycle-Crunch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52501201-Lying-Bicycle-Crunch_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52631201-Old-School-Reverse-Extensions-(female)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52631201-Old-School-Reverse-Extensions-(female)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Negative dragon flag',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52641201-Negative-Dragon-Flag-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52641201-Negative-Dragon-Flag-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52651201-45-degree-Bycicle-Twisting-Crunch-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52651201-45-degree-Bycicle-Twisting-Crunch-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52661201-Air-Twisting-Crunch-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52661201-Air-Twisting-Crunch-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'D',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52701201-Commando-Pull-up-(female)_Back_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52701201-Commando-Pull-up-(female)_Back_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de tracción para desarrollar la espalda y mejorar la postura.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tumbado toe touch',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52751201-Lying-Toe-Touch_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52751201-Lying-Toe-Touch_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52781201-Kneeling-Staggered-Push-up-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52781201-Kneeling-Staggered-Push-up-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de pecho con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52841201-Dumbbell-Sprinter-Thrust-Chest-Press_Hips_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52841201-Dumbbell-Sprinter-Thrust-Chest-Press_Hips_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52981201-Dumbbell-Preacher-Curl-(Turned-Torso)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52981201-Dumbbell-Preacher-Curl-(Turned-Torso)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52991201-Lever-Preacher-Curl-(Turned-Torso)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/52991201-Lever-Preacher-Curl-(Turned-Torso)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53321201-Svend-Bench-Press_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53321201-Svend-Bench-Press_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Trunk rotation con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53331201-Lever-Trunk-Rotation_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53331201-Lever-Trunk-Rotation_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de tracción para desarrollar la espalda y mejorar la postura.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll cuello rotation tumbado en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53711201-Roll-Neck-Rotation-Lying-on-Floor_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53711201-Roll-Neck-Rotation-Lying-on-Floor_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll cuello decompress tumbado en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53721201-Roll-Neck-Decompress-Lying-on-Floor_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53721201-Roll-Neck-Decompress-Lying-on-Floor_Neck_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll antebrazos de pie against pared',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53731201-Roll-Forearms-Standing-Against-Wall_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53731201-Roll-Forearms-Standing-Against-Wall_Forearms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo específico de antebrazo y agarre para reforzar la muñeca y la prensión.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll bíceps tumbado en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53741201-Roll-Biceps-Lying-on-Floor_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53741201-Roll-Biceps-Lying-on-Floor_Upper-Arms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll tríceps side tumbado en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53751201-Roll-Triceps-Side-Lying-on-Floor_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53751201-Roll-Triceps-Side-Lying-on-Floor_Upper-Arms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll pecho opener tumbado en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53761201-Roll-Chest-Opener-Lying-on-Floor_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53761201-Roll-Chest-Opener-Lying-on-Floor_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Stick assisted isometric core',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53991201-Stick-Assisted-Isometric-Core-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/53991201-Stick-Assisted-Isometric-Core-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54011201-Stick-Shoulders-Stretch-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54011201-Stick-Shoulders-Stretch-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54031201-Stick-Standing-Twist-Stretch-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54031201-Stick-Standing-Twist-Stretch-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54041201-Stick-Pass-Around-Stretch-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54041201-Stick-Pass-Around-Stretch-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54051201-Stick-Side-Bend-Stretch-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54051201-Stick-Side-Bend-Stretch-(female)_Waist_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54061201-Stick-Side-to-Front-Bend-Stretch-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54061201-Stick-Side-to-Front-Bend-Stretch-(female)_Waist_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'principiante',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll cuello rotation tumbado en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54101201-Roll-Neck-Rotation-Lying-on-Floor-(female)_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54101201-Roll-Neck-Rotation-Lying-on-Floor-(female)_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll cuello decompress tumbado en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54111201-Roll-Neck-Decompress-Lying-on-Floor-(female)_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54111201-Roll-Neck-Decompress-Lying-on-Floor-(female)_Neck_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll bíceps tumbado en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54131201-Roll-Biceps-Lying-on-Floor-(female)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54131201-Roll-Biceps-Lying-on-Floor-(female)_Upper-Arms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll pecho opener tumbado en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54151201-Roll-Chest-Opener-Lying-on-Floor-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54151201-Roll-Chest-Opener-Lying-on-Floor-(female)_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll pecho tumbado en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54161201-Roll-Chest-Lying-on-Floor-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54161201-Roll-Chest-Lying-on-Floor-(female)_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll hamstrings sitting en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54311201-Roll-Hamstrings-Sitting-on-Floor-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54311201-Roll-Hamstrings-Sitting-on-Floor-(female)_Thighs_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll tibialis anterior',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54361201-Roll-Tibialis-Anterior-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54361201-Roll-Tibialis-Anterior-(female)_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll gemelos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54381201-Roll-Calves-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54381201-Roll-Calves-(female)_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll gemelos (single leg)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54391201-Roll-Calves-(Single-Leg)-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54391201-Roll-Calves-(Single-Leg)-(female)_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll peroneal side tumbado en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54401201-Roll-Peroneal-Side-Lying-on-Floor-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54401201-Roll-Peroneal-Side-Lying-on-Floor-(female)_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Roll foot',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54421201-Roll-Foot-(female)_Feet_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54421201-Roll-Foot-(female)_Feet_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo de pie y tobillo para reforzar la estabilidad distal.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De pie abdominal vacuum',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54451201-Standing-Abdominal-Vacuum-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54451201-Standing-Abdominal-Vacuum-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'EZ bar 21s',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54501201-EZ-bar-21s_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54501201-EZ-bar-21s_Upper-Arms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Plancha con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54971201-Dumbbell-Plank-Pass-Through_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/54971201-Dumbbell-Plank-Pass-Through_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Fondos en banco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/55131201-Bench-Dip-on-Stability-Ball_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/55131201-Bench-Dip-on-Stability-Ball_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/55141201-Twist-Crunch-(Legs-Up)-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/55141201-Twist-Crunch-(Legs-Up)-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De pie una arm face jalón con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/55241201-Cable-Standing-One-Arm-Face-Pull_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/55241201-Cable-Standing-One-Arm-Face-Pull_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Hip circle con hula hoop',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/55261201-Hip-Circle-with-Hula-Hoop_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/55261201-Hip-Circle-with-Hula-Hoop_Waist_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Movimiento de cadena posterior para potenciar glúteos y cadera.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de pecho con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/55761201-Lever-One-Arm-Incline-Chest-Press-(plate-loaded)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/55761201-Lever-One-Arm-Incline-Chest-Press-(plate-loaded)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Face jalón con banda elástica',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/56071201-Band-Face-Pull-(male)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/56071201-Band-Face-Pull-(male)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De pie face jalón con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/56091201-Cable-Standing-Face-Pull_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/56091201-Cable-Standing-Face-Pull_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Hollow rock',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/56491201-Hollow-Rock-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/56491201-Hollow-Rock-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de pecho con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/56601201-Barbell-Pin-Chest-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/56601201-Barbell-Pin-Chest-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/57001201-Bodyweight-Walking-Calf-Raise_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/57001201-Bodyweight-Walking-Calf-Raise_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de pecho con suspensión',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/57381201-Suspension-Chest-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/57381201-Suspension-Chest-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/57411201-Cable-Kneeling-Crunch-(VERSION-2)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/57411201-Cable-Kneeling-Crunch-(VERSION-2)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Empty can ejercicio con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/58191201-Dumbbell-Empty-Can-Exercise-(male)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/58191201-Dumbbell-Empty-Can-Exercise-(male)_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/59161201-Cable-Seated-High-Pulley-Overhead-Tricep-Extension_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/59161201-Cable-Seated-High-Pulley-Overhead-Tricep-Extension_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/59211201-Dumbbell-Hammer-Preacher-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/59211201-Dumbbell-Hammer-Preacher-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/59371201-Half-Squat-Side-Reach-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/59371201-Half-Squat-Side-Reach-(female)_Waist_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/59631201-Vertical-Sit-Up-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/59631201-Vertical-Sit-Up-(male)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/59971201-Lay-Down-Push-Up-(male)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/59971201-Lay-Down-Push-Up-(male)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60041201-Lying-Crunch-(straight-legs)-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60041201-Lying-Crunch-(straight-legs)-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60051201-Lying-Crunch-(straight-legs)-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60051201-Lying-Crunch-(straight-legs)-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60061201-Half-Squat-Side-Reach-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60061201-Half-Squat-Side-Reach-(male)_Waist_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60161201-Twisting-Crunch-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60161201-Twisting-Crunch-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60261201-Side-Plank-Pull-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60261201-Side-Plank-Pull-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60291201-Lay-Down-Push-Up-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60291201-Lay-Down-Push-Up-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Jalón in (on stability ball)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60301201-Pull-In-(on-stability-ball)-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60301201-Pull-In-(on-stability-ball)-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Ab tuck',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60331201-Ab-Tuck-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60331201-Ab-Tuck-(male)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60351201-Cable-Rear-Delt-Row-(parallel-bar)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60351201-Cable-Rear-Delt-Row-(parallel-bar)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60521201-Bottle-Weighted-Overhead-Crunch-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60521201-Bottle-Weighted-Overhead-Crunch-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60531201-Bottle-Weighted-Frog-Crunch-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60531201-Bottle-Weighted-Frog-Crunch-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Bottle con lastre side bend',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60541201-Bottle-Weighted-Side-Bend-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60541201-Bottle-Weighted-Side-Bend-(female)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60551201-Bottle-Weighted-Russian-Twist-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60551201-Bottle-Weighted-Russian-Twist-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de pecho',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60571201-Bottle-Weighted-Lying-Chest-Press-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60571201-Bottle-Weighted-Lying-Chest-Press-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press svend',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60581201-Bottle-Weighted-Svend-Press-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60581201-Bottle-Weighted-Svend-Press-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl inverso',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60701201-Bottle-Weighted-Reverse-Curl-(female)_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60701201-Bottle-Weighted-Reverse-Curl-(female)_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'R',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60711201-Bottle-Weighted-Upright-Row-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60711201-Bottle-Weighted-Upright-Row-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'R',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60721201-Bottle-Weighted-Armpit-Row-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60721201-Bottle-Weighted-Armpit-Row-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de tracción para desarrollar la espalda y mejorar la postura.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación frontal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60731201-Bottle-Weighted-Front-Raise-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60731201-Bottle-Weighted-Front-Raise-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación lateral',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60741201-Bottle-Weighted-Lateral-Raise-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60741201-Bottle-Weighted-Lateral-Raise-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de hombros',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60761201-Bottle-Weighted-Shoulder-Press-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60761201-Bottle-Weighted-Shoulder-Press-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Bottle con lastre halo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60771201-Bottle-Weighted-Halo-(female)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60771201-Bottle-Weighted-Halo-(female)_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60931201-Side-Plank-Pull-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/60931201-Side-Plank-Pull-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/61391201-Squat-Mobility-Twist-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/61391201-Squat-Mobility-Twist-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De pie driver con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/61411201-Dumbbell-Standing-Driver-(male)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/61411201-Dumbbell-Standing-Driver-(male)_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/61441201-Dumbbell-Straight-Arm-Crunch-(VERSION-2)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/61441201-Dumbbell-Straight-Arm-Crunch-(VERSION-2)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Alterno hammer srtict curl con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/61471201-Dumbbell-Alternate-Hammer-Srtict-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/61471201-Dumbbell-Alternate-Hammer-Srtict-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentado drag curl con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/61491201-Dumbbell-Seated-Drag-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/61491201-Dumbbell-Seated-Drag-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/61621201-Dumbbell-Incline-Low-Fly_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/61621201-Dumbbell-Incline-Low-Fly_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl predicador con barra EZ',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/64061201-EZ-Barbell-Preacher-Curl_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/64061201-EZ-Barbell-Preacher-Curl_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  '90 degree heel touch',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/64281201-90-Degree-Heel-Touch-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/64281201-90-Degree-Heel-Touch-(male)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/65841201-Barbell-Feet-Flat-Bench-Press-(male)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/65841201-Barbell-Feet-Flat-Bench-Press-(male)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/66931201-Cable-Kneeling-Side-Crunch-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/66931201-Cable-Kneeling-Side-Crunch-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos con kettlebell',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/66971201-Kettlebell-Standing-Calf-Raise-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/66971201-Kettlebell-Standing-Calf-Raise-(female)_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentado foot eversion con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67451201-Cable-Seated-Foot-Eversion-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67451201-Cable-Seated-Foot-Eversion-(female)_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentado foot inversion con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67461201-Cable-Seated-Foot-Inversion-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67461201-Cable-Seated-Foot-Inversion-(female)_Calves_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De rodillas unilateral hamstring curl',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67481201-Kneeling-Single-Hamstring-Curl-(female)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67481201-Kneeling-Single-Hamstring-Curl-(female)_Thighs_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tumbado scalene muscles activation',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67531201-Lying-Scalene-Muscles-Activation-(female)_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67531201-Lying-Scalene-Muscles-Activation-(female)_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'avanzado',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Over the banco supination con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67581201-Dumbbell-Over-the-Bench-Supination_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67581201-Dumbbell-Over-the-Bench-Supination_Forearms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Trabajo específico de antebrazo y agarre para reforzar la muñeca y la prensión.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press sentado tibialis anterior',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67591201-Seated-Tibialis-Anterior-Press-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67591201-Seated-Tibialis-Anterior-Press-(female)_Calves_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67601201-Cable-Kneeling-Twist-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67601201-Cable-Kneeling-Twist-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67651201-Neck-Stretch-with-Hand-Assisted-(female)_Neck_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67651201-Neck-Stretch-with-Hand-Assisted-(female)_Neck_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67721201-Standing-Peroneus-Muscles-Stretch-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67721201-Standing-Peroneus-Muscles-Stretch-(female)_Calves_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'avanzado',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en E.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Step-up con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67971201-Barbell-Bench-Lateral-Step-up-(male)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67971201-Barbell-Bench-Lateral-Step-up-(male)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tumbado oblique V up con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67991201-Dumbbell-Lying-Oblique-V-Up-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/67991201-Dumbbell-Lying-Oblique-V-Up-(male)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press militar con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68001201-Dumbbell-Military-Press-Russian-Twist-with-Legs-Floor-Off_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68001201-Dumbbell-Military-Press-Russian-Twist-with-Legs-Floor-Off_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press militar con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68011201-Dumbbell-Seated-Military-Press-In-Out-Leg-Raise-on-Floor_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68011201-Dumbbell-Seated-Military-Press-In-Out-Leg-Raise-on-Floor_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de piernas con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68021201-Dumbbell-Seated-Military-Hold-Alternate-Leg-Raise-on-Floor_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68021201-Dumbbell-Seated-Military-Hold-Alternate-Leg-Raise-on-Floor_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Side and frontal in out',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68031201-Side-and-Front-In-Out_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68031201-Side-and-Front-In-Out_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'D',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68041201-Plank-Alternate-Anti-Gravity-Pull-up_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68041201-Plank-Alternate-Anti-Gravity-Pull-up_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Alterno V up con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68051201-Dumbbell-Alternate-V-up_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68051201-Dumbbell-Alternate-V-up_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press militar con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68061201-Dumbbell-Military-Press-Russian-Twist-with-Legs-Floor-Off-(VERSION-2)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68061201-Dumbbell-Military-Press-Russian-Twist-with-Legs-Floor-Off-(VERSION-2)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sitting side step tuck en a padded stool',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68071201-Sitting-Side-Step-Tuck-on-a-padded-stool_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68071201-Sitting-Side-Step-Tuck-on-a-padded-stool_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sit-up con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68091201-Dumbbell-Overhead-Sit-up-with-Legs-on-Bench-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68091201-Dumbbell-Overhead-Sit-up-with-Legs-on-Bench-(male)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press Z con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68901201-Dumbbell-Z-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68901201-Dumbbell-Z-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press Z con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68911201-Dumbbell-Alternate-Z-Press_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/68911201-Dumbbell-Alternate-Z-Press_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Cow yoga pose bitilasana',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/69011201-Cow-Yoga-Pose-Bitilasana-(female)_Stretching_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/69011201-Cow-Yoga-Pose-Bitilasana-(female)_Stretching_.webp',
  ARRAY['Paso 1: Colócate en la posición inicial indicada por el estiramiento.', 'Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.', 'Paso 3: Mantén la postura unos segundos y respira de forma controlada.']::text[],
  'intermedio',
  'Estiramiento orientado a mejorar la movilidad y reducir la rigidez en Cow yoga pose bitilasana.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/69101201-Deep-Push-up-on-Parallel-Bars-(male)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/69101201-Deep-Push-up-on-Parallel-Bars-(male)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/69451201-Wrist-Push-up-(male)_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/69451201-Wrist-Push-up-(male)_Forearms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/69591201-Resistance-Band-Assisted-Push-up-(male)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/69591201-Resistance-Band-Assisted-Push-up-(male)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'De pie manos torsion con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/70541201-Dumbbell-Standing-Hands-Torsion-(male)_Forearms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/70541201-Dumbbell-Standing-Hands-Torsion-(male)_Forearms_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio de agarre y mano para mejorar la fuerza de prensión.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de piernas con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/71081201-Lever-Seated-Leg-Extension-(VERSION-2)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/71081201-Lever-Seated-Leg-Extension-(VERSION-2)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/71091201-Lever-Seated-Single-Leg-Squat-Calf-Raise-on-Leg-Press-Machine-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/71091201-Lever-Seated-Single-Leg-Squat-Calf-Raise-on-Leg-Press-Machine-(female)_Calves_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de gemelos con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/71761201-Lever-Seated-Calf-Press-(VERSION-2)-(male)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/71761201-Lever-Seated-Calf-Press-(VERSION-2)-(male)_Calves_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de gemelos con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/71771201-Lever-Seated-Single-Calf-Press-(female)_Calves_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/71771201-Lever-Seated-Single-Calf-Press-(female)_Calves_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de piernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/72011201-Resistance-Band-Lying-Leg-Raise-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/72011201-Resistance-Band-Lying-Leg-Raise-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/72101201-Resistance-Band-Plank-Jack-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/72101201-Resistance-Band-Plank-Jack-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Side tumbado internal rotation',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/72131201-Side-Lying-Internal-Rotation-(male)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/72131201-Side-Lying-Internal-Rotation-(male)_Shoulders_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/72311201-Dumbbell-Incline-Single-Arm-Y-Raise_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/72311201-Dumbbell-Incline-Single-Arm-Y-Raise_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Trap bar por encima de la cabeza press',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/72871201-Trap-Bar-Overhead-Press-(male)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/72871201-Trap-Bar-Overhead-Press-(male)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de piernas con máquina de palanca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/73271201-Lever-Leg-Extension-(Inward-Toes)-(male)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/73271201-Lever-Leg-Extension-(Inward-Toes)-(male)_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'P',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/73891201-Wall-Plank-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/73891201-Wall-Plank-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/74141201-Crunch-against-Wall-(female)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/74141201-Crunch-against-Wall-(female)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'principiante',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'F',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/74151201-Planche-Dip-on-Parallel-Bars-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/74151201-Planche-Dip-on-Parallel-Bars-(male)_Waist_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'avanzado',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Control corporal', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/74161201-Cable-Standing-Neutral-grip-Fly-(male)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/74161201-Cable-Standing-Neutral-grip-Fly-(male)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'S',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/74171201-Overhead-Sit-up-with-Legs-on-Bench-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/74171201-Overhead-Sit-up-with-Legs-on-Bench-(male)_Waist_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'E',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/75531201-Doorway-Chest-Stretch-(male)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/75531201-Doorway-Chest-Stretch-(male)_Chest_.webp',
  ARRAY['Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.', 'Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.', 'Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración.']::text[],
  'principiante',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Movilidad', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/75781201-Cable-Front-Squat-with-V-bar_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/75781201-Cable-Front-Squat-with-V-bar_Thighs_.webp',
  ARRAY['Paso 1: Sitúa los pies con la base estable y el abdomen firme.', 'Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.', 'Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil.']::text[],
  'intermedio',
  'Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giro de tronco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/75851201-Twist-Turn-Lift-(male)_Waist_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/75851201-Twist-Turn-Lift-(male)_Waist_.webp',
  ARRAY['Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.', 'Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.', 'Paso 3: Controla el regreso para no perder tensión en el core.']::text[],
  'intermedio',
  'Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación frontal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/75881201-Weighted-Front-Raise-Hold_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/75881201-Weighted-Front-Raise-Hold_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tumbado face jalón con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/75911201-Cable-Lying-Face-Pull-(male)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/75911201-Cable-Lying-Face-Pull-(male)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/76201201-Barbell-Banded-Bench-Press_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/76201201-Barbell-Banded-Bench-Press_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Bent over curl con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/76251201-Dumbbell-Bent-Over-Curl-(male)_Upper-Arms_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/76251201-Dumbbell-Bent-Over-Curl-(male)_Upper-Arms_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Half de rodillas face jalón con polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/77431201-Cable-Half-Kneeling-Face-Pull_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/77431201-Cable-Half-Kneeling-Face-Pull_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Nordic hamstring curl',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/77461201-Nordic-Hamstring-Curl-(male)_Thighs_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/77461201-Nordic-Hamstring-Curl-(male)_Thighs_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/77471201-Dumbbell-Prone-W-Raise-(male)_Shoulders_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/77471201-Dumbbell-Prone-W-Raise-(male)_Shoulders_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'principiante',
  'Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/79901201-Dumbbell-Squeeze-Bench-Press-(female)_Chest_.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/lyfta/79901201-Dumbbell-Squeeze-Bench-Press-(female)_Chest_.webp',
  ARRAY['Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.', 'Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.', 'Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio.']::text[],
  'intermedio',
  'Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl martillo con mancuernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_martillo_con_mancuernas.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_martillo_con_mancuernas.webp',
  ARRAY['Paso 1: Ponte de pie sosteniendo una mancuerna en cada mano con un agarre neutro (las palmas mirando hacia el torso) y los brazos extendidos.', 'Paso 2: Manteniendo los codos fijos a los lados del cuerpo, flexiona los codos para elevar las mancuernas hacia los hombros.', 'Paso 3: Sostén la máxima contracción en la parte superior durante un instante.', 'Paso 4: Desciende las mancuernas de manera lenta y controlada hasta la posición inicial.']::text[],
  'principiante',
  'Ejercicio de aislamiento para los flexores del codo que utiliza un agarre neutro para enfatizar el trabajo sobre el braquiorradial y el braquial anterior.',
  ARRAY['Hipertrofia', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps inverso con mancuernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_inverso_con_mancuernas.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_inverso_con_mancuernas.webp',
  ARRAY['Paso 1: De pie, sostén una mancuerna en cada mano con los brazos extendidos y las palmas mirando hacia adelante (agarre supino).', 'Paso 2: Inicia el movimiento flexionando los codos y levantando ambas mancuernas simultáneamente hacia los hombros sin balancear el torso.', 'Paso 3: Aprieta fuertemente los bíceps al alcanzar la flexión completa del codo.', 'Paso 4: Baja el peso lentamente resistiendo la gravedad hasta extender por completo los brazos.']::text[],
  'principiante',
  'Movimiento fundamental de flexión de codo con agarre supino que maximiza el reclutamiento y la hipertrofia del bíceps braquial.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps en polea baja con barra recta',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_en_polea_baja_con_barra_recta.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_en_polea_baja_con_barra_recta.webp',
  ARRAY['Paso 1: Engancha una barra recta a la polea baja de una máquina de cables.', 'Paso 2: Sujeta la barra con un agarre supino a la anchura de los hombros y da un paso atrás para generar tensión en el cable.', 'Paso 3: Flexiona los codos llevando la barra hacia la parte superior del pecho, manteniendo los codos pegados al cuerpo.', 'Paso 4: Desciende la barra controladamente hasta que los brazos estén estirados, sintiendo el estiramiento del bíceps.']::text[],
  'principiante',
  'Variante del curl clásico que utiliza un sistema de poleas para mantener una tensión mecánica constante sobre el bíceps durante todo el rango de movimiento.',
  ARRAY['Hipertrofia', 'Tensión continua']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl inverso en polea baja con barra recta',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_inverso_en_polea_baja_con_barra_recta.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_inverso_en_polea_baja_con_barra_recta.webp',
  ARRAY['Paso 1: Conecta una barra recta a la polea inferior y sujétala con un agarre prono (palmas hacia abajo).', 'Paso 2: Colócate de pie, erguido, con los brazos extendidos y el core contraído.', 'Paso 3: Eleva la barra flexionando los codos hasta que las manos lleguen a la altura de los hombros, manteniendo las muñecas firmes.', 'Paso 4: Retorna a la posición inicial extendiendo los codos a una velocidad controlada.']::text[],
  'intermedio',
  'Ejercicio de tensión continua que emplea un agarre prono para transferir el esfuerzo hacia los extensores de la muñeca y el braquiorradial.',
  ARRAY['Hipertrofia', 'Fuerza de agarre']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl martillo en polea baja con cuerda',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_martillo_en_polea_baja_con_cuerda.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_martillo_en_polea_baja_con_cuerda.webp',
  ARRAY['Paso 1: Fija el accesorio de cuerda en la polea más baja de la estación de cables.', 'Paso 2: Sujeta ambos extremos de la cuerda asegurando un agarre neutro y da un paso hacia atrás.', 'Paso 3: Tira de la cuerda hacia arriba dividiendo ligeramente los extremos al final de la fase concéntrica para mayor contracción.', 'Paso 4: Baja lentamente las manos hasta la extensión casi total de los codos.']::text[],
  'principiante',
  'Movimiento con agarre neutro en polea que permite mayor libertad en las muñecas y aporta una tensión uniforme en la porción lateral del brazo.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con barra EZ',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_barra_ez.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_barra_ez.webp',
  ARRAY['Paso 1: De pie, agarra una barra EZ por sus ondulaciones interiores con un agarre semisupinado (ligeramente inclinado).', 'Paso 2: Inicia con la barra apoyada cerca de los muslos, con el abdomen contraído y la espalda recta.', 'Paso 3: Flexiona los codos subiendo la barra hacia el pecho mientras mantienes la parte superior de los brazos estática.', 'Paso 4: Regresa la barra a la posición de descanso manteniendo la fase excéntrica lenta y controlada.']::text[],
  'principiante',
  'Clásico ejercicio de constructor de masa para el bíceps que utiliza una barra ondulada para reducir el estrés en las articulaciones de la muñeca y el codo.',
  ARRAY['Hipertrofia', 'Fuerza máxima']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl inverso con barra EZ',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_inverso_con_barra_ez.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_inverso_con_barra_ez.webp',
  ARRAY['Paso 1: Agarra la barra EZ por la parte exterior de sus curvas con un agarre prono (palmas mirando hacia tu cuerpo).', 'Paso 2: Mantén los codos pegados al cuerpo, los hombros deprimidos y retraídos, y el core activo.', 'Paso 3: Eleva el peso flexionando únicamente la articulación del codo, manteniendo las muñecas en una posición neutra y rígida.', 'Paso 4: Baja el peso en la fase excéntrica con control absoluto hasta la completa extensión.']::text[],
  'intermedio',
  'Variación del curl con barra ondulada utilizando agarre prono. Es altamente efectivo para desarrollar el músculo braquiorradial y mejorar la fuerza del antebrazo.',
  ARRAY['Hipertrofia', 'Fuerza de agarre']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl inverso con barra recta apoyado en banco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_inverso_con_barra_recta_apoyado_en_banco.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_inverso_con_barra_recta_apoyado_en_banco.webp',
  ARRAY['Paso 1: Ajusta un banco inclinado o predicador a la altura adecuada para estabilizar el torso o los brazos.', 'Paso 2: Sujeta la barra recta con un agarre prono (las palmas mirando hacia abajo) y mantén los brazos extendidos.', 'Paso 3: Flexiona los codos para elevar la barra hacia los hombros de manera controlada sin despegar los brazos del apoyo.', 'Paso 4: Desciende la barra lentamente hasta la posición inicial extendiendo los codos por completo.']::text[],
  'intermedio',
  'Ejercicio de aislamiento enfocado en el desarrollo de la musculatura braquiorradial y los extensores del antebrazo mediante flexión de codo con agarre prono, limitando el impulso con el apoyo corporal.',
  ARRAY['Hipertrofia', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con barra recta apoyado en banco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_barra_recta_apoyado_en_banco.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_barra_recta_apoyado_en_banco.webp',
  ARRAY['Paso 1: Colócate en un banco predicador ajustando la almohadilla bajo las axilas para apoyar firmemente la zona posterior del brazo (tríceps).', 'Paso 2: Toma la barra recta con un agarre supino (las palmas mirando hacia arriba).', 'Paso 3: Flexiona los codos de forma concéntrica para llevar la barra hacia tus hombros contrayendo el bíceps al máximo.', 'Paso 4: Baja la carga de forma excéntrica y controlada hasta la casi total extensión del codo para mantener la tensión muscular.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para hipertrofia del bíceps braquial mediante flexión de codo con agarre supino, utilizando un banco para estabilizar el cuerpo y aislar la carga mecánica en los flexores del brazo.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl inverso con barra recta de pie',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_inverso_con_barra_recta_de_pie.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_inverso_con_barra_recta_de_pie.webp',
  ARRAY['Paso 1: Ponte de pie con la espalda recta, los pies a la anchura de los hombros y el core contraído para aportar estabilidad.', 'Paso 2: Sostén la barra recta frente a ti con un agarre prono (palmas hacia abajo) a la anchura de los hombros.', 'Paso 3: Flexiona los codos para subir la barra hacia la parte superior del pecho sin balancear el tronco ni empujar con las caderas.', 'Paso 4: Desciende la barra lentamente a la posición inicial manteniendo la tensión en el antebrazo y controlando la fase excéntrica.']::text[],
  'principiante',
  'Movimiento fundamental de pie que trabaja de forma integral la musculatura del antebrazo y brazo mediante la flexión del codo con agarre prono.',
  ARRAY['Hipertrofia', 'Fuerza de agarre']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps sobre la cabeza con polea baja y cuerda',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/extension_de_triceps_sobre_la_cabeza_con_polea_baja_y_cuerda.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/extension_de_triceps_sobre_la_cabeza_con_polea_baja_y_cuerda.webp',
  ARRAY['Paso 1: Engancha un agarre de cuerda a la polea ubicada en la posición más baja de la máquina.', 'Paso 2: Colócate de espaldas a la polea, sujeta la cuerda por detrás de la cabeza con un agarre neutro y da un paso hacia adelante para crear tensión.', 'Paso 3: Mantén el torso estable, el core contraído y los codos fijos apuntando hacia arriba. Extiende los codos concéntricamente hasta que los brazos estén completamente estirados sobre la cabeza.', 'Paso 4: Desciende la cuerda de forma excéntrica y controlada, flexionando los codos hasta sentir un estiramiento profundo en los tríceps antes de iniciar la siguiente repetición.']::text[],
  'intermedio',
  'Ejercicio de aislamiento que maximiza el estiramiento y la activación de la cabeza larga del tríceps braquial debido a la flexión del hombro, manteniendo una tensión mecánica constante gracias a la resistencia de la polea.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Hip thrust con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/hip_thrust_con_barra.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/hip_thrust_con_barra.webp',
  ARRAY['Paso 1: Siéntate en el suelo con la parte inferior de las escápulas apoyada firmemente contra el borde de un banco y coloca la barra cargada (preferiblemente con almohadilla) sobre el pliegue de las caderas.', 'Paso 2: Planta los pies en el suelo separados aproximadamente a la anchura de los hombros o de las caderas, asegurándote de que las tibias queden verticales cuando las caderas estén completamente extendidas en la parte alta del movimiento.', 'Paso 3: Manteniendo la barbilla ligeramente metida y el abdomen contraído, empuja el suelo con los talones y extiende las caderas concéntricamente hasta que tus muslos y tu torso formen una línea recta paralela al suelo, contrayendo fuertemente los glúteos.', 'Paso 4: Desciende las caderas de manera excéntrica y controlada hacia la posición inicial, bajando en bloque sin arquear la zona lumbar.']::text[],
  'intermedio',
  'Ejercicio compuesto enfocado en la extensión de cadera que proporciona una máxima activación del glúteo mayor mediante la sobrecarga directa en la pelvis.',
  ARRAY['Hipertrofia', 'Fuerza máxima', 'Potencia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con barra EZ en banco predicador',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_barra_ez_en_banco_predicador.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_barra_ez_en_banco_predicador.webp',
  ARRAY['Paso 1: Ajusta el asiento del banco predicador para que las axilas descansen cómodamente sobre el borde superior de la almohadilla y la parte posterior de los brazos (tríceps) esté completamente apoyada.', 'Paso 2: Sujeta la barra EZ por las curvaturas interiores con un agarre semi-supinado (palmas orientadas hacia arriba y ligeramente hacia adentro).', 'Paso 3: Flexiona los codos de forma concéntrica para llevar la barra hacia los hombros, manteniendo el contacto constante de los brazos con la almohadilla para aislar el bíceps al máximo.', 'Paso 4: Desciende la barra de forma excéntrica y controlada hasta alcanzar la extensión casi completa del codo, manteniendo la tensión muscular en todo momento sin llegar a la hiperextensión.']::text[],
  'intermedio',
  'Ejercicio de aislamiento enfocado en el desarrollo e hipertrofia del bíceps braquial y el braquial anterior. El uso del banco predicador elimina el balanceo corporal y el impulso, mientras que la barra EZ proporciona un agarre semi-supinado que reduce la tensión articular sobre las muñecas en comparación con una barra recta.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla sumo con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_sumo_con_mancuerna.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_sumo_con_mancuerna.webp',
  ARRAY['Paso 1: Adopta una postura amplia con los pies separados más allá de la anchura de los hombros y las puntas apuntando hacia afuera en un ángulo de aproximadamente 45 grados.', 'Paso 2: Sujeta una mancuerna por uno de sus extremos (o discos) con ambas manos, dejando que cuelgue verticalmente en el centro con los brazos completamente extendidos.', 'Paso 3: Manteniendo el pecho erguido y el core contraído, flexiona las rodillas y las caderas de forma excéntrica, descendiendo hasta que los muslos estén paralelos al suelo.', 'Paso 4: Empuja firmemente el suelo con los talones para extender de forma concéntrica las caderas y rodillas, volviendo a la posición inicial mientras contraes los glúteos.']::text[],
  'principiante',
  'Variante de la sentadilla tradicional con una postura de pies más amplia que enfatiza la activación de la musculatura aductora y el glúteo mayor, manteniendo el torso más erguido para reducir el estrés lumbar.',
  ARRAY['Hipertrofia', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Estiramiento de hombros y espalda alta frente a la pared',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/estiramiento_de_hombros_y_espalda_alta_frente_a_la_pared.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/estiramiento_de_hombros_y_espalda_alta_frente_a_la_pared.webp',
  ARRAY['Paso 1: Colócate de pie frente a una pared, aproximadamente a la distancia de un brazo o ligeramente más lejos, manteniendo los pies a la anchura de las caderas.', 'Paso 2: Apoya las palmas de las manos planas en la pared a la altura de los hombros.', 'Paso 3: Deja caer lentamente el pecho hacia el suelo, empujando las caderas hacia atrás mientras mantienes los brazos completamente extendidos, sintiendo el estiramiento en hombros y espalda.', 'Paso 4: Mantén la posición de estiramiento de forma sostenida y respira profundamente antes de regresar de manera controlada a la postura inicial.']::text[],
  'principiante',
  'Ejercicio de estiramiento estático diseñado para elongar la musculatura del hombro y del dorsal, mejorando la movilidad y el rango de flexión de la cintura escapular.',
  ARRAY['Flexibilidad', 'Movilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Retracción escapular isométrica con espalda en la pared',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/retraccion_escapular_isometrica_con_espalda_en_la_pared.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/retraccion_escapular_isometrica_con_espalda_en_la_pared.webp',
  ARRAY['Paso 1: Colócate de pie dando la espalda a una pared, apoyando firmemente los glúteos, la zona dorsal de la espalda y la cabeza.', 'Paso 2: Flexiona los codos a 90 grados y eleva los brazos hasta que la parte posterior del brazo y los dorsos de las manos toquen la pared.', 'Paso 3: Presiona activamente los codos y la parte posterior de los hombros contra la pared, forzando a las escápulas a juntarse en el centro de la espalda.', 'Paso 4: Sostén la máxima contracción isométrica durante los segundos indicados sin arquear excesivamente la zona lumbar, luego relaja la tensión.']::text[],
  'principiante',
  'Ejercicio de activación y control postural centrado en la estabilización de la cintura escapular mediante la contracción isométrica de la musculatura retractora contra una superficie plana.',
  ARRAY['Activación', 'Postura']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión torácica en pared con manos en la nuca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/extension_toracica_en_pared_con_manos_en_la_nuca.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/extension_toracica_en_pared_con_manos_en_la_nuca.webp',
  ARRAY['Paso 1: Colócate de pie frente a una pared a corta distancia y entrelaza las manos suavemente por detrás de tu nuca o zona cervical baja.', 'Paso 2: Apoya ambos codos contra la pared a una altura ligeramente superior a la de tus hombros.', 'Paso 3: Manteniendo el abdomen contraído para no hiperextender la zona lumbar, empuja el pecho lentamente hacia la pared buscando arquear únicamente la zona media-alta de la espalda (columna torácica).', 'Paso 4: Sostén la extensión un breve instante y retorna de manera controlada a la posición neutra.']::text[],
  'principiante',
  'Ejercicio de movilidad articular diseñado para aumentar el rango de extensión de la columna torácica, utilizando la pared como soporte para los codos y punto de pivote.',
  ARRAY['Movilidad', 'Postura']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuernas de pie',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_de_pie.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_de_pie.webp',
  ARRAY['Paso 1: Ponte de pie con la espalda recta, los pies a la anchura de los hombros y sujeta una mancuerna en cada mano con agarre neutro a los lados del cuerpo.', 'Paso 2: Manteniendo los codos fijos y pegados al torso, flexiona los brazos para elevar las mancuernas, girando las muñecas progresivamente hacia un agarre supino (palmas hacia arriba).', 'Paso 3: Sostén la máxima contracción del bíceps en la parte superior del movimiento por un instante.', 'Paso 4: Desciende las mancuernas de manera excéntrica y controlada hasta la posición inicial, deshaciendo el giro de las muñecas hasta extender los codos por completo.']::text[],
  'principiante',
  'Ejercicio de aislamiento para el desarrollo de la hipertrofia del bíceps braquial, realizado de pie para requerir estabilización del core durante la flexión del codo con supinación.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo sentado en polea baja con agarre estrecho',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_sentado_en_polea_baja_con_agarre_estrecho.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_sentado_en_polea_baja_con_agarre_estrecho.webp',
  ARRAY['Paso 1: Siéntate en la máquina de polea baja, apoya los pies firmemente en las plataformas manteniendo las rodillas ligeramente flexionadas y sujeta el maneral de agarre estrecho con ambas manos en posición neutra.', 'Paso 2: Retrae las escápulas, mantén la espalda recta, el pecho erguido y el core contraído, con los brazos completamente extendidos frente a ti.', 'Paso 3: Tira del maneral de forma concéntrica hacia la zona umbilical (parte baja del abdomen), flexionando los codos cerca del torso y juntando las escápulas al máximo en el pico de contracción.', 'Paso 4: Extiende los brazos de forma excéntrica y controlada hasta la posición inicial, permitiendo un estiramiento completo del dorsal ancho sin flexionar ni encorvar la columna lumbar.']::text[],
  'principiante',
  'Ejercicio compuesto de tracción horizontal que enfoca el trabajo en el grosor de la espalda y la retracción escapular, manteniendo una tensión mecánica continua mediante el uso de la polea y maximizando la aducción escapular gracias al agarre cerrado.',
  ARRAY['Hipertrofia', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de piernas acostado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevacion_de_piernas_acostado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevacion_de_piernas_acostado.webp',
  ARRAY['Paso 1: Acuéstate boca arriba en el suelo o colchoneta con las piernas extendidas y los brazos a los lados.', 'Paso 2: Contrae el abdomen presionando la zona lumbar contra el suelo.', 'Paso 3: Eleva ambas piernas rectas simultáneamente hasta que formen un ángulo de 90 grados con tu torso.', 'Paso 4: Desciende las piernas de forma excéntrica y controlada sin que los talones toquen el suelo para la siguiente repetición.']::text[],
  'principiante',
  'Ejercicio enfocado en la musculatura abdominal, específicamente en la flexión del tronco y estabilización pélvica.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tijeras verticales acostado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/tijeras_verticales_acostado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/tijeras_verticales_acostado.webp',
  ARRAY['Paso 1: Acuéstate boca arriba, coloca las manos debajo de los glúteos para soporte lumbar y eleva ligeramente ambas piernas extendidas a unos centímetros del suelo.', 'Paso 2: Eleva una pierna hacia el techo manteniendo la otra abajo.', 'Paso 3: Alterna la posición de las piernas en un movimiento de tijera continuo y fluido.', 'Paso 4: Mantén el core contraído durante todo el ejercicio, evitando arquear la zona lumbar.']::text[],
  'principiante',
  'Movimiento de estabilización central y flexión de cadera alternada que mantiene una tensión isométrica en el recto abdominal.',
  ARRAY['Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de cadera en posición de oso',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/extension_de_cadera_en_posicion_de_oso.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/extension_de_cadera_en_posicion_de_oso.webp',
  ARRAY['Paso 1: Colócate en posición de cuadrupedia y eleva ligeramente las rodillas del suelo (posición de oso), apoyándote sobre manos y puntas de los pies.', 'Paso 2: Manteniendo la espalda neutra y el core estable, extiende una pierna hacia atrás de forma controlada.', 'Paso 3: Contrae el glúteo en la máxima extensión de la pierna sin hiper-extender la región lumbar.', 'Paso 4: Regresa la rodilla a la posición inicial sin tocar el suelo y repite, o alterna las piernas según tu rutina.']::text[],
  'intermedio',
  'Ejercicio de activación de la cadena posterior y estabilización del core realizado desde una postura cuadrupédica isométrica.',
  ARRAY['Activación', 'Estabilidad central']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Mountain climbers',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/mountain_climbers.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/mountain_climbers.webp',
  ARRAY['Paso 1: Adopta una posición de plancha alta con las manos apoyadas en el suelo a la anchura de los hombros y el cuerpo formando una línea recta.', 'Paso 2: Lleva una rodilla hacia tu pecho de forma rápida y explosiva.', 'Paso 3: Regresa la pierna a la posición inicial de plancha.', 'Paso 4: Alterna inmediatamente con la otra pierna, manteniendo un ritmo constante como si estuvieras corriendo en el sitio sin elevar excesivamente la pelvis.']::text[],
  'principiante',
  'Ejercicio cardiovascular y de resistencia central que combina estabilización isométrica y flexión dinámica de cadera.',
  ARRAY['Acondicionamiento metabólico', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/crunch_abdominal_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/crunch_abdominal_sentado.webp',
  ARRAY['Paso 1: Siéntate en el borde de un banco o colchoneta, inclina el torso ligeramente hacia atrás y sujeta los bordes para mantener el equilibrio, con las piernas extendidas frente a ti.', 'Paso 2: Flexiona simultáneamente el tronco y las rodillas, acercando el pecho hacia los muslos.', 'Paso 3: Sostén la contracción en la zona abdominal durante un instante en el punto de mayor acortamiento.', 'Paso 4: Extiende el torso y las piernas de forma excéntrica y controlada para volver a la posición inicial sin que los pies descansen en el suelo.']::text[],
  'principiante',
  'Variación del encogimiento abdominal tradicional realizado en una postura sentada, enfocándose en la contracción de la pared abdominal superior e inferior al acercar el torso a las rodillas.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sit-up con piernas estiradas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/situp_con_piernas_estiradas.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/situp_con_piernas_estiradas.webp',
  ARRAY['Paso 1: Acuéstate boca arriba en una colchoneta con las piernas completamente extendidas sobre el suelo y los brazos estirados por encima de la cabeza.', 'Paso 2: Inicia el movimiento contrayendo el abdomen y eleva los brazos, la cabeza y los hombros del suelo de forma secuencial.', 'Paso 3: Continúa flexionando el torso hasta llegar a una posición completamente sentada, intentando tocar las puntas de los pies con las manos.', 'Paso 4: Desciende desenrollando la columna vértebra a vértebra de forma excéntrica y controlada hasta regresar a la postura inicial en el suelo.']::text[],
  'intermedio',
  'Ejercicio clásico de flexión de tronco y cadera donde la extensión de las piernas reduce la inhibición del psoas, incrementando el trabajo global del flexor de la cadera.',
  ARRAY['Fuerza', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla trasera con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_trasera_con_barra.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_trasera_con_barra.webp',
  ARRAY['Paso 1: Colócate debajo de la barra apoyándola sobre los trapecios o la parte posterior de los deltoides, y sujétala con ambas manos para mayor estabilidad.', 'Paso 2: Saca la barra del soporte, da un paso hacia atrás y separa los pies aproximadamente a la anchura de los hombros, con las puntas ligeramente hacia afuera.', 'Paso 3: Manteniendo el pecho alto y el core contraído, flexiona caderas y rodillas de forma excéntrica para descender hasta que los muslos estén paralelos al suelo o por debajo.', 'Paso 4: Empuja firmemente el suelo con toda la planta del pie para extender de forma concéntrica caderas y rodillas hasta regresar a la posición inicial.']::text[],
  'intermedio',
  'Ejercicio compuesto fundamental para el desarrollo del tren inferior que implica la triple extensión de cadera, rodilla y tobillo, soportando la carga axial sobre la parte posterior de los hombros y espalda alta.',
  ARRAY['Hipertrofia', 'Fuerza máxima']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate en un banco con la espalda recta, apoyada en el respaldo si lo tiene, y sostén una mancuerna en cada mano con los brazos extendidos a los lados del cuerpo.', 'Paso 2: Inicia el movimiento flexionando los codos para elevar las mancuernas, rotando las muñecas para asegurar un agarre supino (palmas hacia arriba) al llegar a la parte superior.', 'Paso 3: Sostén la máxima contracción del bíceps en la parte alta del movimiento durante un instante.', 'Paso 4: Desciende las mancuernas de forma excéntrica y controlada a la posición inicial, extendiendo los codos por completo.']::text[],
  'principiante',
  'Ejercicio de aislamiento enfocado en el desarrollo del bíceps braquial mediante la flexión del codo. Realizarlo sentado minimiza el uso de impulso corporal, forzando un trabajo más estricto del músculo con un agarre supino o rotación hacia supinación.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate en un banco con la espalda recta, apoyada en el respaldo si lo tiene, y sostén una mancuerna en cada mano con los brazos extendidos a los lados del cuerpo.', 'Paso 2: Inicia el movimiento flexionando los codos para elevar las mancuernas, rotando las muñecas para asegurar un agarre supino (palmas hacia arriba) al llegar a la parte superior.', 'Paso 3: Sostén la máxima contracción del bíceps en la parte alta del movimiento durante un instante.', 'Paso 4: Desciende las mancuernas de forma excéntrica y controlada a la posición inicial, extendiendo los codos por completo.']::text[],
  'principiante',
  'Ejercicio de aislamiento enfocado en el desarrollo del bíceps braquial mediante la flexión del codo. Realizarlo sentado minimiza el uso de impulso corporal, forzando un trabajo más estricto del músculo con un agarre supino o rotación hacia supinación.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl inverso con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_inverso_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_inverso_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate en un banco manteniendo la espalda recta y sujeta una mancuerna en cada mano con un agarre prono (las palmas mirando hacia atrás al estar los brazos colgando).', 'Paso 2: Flexiona los codos manteniendo los brazos pegados al torso, elevando las mancuernas de forma controlada sin cambiar la pronación de las muñecas.', 'Paso 3: Alcanza el punto de máxima flexión apretando la musculatura del antebrazo y el braquial.', 'Paso 4: Baja las mancuernas de manera excéntrica y pausada hasta retornar a la extensión completa de los codos.']::text[],
  'intermedio',
  'Variante de flexión de codo realizada en posición sentada utilizando un agarre prono (palmas hacia abajo). Este agarre desplaza el énfasis del bíceps braquial hacia la musculatura del antebrazo y el braquial anterior.',
  ARRAY['Hipertrofia', 'Fuerza de agarre']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl martillo con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_martillo_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_martillo_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate en un banco con el torso erguido y sostén una mancuerna en cada mano usando un agarre neutro, con las palmas mirando hacia tu cuerpo.', 'Paso 2: Flexiona los codos para llevar las mancuernas hacia los hombros, manteniendo las palmas enfrentadas durante todo el recorrido.', 'Paso 3: Sostén la contracción en la parte alta del movimiento, asegurando que los codos no se desplacen excesivamente hacia adelante.', 'Paso 4: Desciende las cargas de forma controlada hasta la posición inicial de brazos extendidos.']::text[],
  'principiante',
  'Ejercicio de flexión de codo utilizando un agarre neutro (palmas enfrentadas) que permite un excelente desarrollo simultáneo del braquiorradial, braquial anterior y bíceps braquial, realizado sentado para maximizar la estabilidad.',
  ARRAY['Hipertrofia', 'Fuerza de agarre']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Pullover con mancuerna en banco plano',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/pullover_con_mancuerna_en_banco_plano.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/pullover_con_mancuerna_en_banco_plano.webp',
  ARRAY['Paso 1: Acuéstate boca arriba sobre un banco plano, apoyando firmemente la cabeza, los hombros y la zona dorsal. Planta los pies en el suelo.', 'Paso 2: Sostén una mancuerna con ambas manos por uno de sus extremos (formando un diamante con las palmas bajo el disco) y extiéndela sobre tu pecho con los codos ligeramente flexionados.', 'Paso 3: Desciende la mancuerna lentamente hacia atrás por encima de tu cabeza, manteniendo el ángulo de los codos constante, hasta sentir un estiramiento profundo en el pecho y dorsales.', 'Paso 4: Contrae los músculos objetivo para llevar la mancuerna de vuelta a la posición inicial sobre el pecho.']::text[],
  'intermedio',
  'Ejercicio compuesto que trabaja en la extensión del hombro, elongando y contrayendo tanto el dorsal ancho como el pectoral mayor. Su ejecución en banco plano estabiliza el torso durante el amplio rango de movimiento.',
  ARRAY['Hipertrofia', 'Movilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con mancuernas en banco plano',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/aperturas_con_mancuernas_en_banco_plano.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/aperturas_con_mancuernas_en_banco_plano.webp',
  ARRAY['Paso 1: Acuéstate sobre un banco plano sosteniendo una mancuerna en cada mano sobre el pecho, con los brazos extendidos pero manteniendo una ligera flexión en los codos.', 'Paso 2: Con las palmas enfrentadas (agarre neutro), abre los brazos hacia los lados en un movimiento amplio y semicircular, como si fueras a dar un abrazo.', 'Paso 3: Desciende hasta sentir un estiramiento profundo en los músculos pectorales, asegurándote de no sobrepasar la línea de los hombros de forma incómoda.', 'Paso 4: Contrae los pectorales para revertir el movimiento y juntar las mancuernas nuevamente en la parte superior.']::text[],
  'intermedio',
  'Ejercicio de aislamiento enfocado en la aducción horizontal del hombro, diseñado para maximizar el estiramiento y la hipertrofia del pectoral mayor al eliminar la asistencia del tríceps.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Patada de tríceps con mancuernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/patada_de_triceps_con_mancuernas.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/patada_de_triceps_con_mancuernas.webp',
  ARRAY['Paso 1: Inclina el torso hacia adelante apoyando una mano y rodilla sobre un banco, o manteniendo una postura bisagra de cadera. Sostén una mancuerna con la otra mano usando un agarre neutro.', 'Paso 2: Pega la parte superior del brazo a tu torso de forma paralela al suelo y flexiona el codo a 90 grados.', 'Paso 3: Manteniendo el brazo superior completamente inmóvil, extiende el codo empujando la mancuerna hacia atrás hasta que el brazo quede totalmente estirado.', 'Paso 4: Contrae fuertemente el tríceps por un segundo y desciende la mancuerna de forma controlada a la posición inicial.']::text[],
  'principiante',
  'Ejercicio de aislamiento para el tríceps braquial realizado con el hombro en extensión, lo que permite lograr una fuerte contracción de la cabeza larga en el punto máximo del recorrido.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevaciones laterales sin peso',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevaciones_laterales_sin_peso.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevaciones_laterales_sin_peso.webp',
  ARRAY['Paso 1: Colócate de pie con una postura erguida, los pies a la anchura de los hombros y los brazos descansando a los lados del cuerpo.', 'Paso 2: Manteniendo una ligerísima flexión en los codos, eleva ambos brazos hacia los lados de forma controlada.', 'Paso 3: Sube los brazos hasta que queden paralelos al suelo, alineando las manos con la altura de los hombros.', 'Paso 4: Desciende los brazos lentamente hacia la posición inicial, manteniendo la tensión y el control muscular en todo momento.']::text[],
  'principiante',
  'Movimiento de abducción del hombro ejecutado sin carga externa, ideal para calentamiento, activación neuromuscular, rehabilitación o mejora de la movilidad activa del complejo articular del hombro.',
  ARRAY['Activación', 'Movilidad', 'Calentamiento']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo con barra agarre prono',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_con_barra_agarre_prono.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_con_barra_agarre_prono.webp',
  ARRAY['Paso 1: Colócate de pie frente a la barra, flexiona las caderas y rodillas manteniendo la espalda recta (bisagra de cadera) hasta que el torso quede casi paralelo al suelo.', 'Paso 2: Sujeta la barra con un agarre prono, con las manos separadas ligeramente más allá de la anchura de los hombros.', 'Paso 3: Tira de la barra hacia la parte inferior de tu pecho o abdomen alto, retrayendo fuertemente las escápulas y manteniendo los codos en un ángulo de aproximadamente 45 grados respecto al torso.', 'Paso 4: Extiende los brazos de forma excéntrica y controlada para volver a la posición inicial sin perder la postura recta de la espalda.']::text[],
  'intermedio',
  'Ejercicio compuesto fundamental para el desarrollo del grosor de la espalda. El agarre prono (palmas hacia ti) incrementa la activación de la parte superior de la espalda y los retractores escapulares en comparación con otras variantes de agarre.',
  ARRAY['Hipertrofia', 'Fuerza máxima']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de hombros sentado en máquina Smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/press_hombros/press_de_hombros_sentado_en_maquina_smith.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/press_hombros/press_de_hombros_sentado_en_maquina_smith.webp',
  ARRAY['Paso 1: Coloca un banco regulable bajo la barra de la máquina Smith, ajustando el respaldo a un ángulo de entre 75 y 85 grados para proteger la articulación del hombro.', 'Paso 2: Siéntate apoyando firmemente la espalda y la cabeza en el respaldo. Ajusta la barra para que quede a la altura de tu barbilla o clavícula al iniciar.', 'Paso 3: Sujeta la barra con un agarre prono (palmas hacia adelante) a una anchura ligeramente mayor a la de los hombros, retira los seguros y empuja concéntricamente la carga hacia arriba hasta extender casi por completo los codos.', 'Paso 4: Desciende la barra de forma excéntrica y controlada hasta que vuelva a quedar a la altura de la barbilla, evitando que los codos bajen en exceso o se abran hacia atrás.']::text[],
  'intermedio',
  'Ejercicio compuesto de empuje vertical enfocado en la hipertrofia y fuerza de los hombros. La trayectoria guiada por la máquina Smith ofrece gran estabilidad, aislando el trabajo en los deltoides al reducir la necesidad de usar músculos estabilizadores.',
  ARRAY['Hipertrofia', 'Fuerza máxima']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Peso muerto rumano con peso corporal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/peso_muerto_rumano_con_peso_corporal.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/peso_muerto_rumano_con_peso_corporal.webp',
  ARRAY['Paso 1: Colócate de pie con los pies a la anchura de las caderas, manteniendo una ligera y constante flexión en las rodillas.', 'Paso 2: Manteniendo la espalda completamente recta y el core contraído, empuja las caderas hacia atrás de forma excéntrica como si quisieras tocar la pared detrás de ti.', 'Paso 3: Desciende el torso hasta que quede casi paralelo al suelo o hasta sentir un estiramiento profundo en la parte posterior de los muslos.', 'Paso 4: Contrae los glúteos y los isquiosurales para empujar las caderas hacia adelante de forma concéntrica y volver a la posición inicial erguida.']::text[],
  'principiante',
  'Ejercicio de bisagra de cadera enfocado en el estiramiento y activación de la cadena posterior utilizando únicamente el peso del cuerpo para promover la movilidad y el control motor.',
  ARRAY['Movilidad', 'Activación', 'Control motor']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con peso corporal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_con_peso_corporal.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_con_peso_corporal.webp',
  ARRAY['Paso 1: Colócate de pie con los pies separados aproximadamente a la anchura de los hombros, con las puntas de los pies rotadas ligeramente hacia afuera.', 'Paso 2: Inicia el movimiento flexionando las caderas y las rodillas de forma simultánea, manteniendo el pecho erguido y el core activado.', 'Paso 3: Desciende de manera controlada hasta que tus muslos estén al menos paralelos al suelo, o tan profundo como tu movilidad lo permita sin perder la postura recta de la espalda.', 'Paso 4: Empuja fuertemente el suelo con toda la planta del pie para extender caderas y rodillas y regresar a la posición inicial de pie.']::text[],
  'principiante',
  'Ejercicio compuesto fundamental para el desarrollo del patrón de movimiento de triple flexión y extensión, mejorando la fuerza y movilidad del tren inferior con el propio peso.',
  ARRAY['Movilidad', 'Fuerza base', 'Acondicionamiento']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla sumo con peso corporal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_sumo_con_peso_corporal.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_sumo_con_peso_corporal.webp',
  ARRAY['Paso 1: Adopta una postura amplia separando los pies más allá de la anchura de los hombros, apuntando las puntas de los pies hacia afuera en un ángulo de aproximadamente 45 grados.', 'Paso 2: Manteniendo el torso erguido y las manos al frente para equilibrarte, flexiona caderas y rodillas asegurándote de que las rodillas se dirijan en la misma línea que las puntas de los pies.', 'Paso 3: Desciende excéntricamente hasta que tus muslos queden paralelos al suelo o sientas un buen estiramiento en los aductores.', 'Paso 4: Empuja firmemente el suelo con los talones, contrayendo fuertemente los glúteos y aductores para extender concéntricamente el cuerpo hasta la postura inicial.']::text[],
  'principiante',
  'Variante de la sentadilla libre que utiliza una postura amplia para enfatizar el estiramiento y activación de los músculos de la parte interna del muslo, además del glúteo mayor.',
  ARRAY['Movilidad', 'Activación', 'Fuerza base']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de hombros con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_hombros_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_hombros_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate en un banco con respaldo vertical, sujetando una mancuerna en cada mano a la altura de los hombros con los codos flexionados.', 'Paso 2: Mantén la espalda apoyada contra el respaldo y el core contraído para evitar arcos lumbares.', 'Paso 3: Empuja las mancuernas de forma concéntrica y vertical hacia arriba hasta que tus brazos estén casi completamente extendidos.', 'Paso 4: Desciende las mancuernas de manera excéntrica y controlada hasta que vuelvan a la altura de tus hombros sin rebotar.']::text[],
  'intermedio',
  'Ejercicio de empuje vertical diseñado para el desarrollo de la masa muscular y fuerza del complejo articular del hombro, ejecutado sentado para una mayor estabilidad del tronco.',
  ARRAY['Hipertrofia', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de hombros con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_hombros_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_hombros_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate en un banco con respaldo vertical, sujetando una mancuerna en cada mano a la altura de los hombros con los codos flexionados.', 'Paso 2: Mantén la espalda apoyada contra el respaldo y el core contraído para evitar arcos lumbares.', 'Paso 3: Empuja las mancuernas de forma concéntrica y vertical hacia arriba hasta que tus brazos estén casi completamente extendidos.', 'Paso 4: Desciende las mancuernas de manera excéntrica y controlada hasta que vuelvan a la altura de tus hombros sin rebotar.']::text[],
  'intermedio',
  'Ejercicio de empuje vertical diseñado para el desarrollo de la masa muscular y fuerza del complejo articular del hombro, ejecutado sentado para una mayor estabilidad del tronco.',
  ARRAY['Hipertrofia', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación frontal con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevacion_frontal_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevacion_frontal_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate con la espalda recta y sujeta una mancuerna en cada mano con agarre neutro, brazos extendidos a los costados.', 'Paso 2: Eleva un brazo hacia adelante de forma concéntrica manteniendo el codo ligeramente flexionado, hasta que la mancuerna llegue a la altura de tus ojos.', 'Paso 3: Sostén un breve instante la parte alta del movimiento para maximizar la contracción.', 'Paso 4: Baja el brazo de forma excéntrica y controlada a la posición inicial y alterna con el otro brazo.']::text[],
  'principiante',
  'Ejercicio de aislamiento para el deltoides anterior, realizado sentado para eliminar el balanceo y focalizar la carga exclusivamente en la porción frontal del hombro.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación lateral con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevacion_lateral_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevacion_lateral_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate erguido, sujeta una mancuerna en cada mano con los brazos extendidos a los lados y palmas enfrentadas.', 'Paso 2: Eleva ambos brazos lateralmente hasta alcanzar la altura de los hombros, manteniendo una ligera flexión en los codos.', 'Paso 3: Mantén la posición un segundo, concentrándote en la contracción de la porción media del hombro.', 'Paso 4: Desciende los brazos lentamente de forma excéntrica hasta volver a la posición de inicio.']::text[],
  'principiante',
  'Movimiento de abducción del hombro realizado sentado, enfocado en el desarrollo de la anchura del deltoides medio y la estética de la parte superior del cuerpo.',
  ARRAY['Hipertrofia', 'Estética']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación posterior con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevacion_posterior_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevacion_posterior_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate en el borde del banco, inclina el torso hacia adelante hasta que tu pecho esté cerca de los muslos y sujeta las mancuernas por debajo de tus pantorrillas.', 'Paso 2: Con una ligera flexión en los codos, eleva los brazos lateralmente hacia atrás, concentrándote en separar los hombros.', 'Paso 3: Sube las mancuernas hasta que tus codos alcancen la altura de los hombros, contrayendo la zona posterior.', 'Paso 4: Baja los brazos de forma controlada y excéntrica hasta regresar a la posición inicial.']::text[],
  'intermedio',
  'Ejercicio de aislamiento enfocado en la musculatura posterior del hombro, ejecutado sentado e inclinado hacia adelante para maximizar el ángulo de tracción sobre el deltoides posterior.',
  ARRAY['Hipertrofia', 'Postura']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Encogimiento de hombros con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/encogimiento_de_hombros_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/encogimiento_de_hombros_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate erguido en un banco con una mancuerna en cada mano, brazos extendidos a lo largo del cuerpo y agarre neutro.', 'Paso 2: Eleva los hombros verticalmente hacia las orejas, evitando rotar las muñecas o usar los brazos para traccionar.', 'Paso 3: Contrae fuertemente el trapecio en la posición más alta del movimiento.', 'Paso 4: Desciende los hombros lentamente hasta la posición inicial de forma excéntrica para completar la repetición.']::text[],
  'principiante',
  'Ejercicio de aislamiento enfocado en la hipertrofia y función del trapecio superior, utilizando mancuernas y posición sentada para una ejecución estricta.',
  ARRAY['Hipertrofia', 'Fuerza funcional']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla sumo con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/sentadilla/sentadilla_sumo_con_mancuerna.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/sentadilla/sentadilla_sumo_con_mancuerna.webp',
  ARRAY['Paso 1: Colócate de pie con una apertura de piernas mayor a la anchura de tus hombros y las puntas de los pies giradas hacia afuera unos 45 grados.', 'Paso 2: Sujeta una mancuerna por uno de sus extremos con ambas manos y deja que cuelgue verticalmente entre tus piernas con los brazos estirados.', 'Paso 3: Realiza una flexión de caderas y rodillas manteniendo el pecho erguido y el abdomen contraído, bajando hasta que los muslos estén paralelos al suelo.', 'Paso 4: Empuja a través de los talones para extender la cadera y las rodillas de forma controlada hasta regresar a la posición inicial.']::text[],
  'principiante',
  'Variante de sentadilla con base amplia que enfatiza la activación de los músculos aductores y el glúteo mayor, manteniendo el torso erguido gracias a la carga posicionada centralmente.',
  ARRAY['Hipertrofia', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación lateral a una mano en polea baja inclinado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevacion_lateral_a_una_mano_en_polea_baja_inclinado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevacion_lateral_a_una_mano_en_polea_baja_inclinado.webp',
  ARRAY['Paso 1: Ajusta la polea en la posición más baja y selecciona un peso adecuado.', 'Paso 2: Colócate de costado a la máquina, sujeta el agarre de la polea con la mano más alejada y apoya la mano libre en la columna de la máquina o un soporte estable, inclinando el torso para que el brazo quede alineado con el cable.', 'Paso 3: Realiza una abducción del hombro elevando el brazo lateralmente de forma controlada hasta que el codo alcance la altura del hombro, manteniendo una ligera flexión en el codo.', 'Paso 4: Regresa lentamente a la posición inicial de forma excéntrica, evitando que el peso descanse en la pila de la máquina para mantener la tensión muscular.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para el deltoides medio que mantiene una tensión constante durante todo el rango de movimiento gracias a la resistencia de la polea, mientras la inclinación del torso altera el perfil de resistencia para una mayor estimulación mecánica.',
  ARRAY['Hipertrofia', 'Estética', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca plano con agarre neutro',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_banca_plano_con_agarre_neutro.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_banca_plano_con_agarre_neutro.webp',
  ARRAY['Paso 1: Túmbate sobre un banco plano, apoya firmemente los pies en el suelo y sujeta una mancuerna en cada mano con las palmas enfrentadas.', 'Paso 2: Baja las mancuernas de forma controlada hacia los lados de tu pecho, manteniendo los codos cerca del torso.', 'Paso 3: Empuja las mancuernas de manera explosiva hacia arriba hasta extender los brazos sin bloquear los codos.', 'Paso 4: Regresa a la posición inicial manteniendo el control de la carga durante todo el recorrido.']::text[],
  'intermedio',
  'Ejercicio de empuje horizontal realizado en banco plano utilizando mancuernas con agarre neutro, lo que reduce la rotación interna del hombro y enfatiza el trabajo del pectoral mayor y el tríceps.',
  ARRAY['Hipertrofia', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca plano con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_banca_plano_con_barra.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_banca_plano_con_barra.webp',
  ARRAY['Paso 1: Túmbate en el banco, retira la barra del soporte con un agarre prono ligeramente superior a la anchura de los hombros.', 'Paso 2: Baja la barra de forma lenta hasta tocar ligeramente el centro del pecho, manteniendo los codos en un ángulo de 45 grados respecto al torso.', 'Paso 3: Empuja la barra hacia arriba de forma potente extendiendo los codos sin hiperextender.', 'Paso 4: Realiza las repeticiones manteniendo el contacto de glúteos y espalda con el banco durante todo el movimiento.']::text[],
  'intermedio',
  'Movimiento básico de fuerza que trabaja la musculatura de empuje horizontal, permitiendo manejar cargas elevadas para el desarrollo integral del pecho y los brazos.',
  ARRAY['Fuerza máxima', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca plano con agarre estrecho',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_banca_plano_con_agarre_estrecho.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_banca_plano_con_agarre_estrecho.webp',
  ARRAY['Paso 1: Túmbate en el banco y sujeta la barra con un agarre a la anchura de los hombros o ligeramente más estrecho.', 'Paso 2: Baja la barra hacia la parte baja del pecho manteniendo los codos pegados al cuerpo durante todo el recorrido.', 'Paso 3: Empuja la barra de forma controlada hasta bloquear los codos al final del movimiento.', 'Paso 4: Mantén los hombros estables y evita el rebote contra el pecho.']::text[],
  'intermedio',
  'Variante del press de banca enfocada en desplazar la mayor parte de la carga hacia los tríceps, manteniendo un agarre cerrado sobre la barra.',
  ARRAY['Hipertrofia de tríceps', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca inclinado con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_banca_inclinado_con_barra.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_banca_inclinado_con_barra.webp',
  ARRAY['Paso 1: Ajusta el banco en inclinación y siéntate, retirando la barra del soporte con agarre prono.', 'Paso 2: Baja la barra de forma controlada hacia la parte superior del pecho, cerca de las clavículas.', 'Paso 3: Empuja la barra hacia arriba hasta la extensión completa de los brazos.', 'Paso 4: Mantén la espalda firme contra el respaldo durante todo el ejercicio.']::text[],
  'intermedio',
  'Ejercicio enfocado en la porción superior del pectoral mediante un empuje inclinado, utilizando el banco en posición de 30 a 45 grados.',
  ARRAY['Hipertrofia', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca declinado con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_banca_declinado_con_barra.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_banca_declinado_con_barra.webp',
  ARRAY['Paso 1: Túmbate en el banco declinado asegurando tus piernas en los soportes.', 'Paso 2: Retira la barra del soporte y bájala hacia la parte baja del pecho de forma controlada.', 'Paso 3: Empuja la barra verticalmente hasta la extensión de los codos.', 'Paso 4: Asegúrate de mantener la estabilidad del cuerpo y no arquear excesivamente la espalda.']::text[],
  'intermedio',
  'Variante realizada en un banco declinado, enfocada en trabajar la porción inferior del pectoral mayor y aislar menos el deltoides anterior.',
  ARRAY['Hipertrofia', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/push_up.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/push_up.webp',
  ARRAY['Paso 1: Colócate en posición de plancha con las manos apoyadas en el suelo a una anchura ligeramente superior a la de los hombros y el cuerpo alineado desde la cabeza hasta los talones.', 'Paso 2: Manteniendo el core contraído y los codos en un ángulo de aproximadamente 45 grados respecto al torso, desciende el pecho hacia el suelo de forma controlada.', 'Paso 3: Empuja el suelo con firmeza para extender los brazos de manera concéntrica hasta alcanzar la posición inicial sin bloquear los codos.', 'Paso 4: Mantén la columna neutra y evita arquear la zona lumbar durante todo el recorrido del movimiento.']::text[],
  'principiante',
  'Ejercicio de empuje horizontal fundamental realizado con el peso corporal, que desarrolla la fuerza y la estabilidad de la cadena anterior mediante la extensión del codo y la aducción horizontal del hombro.',
  ARRAY['Fuerza', 'Resistencia muscular', 'Estabilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de hombros con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_hombros_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_hombros_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate en un banco con respaldo vertical, sujeta una mancuerna en cada mano y elévalas hasta la altura de tus hombros con los codos flexionados.', 'Paso 2: Mantén la espalda totalmente apoyada contra el respaldo y el core contraído para evitar arquear la columna lumbar durante el movimiento.', 'Paso 3: Empuja las mancuernas hacia arriba de forma concéntrica y controlada hasta alcanzar la extensión casi completa de los brazos, sin llegar a bloquear los codos.', 'Paso 4: Desciende las mancuernas de manera excéntrica hasta retomar la posición inicial a la altura de los hombros, manteniendo siempre el control del peso.']::text[],
  'intermedio',
  'Ejercicio de empuje vertical para el fortalecimiento y desarrollo hipertrófico del complejo articular del hombro, ejecutado en posición sentada para asegurar una mayor estabilidad del tronco y aislar el trabajo muscular.',
  ARRAY['Hipertrofia', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate en un banco con respaldo, sosteniendo una mancuerna en cada mano con los brazos extendidos a los lados.', 'Paso 2: Flexiona los codos para elevar las mancuernas, rotando las muñecas durante el ascenso para terminar con un agarre supino.', 'Paso 3: Sostén la contracción máxima en la parte superior del movimiento durante un breve instante.', 'Paso 4: Desciende las mancuernas de forma excéntrica y controlada hasta la posición inicial de extensión completa.']::text[],
  'principiante',
  'Ejercicio de aislamiento enfocado en la hipertrofia del bíceps braquial, ejecutado en posición sentada para minimizar el uso de impulso corporal y maximizar el reclutamiento de las fibras musculares.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate en un banco con respaldo, sosteniendo una mancuerna en cada mano con los brazos extendidos a los lados.', 'Paso 2: Flexiona los codos para elevar las mancuernas, rotando las muñecas durante el ascenso para terminar con un agarre supino.', 'Paso 3: Sostén la contracción máxima en la parte superior del movimiento durante un breve instante.', 'Paso 4: Desciende las mancuernas de forma excéntrica y controlada hasta la posición inicial de extensión completa.']::text[],
  'principiante',
  'Ejercicio de aislamiento enfocado en la hipertrofia del bíceps braquial, ejecutado en posición sentada para minimizar el uso de impulso corporal y maximizar el reclutamiento de las fibras musculares.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl inverso con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_inverso_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_inverso_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate en un banco manteniendo el tronco erguido y sujeta una mancuerna en cada mano con agarre prono (palmas mirando hacia el suelo).', 'Paso 2: Mantén los codos pegados al cuerpo y flexiona los antebrazos para elevar las mancuernas.', 'Paso 3: Alcanza el pico de flexión contrayendo activamente los extensores del antebrazo.', 'Paso 4: Regresa lentamente a la posición inicial, manteniendo la tensión en la fase excéntrica del movimiento.']::text[],
  'intermedio',
  'Variante de flexión de codo con agarre prono realizada en banco, enfocada en el desarrollo de la musculatura del antebrazo y el braquial anterior.',
  ARRAY['Hipertrofia', 'Fuerza de agarre']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl martillo con mancuernas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_martillo_con_mancuernas_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_martillo_con_mancuernas_sentado.webp',
  ARRAY['Paso 1: Siéntate en un banco con la espalda erguida, sujetando una mancuerna en cada mano con un agarre neutro (palmas enfrentadas).', 'Paso 2: Flexiona los codos para llevar las mancuernas hacia los hombros sin rotar las muñecas.', 'Paso 3: Aprieta los músculos del antebrazo y brazo en la parte superior del movimiento.', 'Paso 4: Desciende las cargas de manera controlada hasta la extensión total de los codos.']::text[],
  'principiante',
  'Ejercicio de flexión de codo con agarre neutro, altamente eficaz para el desarrollo simultáneo del braquial anterior, braquiorradial y bíceps braquial.',
  ARRAY['Hipertrofia', 'Fuerza de agarre']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Pullover con mancuerna en banco plano',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/pullover_con_mancuerna_en_banco_plano.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/pullover_con_mancuerna_en_banco_plano.webp',
  ARRAY['Paso 1: Acuéstate boca arriba en un banco plano, apoyando cabeza y hombros. Sujeta una mancuerna con ambas manos formando un diamante.', 'Paso 2: Con los codos ligeramente flexionados, baja la mancuerna por encima de tu cabeza hasta sentir un estiramiento profundo.', 'Paso 3: Contrae activamente la musculatura dorsal y pectoral para devolver la mancuerna a la posición vertical sobre el pecho.', 'Paso 4: Mantén una postura estable y controlada durante todo el rango de recorrido.']::text[],
  'intermedio',
  'Ejercicio compuesto que permite un estiramiento profundo del dorsal ancho y el pectoral mayor a través de un amplio rango de movimiento de extensión del hombro.',
  ARRAY['Hipertrofia', 'Movilidad torácica']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas con mancuernas en banco plano',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/aperturas_con_mancuernas_en_banco_plano.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/aperturas_con_mancuernas_en_banco_plano.webp',
  ARRAY['Paso 1: Acuéstate en un banco plano sosteniendo una mancuerna en cada mano, con brazos extendidos sobre el pecho y palmas enfrentadas.', 'Paso 2: Abre los brazos en un arco amplio y controlado hasta que sientas un estiramiento en el pecho.', 'Paso 3: Contrae el pectoral para retornar a la posición inicial uniendo las mancuernas sobre el centro del torso.', 'Paso 4: Mantén una ligera flexión en los codos durante todo el movimiento para proteger la articulación del hombro.']::text[],
  'intermedio',
  'Ejercicio de aislamiento enfocado en la aducción horizontal del hombro para el desarrollo estético y funcional del pectoral mayor.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Patada de tríceps con mancuernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/patada_de_triceps_con_mancuernas.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/patada_de_triceps_con_mancuernas.webp',
  ARRAY['Paso 1: Inclina el torso hacia adelante, apoyando una mano en un banco. Sujeta la mancuerna con la otra mano manteniendo el brazo paralelo al suelo.', 'Paso 2: Con el brazo superior fijo, extiende el codo hasta estirar completamente el brazo hacia atrás.', 'Paso 3: Contrae fuertemente el tríceps en la extensión total.', 'Paso 4: Regresa de forma controlada a la flexión de 90 grados inicial.']::text[],
  'principiante',
  'Ejercicio de aislamiento que enfatiza la contracción completa del tríceps braquial mediante la extensión del codo con el hombro en posición estable.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevaciones laterales sin peso',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevaciones_laterales_sin_peso.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevaciones_laterales_sin_peso.webp',
  ARRAY['Paso 1: Colócate de pie con la espalda recta y los brazos extendidos a los costados del cuerpo.', 'Paso 2: Eleva ambos brazos lateralmente de forma controlada hasta alcanzar la altura de los hombros.', 'Paso 3: Mantén la tensión en la parte alta antes de descender los brazos lentamente.', 'Paso 4: Realiza el movimiento de forma rítmica sin generar impulso mediante el balanceo del cuerpo.']::text[],
  'principiante',
  'Ejercicio de movilidad y activación muscular para el deltoides medio, ideal para protocolos de calentamiento o trabajo de control motor.',
  ARRAY['Activación', 'Movilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo con barra agarre prono',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_con_barra_agarre_prono.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_con_barra_agarre_prono.webp',
  ARRAY['Paso 1: Realiza una bisagra de cadera hasta que el torso quede casi paralelo al suelo, manteniendo la espalda recta.', 'Paso 2: Sujeta la barra con agarre prono y tracciona hacia el abdomen alto retrayendo las escápulas.', 'Paso 3: Aprieta la parte superior de la espalda al alcanzar el punto de máxima contracción.', 'Paso 4: Extiende los brazos controladamente hasta la posición inicial sin encorvar la columna.']::text[],
  'intermedio',
  'Movimiento compuesto de tracción horizontal para el desarrollo del grosor de la espalda, enfatizando la musculatura central y superior de la misma.',
  ARRAY['Hipertrofia', 'Fuerza máxima']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuernas de pie',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_de_pie.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_de_pie.webp',
  ARRAY['Paso 1: Ponte de pie con la espalda erguida, los pies a la anchura de los hombros y sujeta una mancuerna en cada mano con agarre neutro a los lados del cuerpo.', 'Paso 2: Manteniendo los codos fijos cerca del torso, flexiona los brazos para elevar las mancuernas mientras rotas las muñecas para realizar un agarre supino (palmas hacia arriba) durante el ascenso.', 'Paso 3: Sostén la máxima contracción del bíceps en la parte superior del movimiento durante un instante.', 'Paso 4: Desciende las mancuernas de manera excéntrica y controlada a la posición inicial, invirtiendo la rotación de las muñecas hasta extender los codos por completo.']::text[],
  'principiante',
  'Ejercicio de aislamiento enfocado en la hipertrofia del bíceps braquial mediante la flexión del codo con supinación, realizado de pie para integrar la estabilización del core.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Estiramiento de dorsal de rodillas con apoyo en banco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/estiramiento_de_dorsal_de_rodillas_con_apoyo_en_banco.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/estiramiento_de_dorsal_de_rodillas_con_apoyo_en_banco.webp',
  ARRAY['Paso 1: Colócate de rodillas frente a un banco plano a una distancia aproximada de un brazo.', 'Paso 2: Apoya los codos o antebrazos sobre el borde del banco, manteniendo las manos juntas o separadas a la anchura de los hombros.', 'Paso 3: Empuja el pecho hacia el suelo mientras desplazas los glúteos hacia atrás, sintiendo un estiramiento profundo a lo largo de los costados del torso y la espalda.', 'Paso 4: Sostén la posición de estiramiento de manera controlada y respira profundamente para relajar la musculatura.']::text[],
  'principiante',
  'Ejercicio de estiramiento estático que elonga las fibras del dorsal ancho y mejora la flexibilidad en la articulación del hombro mediante una posición de rodillas apoyadas.',
  ARRAY['Flexibilidad', 'Movilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Estiramiento de espalda alta sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/estiramiento_de_espalda_alta_sentado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/estiramiento_de_espalda_alta_sentado.webp',
  ARRAY['Paso 1: Siéntate en una silla o banco con la espalda recta y los pies firmemente apoyados en el suelo.', 'Paso 2: Entrelaza los dedos de las manos frente a ti y extiende los brazos hacia adelante, empujando con las palmas hacia afuera.', 'Paso 3: Encórvate ligeramente hacia adelante desde la zona media de la espalda mientras alejas las manos de tu pecho, sintiendo el ensanchamiento de las escápulas.', 'Paso 4: Mantén la posición estática sintiendo el estiramiento en la zona entre las escápulas antes de retornar a la posición erguida.']::text[],
  'principiante',
  'Estiramiento enfocado en la musculatura de la zona torácica y escapular, ideal para liberar tensión tras periodos de sedentarismo o entrenamiento intenso.',
  ARRAY['Flexibilidad', 'Alivio de tensión']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Rotación torácica en cuadrupedia',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/rotacion_toracica_en_cuadrupedia.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/rotacion_toracica_en_cuadrupedia.webp',
  ARRAY['Paso 1: Colócate en posición de cuadrupedia, con manos bajo los hombros y rodillas bajo las caderas.', 'Paso 2: Coloca una mano detrás de la nuca, manteniendo el codo apuntando hacia el suelo.', 'Paso 3: Rota el torso llevando el codo hacia arriba y hacia el techo, siguiendo el movimiento con la mirada y permitiendo que la columna torácica se abra.', 'Paso 4: Regresa el codo a la posición inicial acercándolo hacia la mano contraria y repite el movimiento de forma controlada antes de cambiar de lado.']::text[],
  'intermedio',
  'Ejercicio de movilidad dinámica para la columna torácica, diseñado para mejorar la capacidad de rotación del tronco y liberar restricciones en la espalda alta.',
  ARRAY['Movilidad', 'Flexibilidad torácica']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl araña con mancuernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_arana_con_mancuernas.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_arana_con_mancuernas.webp',
  ARRAY['Paso 1: Ajusta un banco inclinado a unos 45 grados y túmbate sobre él boca abajo, apoyando el pecho y dejando los brazos colgando verticalmente hacia el suelo.', 'Paso 2: Sujeta una mancuerna en cada mano con un agarre supino (palmas mirando hacia adelante).', 'Paso 3: Flexiona los codos manteniendo los brazos superiores inmóviles, elevando las mancuernas hacia los hombros mediante la contracción del bíceps.', 'Paso 4: Desciende las cargas de forma controlada hasta la extensión completa de los codos, manteniendo la tensión en la fase excéntrica.']::text[],
  'intermedio',
  'Ejercicio de aislamiento del bíceps braquial realizado en decúbito prono sobre un banco inclinado, lo que elimina la posibilidad de balanceo y mantiene los brazos en una posición de ventaja mecánica para el aislamiento muscular.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuernas en banco inclinado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_en_banco_inclinado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_en_banco_inclinado.webp',
  ARRAY['Paso 1: Ajusta el respaldo de un banco a una inclinación de entre 45 y 60 grados y siéntate apoyando completamente la espalda.', 'Paso 2: Sujeta una mancuerna en cada mano dejando que los brazos cuelguen hacia atrás, manteniendo los hombros estables.', 'Paso 3: Flexiona los codos de forma concéntrica para elevar las mancuernas hacia los hombros, manteniendo los codos fijos en todo momento.', 'Paso 4: Regresa lentamente a la posición inicial, permitiendo que el bíceps se estire completamente en la base del movimiento.']::text[],
  'intermedio',
  'Variante de curl que, gracias a la inclinación del respaldo, estira la cabeza larga del bíceps braquial en la posición inicial, aumentando la demanda mecánica y el rango de estiramiento.',
  ARRAY['Hipertrofia', 'Estiramiento activo']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuerna con agarre supino',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuerna_con_agarre_supino.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuerna_con_agarre_supino.webp',
  ARRAY['Paso 1: Ponte de pie con los pies a la anchura de las caderas y el torso erguido, sujetando una mancuerna en la mano con la palma mirando hacia adelante.', 'Paso 2: Manteniendo el codo pegado al torso, flexiona el brazo de forma concentrada hasta contraer totalmente el bíceps.', 'Paso 3: Sostén la contracción durante un segundo en el punto máximo de flexión.', 'Paso 4: Desciende la mancuerna de manera controlada hasta retornar a la posición inicial de extensión completa del codo.']::text[],
  'principiante',
  'Ejercicio de aislamiento enfocado en la flexión del codo donde el agarre supino garantiza la máxima implicación del bíceps braquial en su función principal de supinación y flexión.',
  ARRAY['Hipertrofia', 'Fuerza aislada']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl martillo con mancuerna con agarre neutro',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_martillo_con_mancuerna_con_agarre_neutro.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_martillo_con_mancuerna_con_agarre_neutro.webp',
  ARRAY['Paso 1: Sujeta una mancuerna con agarre neutro (palmas mirando hacia el cuerpo) mientras estás de pie con el tronco estable.', 'Paso 2: Flexiona el codo para elevar la mancuerna hacia el hombro homolateral, manteniendo las palmas enfrentadas en todo momento.', 'Paso 3: Contrae los músculos de la zona lateral del brazo en la parte superior del movimiento.', 'Paso 4: Regresa lentamente a la posición de inicio, manteniendo la tensión en la fase de descenso.']::text[],
  'principiante',
  'Variante de flexión de codo que mediante un agarre neutro permite una transferencia eficiente de fuerza hacia el braquiorradial y el braquial anterior, optimizando el desarrollo del antebrazo y brazo.',
  ARRAY['Hipertrofia', 'Fuerza de agarre']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl martillo con mancuernas en banco inclinado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_martillo_con_mancuernas_en_banco_inclinado.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_martillo_con_mancuernas_en_banco_inclinado.webp',
  ARRAY['Paso 1: Siéntate en un banco inclinado a 45 grados apoyando bien la espalda y sosteniendo una mancuerna en cada mano con agarre neutro.', 'Paso 2: Flexiona ambos codos para elevar las mancuernas manteniendo las palmas enfrentadas y los codos en posición fija.', 'Paso 3: Aprieta los brazos en la fase concéntrica, asegurando que no haya rotación de la muñeca.', 'Paso 4: Desciende las cargas de forma controlada hasta la extensión completa de los codos, permitiendo un ligero estiramiento al final del recorrido.']::text[],
  'intermedio',
  'Ejercicio que combina la estabilidad del banco inclinado con el agarre neutro, permitiendo un mayor estiramiento del braquial anterior y braquiorradial al desplazar ligeramente el brazo hacia atrás.',
  ARRAY['Hipertrofia', 'Desarrollo del antebrazo']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla trasera con barra (postura estándar)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_trasera_con_barra_postura_estandar.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_trasera_con_barra_postura_estandar.webp',
  ARRAY['Paso 1: Colócate bajo la barra en un rack y apóyala sobre los trapecios. Separa los pies a la anchura de los hombros con las puntas ligeramente hacia afuera.', 'Paso 2: Retira la barra y mantén el core contraído y el pecho erguido.', 'Paso 3: Realiza la fase excéntrica flexionando caderas y rodillas simultáneamente hasta que los muslos estén paralelos al suelo.', 'Paso 4: Empuja desde los talones para extender caderas y rodillas hasta regresar a la posición inicial.']::text[],
  'intermedio',
  'Ejercicio fundamental de fuerza compuesto donde la carga se apoya sobre los trapecios, permitiendo un trabajo integral de la musculatura del tren inferior con un patrón de movimiento completo.',
  ARRAY['Hipertrofia', 'Fuerza máxima']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla trasera con barra (postura cerrada)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_trasera_con_barra_postura_cerrada.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_trasera_con_barra_postura_cerrada.webp',
  ARRAY['Paso 1: Colócate bajo la barra y apóyala sobre los trapecios. Coloca los pies con una separación menor a la anchura de los hombros.', 'Paso 2: Mantén el torso lo más erguido posible para enfatizar el trabajo de las rodillas.', 'Paso 3: Desciende controladamente flexionando las rodillas hasta alcanzar la profundidad adecuada.', 'Paso 4: Extiende las piernas utilizando la fuerza de los cuádriceps para volver a la posición erguida.']::text[],
  'intermedio',
  'Variante de la sentadilla tradicional donde una base de sustentación más estrecha traslada mayor énfasis mecánico hacia el vasto lateral del cuádriceps.',
  ARRAY['Hipertrofia', 'Enfoque en cuádriceps']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla sumo con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_sumo_con_barra.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_sumo_con_barra.webp',
  ARRAY['Paso 1: Apoya la barra sobre los trapecios y separa los pies más allá de la anchura de los hombros, rotando las puntas hacia afuera.', 'Paso 2: Mantén el pecho erguido y desciende flexionando caderas y rodillas.', 'Paso 3: Asegúrate de que las rodillas sigan la línea de las puntas de los pies durante todo el recorrido.', 'Paso 4: Empuja con los talones y contrae glúteos y aductores para subir hasta la posición inicial.']::text[],
  'intermedio',
  'Ejercicio de tren inferior realizado con una base muy amplia que permite una mayor participación de los músculos aductores y una posición de torso más vertical.',
  ARRAY['Hipertrofia', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de piernas a 45° (pies altos)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_pies_altos.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_pies_altos.webp',
  ARRAY['Paso 1: Siéntate en la prensa y coloca los pies en la parte alta de la plataforma.', 'Paso 2: Libera el seguro y desciende la plataforma hasta que las rodillas alcancen un ángulo cercano a los 90 grados.', 'Paso 3: Mantén la espalda baja siempre apoyada contra el respaldo.', 'Paso 4: Empuja la plataforma mediante la extensión de caderas y rodillas sin bloquear las articulaciones al finalizar.']::text[],
  'intermedio',
  'Variante de prensa de piernas donde la posición superior de los pies aumenta la flexión de cadera, trasladando el mayor esfuerzo hacia la cadena posterior.',
  ARRAY['Hipertrofia', 'Fortalecimiento de cadena posterior']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de piernas a 45° (pies bajos)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_pies_bajos.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_pies_bajos.webp',
  ARRAY['Paso 1: Siéntate en la prensa y coloca los pies en la parte baja de la plataforma, evitando que los talones se separen.', 'Paso 2: Desciende la plataforma controladamente, permitiendo que las rodillas se desplacen hacia adelante.', 'Paso 3: Asegúrate de mantener un rango de movimiento que no comprometa la integridad de la rodilla.', 'Paso 4: Extiende las piernas utilizando la fuerza de los cuádriceps para empujar la carga.']::text[],
  'intermedio',
  'Variante de prensa que coloca los pies en la parte inferior de la plataforma, forzando una mayor flexión de rodilla y enfocando el trabajo en el cuádriceps.',
  ARRAY['Hipertrofia', 'Enfoque en cuádriceps']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de piernas a 45° (postura sumo)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_postura_sumo_enfasis_en_aductores.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_postura_sumo_enfasis_en_aductores.webp',
  ARRAY['Paso 1: Siéntate en la prensa y coloca los pies con una apertura amplia, rotando las puntas hacia el exterior de la plataforma.', 'Paso 2: Desciende la plataforma permitiendo que las rodillas se abran lateralmente.', 'Paso 3: Alcanza un rango de profundidad que permita sentir el estiramiento en la cara interna del muslo.', 'Paso 4: Empuja la plataforma con fuerza, manteniendo la alineación de las rodillas con los pies.']::text[],
  'intermedio',
  'Variante de prensa con pies separados y puntas hacia afuera, ideal para enfatizar la activación de los aductores y aumentar la profundidad en la zona interna del muslo.',
  ARRAY['Hipertrofia', 'Desarrollo de aductores']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de piernas a 45° (postura sumo)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_postura_sumo.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_postura_sumo.webp',
  ARRAY['Paso 1: Colócate en la prensa de piernas y sitúa tus pies en la plataforma con una separación mayor a la de tus hombros y las puntas rotadas hacia el exterior.', 'Paso 2: Libera el seguro de la máquina y desciende la plataforma de forma controlada permitiendo que las rodillas se desplacen lateralmente hacia afuera.', 'Paso 3: Baja la plataforma hasta que sientas un estiramiento profundo en la cara interna de los muslos sin perder el contacto de la zona lumbar con el respaldo.', 'Paso 4: Empuja la plataforma mediante la extensión coordinada de caderas y rodillas, asegurándote de que las rodillas no colapsen hacia el interior durante el ascenso.']::text[],
  'intermedio',
  'Variante de prensa de piernas realizada con una base de sustentación amplia y rotación externa de caderas para enfatizar el trabajo de la musculatura aductora y el glúteo mayor.',
  ARRAY['Hipertrofia', 'Fortalecimiento de aductores']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de piernas a 45° (postura cerrada)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_postura_cerrada_enfasis_en_vasto_lateral.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_postura_cerrada_enfasis_en_vasto_lateral.webp',
  ARRAY['Paso 1: Sitúate en la máquina de prensa y coloca tus pies en el centro de la plataforma con una separación menor a la anchura de tus caderas.', 'Paso 2: Desbloquea la plataforma y desciende el peso manteniendo los talones totalmente apoyados en la superficie durante todo el recorrido.', 'Paso 3: Desciende con un control absoluto hasta que tus rodillas formen un ángulo agudo, siempre manteniendo la espalda baja firmemente apoyada en el respaldo.', 'Paso 4: Extiende las piernas empujando la carga, concentrando la fuerza en los cuádriceps y evitando bloquear las rodillas en la fase final del movimiento.']::text[],
  'intermedio',
  'Variante de prensa que utiliza una base de sustentación estrecha, lo cual desplaza una mayor demanda mecánica hacia el vasto lateral del cuádriceps.',
  ARRAY['Hipertrofia', 'Enfoque en cuádriceps']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de piernas a 45° (postura estándar)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_postura_estandar_enfasis_en_cuadriceps.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_postura_estandar_enfasis_en_cuadriceps.webp',
  ARRAY['Paso 1: Colócate en la prensa y sitúa tus pies en la plataforma a la misma anchura que tus hombros y con una ligera rotación externa de las puntas.', 'Paso 2: Libera la carga y desciende la plataforma de manera controlada hasta que tus rodillas alcancen un ángulo aproximado de 90 grados.', 'Paso 3: Asegúrate de que tu zona lumbar y pelvis permanezcan en contacto total con el respaldo durante el descenso para evitar esfuerzos inadecuados en la columna.', 'Paso 4: Empuja la carga mediante la extensión coordinada de rodillas y caderas, deteniendo el movimiento justo antes de que las articulaciones de la rodilla se bloqueen.']::text[],
  'principiante',
  'Ejercicio de empuje horizontal para el tren inferior que, realizado con una postura neutra, proporciona un estímulo equilibrado en toda la musculatura del muslo.',
  ARRAY['Hipertrofia', 'Desarrollo general de fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de piernas a 45° (pies bajos)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_pies_bajos_enfasis_en_cuadriceps.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_pies_bajos_enfasis_en_cuadriceps.webp',
  ARRAY['Paso 1: Posiciona tus pies en la parte inferior de la plataforma de la prensa, manteniendo la anchura de tus hombros y los talones apoyados firmemente.', 'Paso 2: Desbloquea la plataforma y baja la carga controladamente, permitiendo que las rodillas se desplacen hacia adelante por encima de la línea de los dedos de los pies.', 'Paso 3: Desciende hasta el límite de tu movilidad articular manteniendo siempre el apoyo firme de toda la planta del pie en la plataforma.', 'Paso 4: Extiende las piernas utilizando la fuerza de los cuádriceps para empujar el peso, controlando el retorno a la posición de inicio.']::text[],
  'intermedio',
  'Variante donde el posicionamiento inferior de los pies en la plataforma maximiza la flexión de rodilla, incrementando significativamente la carga mecánica sobre el cuádriceps.',
  ARRAY['Hipertrofia', 'Enfoque en cuádriceps']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de piernas a 45° (pies altos)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_pies_altos_enfasis_en_gluteo_e_isquiosurales.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_a_45_pies_altos_enfasis_en_gluteo_e_isquiosurales.webp',
  ARRAY['Paso 1: Coloca tus pies en la parte superior de la plataforma de prensa, manteniendo una separación igual a la anchura de tus hombros.', 'Paso 2: Libera la carga y desciende la plataforma de forma lenta y controlada, asegurándote de que la rodilla se mantenga en una trayectoria alineada con el pie.', 'Paso 3: Desciende hasta alcanzar un rango de movimiento que involucre una mayor flexión de la articulación de la cadera.', 'Paso 4: Empuja la plataforma utilizando principalmente la fuerza de la cadena posterior y el glúteo, manteniendo el control de la carga durante todo el movimiento.']::text[],
  'intermedio',
  'Posición de los pies en la parte alta de la plataforma que aumenta la flexión de cadera, favoreciendo un mayor reclutamiento de glúteos e isquiosurales durante el empuje.',
  ARRAY['Hipertrofia', 'Desarrollo de cadena posterior']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo sentado en polea baja con agarre ancho prono (Espalda alta y deltoides posterior)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_sentado_en_polea_baja_con_agarre_ancho_prono_espalda_alta_y_deltoides_posterior.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_sentado_en_polea_baja_con_agarre_ancho_prono_espalda_alta_y_deltoides_posterior.webp',
  ARRAY['Paso 1: Siéntate frente a la polea baja, sujeta la barra larga con un agarre ancho en posición prono (palmas hacia abajo) y apoya los pies firmemente.', 'Paso 2: Mantén el torso estable y ligeramente inclinado hacia adelante para iniciar el movimiento.', 'Paso 3: Tracciona la barra hacia la zona del esternón, permitiendo que los codos se abran lateralmente para maximizar el trabajo escapular.', 'Paso 4: Regresa lentamente a la posición inicial manteniendo el control de la fase excéntrica y evitando redondear la espalda.']::text[],
  'intermedio',
  'Ejercicio de tracción horizontal que, mediante un agarre ancho y prono, desplaza el énfasis de la carga hacia la parte superior de la espalda y la porción posterior del hombro.',
  ARRAY['Hipertrofia', 'Mejora postural', 'Desarrollo de espalda alta']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo sentado en polea baja con agarre estrecho neutro (Dorsal ancho)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_sentado_en_polea_baja_con_agarre_estrecho_neutro_dorsal_ancho.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_sentado_en_polea_baja_con_agarre_estrecho_neutro_dorsal_ancho.webp',
  ARRAY['Paso 1: Siéntate en la máquina de remo, apoya los pies en la plataforma y sujeta el agarre estrecho neutro con ambas manos.', 'Paso 2: Mantén la espalda recta y el core activado antes de iniciar el movimiento.', 'Paso 3: Realiza la tracción llevando el agarre hacia la zona inferior del abdomen, retrayendo las escápulas y pegando los codos al torso.', 'Paso 4: Extiende los brazos controladamente hasta la posición de estiramiento inicial sin encorvar la columna.']::text[],
  'principiante',
  'Ejercicio de tracción horizontal enfocado en el desarrollo del grosor del dorsal ancho mediante el uso de un agarre estrecho neutro que permite un mayor recorrido de tracción.',
  ARRAY['Hipertrofia', 'Fuerza de tracción']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo sentado en polea baja con agarre biacromial supino (Dorsal ancho y espalda media)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_sentado_en_polea_baja_con_agarre_biacromial_supino_dorsal_ancho_y_espalda_media.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_sentado_en_polea_baja_con_agarre_biacromial_supino_dorsal_ancho_y_espalda_media.webp',
  ARRAY['Paso 1: Siéntate frente a la polea baja, apoya los pies y sujeta la barra recta con un agarre supino (palmas hacia arriba) a la anchura de tus hombros (biacromial).', 'Paso 2: Mantén el pecho erguido y los hombros en posición neutra.', 'Paso 3: Tracciona la barra hacia el abdomen, enfocándote en empujar los codos hacia atrás y apretar las escápulas.', 'Paso 4: Regresa a la posición inicial extendiendo los brazos lentamente para mantener la tensión constante.']::text[],
  'intermedio',
  'Variante de remo que utiliza un agarre supino a la anchura de los hombros, favoreciendo una mayor implicación del bíceps y una excelente activación del dorsal ancho y musculatura interescapular.',
  ARRAY['Hipertrofia', 'Fuerza', 'Desarrollo de espalda completa']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Hip thrust con mancuerna (Glúteo mayor)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/hip_thrust_con_mancuerna_gluteo_mayor.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/hip_thrust_con_mancuerna_gluteo_mayor.webp',
  ARRAY['Paso 1: Siéntate en el suelo con la parte superior de la espalda apoyada contra un banco y coloca una mancuerna sobre la zona de la pelvis.', 'Paso 2: Flexiona las rodillas y apoya las plantas de los pies firmemente en el suelo a la anchura de las caderas.', 'Paso 3: Eleva la pelvis mediante la extensión de cadera hasta que el torso y los muslos formen una línea recta, apretando los glúteos en la parte superior.', 'Paso 4: Desciende la pelvis de manera controlada hasta la posición inicial sin perder la tensión muscular.']::text[],
  'intermedio',
  'Ejercicio de aislamiento enfocado en la extensión de cadera para el desarrollo del glúteo mayor, utilizando una mancuerna sobre la pelvis como carga externa.',
  ARRAY['Hipertrofia', 'Fuerza de cadena posterior']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla búlgara con mancuernas (Cuádriceps)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_bulgara_con_mancuernas_cuadriceps.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_bulgara_con_mancuernas_cuadriceps.webp',
  ARRAY['Paso 1: Colócate de espaldas a un banco y apoya el empeine de un pie sobre él mientras sujetas una mancuerna en cada mano.', 'Paso 2: Mantén el torso erguido y desciende flexionando la rodilla y cadera de la pierna adelantada hasta que el muslo esté paralelo al suelo.', 'Paso 3: Mantén la rodilla alineada con la punta del pie durante todo el descenso.', 'Paso 4: Empuja con el talón de la pierna adelantada para regresar a la posición inicial.']::text[],
  'intermedio',
  'Ejercicio unilateral de tren inferior que enfatiza el trabajo de cuádriceps mediante una gran amplitud de rango de movimiento y estabilización unipodal.',
  ARRAY['Hipertrofia', 'Fuerza unilateral', 'Equilibrio']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Deadlift unilateral con mancuerna y apoyo (Isquiosurales)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/deadlift_unilateral_con_mancuerna_y_apoyo_isquiosurales.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/deadlift_unilateral_con_mancuerna_y_apoyo_isquiosurales.webp',
  ARRAY['Paso 1: Sujeta una mancuerna en la mano contraria a la pierna de apoyo y apoya la mano libre en un soporte estable.', 'Paso 2: Inicia la bisagra de cadera llevando la pierna libre hacia atrás mientras el torso se inclina hacia adelante.', 'Paso 3: Desciende la mancuerna manteniendo la espalda recta hasta sentir un estiramiento en la parte posterior de la pierna de apoyo.', 'Paso 4: Regresa a la posición vertical mediante una extensión de cadera controlada.']::text[],
  'intermedio',
  'Movimiento de bisagra de cadera unipodal para fortalecer isquiosurales y glúteos, utilizando un apoyo externo para facilitar el equilibrio.',
  ARRAY['Fortalecimiento isquiosural', 'Estabilidad', 'Propiocepción']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Hip thrust con mancuerna (Glúteo mayor)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/hip_thrust_con_mancuerna_gluteo_mayor.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/hip_thrust_con_mancuerna_gluteo_mayor.webp',
  ARRAY['Paso 1: Siéntate en el suelo con la parte superior de la espalda apoyada contra un banco y coloca una mancuerna sobre la zona de la pelvis.', 'Paso 2: Flexiona las rodillas y apoya las plantas de los pies firmemente en el suelo a la anchura de las caderas.', 'Paso 3: Eleva la pelvis mediante la extensión de cadera hasta que el torso y los muslos formen una línea recta, apretando los glúteos en la parte superior.', 'Paso 4: Desciende la pelvis de manera controlada hasta la posición inicial sin perder la tensión muscular.']::text[],
  'intermedio',
  'Ejercicio de aislamiento enfocado en la extensión de cadera para el desarrollo del glúteo mayor, utilizando una mancuerna sobre la pelvis como carga externa.',
  ARRAY['Hipertrofia', 'Fuerza de cadena posterior']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Donkey calf raise unilateral con mancuerna en déficit (Gastrocnemio)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/donkey_calf_raise_unilateral_con_mancuerna_en_deficit_gastrocnemio.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/donkey_calf_raise_unilateral_con_mancuerna_en_deficit_gastrocnemio.webp',
  ARRAY['Paso 1: Apoya el antepié sobre un escalón o déficit, sostén una mancuerna en el lado del pie que trabaja y apóyate con la mano libre.', 'Paso 2: Realiza una flexión de cadera inclinando el torso y eleva el talón lo máximo posible mediante una contracción plantar.', 'Paso 3: Sostén un instante la contracción en la parte alta del movimiento.', 'Paso 4: Desciende el talón por debajo de la línea del escalón de manera controlada para lograr un estiramiento profundo.']::text[],
  'avanzado',
  'Ejercicio de elevación de talón con flexión de cadera profunda, realizado sobre un déficit para maximizar el estiramiento y trabajo del tríceps sural.',
  ARRAY['Hipertrofia de gemelos', 'Fuerza funcional']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  '[Gym] Aperturas en polea baja en banco inclinado con agarre neutro (Pectoral superior) / [Casa] flexión inclinada con déficit en sillas (Pectoral inferior)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/gym_aperturas_en_polea_baja_en_banco_inclinado_con_agarre_neutro_pectoral_superior_casa_push_up_inclinado_con_deficit_en_sillas_pectoral_inferior.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/gym_aperturas_en_polea_baja_en_banco_inclinado_con_agarre_neutro_pectoral_superior_casa_push_up_inclinado_con_deficit_en_sillas_pectoral_inferior.webp',
  ARRAY['Paso 1: Para la versión de gimnasio, ajusta un banco a 45 grados entre poleas bajas y realiza aperturas con agarre neutro.', 'Paso 2: Para la versión de casa, coloca las manos sobre dos sillas estables para realizar flexiones con mayor rango de recorrido.', 'Paso 3: Mantén el control constante en la fase excéntrica y una contracción focalizada en la fase concéntrica.', 'Paso 4: Asegúrate de mantener la alineación escapular durante todo el movimiento para proteger el hombro.']::text[],
  'intermedio',
  'Catálogo dual que incluye una variante de aislamiento para el pectoral superior en poleas y un ejercicio de empuje con peso corporal sobre déficit para el pectoral inferior.',
  ARRAY['Hipertrofia', 'Definición muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  '[Gym] Cruces en polea alta (Pectoral inferior) / [Casa] flexión declinada con pies elevados (Pectoral superior)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/gym_cruces_en_polea_alta_pectoral_inferior_casa_push_up_declinado_con_pies_elevados_pectoral_superior.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/gym_cruces_en_polea_alta_pectoral_inferior_casa_push_up_declinado_con_pies_elevados_pectoral_superior.webp',
  ARRAY['Paso 1: En gimnasio, realiza cruces de polea alta traccionando hacia abajo y al centro frente a tus muslos.', 'Paso 2: En casa, apoya los pies en una superficie elevada para realizar flexiones que enfaticen la parte superior del pectoral.', 'Paso 3: Ejecuta ambos movimientos con un tempo controlado, evitando el uso de inercia.', 'Paso 4: Mantén una postura estable y el core contraído durante toda la ejecución.']::text[],
  'intermedio',
  'Catálogo dual que presenta un movimiento de aducción horizontal para la parte baja del pecho en poleas y un empuje declinado para la porción clavicular.',
  ARRAY['Hipertrofia', 'Estética']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  '[Gym] Fondos en paralelas con inclinación de torso (Pectoral inferior) / [Casa] fondos en banco en silla (Tríceps braquial)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/gym_dips_en_paralelas_con_inclinacion_de_torso_pectoral_inferior_casa_bench_dips_en_silla_triceps_braquial.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/gym_dips_en_paralelas_con_inclinacion_de_torso_pectoral_inferior_casa_bench_dips_en_silla_triceps_braquial.webp',
  ARRAY['Paso 1: En gimnasio, realiza fondos en paralelas inclinando el torso hacia adelante para cargar el pectoral inferior.', 'Paso 2: En casa, utiliza una silla para realizar fondos centrando el esfuerzo en la extensión del codo para el tríceps.', 'Paso 3: Asegúrate de mantener los hombros alejados de las orejas en ambos ejercicios.', 'Paso 4: Controla el descenso y empuja explosivamente de forma segura para las articulaciones.']::text[],
  'intermedio',
  'Catálogo dual que combina fondos en paralelas para enfatizar el pecho bajo y fondos entre bancos para el trabajo específico de tríceps.',
  ARRAY['Fuerza', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch abdominal (Recto abdominal superior)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/crunch_abdominal_recto_abdominal_superior.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/crunch_abdominal_recto_abdominal_superior.webp',
  ARRAY['Paso 1: Túmbate boca arriba en el suelo con las rodillas flexionadas y las plantas de los pies apoyadas.', 'Paso 2: Coloca las manos suavemente detrás de la cabeza o cruzadas sobre el pecho, evitando tirar del cuello.', 'Paso 3: Realiza una flexión de la columna levantando los hombros del suelo mediante la contracción del abdomen.', 'Paso 4: Mantén la zona lumbar pegada al suelo y desciende lentamente hasta la posición inicial.']::text[],
  'principiante',
  'Ejercicio de flexión del tronco diseñado para aislar la musculatura de la pared abdominal, centrándose en la parte superior del recto abdominal.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de piernas en decúbito supino (Recto abdominal inferior)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevacion_de_piernas_en_decubito_supino_recto_abdominal_inferior.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevacion_de_piernas_en_decubito_supino_recto_abdominal_inferior.webp',
  ARRAY['Paso 1: Túmbate boca arriba con las piernas estiradas y los brazos extendidos a los costados para mayor estabilidad.', 'Paso 2: Eleva ambas piernas simultáneamente hacia el techo manteniendo las rodillas extendidas o con una ligera flexión.', 'Paso 3: Sube las piernas hasta que formen un ángulo de 90 grados con el torso, evitando arquear la espalda baja.', 'Paso 4: Desciende las piernas de forma controlada sin llegar a tocar el suelo, manteniendo la tensión en el abdomen inferior.']::text[],
  'intermedio',
  'Movimiento de flexión de cadera que, al realizarse en decúbito supino, exige una fuerte contracción isométrica y dinámica del abdomen para estabilizar la pelvis.',
  ARRAY['Hipertrofia', 'Estabilidad lumbopélvica']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Crunch bicicleta (Oblicuos)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/crunch_bicicleta_oblicuos.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/crunch_bicicleta_oblicuos.webp',
  ARRAY['Paso 1: Túmbate boca arriba con las manos detrás de la cabeza y las piernas elevadas con rodillas a 90 grados.', 'Paso 2: Lleva el codo derecho hacia la rodilla izquierda al mismo tiempo que extiendes la pierna derecha.', 'Paso 3: Alterna el movimiento llevando el codo izquierdo hacia la rodilla derecha de forma rítmica y controlada.', 'Paso 4: Mantén la mirada al frente y asegúrate de que la rotación provenga del torso y no solo del cuello.']::text[],
  'intermedio',
  'Ejercicio dinámico de rotación de tronco que combina la flexión abdominal con la activación cruzada de los oblicuos mediante un movimiento de pedaleo.',
  ARRAY['Resistencia muscular', 'Hipertrofia de oblicuos']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Hollow body hold isométrico (Core)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/hollow_body_hold_isometrico_core.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/hollow_body_hold_isometrico_core.webp',
  ARRAY['Paso 1: Túmbate boca arriba con los brazos extendidos por encima de la cabeza y las piernas estiradas.', 'Paso 2: Eleva simultáneamente las piernas, la cabeza y los hombros del suelo, manteniendo la zona lumbar bien pegada al piso.', 'Paso 3: Mantén esta posición en forma de media luna, contrayendo fuertemente el abdomen.', 'Paso 4: Sostén la posición durante el tiempo establecido respirando de forma controlada.']::text[],
  'intermedio',
  'Ejercicio isométrico fundamental para desarrollar la fuerza y el control del core, manteniendo la columna en una posición neutra y segura.',
  ARRAY['Estabilidad del core', 'Fuerza isométrica']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión lumbar alterna en decúbito prono (Erectores espinales)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/extension_lumbar_alterna_en_decubito_prono_erectores_espinales.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/extension_lumbar_alterna_en_decubito_prono_erectores_espinales.webp',
  ARRAY['Paso 1: Túmbate boca abajo con las piernas estiradas y los brazos extendidos hacia adelante.', 'Paso 2: Eleva simultáneamente el brazo derecho y la pierna izquierda, manteniendo una ligera contracción en la zona lumbar.', 'Paso 3: Alterna el movimiento elevando el brazo izquierdo y la pierna derecha de forma fluida y controlada.', 'Paso 4: Evita movimientos bruscos y mantén la cabeza en posición neutra durante toda la serie.']::text[],
  'principiante',
  'Ejercicio de cadena posterior diseñado para fortalecer los músculos de la zona baja de la espalda mediante la elevación alternada de miembros.',
  ARRAY['Fortalecimiento lumbar', 'Salud postural']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Peso muerto rumano con barra (Glúteo mayor)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/romanian_deadlift_con_barra_gluteo_mayor.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/romanian_deadlift_con_barra_gluteo_mayor.webp',
  ARRAY['Paso 1: Colócate de pie con los pies a la anchura de las caderas, sujetando la barra con un agarre prono frente a los muslos.', 'Paso 2: Realiza una bisagra de cadera empujando los glúteos hacia atrás mientras mantienes la espalda neutra y las rodillas bloqueadas en una flexión mínima.', 'Paso 3: Desciende la barra pegada a las piernas hasta notar un estiramiento profundo en glúteos e isquiosurales, sin permitir que la barra toque el suelo.', 'Paso 4: Contrae activamente los glúteos para regresar a la posición erguida, manteniendo el control total de la carga.']::text[],
  'intermedio',
  'Ejercicio de bisagra de cadera enfocado en el estiramiento activo y fortalecimiento del glúteo mayor, manteniendo una flexión mínima y constante de rodillas para minimizar la implicación del cuádriceps.',
  ARRAY['Hipertrofia', 'Fuerza de cadena posterior']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Peso muerto piernas rígidas con barra (Isquiosurales)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/stiff_leg_deadlift_con_barra_isquiosurales.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/stiff_leg_deadlift_con_barra_isquiosurales.webp',
  ARRAY['Paso 1: Sujeta la barra con agarre prono, mantén los pies a la anchura de los hombros y las piernas con una flexión de rodilla mínima, casi bloqueadas pero no hiperextendidas.', 'Paso 2: Inclina el torso hacia adelante mediante una bisagra de cadera pronunciada, manteniendo la espalda firme y neutra.', 'Paso 3: Baja la barra hasta donde tu movilidad lo permita, buscando sentir la tensión máxima en la parte posterior de los muslos.', 'Paso 4: Regresa a la posición vertical mediante la extensión de cadera, manteniendo el peso cerca del cuerpo durante todo el recorrido.']::text[],
  'intermedio',
  'Variante de peso muerto donde las piernas se mantienen casi totalmente extendidas, priorizando el estiramiento y trabajo directo de los isquiosurales a través de una bisagra de cadera profunda.',
  ARRAY['Hipertrofia', 'Fuerza de cadena posterior']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  '[Izquierda] Peso muerto rumano con barra (Glúteo mayor) / [Derecha] peso muerto piernas rígidas con barra (Isquiosurales)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/izquierda_romanian_deadlift_con_barra_gluteo_mayor_derecha_stiff_leg_deadlift_con_barra_isquiosurales.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/izquierda_romanian_deadlift_con_barra_gluteo_mayor_derecha_stiff_leg_deadlift_con_barra_isquiosurales.webp',
  ARRAY['Paso 1: Para la versión izquierda (Glúteo), mantén una flexión de rodilla ligera y constante durante todo el recorrido de bisagra.', 'Paso 2: Para la versión derecha (Isquios), mantén las piernas casi rectas durante el descenso para maximizar el estiramiento de los isquiosurales.', 'Paso 3: En ambos casos, asegura que el movimiento provenga exclusivamente de la articulación de la cadera.', 'Paso 4: Mantén siempre la columna en posición neutra y los hombros activos para evitar lesiones lumbares.']::text[],
  'avanzado',
  'Comparativa técnica que ilustra la diferencia en el patrón motor entre el Romanian deadlift para glúteos y el Stiff-leg deadlift enfocado en isquiosurales.',
  ARRAY['Análisis biomecánico', 'Educación técnica']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Postura isométrica en decúbito supino (Erectores espinales)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/postura_isometrica_en_decubito_supino_erectores_espinales.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/postura_isometrica_en_decubito_supino_erectores_espinales.webp',
  ARRAY['Paso 1: Túmbate boca arriba con las piernas estiradas y los brazos relajados a los costados.', 'Paso 2: Activa la musculatura de la espalda baja presionando ligeramente la zona lumbar contra el suelo sin realizar un esfuerzo excesivo.', 'Paso 3: Mantén esta contracción isométrica controlada, asegurando que el torso permanezca alineado y estable.', 'Paso 4: Sostén la postura durante el tiempo indicado respirando de forma natural y rítmica.']::text[],
  'principiante',
  'Ejercicio estático destinado a activar y estabilizar la musculatura de la columna vertebral en posición acostada, promoviendo una postura neutra y controlada.',
  ARRAY['Estabilidad', 'Activación muscular', 'Control motor']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elongación axial en decúbito supino con tobillos cruzados y manos en la nuca (Erectores espinales)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elongacion_axial_en_decubito_supino_con_tobillos_cruzados_y_manos_en_la_nuca_erectores_espinales.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elongacion_axial_en_decubito_supino_con_tobillos_cruzados_y_manos_en_la_nuca_erectores_espinales.webp',
  ARRAY['Paso 1: Túmbate boca arriba, cruza los tobillos y coloca las manos detrás de la nuca con los codos abiertos.', 'Paso 2: Intenta alargar el cuerpo desde la coronilla hasta los talones mientras mantienes la espalda baja en contacto con el suelo.', 'Paso 3: Genera una ligera tensión hacia arriba desde el cuello y los hombros, manteniendo los erectores espinales comprometidos en el esfuerzo.', 'Paso 4: Mantén la posición estática sintiendo el trabajo en la espalda sin elevar el torso.']::text[],
  'intermedio',
  'Técnica de estiramiento y activación que busca alargar la columna vertebral y fortalecer los erectores espinales mediante una postura de tensión controlada.',
  ARRAY['Descompresión vertebral', 'Fortalecimiento', 'Postura']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Postura de reposo constructivo en decúbito supino con abducción de caderas (Zona lumbar)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/postura_de_reposo_constructivo_en_decubito_supino_con_abduccion_de_caderas_zona_lumbar.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/postura_de_reposo_constructivo_en_decubito_supino_con_abduccion_de_caderas_zona_lumbar.webp',
  ARRAY['Paso 1: Túmbate boca arriba, flexiona las rodillas y junta las plantas de los pies, dejando que las rodillas caigan hacia afuera por gravedad.', 'Paso 2: Relaja los hombros y asegúrate de que toda la columna esté en contacto con el suelo.', 'Paso 3: Respira profundamente, permitiendo que la zona lumbar se relaje y se libere de cualquier presión acumulada.', 'Paso 4: Mantén esta postura durante varios minutos para favorecer el descanso del sistema muscular de la espalda.']::text[],
  'principiante',
  'Posición de descanso terapéutico diseñada para relajar la musculatura paravertebral y liberar tensiones en la región lumbar mediante la apertura de caderas.',
  ARRAY['Relajación', 'Alivio de tensión', 'Movilidad de cadera']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Rotación lumbar en decúbito supino con cruce de pierna izquierda hacia la derecha (Cuadrado lumbar y erectores espinales)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/rotacion_lumbar_en_decubito_supino_con_cruce_de_pierna_izquierda_hacia_la_derecha_cuadrado_lumbar_y_erectores_espinales.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/rotacion_lumbar_en_decubito_supino_con_cruce_de_pierna_izquierda_hacia_la_derecha_cuadrado_lumbar_y_erectores_espinales.webp',
  ARRAY['Paso 1: Túmbate boca arriba con los brazos en cruz y las piernas estiradas.', 'Paso 2: Flexiona la pierna izquierda y crúzala sobre el cuerpo hacia el lado derecho, buscando tocar el suelo con la rodilla si es posible.', 'Paso 3: Mantén los hombros bien pegados al suelo mientras realizas la rotación, sintiendo el estiramiento en la zona lumbar izquierda.', 'Paso 4: Sostén la posición de rotación durante unos segundos y vuelve lentamente al centro.']::text[],
  'principiante',
  'Movimiento de movilidad asistida para la región baja de la espalda, que busca estirar los músculos laterales y posteriores mediante una rotación controlada.',
  ARRAY['Movilidad', 'Estiramiento', 'Descompresión']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Rotación lumbar en decúbito supino con cruce de pierna izquierda hacia la izquierda (Cuadrado lumbar y erectores espinales)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/rotacion_lumbar_en_decubito_supino_con_cruce_de_pierna_izquierda_hacia_la_izquierda_cuadrado_lumbar_y_erectores_espinales.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/rotacion_lumbar_en_decubito_supino_con_cruce_de_pierna_izquierda_hacia_la_izquierda_cuadrado_lumbar_y_erectores_espinales.webp',
  ARRAY['Paso 1: Túmbate boca arriba, flexiona la pierna izquierda y ábrela hacia el costado izquierdo sin mover la pelvis excesivamente.', 'Paso 2: Permite que la rodilla se acerque al suelo por el lateral, manteniendo la espalda firme contra la base.', 'Paso 3: Siente cómo se elonga el tejido conectivo en el lado izquierdo de la espalda baja durante la apertura.', 'Paso 4: Mantén el control del movimiento y respira pausadamente mientras sostienes la posición.']::text[],
  'principiante',
  'Movimiento de movilidad lateral que enfoca el estiramiento en el lado izquierdo del cuadrado lumbar y erectores espinales mediante una rotación externa.',
  ARRAY['Movilidad lateral', 'Estiramiento']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Rotación lumbar en decúbito supino con cruce de pierna derecha hacia la derecha (Cuadrado lumbar y erectores espinales)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/rotacion_lumbar_en_decubito_supino_con_cruce_de_pierna_derecha_hacia_la_derecha_cuadrado_lumbar_y_erectores_espinales.mp4',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/rotacion_lumbar_en_decubito_supino_con_cruce_de_pierna_derecha_hacia_la_derecha_cuadrado_lumbar_y_erectores_espinales.webp',
  ARRAY['Paso 1: Túmbate boca arriba y flexiona la pierna derecha para prepararte para el movimiento.', 'Paso 2: Abre la pierna derecha hacia el lado derecho, buscando aproximar la rodilla al suelo mientras mantienes la espalda estable.', 'Paso 3: Siente el estiramiento profundo en el cuadrado lumbar y erectores espinales del lado derecho.', 'Paso 4: Regresa al centro con suavidad, evitando tirones en la musculatura de la espalda.']::text[],
  'principiante',
  'Movimiento de apertura lateral que elonga y libera tensión en el lado derecho de la región lumbar, ayudando a mejorar la movilidad y el bienestar de la columna.',
  ARRAY['Movilidad', 'Estiramiento']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Ejercicio cardiovascular en máquina elíptica',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/ejercicio_cardiovascular_en_maquina_eliptica.webp',
  ARRAY['Paso 1: Sube a la plataforma y sujeta los agarres móviles, manteniendo la espalda erguida.', 'Paso 2: Comienza a pedalear suavemente, coordinando el movimiento de brazos y piernas.', 'Paso 3: Aumenta el ritmo manteniendo una postura estable y el core ligeramente activado.', 'Paso 4: Mantén un ritmo constante durante toda la duración del ejercicio.']::text[],
  'principiante',
  'Movimiento de bajo impacto que simula la zancada de carrera o marcha, involucrando tanto tren superior como inferior de forma coordinada para elevar la frecuencia cardíaca.',
  ARRAY['Resistencia cardiovascular', 'Quema de calorías']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Ascenso en máquina escaladora',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/ascenso_en_maquina_escaladora.webp',
  ARRAY['Paso 1: Sube a la máquina y sujeta los pasamanos para mantener el equilibrio.', 'Paso 2: Comienza a subir los escalones evitando apoyarte excesivamente en los brazos.', 'Paso 3: Mantén el torso erguido y realiza pasos completos aprovechando toda la profundidad del escalón.', 'Paso 4: Controla el ritmo para sostener la actividad aeróbica durante el tiempo objetivo.']::text[],
  'intermedio',
  'Ejercicio cardiovascular que simula el ascenso continuo de escaleras, altamente demandante para el sistema cardiorrespiratorio y la musculatura de las piernas.',
  ARRAY['Resistencia cardiovascular', 'Fortalecimiento de tren inferior']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Carrera en cinta rodante',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/carrera_en_cinta_rodante.webp',
  ARRAY['Paso 1: Posiciónate en la cinta y selecciona una velocidad de inicio segura.', 'Paso 2: Mantén una postura erguida, mirada al frente y brazos acompañando el movimiento natural de carrera.', 'Paso 3: Apoya el pie de forma natural, preferiblemente evitando el impacto excesivo con el talón.', 'Paso 4: Mantén un ritmo de respiración rítmico para sostener el esfuerzo cardiovascular.']::text[],
  'intermedio',
  'Actividad aeróbica fundamental que consiste en desplazarse a velocidad de trote o carrera sobre una superficie móvil.',
  ARRAY['Resistencia cardiovascular', 'Salud metabólica']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Marcha en cinta rodante',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/marcha_en_cinta_rodante.webp',
  ARRAY['Paso 1: Súbete a la cinta y comienza caminando a una velocidad cómoda.', 'Paso 2: Puedes ajustar la inclinación para aumentar la demanda calórica sin necesidad de correr.', 'Paso 3: Mantén una pisada firme desde el talón hacia la punta.', 'Paso 4: Mantén una postura relajada pero activa, acompañando con los brazos.']::text[],
  'principiante',
  'Ejercicio de caminata sostenida con inclinación o velocidad moderada, ideal para el desarrollo de resistencia aeróbica de bajo impacto.',
  ARRAY['Resistencia cardiovascular', 'Quema de grasa']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tijeras abdominales en decúbito supino',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/tijeras_abdominales_en_decubito_supino.webp',
  ARRAY['Paso 1: Túmbate boca arriba con las piernas extendidas y las manos bajo los glúteos para mayor soporte lumbar.', 'Paso 2: Eleva ligeramente ambas piernas del suelo y comienza a alternarlas en un movimiento de vaivén cruzado.', 'Paso 3: Mantén la zona lumbar presionada contra el suelo en todo momento.', 'Paso 4: Realiza el movimiento de forma controlada y continua.']::text[],
  'intermedio',
  'Movimiento dinámico que alterna la elevación de piernas de forma cruzada, enfatizando la musculatura del core y la resistencia muscular.',
  ARRAY['Resistencia abdominal', 'Estabilidad del core']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Lunge alterno con salto',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/lunge_alterno_con_salto.webp',
  ARRAY['Paso 1: Comienza en posición de zancada (lunge) con una pierna delante y otra detrás.', 'Paso 2: Impúlsate explosivamente hacia arriba para cambiar la posición de las piernas en el aire.', 'Paso 3: Aterriza suavemente en la posición de zancada contraria.', 'Paso 4: Mantén el torso erguido durante todo el movimiento explosivo.']::text[],
  'avanzado',
  'Ejercicio pliométrico explosivo que alterna zancadas mediante un salto, ideal para la potencia de piernas y acondicionamiento metabólico.',
  ARRAY['Potencia', 'Resistencia cardiovascular', 'Quema de calorías']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Shadowboxing',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/shadowboxing.webp',
  ARRAY['Paso 1: Colócate en posición de guardia con pies ligeramente separados.', 'Paso 2: Lanza combinaciones de golpes (jab, directo, crochet) sin impactar ningún objeto.', 'Paso 3: Mantén un juego de pies constante y el core activo.', 'Paso 4: Sostén un ritmo constante combinando velocidad y precisión.']::text[],
  'principiante',
  'Simulación de combate de boxeo lanzando golpes al aire, excelente para la coordinación, acondicionamiento cardiovascular y trabajo de hombros.',
  ARRAY['Resistencia cardiovascular', 'Coordinación', 'Acondicionamiento físico']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Box jump',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/box_jump.webp',
  ARRAY['Paso 1: Colócate frente a un cajón firme a una distancia segura.', 'Paso 2: Realiza un balanceo de brazos y salta con ambos pies simultáneamente sobre el cajón.', 'Paso 3: Aterriza con los pies planos en el centro del cajón y extiende totalmente las caderas.', 'Paso 4: Desciende bajando un pie a la vez para evitar impacto excesivo.']::text[],
  'avanzado',
  'Ejercicio pliométrico de saltos explosivos sobre una plataforma elevada, enfocado en el desarrollo de potencia de las piernas.',
  ARRAY['Potencia', 'Resistencia cardiovascular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla libre con salto',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/sentadilla_libre_con_salto.webp',
  ARRAY['Paso 1: Realiza una sentadilla estándar hasta que los muslos estén paralelos al suelo.', 'Paso 2: Impúlsate con potencia para realizar un salto vertical lo más alto posible.', 'Paso 3: Aterriza con las rodillas ligeramente flexionadas para absorber el impacto.', 'Paso 4: Conecta inmediatamente con la siguiente repetición de forma controlada.']::text[],
  'intermedio',
  'Variante de sentadilla que incorpora una fase explosiva de salto, aumentando la demanda energética y la potencia neuromuscular.',
  ARRAY['Potencia', 'Acondicionamiento físico']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Ondulaciones alternas con battle ropes',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/ondulaciones_alternas_con_battle_ropes.webp',
  ARRAY['Paso 1: Sujeta un extremo de la cuerda en cada mano con postura atlética (rodillas ligeramente flexionadas).', 'Paso 2: Mueve los brazos hacia arriba y hacia abajo de forma alternada y rápida para crear ondas en la cuerda.', 'Paso 3: Mantén el core firme para evitar balanceo innecesario del torso.', 'Paso 4: Mantén un ritmo sostenido de alta intensidad durante todo el tiempo de trabajo.']::text[],
  'intermedio',
  'Ejercicio de alta intensidad que utiliza cuerdas pesadas para crear ondas, demandando fuerza explosiva, resistencia muscular en hombros y un alto gasto calórico.',
  ARRAY['Resistencia cardiovascular', 'Fuerza explosiva', 'Quema de calorías']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Desplazamientos en escalera de agilidad',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/desplazamientos_en_escalera_de_agilidad.webp',
  ARRAY['Paso 1: Colócate frente a la escalera de agilidad en posición atlética con las rodillas ligeramente flexionadas.', 'Paso 2: Realiza el patrón de pasos preestablecido pisando dentro de los espacios de la escalera con rapidez.', 'Paso 3: Mantén un contacto breve con el suelo, enfocándote en la velocidad y la precisión del movimiento de tus pies.', 'Paso 4: Coordina el movimiento de brazos para equilibrar el cuerpo mientras avanzas a lo largo de toda la estructura.']::text[],
  'intermedio',
  'Ejercicio de alta frecuencia orientado a mejorar la coordinación neuromuscular, la rapidez de pies y la agilidad mediante patrones de movimiento repetitivos a través de una escalera de entrenamiento.',
  ARRAY['Agilidad', 'Coordinación', 'Velocidad de pies']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Giros rusos con balón medicinal',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/giros_rusos_con_balon_medicinal.webp',
  ARRAY['Paso 1: Siéntate en el suelo con las rodillas flexionadas, inclinando ligeramente el torso hacia atrás manteniendo la espalda recta.', 'Paso 2: Eleva los pies del suelo para aumentar la demanda de estabilidad y sujeta el balón medicinal con ambas manos frente al pecho.', 'Paso 3: Realiza una rotación controlada del torso llevando el balón hacia un lado y luego hacia el otro, siguiendo el movimiento con la mirada.', 'Paso 4: Mantén la tensión en el abdomen durante todo el rango de giro evitando movimientos bruscos.']::text[],
  'intermedio',
  'Ejercicio de rotación de tronco realizado con carga externa, diseñado para fortalecer la musculatura oblicua y mejorar la estabilidad rotacional del core.',
  ARRAY['Fortalecimiento de oblicuos', 'Estabilidad rotacional', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'V-ups con transferencia de balón medicinal',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/v_ups_con_transferencia_de_balon_medicinal.webp',
  ARRAY['Paso 1: Túmbate boca arriba con brazos y piernas extendidos, sosteniendo el balón medicinal con las manos.', 'Paso 2: Eleva simultáneamente el tronco y las piernas, cerrando el ángulo hasta que tus manos alcancen los pies.', 'Paso 3: Transfiere el balón de las manos a los pies, o viceversa, en el punto de máxima contracción abdominal.', 'Paso 4: Regresa lentamente a la posición inicial sin apoyar completamente el core en el suelo y repite el proceso.']::text[],
  'avanzado',
  'Movimiento avanzado de flexión total que combina la elevación simultánea de tronco y piernas con un componente de coordinación al pasar el balón entre manos y pies.',
  ARRAY['Potencia abdominal', 'Coordinación', 'Flexibilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Mountain climbers sobre fitball',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/mountain_climbers_sobre_fitball.webp',
  ARRAY['Paso 1: Colócate en posición de flexión con las manos apoyadas firmemente sobre el fitball y el cuerpo alineado.', 'Paso 2: Lleva una rodilla hacia el pecho manteniendo la estabilidad sobre la pelota.', 'Paso 3: Alterna las piernas con un movimiento rápido pero controlado, asegurando que el fitball no se desplace lateralmente.', 'Paso 4: Mantén la espalda neutra durante toda la ejecución para evitar sobrecarga lumbar.']::text[],
  'avanzado',
  'Variante inestable del escalador tradicional, que utiliza una pelota suiza para incrementar la demanda de estabilización del core y el control de la cintura escapular.',
  ARRAY['Estabilidad del core', 'Coordinación', 'Resistencia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Handstand',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/handstand.webp',
  ARRAY['Paso 1: Colócate frente a una pared para mayor seguridad, apoya las manos en el suelo a la anchura de hombros.', 'Paso 2: Lanza las piernas hacia arriba controladamente hasta lograr la verticalidad completa.', 'Paso 3: Mantén los codos bloqueados, los hombros activos empujando el suelo y el core completamente contraído.', 'Paso 4: Sostén la posición manteniendo una alineación perfecta de manos, hombros, caderas y pies.']::text[],
  'avanzado',
  'Postura de inversión total en la que el cuerpo se mantiene equilibrado sobre las manos, requiriendo gran fuerza de hombros, control de la línea central y equilibrio.',
  ARRAY['Fuerza de hombros', 'Equilibrio', 'Control postural']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Swing ruso con kettlebell',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/swing_ruso_con_kettlebell.webp',
  ARRAY['Paso 1: Colócate con los pies algo más anchos que los hombros y sujeta la kettlebell con ambas manos frente a ti.', 'Paso 2: Inicia el balanceo con una bisagra de cadera, enviando la kettlebell hacia atrás entre las piernas.', 'Paso 3: Extiende la cadera explosivamente para propulsar la kettlebell hacia adelante hasta la altura de los hombros.', 'Paso 4: Deja que la kettlebell regrese de forma controlada utilizando la fuerza de tus caderas para absorber el impulso.']::text[],
  'intermedio',
  'Ejercicio balístico fundamental que utiliza la bisagra de cadera para generar fuerza explosiva, siendo excelente para la cadena posterior y el acondicionamiento metabólico.',
  ARRAY['Potencia', 'Resistencia cardiovascular', 'Fortalecimiento de cadena posterior']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Skipping alto',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/skipping_alto.webp',
  ARRAY['Paso 1: Ponte de pie con una postura erguida y mirada al frente.', 'Paso 2: Comienza a elevar las rodillas hacia la altura de la cintura alternativamente con gran rapidez.', 'Paso 3: Mantén los brazos moviéndose de forma coordinada con el ritmo de tus pasos.', 'Paso 4: Asegúrate de aterrizar suavemente sobre el antepié manteniendo una alta frecuencia de pasos por segundo.']::text[],
  'principiante',
  'Ejercicio de carrera estática o dinámica que consiste en elevar las rodillas hacia el pecho de forma rítmica y veloz, mejorando la capacidad aeróbica y la potencia de zancada.',
  ARRAY['Resistencia cardiovascular', 'Coordinación', 'Calentamiento']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Ciclismo indoor en bicicleta estática',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/ciclismo_indoor_en_bicicleta_estatica.webp',
  ARRAY['Paso 1: Ajusta la altura del sillín y del manillar para mantener una posición ergonómica.', 'Paso 2: Sube a la bicicleta, ajusta los pedales y comienza a pedalear a una cadencia constante.', 'Paso 3: Mantén el torso estable y evita balanceos innecesarios durante el pedaleo.', 'Paso 4: Regula la resistencia de la bicicleta según la intensidad deseada para tu objetivo aeróbico.']::text[],
  'principiante',
  'Actividad cardiovascular de bajo impacto centrada en el tren inferior, realizada en una bicicleta estática para el acondicionamiento aeróbico y muscular.',
  ARRAY['Resistencia cardiovascular', 'Quema de calorías']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo en ergómetro',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/remo_en_ergometro.webp',
  ARRAY['Paso 1: Siéntate en el carro y asegura tus pies en los apoyos.', 'Paso 2: Realiza la fase de ataque inclinando el torso ligeramente hacia adelante y estirando los brazos hacia la máquina.', 'Paso 3: Ejecuta la fase de tracción empujando primero con las piernas, luego llevando el torso hacia atrás y finalmente traccionando con los brazos hacia el abdomen.', 'Paso 4: Regresa controladamente a la posición inicial revirtiendo el movimiento.']::text[],
  'intermedio',
  'Ejercicio cardiovascular integral que simula el movimiento de remo en el agua, trabajando tanto la cadena posterior como el tren superior de forma explosiva.',
  ARRAY['Resistencia cardiovascular', 'Acondicionamiento completo']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Jumping jacks',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/jumping_jacks.webp',
  ARRAY['Paso 1: Empieza de pie con los pies juntos y los brazos a los lados.', 'Paso 2: Salta abriendo las piernas a la vez que llevas los brazos por encima de la cabeza.', 'Paso 3: Salta de nuevo para volver a la posición inicial cerrando piernas y bajando brazos.', 'Paso 4: Mantén un ritmo ágil y fluido durante todo el ejercicio.']::text[],
  'principiante',
  'Ejercicio de calistenia clásico que combina salto y apertura de brazos y piernas, ideal para elevar la frecuencia cardíaca de forma rápida.',
  ARRAY['Resistencia cardiovascular', 'Calentamiento']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Salto a la comba',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/salto_a_la_comba.webp',
  ARRAY['Paso 1: Sostén los extremos de la comba con las manos y colócala detrás de tus talones.', 'Paso 2: Realiza pequeños saltos verticales con ambos pies mientras giras las muñecas para mover la cuerda.', 'Paso 3: Mantén una postura erguida y aterrizajes suaves sobre las puntas de los pies.', 'Paso 4: Ajusta la velocidad según tu nivel para mantener un ritmo sostenido.']::text[],
  'intermedio',
  'Ejercicio de alta intensidad que mejora la coordinación, la agilidad y el acondicionamiento aeróbico a través de saltos rítmicos sobre una cuerda.',
  ARRAY['Resistencia cardiovascular', 'Coordinación']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Mountain climbers',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/mountain_climbers.webp',
  ARRAY['Paso 1: Colócate en posición de plancha con las manos apoyadas directamente bajo los hombros.', 'Paso 2: Lleva una rodilla hacia el pecho de manera explosiva mientras mantienes la cadera estable.', 'Paso 3: Alterna las piernas rápidamente manteniendo el torso alineado y paralelo al suelo.', 'Paso 4: Evita que la cadera rebote o se eleve demasiado durante el movimiento.']::text[],
  'intermedio',
  'Ejercicio dinámico de core realizado en posición de plancha alta, que imita el movimiento de escalada vertical mediante la alternancia de rodillas al pecho.',
  ARRAY['Estabilidad del core', 'Resistencia cardiovascular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión pliométrica',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/cardio/flexion_pliometrica.webp',
  ARRAY['Paso 1: Realiza una flexión normal bajando el pecho hacia el suelo.', 'Paso 2: Empuja el suelo con la máxima fuerza explosiva posible para despegar las manos brevemente.', 'Paso 3: Aterriza controladamente absorbiendo el impacto con los brazos.', 'Paso 4: Mantén el cuerpo rígido desde la cabeza hasta los talones en todo momento.']::text[],
  'avanzado',
  'Variante de flexión de pecho que incorpora un empuje explosivo despegando las manos del suelo, ideal para ganar potencia en el tren superior.',
  ARRAY['Potencia', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dominadas con agarre prono',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/dominadas_con_agarre_prono.webp',
  ARRAY['Paso 1: Sujeta la barra con un agarre prono un poco más ancho que tus hombros.', 'Paso 2: Desde una posición de suspensión, tracciona con fuerza llevando el pecho hacia la barra.', 'Paso 3: Realiza la contracción máxima retrayendo las escápulas.', 'Paso 4: Desciende de forma controlada hasta estirar completamente los brazos.']::text[],
  'intermedio',
  'Ejercicio de tracción vertical enfocado en el desarrollo de la espalda, utilizando el peso corporal y un agarre con palmas mirando hacia afuera.',
  ARRAY['Hipertrofia', 'Fuerza de espalda']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexiones de brazos en el suelo',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/flexiones_de_brazos_en_el_suelo.webp',
  ARRAY['Paso 1: Colócate en posición de plancha con manos a la anchura de hombros.', 'Paso 2: Desciende el pecho hacia el suelo manteniendo los codos en un ángulo de 45 grados respecto al cuerpo.', 'Paso 3: Empuja con fuerza para volver a la posición extendida inicial.', 'Paso 4: Mantén el cuerpo alineado y el abdomen contraído durante todo el movimiento.']::text[],
  'principiante',
  'Ejercicio básico de empuje horizontal para fortalecer la musculatura del pectoral, hombros y tríceps mediante el peso corporal.',
  ARRAY['Hipertrofia', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Plancha abdominal sobre antebrazos',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/plancha_abdominal_sobre_antebrazos.webp',
  ARRAY['Paso 1: Apóyate sobre los antebrazos y las puntas de los pies con el cuerpo en línea recta.', 'Paso 2: Contrae fuertemente el abdomen y glúteos para evitar que la cadera caiga.', 'Paso 3: Mantén la cabeza en posición neutra mirando al suelo.', 'Paso 4: Sostén la posición durante el tiempo deseado manteniendo la respiración fluida.']::text[],
  'principiante',
  'Ejercicio isométrico para desarrollar la estabilidad y resistencia de toda la pared abdominal y estabilizadores espinales.',
  ARRAY['Estabilidad del core', 'Resistencia isométrica']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevaciones de piernas rectas en suspensión',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/elevaciones_de_piernas_rectas_en_suspension.webp',
  ARRAY['Paso 1: Sujétate a la barra de dominadas con los brazos extendidos.', 'Paso 2: Eleva las piernas manteniendo las rodillas extendidas hasta que queden paralelas al suelo o más arriba.', 'Paso 3: Controla el movimiento al bajar para evitar balanceos.', 'Paso 4: Mantén el torso estable durante todo el recorrido.']::text[],
  'avanzado',
  'Ejercicio avanzado para la pared abdominal que requiere fuerza de agarre y control pélvico en suspensión.',
  ARRAY['Hipertrofia de core', 'Fuerza abdominal']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'L-sit en barras paralelas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/l_sit_en_barras_paralelas.webp',
  ARRAY['Paso 1: Apóyate sobre las barras paralelas con los brazos extendidos.', 'Paso 2: Eleva las piernas estiradas hasta formar un ángulo de 90 grados con el torso.', 'Paso 3: Mantén los hombros deprimidos y lejos de las orejas.', 'Paso 4: Sostén la posición manteniendo la tensión en core y tríceps.']::text[],
  'avanzado',
  'Ejercicio isométrico avanzado de calistenia que requiere gran fuerza abdominal y de presión (empuje) para mantener el cuerpo en forma de ''L''.',
  ARRAY['Fuerza de core', 'Estabilidad escapular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Handstand libre',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/handstand_libre.webp',
  ARRAY['Paso 1: Coloca las manos en el suelo a la anchura de hombros.', 'Paso 2: Lanza las piernas hacia arriba controladamente hasta la posición vertical.', 'Paso 3: Empuja activamente el suelo con los hombros manteniendo el core contraído.', 'Paso 4: Mantén el equilibrio ajustando con la punta de los dedos y el movimiento de hombros.']::text[],
  'avanzado',
  'Habilidad máxima de equilibrio sobre las manos que demanda un control corporal total y fuerza estructural en los hombros.',
  ARRAY['Equilibrio', 'Control motor', 'Fuerza isométrica de hombros']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Front lever a un brazo',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/front_lever_a_un_brazo.webp',
  ARRAY['Paso 1: Sujeta la barra con una mano mientras mantienes el cuerpo paralelo al suelo.', 'Paso 2: Estira el cuerpo completamente manteniendo la tensión escapular.', 'Paso 3: Mantén la posición evitando que la cadera caiga.', 'Paso 4: Ejecuta el ejercicio solo si posees una base sólida de fuerza en la versión a dos brazos.']::text[],
  'avanzado',
  'Movimiento de élite en calistenia que requiere una fuerza excepcional de tracción y una tensión extrema en el core.',
  ARRAY['Fuerza máxima', 'Dominio corporal']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Back lever a un brazo',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/back_lever_a_un_brazo.webp',
  ARRAY['Paso 1: Sujeta la barra con una mano, pasando los pies por encima de la barra hasta quedar paralelo al suelo.', 'Paso 2: Mantén la espalda recta y el core muy contraído.', 'Paso 3: Sostén la posición manteniendo el hombro activo.', 'Paso 4: Esta progresión solo debe ser realizada por atletas experimentados.']::text[],
  'avanzado',
  'Movimiento de alta complejidad técnica que consiste en mantener el cuerpo paralelo al suelo en posición supina, sujetado por un solo brazo.',
  ARRAY['Fuerza isométrica', 'Fuerza de empuje']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Human flag en barra vertical',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/human_flag_en_barra_vertical.webp',
  ARRAY['Paso 1: Sujeta una barra vertical con una mano por encima y otra por debajo.', 'Paso 2: Empuja con la mano inferior y tracciona con la superior para elevar el cuerpo.', 'Paso 3: Extiende el cuerpo manteniéndolo paralelo al suelo.', 'Paso 4: La técnica requiere una combinación crítica de fuerza de hombros, oblicuos y brazos.']::text[],
  'avanzado',
  'Habilidad icónica de calistenia donde el cuerpo se mantiene perpendicular al suelo sujeto a una barra vertical mediante fuerza de empuje y tracción.',
  ARRAY['Dominio corporal', 'Fuerza de hombros y core']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Fondos en barras paralelas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/fondos_en_barras_paralelas.webp',
  ARRAY['Paso 1: Apóyate en las barras paralelas con los brazos extendidos.', 'Paso 2: Desciende el cuerpo flexionando los codos hasta que los hombros estén por debajo de los codos.', 'Paso 3: Empuja con fuerza para volver a la posición inicial.', 'Paso 4: Mantén el torso ligeramente inclinado hacia adelante para mayor énfasis en el pectoral.']::text[],
  'intermedio',
  'Ejercicio fundamental de empuje para desarrollar la fuerza y volumen del tríceps y pectoral inferior.',
  ARRAY['Hipertrofia', 'Fuerza de empuje']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'L-sit en el suelo',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/l_sit_en_el_suelo.webp',
  ARRAY['Paso 1: Siéntate en el suelo con las piernas estiradas y las manos apoyadas a los lados de tus caderas.', 'Paso 2: Presiona con las palmas de las manos contra el suelo, activando tríceps y hombros para elevar todo el cuerpo.', 'Paso 3: Mantén las piernas estiradas y paralelas al suelo, formando una ''L'' con tu torso.', 'Paso 4: Sostén la posición manteniendo una contracción constante en el abdomen y una retracción escapular activa.']::text[],
  'avanzado',
  'Ejercicio isométrico de alta intensidad que requiere una gran fuerza de core y estabilidad de hombros para elevar el cuerpo formando un ángulo de 90 grados.',
  ARRAY['Fuerza de core', 'Estabilidad escapular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dominadas con agarre ancho prono (Dorsal ancho)',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/dominadas_con_agarre_ancho_prono_dorsal_ancho.webp',
  ARRAY['Paso 1: Sujeta la barra con un agarre prono significativamente más ancho que tus hombros.', 'Paso 2: Desde una posición de suspensión, tracciona con fuerza llevando la parte superior del pecho hacia la barra.', 'Paso 3: Mantén los codos apuntando hacia el suelo y las escápulas activas durante todo el recorrido.', 'Paso 4: Desciende de forma controlada hasta alcanzar la extensión completa de los brazos.']::text[],
  'intermedio',
  'Ejercicio de tracción vertical que enfatiza el desarrollo del ancho de la espalda mediante un agarre supino abierto.',
  ARRAY['Hipertrofia', 'Fuerza de tracción']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Fondos en barras paralelas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/fondos_en_barras_paralelas.webp',
  ARRAY['Paso 1: Súbete a las barras paralelas manteniendo los brazos estirados.', 'Paso 2: Desciende el cuerpo flexionando los codos hasta que los hombros queden por debajo de la articulación del codo.', 'Paso 3: Empuja el cuerpo hacia arriba hasta la posición de bloqueo inicial.', 'Paso 4: Mantén el torso ligeramente inclinado hacia adelante durante todo el recorrido.']::text[],
  'intermedio',
  'Movimiento de empuje vertical que desarrolla el volumen y fuerza del tríceps y la porción inferior del pectoral.',
  ARRAY['Hipertrofia', 'Fuerza de empuje']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Fondos en barras paralelas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/fondos_en_barras_paralelas_v2.webp',
  ARRAY['Paso 1: Súbete a las barras paralelas manteniendo los brazos estirados.', 'Paso 2: Desciende el cuerpo flexionando los codos hasta que los hombros queden por debajo de la articulación del codo.', 'Paso 3: Empuja el cuerpo hacia arriba hasta la posición de bloqueo inicial.', 'Paso 4: Mantén el torso ligeramente inclinado hacia adelante durante todo el recorrido.']::text[],
  'intermedio',
  'Movimiento de empuje vertical que desarrolla el volumen y fuerza del tríceps y la porción inferior del pectoral.',
  ARRAY['Hipertrofia', 'Fuerza de empuje']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Full planche en barras paralelas bajas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/full_planche_en_barras_paralelas_bajas.webp',
  ARRAY['Paso 1: Coloca las manos sobre las barras paralelas bajas con una rotación externa de hombros.', 'Paso 2: Eleva el cuerpo y estira las piernas hasta lograr una línea recta horizontal completa.', 'Paso 3: Mantén una protracción escapular agresiva y una tensión total en todo el core.', 'Paso 4: Sostén la posición controlando la basculación del centro de gravedad.']::text[],
  'avanzado',
  'Ejercicio avanzado de calistenia que requiere una fuerza estructural inmensa para mantener el cuerpo paralelo al suelo sobre las manos.',
  ARRAY['Fuerza absoluta', 'Dominio corporal']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Muscle-up en anillas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/muscle_up_en_anillas.webp',
  ARRAY['Paso 1: Sujétate a las anillas y realiza una dominada explosiva.', 'Paso 2: En el punto más alto, ejecuta la transición rotando las muñecas para posicionar los codos sobre las anillas.', 'Paso 3: Finaliza el movimiento con un fondo de tríceps hasta la extensión total de brazos.', 'Paso 4: Regresa controladamente a la posición de inicio siguiendo la ruta inversa.']::text[],
  'avanzado',
  'Movimiento compuesto de élite que combina una tracción vertical explosiva con una transición y un empuje final para elevar el cuerpo sobre las anillas.',
  ARRAY['Potencia', 'Coordinación', 'Fuerza funcional']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Fondos en banco',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/fondos_en_banco.webp',
  ARRAY['Paso 1: Apoya las manos en el borde de un banco estable con los dedos mirando hacia adelante.', 'Paso 2: Con las piernas estiradas o flexionadas, baja los glúteos hacia el suelo flexionando los codos.', 'Paso 3: Empuja con fuerza utilizando exclusivamente la musculatura del tríceps hasta estirar los brazos.', 'Paso 4: Mantén la espalda cerca del banco durante todo el movimiento.']::text[],
  'principiante',
  'Ejercicio de empuje de aislamiento para tríceps utilizando un banco como apoyo para el tren superior.',
  ARRAY['Hipertrofia', 'Resistencia de tríceps']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dominadas con agarre prono (Bíceps braquial)',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/dominadas_con_agarre_prono_biceps_braquial.webp',
  ARRAY['Paso 1: Sujeta la barra con un agarre prono a la anchura de tus hombros.', 'Paso 2: Tracciona el pecho hacia la barra concentrando el esfuerzo en la flexión del codo.', 'Paso 3: Evita balanceos excesivos manteniendo el core activo.', 'Paso 4: Desciende de forma controlada hasta estirar los brazos por completo.']::text[],
  'intermedio',
  'Variante de dominada donde el agarre prono permite una mayor activación de los flexores del brazo, específicamente el bíceps.',
  ARRAY['Hipertrofia de bíceps', 'Fuerza']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Plancha abdominal sobre antebrazos con apoyo de rodillas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/plancha_abdominal_sobre_antebrazos_con_apoyo_de_rodillas.webp',
  ARRAY['Paso 1: Apóyate sobre antebrazos y rodillas en el suelo.', 'Paso 2: Mantén la espalda recta y el abdomen contraído firmemente.', 'Paso 3: Asegúrate de que tu cuerpo forme una línea recta desde la cabeza hasta las rodillas.', 'Paso 4: Sostén la posición manteniendo una respiración constante.']::text[],
  'principiante',
  'Variante simplificada de la plancha isométrica ideal para fortalecer la estabilidad del core en etapas iniciales.',
  ARRAY['Estabilidad del core', 'Resistencia muscular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexiones de brazos en pared',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/flexiones_de_brazos_en_pared.webp',
  ARRAY['Paso 1: Colócate frente a una pared, apoya las manos a la altura de tus hombros.', 'Paso 2: Flexiona los codos llevando el pecho cerca de la pared.', 'Paso 3: Empuja el cuerpo hacia atrás hasta la extensión completa de brazos.', 'Paso 4: Mantén el cuerpo alineado y los pies estables en el suelo.']::text[],
  'principiante',
  'Ejercicio de empuje de bajísima intensidad, ideal para principiantes o recuperación, realizado de pie apoyando manos en la pared.',
  ARRAY['Iniciación al empuje', 'Resistencia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Pistol squat',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/pistol_squat.webp',
  ARRAY['Paso 1: De pie, eleva una pierna hacia adelante sin tocar el suelo.', 'Paso 2: Desciende realizando una sentadilla con la pierna de apoyo mientras mantienes el equilibrio.', 'Paso 3: Baja hasta que el glúteo toque el talón o alcances la máxima profundidad.', 'Paso 4: Empuja con fuerza para volver a la posición erguida sin perder la estabilidad.']::text[],
  'avanzado',
  'Sentadilla a una pierna que requiere niveles avanzados de fuerza, equilibrio y movilidad de tobillo y cadera.',
  ARRAY['Fuerza unilateral', 'Equilibrio', 'Movilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexiones pseudo planche',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/flexiones_pseudo_planche.webp',
  ARRAY['Paso 1: Colócate en posición de flexión, situando tus manos a la altura de la cadera con los dedos orientados hacia los pies o ligeramente hacia afuera.', 'Paso 2: Inclina el torso hacia adelante hasta que tus hombros sobrepasen la línea de las manos.', 'Paso 3: Desciende controladamente flexionando los codos mientras mantienes los hombros activos y los codos cerca de las costillas.', 'Paso 4: Empuja explosivamente hasta la posición inicial manteniendo la protracción escapular durante todo el movimiento.']::text[],
  'intermedio',
  'Variante de flexión de brazos donde el apoyo de las manos se sitúa hacia la cintura, desplazando el centro de gravedad para enfatizar el deltoides anterior y la fuerza estructural necesaria para la plancha.',
  ARRAY['Fuerza específica', 'Hipertrofia de hombro']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Straddle planche en barras paralelas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/straddle_planche_en_barras_paralelas.webp',
  ARRAY['Paso 1: Colócate sobre las barras paralelas con los hombros en posición de apoyo y rotación externa.', 'Paso 2: Eleva el cuerpo y abre las piernas en forma de ''V'' (straddle) para desplazar el centro de masas.', 'Paso 3: Mantén la espalda totalmente recta, los brazos bloqueados y una retracción/depresión escapular fuerte.', 'Paso 4: Sostén la posición isométrica controlando el equilibrio mediante la presión de los dedos.']::text[],
  'avanzado',
  'Progresión de planche donde la apertura de piernas reduce el brazo de palanca, facilitando el mantenimiento de la posición horizontal sobre las manos.',
  ARRAY['Fuerza isométrica', 'Dominio corporal']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexiones arqueras',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/flexiones_arqueras.webp',
  ARRAY['Paso 1: Colócate en posición de flexión con las manos notablemente más separadas de la anchura de hombros.', 'Paso 2: Desciende llevando el peso hacia un brazo mientras el otro se mantiene estirado lateralmente.', 'Paso 3: Empuja el suelo con el brazo flexionado para volver al centro, alternando el lado en la siguiente repetición.', 'Paso 4: Mantén el torso paralelo al suelo sin elevar excesivamente la cadera.']::text[],
  'intermedio',
  'Variante de flexión unilateral que traslada la carga predominantemente hacia un lado, siendo una excelente progresión para ganar fuerza real de empuje.',
  ARRAY['Fuerza unilateral', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevaciones de piernas a la barra en suspensión',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/elevaciones_de_piernas_a_la_barra_en_suspension.webp',
  ARRAY['Paso 1: Sujétate a la barra de dominadas con un agarre prono firme.', 'Paso 2: Activa los hombros y eleva las piernas buscando tocar la barra con los pies.', 'Paso 3: Controla la bajada para evitar el balanceo excesivo del cuerpo.', 'Paso 4: Mantén las piernas extendidas durante todo el movimiento para mayor intensidad.']::text[],
  'avanzado',
  'Ejercicio de core que requiere una fuerte flexión de cadera y abdominal en suspensión, excelente para desarrollar la zona baja del recto abdominal.',
  ARRAY['Hipertrofia de core', 'Fuerza abdominal']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dominada a un brazo',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/dominada_a_un_brazo.webp',
  ARRAY['Paso 1: Sujeta la barra con una sola mano, asegurando un agarre firme y estable.', 'Paso 2: Inicia la tracción iniciando el movimiento con una leve rotación del torso para aprovechar el impulso.', 'Paso 3: Lleva el mentón o el hombro hacia la barra, manteniendo el cuerpo lo más recto posible.', 'Paso 4: Regresa lentamente a la posición de cuelgue total sin perder el control.']::text[],
  'avanzado',
  'Ejercicio de tracción suprema que demuestra un nivel máximo de fuerza relativa, requiriendo equilibrio, técnica de agarre y potencia en el dorsal.',
  ARRAY['Fuerza máxima', 'Dominio corporal']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Full planche en anillas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/full_planche_en_anillas.webp',
  ARRAY['Paso 1: Sujeta las anillas y bloquea los codos en posición de apoyo.', 'Paso 2: Inclina el cuerpo hacia adelante elevando las piernas hasta una línea horizontal perfecta.', 'Paso 3: Mantén una protracción escapular máxima y una tensión isométrica total.', 'Paso 4: Controla el balanceo de las anillas mediante una presión constante y estable.']::text[],
  'avanzado',
  'Variante extrema de planche realizada sobre anillas, lo cual añade una inestabilidad técnica que demanda un control muscular superior y fuerza de core extrema.',
  ARRAY['Fuerza absoluta', 'Control motor']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Muscle up explosivo con suelta de manos',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/muscle_up_explosivo_con_suelta_de_manos.webp',
  ARRAY['Paso 1: Sujétate a la barra fija e inicia una dominada con máxima explosividad, aprovechando la inercia del cuerpo.', 'Paso 2: Tracciona agresivamente llevando la cadera hacia la barra para ejecutar una transición ultra rápida.', 'Paso 3: Al superar la barra, empuja con extrema potencia en la fase de fondo para crear ingravidez y soltar las manos por un instante.', 'Paso 4: Atrapa la barra rápidamente antes de comenzar la caída y desciende de forma controlada absorbiendo el impacto.']::text[],
  'avanzado',
  'Variante de élite del muscle up que requiere una potencia de tracción y empuje extrema para elevar el torso por encima de la barra y liberar momentáneamente el agarre en el aire.',
  ARRAY['Potencia explosiva', 'Coordinación', 'Fuerza absoluta']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Skin the cat en barra fija',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/skin_the_cat_en_barra_fija.webp',
  ARRAY['Paso 1: Sujétate a la barra y eleva las piernas pasando por debajo de ella.', 'Paso 2: Continúa la rotación llevando los pies hacia atrás hasta que el cuerpo quede colgado boca abajo.', 'Paso 3: Mantén el control de los hombros durante todo el giro.', 'Paso 4: Regresa realizando el movimiento a la inversa hasta volver a la posición de inicio.']::text[],
  'avanzado',
  'Ejercicio de movilidad y fuerza escapular que consiste en rotar el cuerpo a través de los brazos sujetos a la barra.',
  ARRAY['Movilidad escapular', 'Fuerza estructural']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dominadas en L-sit con agarre prono',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/dominadas_en_l_sit_con_agarre_prono.webp',
  ARRAY['Paso 1: Sujeta la barra con agarre prono y eleva las piernas a 90 grados.', 'Paso 2: Mantén esta posición de L-sit durante toda la tracción.', 'Paso 3: Realiza la dominada llevando el pecho hacia la barra.', 'Paso 4: Baja de forma controlada sin perder la posición de las piernas.']::text[],
  'avanzado',
  'Variante de dominada que combina tracción vertical con el mantenimiento de una posición estática de ''L'' con las piernas, aumentando la demanda abdominal.',
  ARRAY['Hipertrofia', 'Fuerza de core']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dominada a un brazo con dos dedos',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/dominada_a_un_brazo_con_dos_dedos.webp',
  ARRAY['Paso 1: Sujeta la barra de dominadas usando solo el dedo índice y el medio de una mano.', 'Paso 2: Inicia la tracción vertical manteniendo el cuerpo alineado y activando la musculatura escapular del lado activo.', 'Paso 3: Eleva el cuerpo hasta que la barbilla supere la línea de la barra, utilizando la rotación del torso si es necesario para asistir el movimiento.', 'Paso 4: Regresa lentamente a la posición inicial controlando la fase excéntrica sin soltar el agarre.']::text[],
  'avanzado',
  'Ejercicio de tracción vertical extremo que combina fuerza de dorsal con un requerimiento de agarre específico, utilizando únicamente dos dedos para sujetar la carga.',
  ARRAY['Fuerza máxima', 'Fuerza de agarre']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Full planche en el suelo',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/full_planche_en_el_suelo.webp',
  ARRAY['Paso 1: Coloca las manos en el suelo, preferiblemente con una rotación externa de hombros.', 'Paso 2: Eleva el cuerpo y estira las piernas formando una línea horizontal paralela al suelo.', 'Paso 3: Mantén una protracción escapular máxima, los brazos bloqueados y el core intensamente contraído.', 'Paso 4: Sostén la posición isométrica controlando el centro de gravedad mediante la presión de los dedos.']::text[],
  'avanzado',
  'Posición estática de empuje donde el cuerpo se mantiene suspendido horizontalmente respecto al suelo sobre las manos, sin apoyo de pies.',
  ARRAY['Fuerza absoluta', 'Estabilidad escapular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Straddle planche en barras paralelas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/straddle_planche_en_barras_paralelas.webp',
  ARRAY['Paso 1: Apoya las manos en las barras paralelas y activa la retracción/depresión escapular.', 'Paso 2: Eleva el cuerpo y separa las piernas en forma de ''V'' para distribuir el peso.', 'Paso 3: Mantén los brazos bloqueados y la espalda recta mientras sostienes el cuerpo paralelo al suelo.', 'Paso 4: Equilibra la posición mediante el ajuste constante del peso sobre las muñecas y los dedos.']::text[],
  'avanzado',
  'Progresión técnica de planche que reduce el brazo de palanca mediante la apertura de piernas, permitiendo sostener el cuerpo en posición horizontal.',
  ARRAY['Fuerza isométrica', 'Dominio corporal']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexiones a un brazo',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/flexiones_a_un_brazo.webp',
  ARRAY['Paso 1: Adopta una posición de flexión con las piernas separadas para mayor base de apoyo.', 'Paso 2: Coloca una mano sobre el centro del pecho o espalda y realiza el descenso con el otro brazo.', 'Paso 3: Mantén los hombros alineados y evita la rotación excesiva del torso.', 'Paso 4: Empuja con fuerza manteniendo la tensión total en el brazo de apoyo hasta la extensión completa.']::text[],
  'avanzado',
  'Movimiento de empuje unilateral que requiere gran estabilidad de core para mantener el tronco paralelo al suelo durante la ejecución.',
  ARRAY['Fuerza unilateral', 'Estabilidad del core']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dominadas en front lever',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/dominadas_en_front_lever.webp',
  ARRAY['Paso 1: Adopta la posición de front lever (cuerpo paralelo al suelo) sujetado a una barra.', 'Paso 2: Realiza una tracción explosiva llevando la barra hacia tu cadera/cintura mientras mantienes el cuerpo rígido.', 'Paso 3: Ejecuta el movimiento con control absoluto sin perder la alineación horizontal.', 'Paso 4: Regresa a la posición isométrica de front lever antes de iniciar la siguiente repetición.']::text[],
  'avanzado',
  'Movimiento dinámico complejo que consiste en realizar una tracción desde la posición isométrica de front lever hasta llevar la barra a la cintura.',
  ARRAY['Fuerza máxima', 'Hipertrofia de dorsal']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Straddle planche a un brazo',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/straddle_planche_a_un_brazo.webp',
  ARRAY['Paso 1: Colócate en posición de planche con un brazo, manteniendo el otro retirado del apoyo.', 'Paso 2: Abre las piernas en posición straddle para compensar el desequilibrio lateral.', 'Paso 3: Mantén el cuerpo perfectamente horizontal y el brazo bloqueado con una protracción escapular agresiva.', 'Paso 4: Sostén la posición isométrica ajustando constantemente el centro de gravedad con la mano de apoyo.']::text[],
  'avanzado',
  'Variación extremadamente avanzada de planche donde el empuje se realiza con un solo brazo, requiriendo un equilibrio y fuerza sobrehumanos.',
  ARRAY['Fuerza máxima', 'Dominio corporal absoluto']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dominadas lastradas con agarre prono',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/dominadas_lastradas_con_agarre_prono.webp',
  ARRAY['Paso 1: Colócate un cinturón de lastre con discos de peso asegurados.', 'Paso 2: Sujeta la barra con agarre prono y realiza la dominada superando el lastre con técnica estricta.', 'Paso 3: Realiza el recorrido completo, desde la extensión total hasta el contacto del pecho con la barra.', 'Paso 4: Baja lentamente para maximizar el tiempo bajo tensión en la fase excéntrica.']::text[],
  'avanzado',
  'Variante de dominada de alta intensidad que incorpora una carga externa adicional para maximizar la sobrecarga mecánica y la hipertrofia.',
  ARRAY['Fuerza explosiva', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dominada a un brazo',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/dominada_a_un_brazo.webp',
  ARRAY['Paso 1: Sujeta la barra firmemente con una sola mano, manteniéndote en posición de colgado.', 'Paso 2: Inicia la tracción combinando fuerza de tracción pura y una leve rotación del tronco.', 'Paso 3: Lleva el hombro activo a la altura de la barra, manteniendo el core estable.', 'Paso 4: Desciende de manera controlada hasta la posición inicial sin perder la firmeza en el agarre.']::text[],
  'avanzado',
  'Movimiento de tracción vertical suprema que demanda una fuerza relativa superior y un control técnico preciso.',
  ARRAY['Fuerza máxima', 'Dominio corporal']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Full front lever en barra fija',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/full_front_lever_en_barra_fija.webp',
  ARRAY['Paso 1: Sujeta la barra fija con las manos y realiza una retracción escapular activa.', 'Paso 2: Eleva las piernas y el torso hasta lograr una línea horizontal perfecta respecto al suelo.', 'Paso 3: Mantén los brazos bloqueados y el cuerpo completamente rígido mediante la contracción abdominal.', 'Paso 4: Sostén la posición manteniendo la tensión en dorsales y core durante todo el tiempo de trabajo.']::text[],
  'avanzado',
  'Habilidad estática avanzada donde el cuerpo se mantiene completamente horizontal, suspendido por las manos, desafiando la cadena posterior y el core.',
  ARRAY['Fuerza isométrica', 'Fuerza de dorsal']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Front lever a un brazo',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/front_lever_a_un_brazo.webp',
  ARRAY['Paso 1: Sujeta la barra con una sola mano y realiza la entrada a front lever mediante una retracción escapular potente.', 'Paso 2: Mantén el cuerpo totalmente horizontal, compensando la rotación lateral mediante la tensión abdominal.', 'Paso 3: Asegura que el hombro de apoyo se mantenga activo y estable.', 'Paso 4: Esta progresión representa el nivel máximo de tracción estática y debe realizarse con total dominio técnico.']::text[],
  'avanzado',
  'Versión extrema del front lever donde la sujeción del cuerpo horizontal se realiza con una sola mano, demandando un equilibrio y fuerza de tracción superiores.',
  ARRAY['Fuerza extrema', 'Dominio corporal']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dead hang en barra fija',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/dead_hang_en_barra_fija.webp',
  ARRAY['Paso 1: Sujeta la barra con agarre prono a la anchura de tus hombros.', 'Paso 2: Permite que tu cuerpo cuelgue completamente, relajando la musculatura del tren superior.', 'Paso 3: Mantén la cabeza en posición neutra y evita balanceos innecesarios.', 'Paso 4: Sostén la posición durante el tiempo establecido, manteniendo un agarre firme y seguro.']::text[],
  'principiante',
  'Suspensión pasiva en barra fija diseñada para mejorar la fuerza de agarre y permitir la descompresión articular de la columna y hombros.',
  ARRAY['Fuerza de agarre', 'Salud articular']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Full planche en paralelas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/full_planche_en_paralelas.webp',
  ARRAY['Paso 1: Coloca las manos en las paralelas con una rotación externa de hombros estable.', 'Paso 2: Eleva el cuerpo y extiende las piernas hasta formar una línea recta perfecta con el torso.', 'Paso 3: Mantén protracción escapular máxima y contracción isométrica total de todo el core.', 'Paso 4: Sostén la posición controlando el centro de masas para evitar oscilaciones.']::text[],
  'avanzado',
  'Habilidad isométrica de empuje horizontal extremo donde el cuerpo se mantiene alineado horizontalmente respecto al suelo apoyado sobre las manos en paralelas.',
  ARRAY['Fuerza máxima', 'Dominio corporal']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Maltese push-up',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/maltese_push_up.webp',
  ARRAY['Paso 1: Colócate en posición de flexión con las manos situadas significativamente más allá de la anchura de tus hombros.', 'Paso 2: Desciende controladamente manteniendo los codos en una posición estable y el torso paralelo al suelo.', 'Paso 3: Empuja el cuerpo hacia arriba mediante una contracción explosiva del pecho y deltoides.', 'Paso 4: Asegura mantener la protracción escapular durante todo el rango de movimiento.']::text[],
  'avanzado',
  'Variante extrema de flexión de brazos con un ancho de manos muy superior al de los hombros, aumentando la carga mecánica sobre el pectoral y hombros.',
  ARRAY['Fuerza específica', 'Hipertrofia de pectoral']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Salida en mortal hacia atrás en barra fija',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/salida_en_mortal_hacia_atras_en_barra_fija.webp',
  ARRAY['Paso 1: Ejecuta un balanceo potente sobre la barra para maximizar la inercia vertical.', 'Paso 2: Libera el agarre en el punto culminante mientras realizas una flexión explosiva de cadera hacia atrás.', 'Paso 3: Completa la rotación en el aire, manteniendo la vista en el punto de aterrizaje.', 'Paso 4: Aterriza con las rodillas ligeramente flexionadas para absorber el impacto de forma segura.']::text[],
  'avanzado',
  'Maniobra acrobática avanzada de desenganche de la barra, que implica una rotación completa hacia atrás en el aire.',
  ARRAY['Acrobacia', 'Potencia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Balanceo dinámico a una mano en barra fija',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/balanceo_dinamico_a_una_mano_en_barra_fija.webp',
  ARRAY['Paso 1: Sujeta la barra con una sola mano y comienza un balanceo controlado.', 'Paso 2: Utiliza la inercia para mover el cuerpo en un arco de movimiento fluido bajo la barra.', 'Paso 3: Mantén la articulación del hombro activa para prevenir lesiones por tracción.', 'Paso 4: Controla el ritmo del balanceo para mantener la estabilidad unilateral.']::text[],
  'avanzado',
  'Ejercicio avanzado que utiliza la inercia pendular sobre una barra, desafiando la estabilidad unilateral y la fuerza de agarre.',
  ARRAY['Fuerza de agarre', 'Estabilidad unilateral']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Transición 180 sobre la barra a Front lever',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/transicion_180_sobre_la_barra_a_front_lever.webp',
  ARRAY['Paso 1: Impúlsate sobre la barra fija, sobrepasándola con el pecho.', 'Paso 2: Realiza el giro de 180 grados manteniendo un agarre seguro.', 'Paso 3: Inicia un descenso controlado hacia la posición paralela al suelo.', 'Paso 4: Bloquea el cuerpo horizontalmente para estabilizar el front lever con tensión máxima.']::text[],
  'avanzado',
  'Movimiento complejo que integra una rotación de 180 grados sobre la barra con una transición directa a una posición estática horizontal de front lever.',
  ARRAY['Dominio corporal', 'Fuerza de tracción']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Salto dinámico desde apoyo frontal en barra fija',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/salto_dinamico_desde_apoyo_frontal_en_barra_fija.webp',
  ARRAY['Paso 1: Adopta la posición de apoyo frontal sobre la barra con brazos extendidos.', 'Paso 2: Genera un impulso explosivo desde el apoyo para elevar el cuerpo verticalmente.', 'Paso 3: Despega el apoyo de la barra momentáneamente.', 'Paso 4: Aterriza nuevamente en la posición de apoyo frontal con control total.']::text[],
  'avanzado',
  'Ejercicio de potencia explosiva que parte de la posición de apoyo sobre la barra y se eleva mediante un salto hacia arriba.',
  ARRAY['Potencia', 'Coordinación']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Suelta acrobática en posición extendida en barra fija',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/suelta_acrobatica_en_posicion_extendida_en_barra_fija.webp',
  ARRAY['Paso 1: Realiza un balanceo que permita extender el cuerpo completamente lejos de la barra.', 'Paso 2: Suelta el agarre en el punto crítico de máxima inercia.', 'Paso 3: Ejecuta la rotación técnica en el aire mientras te mantienes extendido.', 'Paso 4: Asegura un aterrizaje controlado, utilizando la flexión de piernas para amortiguar.']::text[],
  'avanzado',
  'Maniobra acrobática donde el atleta se suelta de la barra en una fase de máxima extensión para ejecutar un giro o pirueta aérea.',
  ARRAY['Dominio acrobático', 'Potencia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Suelta acrobática en posición extendida en barra fija',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/suelta_acrobatica_en_posicion_extendida_en_barra_fija_v2.webp',
  ARRAY['Paso 1: Realiza un balanceo que permita extender el cuerpo completamente lejos de la barra.', 'Paso 2: Suelta el agarre en el punto crítico de máxima inercia.', 'Paso 3: Ejecuta la rotación técnica en el aire mientras te mantienes extendido.', 'Paso 4: Asegura un aterrizaje controlado, utilizando la flexión de piernas para amortiguar.']::text[],
  'avanzado',
  'Maniobra acrobática donde el atleta se suelta de la barra en una fase de máxima extensión para ejecutar un giro o pirueta aérea.',
  ARRAY['Dominio acrobático', 'Potencia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Suelta acrobática en posición extendida en barra fija',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/suelta_acrobatica_en_posicion_extendida_en_barra_fija_v3.webp',
  ARRAY['Paso 1: Ejecuta un balanceo vigoroso sobre la barra para maximizar la inercia del cuerpo.', 'Paso 2: Libera las manos de la barra en el punto culminante de la extensión, manteniendo el cuerpo rígido.', 'Paso 3: Realiza la rotación técnica en el aire mientras mantienes la posición corporal extendida.', 'Paso 4: Aterriza con las articulaciones de las rodillas y tobillos flexionadas para disipar la fuerza del impacto.']::text[],
  'avanzado',
  'Maniobra aérea avanzada de liberación de la barra en la fase de máxima extensión, seguida de una rotación controlada antes de realizar el aterrizaje.',
  ARRAY['Dominio acrobático', 'Potencia de salida']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Human flag',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/human_flag.webp',
  ARRAY['Paso 1: Sujeta una barra vertical con la mano superior en agarre prono y la mano inferior en agarre supino.', 'Paso 2: Genera un impulso inicial y tracciona con el brazo superior mientras empujas vigorosamente con el brazo inferior.', 'Paso 3: Eleva las piernas y el torso hasta lograr la posición horizontal, alineando perfectamente el cuerpo.', 'Paso 4: Mantén la contracción isométrica intensa de oblicuos, dorsales y deltoides para sostener la bandera.']::text[],
  'avanzado',
  'Habilidad isométrica extrema que consiste en sostener el cuerpo en posición perpendicular al suelo, sujeto a una barra vertical mediante fuerzas opuestas de empuje y tracción.',
  ARRAY['Fuerza máxima', 'Dominio corporal', 'Fuerza isométrica de core']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Salida en mortal hacia atrás en barra fija',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/salida_en_mortal_hacia_atras_en_barra_fija_v2.webp',
  ARRAY['Paso 1: Realiza un ciclo de balanceo dinámico sobre la barra fija para acumular energía cinética.', 'Paso 2: Suelta el agarre en la fase ascendente del balanceo mientras ejecutas una flexión explosiva de cadera hacia atrás.', 'Paso 3: Realiza la rotación completa del cuerpo en el aire con la mirada enfocada en el aterrizaje.', 'Paso 4: Aterriza de forma controlada sobre ambas piernas, amortiguando la caída con una flexión conjunta de rodillas y caderas.']::text[],
  'avanzado',
  'Maniobra acrobática de desenganche de la barra que culmina con una rotación completa hacia atrás en el eje transversal del cuerpo.',
  ARRAY['Dominio acrobático', 'Potencia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Salida en mortal hacia atrás en barras paralelas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/salida_en_mortal_hacia_atras_en_barras_paralelas.webp',
  ARRAY['Paso 1: Realiza un balanceo explosivo entre las barras paralelas hasta alcanzar una altura suficiente.', 'Paso 2: Despréndete de las barras impulsando la cadera hacia arriba y atrás al finalizar la oscilación.', 'Paso 3: Completa la trayectoria circular hacia atrás mientras el cuerpo se encuentra en la fase aérea.', 'Paso 4: Realiza el aterrizaje con los pies paralelos, amortiguando el impacto con la musculatura del tren inferior.']::text[],
  'avanzado',
  'Ejecución de un giro acrobático hacia atrás partiendo de un impulso previo entre barras paralelas, exigiendo gran potencia explosiva y orientación espacial.',
  ARRAY['Acrobacia', 'Potencia', 'Coordinación']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Handstand en barra fija',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/calistenia/handstand_en_barra_fija.webp',
  ARRAY['Paso 1: Sube a la barra fija utilizando una técnica de ''pull-over'' o impulso para quedar en apoyo frontal.', 'Paso 2: Realiza una transición hacia la vertical, sosteniéndote exclusivamente de la barra con las manos.', 'Paso 3: Mantén los brazos bloqueados, los hombros activos en empuje y el core totalmente estable para evitar la caída.', 'Paso 4: Equilibra el cuerpo mediante micromovimientos de muñeca y ajuste de la línea de gravedad.']::text[],
  'avanzado',
  'Posición de equilibrio vertical invertido realizada sobre la estructura de una barra fija, desafiando la fuerza de agarre, el equilibrio y el control escapular.',
  ARRAY['Equilibrio', 'Control postural', 'Fuerza isométrica de hombros']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Postura del bebé feliz',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/postura_del_bebe_feliz.webp',
  ARRAY['Paso 1: Túmbate boca arriba y flexiona las rodillas hacia el pecho.', 'Paso 2: Sujeta la parte externa de tus pies con las manos, abriendo las rodillas más allá del torso.', 'Paso 3: Empuja suavemente los pies hacia abajo mientras mantienes la espalda plana contra el suelo.', 'Paso 4: Mantén la posición respirando profundamente para profundizar en el estiramiento.']::text[],
  'principiante',
  'Estiramiento restaurativo que busca la apertura profunda de las caderas y la relajación de la zona lumbar.',
  ARRAY['Movilidad de cadera', 'Relajación lumbar']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Estiramiento de mariposa',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/estiramiento_de_mariposa.webp',
  ARRAY['Paso 1: Siéntate en el suelo con la espalda erguida, junta las plantas de los pies y deja caer las rodillas hacia los lados.', 'Paso 2: Sujeta tus pies con las manos y acerca los talones hacia la pelvis lo máximo posible.', 'Paso 3: Mantén la columna recta mientras inclinas el tronco ligeramente hacia adelante desde la cadera.', 'Paso 4: Siente el estiramiento en la cara interna de los muslos sin forzar las rodillas.']::text[],
  'principiante',
  'Ejercicio de flexibilidad enfocado en la elongación de la musculatura aductora mediante la abducción y rotación externa de cadera.',
  ARRAY['Flexibilidad de aductores', 'Apertura de cadera']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla profunda isométrica',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/sentadilla_profunda_isometrica.webp',
  ARRAY['Paso 1: Adopta una posición de sentadilla con pies ligeramente más anchos que la cadera.', 'Paso 2: Desciende hasta que el glúteo quede lo más cerca posible de los talones.', 'Paso 3: Mantén el pecho erguido y los talones en contacto total con el suelo.', 'Paso 4: Sostén la posición manteniendo una contracción estable en el core.']::text[],
  'intermedio',
  'Posición estática en máxima flexión de rodillas y caderas para mejorar la movilidad articular y la resistencia funcional de los miembros inferiores.',
  ARRAY['Movilidad articular', 'Estabilidad funcional']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Postura del niño',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/postura_del_nino.webp',
  ARRAY['Paso 1: Arrodíllate en el suelo y siéntate sobre tus talones.', 'Paso 2: Inclina el tronco hacia adelante extendiendo los brazos por encima de la cabeza.', 'Paso 3: Apoya la frente sobre la superficie, relajando los hombros y el cuello.', 'Paso 4: Sostén la posición permitiendo que la zona lumbar se estire suavemente.']::text[],
  'principiante',
  'Ejercicio de estiramiento y relajación pasiva que busca elongar la columna vertebral y liberar tensión en los músculos dorsales y lumbares.',
  ARRAY['Estiramiento dorsal', 'Relajación']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Postura de la cobra',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/postura_de_la_cobra.webp',
  ARRAY['Paso 1: Túmbate boca abajo con las manos apoyadas debajo de los hombros.', 'Paso 2: Presiona con las manos hacia el suelo extendiendo los brazos y elevando el pecho.', 'Paso 3: Mantén la pelvis apoyada en el suelo y la mirada hacia el frente o ligeramente arriba.', 'Paso 4: Siente el estiramiento en el abdomen y la contracción en la espalda baja.']::text[],
  'principiante',
  'Estiramiento dinámico de la cadena anterior diseñado para mejorar la extensión de la columna y fortalecer los músculos lumbares.',
  ARRAY['Extensión de columna', 'Fortalecimiento lumbar']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Torsión espinal supina',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/torsion_espinal_supina.webp',
  ARRAY['Paso 1: Túmbate boca arriba y lleva una rodilla flexionada hacia el lado opuesto del cuerpo.', 'Paso 2: Extiende los brazos en cruz y mantén los hombros bien apoyados en el suelo.', 'Paso 3: Presiona suavemente la rodilla hacia el piso con la mano contraria mientras giras la cabeza hacia el lado opuesto.', 'Paso 4: Mantén la posición unos segundos y cambia de lado de forma controlada.']::text[],
  'principiante',
  'Movimiento de rotación pasiva para la columna vertebral, excelente para mejorar la movilidad torácica y aliviar tensiones en la zona lumbar.',
  ARRAY['Movilidad de columna', 'Alivio de tensión']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevaciones laterales con banda de resistencia tubular',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/elevaciones_laterales_con_banda_de_resistencia_tubular.webp',
  ARRAY['Paso 1: Písate el centro de la banda tubular con un pie y sujeta los extremos con las manos.', 'Paso 2: Con los brazos ligeramente flexionados, eleva los brazos lateralmente hasta la altura de los hombros.', 'Paso 3: Controla el descenso evitando dejar caer la carga bruscamente.', 'Paso 4: Mantén el tronco erguido y el core activado durante la ejecución.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para la musculatura deltoidea, utilizando la tensión elástica para fortalecer la abducción del brazo.',
  ARRAY['Hipertrofia de hombros', 'Fortalecimiento lateral']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Estiramiento de psoas en posición de caballero',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/estiramiento_de_psoas_en_posicion_de_caballero.webp',
  ARRAY['Paso 1: Colócate en posición de caballero (una rodilla en el suelo, el otro pie apoyado adelante).', 'Paso 2: Mantén el torso erguido y empuja la cadera hacia adelante manteniendo la espalda recta.', 'Paso 3: Siente un estiramiento profundo en la parte anterior de la cadera de la pierna apoyada.', 'Paso 4: Contrae el glúteo de la pierna trasera para maximizar la apertura del psoas.']::text[],
  'principiante',
  'Movimiento enfocado en la elongación del músculo psoas ilíaco, fundamental para mejorar la extensión de cadera y la salud postural.',
  ARRAY['Flexibilidad de cadera', 'Corrección postural']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión dinámica de cadera de pie con pierna extendida',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/flexion_dinamica_de_cadera_de_pie_con_pierna_extendida.webp',
  ARRAY['Paso 1: De pie, busca un apoyo estable si es necesario y mantén la espalda erguida.', 'Paso 2: Eleva una pierna extendida hacia adelante hasta alcanzar la máxima altura sin redondear la espalda.', 'Paso 3: Baja la pierna de forma controlada sin apoyar totalmente en el suelo si es posible.', 'Paso 4: Realiza el movimiento manteniendo el core activado para estabilizar la pelvis.']::text[],
  'intermedio',
  'Ejercicio dinámico para trabajar la movilidad y la fuerza de los flexores de cadera en un rango completo de movimiento.',
  ARRAY['Movilidad activa', 'Fortalecimiento de flexores']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Estiramiento de isquiosurales sentado',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/estiramiento_de_isquiosurales_sentado.webp',
  ARRAY['Paso 1: Siéntate con las piernas extendidas y la espalda recta.', 'Paso 2: Inclina el torso desde la cadera hacia adelante intentando alcanzar tus pies.', 'Paso 3: Mantén la columna lo más neutra posible sin redondear excesivamente la espalda.', 'Paso 4: Sostén la posición sintiendo la tensión en la parte posterior de los muslos.']::text[],
  'principiante',
  'Ejercicio de estiramiento pasivo enfocado en la cadena posterior de los muslos para mejorar la flexibilidad isquiosural.',
  ARRAY['Flexibilidad isquiosural', 'Alivio de tensión posterior']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Glute bridge',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/glute_bridge.webp',
  ARRAY['Paso 1: Túmbate boca arriba con las rodillas flexionadas y las plantas de los pies apoyadas en el suelo a la anchura de la cadera.', 'Paso 2: Contrae los glúteos y eleva la pelvis hacia el techo hasta que el cuerpo forme una línea recta desde los hombros hasta las rodillas.', 'Paso 3: Mantén la posición un segundo en el punto máximo de contracción.', 'Paso 4: Desciende la pelvis de forma controlada hasta regresar a la posición inicial.']::text[],
  'principiante',
  'Ejercicio de activación de cadena posterior mediante la extensión de cadera desde una posición supina, enfocado en el fortalecimiento de los glúteos.',
  ARRAY['Activación de glúteo', 'Fortalecimiento de cadena posterior']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Movilidad espinal Gato-Vaca',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/movilidad_espinal_gato_vaca.webp',
  ARRAY['Paso 1: Colócate en posición de cuadrupedia con las manos bajo los hombros y las rodillas bajo las caderas.', 'Paso 2: Inhala mientras arqueas la espalda hacia abajo, elevando el pecho y la mirada (Vaca).', 'Paso 3: Exhala mientras redondeas la espalda hacia el techo, metiendo la barbilla hacia el pecho (Gato).', 'Paso 4: Realiza el movimiento de forma fluida y coordinada con la respiración.']::text[],
  'principiante',
  'Ejercicio dinámico de movilidad vertebral que busca mejorar la flexibilidad de la columna mediante la alternancia entre flexión y extensión.',
  ARRAY['Movilidad de columna', 'Alivio de tensión']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevaciones laterales con banda de resistencia',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/elevaciones_laterales_con_banda_de_resistencia.webp',
  ARRAY['Paso 1: Písate el centro de la banda con un pie y sujeta los extremos con ambas manos.', 'Paso 2: Mantén los brazos ligeramente flexionados y eleva lateralmente hasta que las manos alcancen la altura de los hombros.', 'Paso 3: Controla la bajada para mantener la tensión de la banda en todo momento.', 'Paso 4: Mantén el torso estable y evita ayudarse con impulsos del cuerpo.']::text[],
  'intermedio',
  'Ejercicio de aislamiento para la musculatura deltoidea que utiliza la tensión elástica para fortalecer la abducción del hombro.',
  ARRAY['Hipertrofia de hombros', 'Fortalecimiento lateral']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Liberación miofascial de cuádriceps con foam roller',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/liberacion_miofascial_de_cuadriceps_con_foam_roller.webp',
  ARRAY['Paso 1: Túmbate boca abajo sobre el rodillo de espuma, colocándolo en la parte superior de los muslos.', 'Paso 2: Utiliza los antebrazos para desplazarte lentamente hacia adelante y hacia atrás sobre los cuádriceps.', 'Paso 3: Detente en áreas de mayor tensión o dolor durante 20-30 segundos para permitir la relajación.', 'Paso 4: Mantén una respiración profunda y relajada durante todo el proceso.']::text[],
  'principiante',
  'Técnica de recuperación muscular mediante el uso de un rodillo de espuma para masajear y liberar puntos de tensión en los cuádriceps.',
  ARRAY['Recuperación muscular', 'Liberación miofascial']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Estiramiento de psoas en posición de caballero',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/movilidad_estiramientos/estiramiento_de_psoas_en_posicion_de_caballero_v2.webp',
  ARRAY['Paso 1: Colócate en posición de caballero (rodilla trasera apoyada, pie delantero adelantado).', 'Paso 2: Mantén el torso erguido y desplaza la cadera hacia adelante con suavidad.', 'Paso 3: Contrae el glúteo de la pierna trasera para aumentar el estiramiento en la parte anterior de la cadera.', 'Paso 4: Mantén la posición sintiendo la tensión controlada durante el tiempo indicado.']::text[],
  'principiante',
  'Ejercicio de elongación para el flexor principal de la cadera, esencial para mejorar la postura y movilidad de la zona pélvica.',
  ARRAY['Flexibilidad de cadera', 'Corrección postural']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Pull-up con agarre prono',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/pull_up_con_agarre_prono.webp',
  ARRAY['Paso 1: Sujeta la barra con un agarre prono un poco más ancho que tus hombros.', 'Paso 2: Desde la posición de cuelgue, tracciona llevando el pecho hacia la barra mediante la activación escapular.', 'Paso 3: Eleva el cuerpo hasta que la barbilla supere la altura de la barra.', 'Paso 4: Desciende de manera controlada hasta la posición de extensión total de los brazos.']::text[],
  'intermedio',
  'Ejercicio de tracción vertical que involucra la musculatura de la espalda y los brazos mediante la elevación del peso corporal.',
  ARRAY['Hipertrofia', 'Fuerza de tracción']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Soporte isométrico en anillas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/soporte_isometrico_en_anillas.webp',
  ARRAY['Paso 1: Colócate entre las anillas y elévalas hasta que tus brazos estén extendidos bloqueando los codos.', 'Paso 2: Mantén las anillas cerca del cuerpo y los hombros deprimidos.', 'Paso 3: Activa fuertemente el core y los músculos del pectoral para estabilizar las anillas.', 'Paso 4: Sostén la posición manteniendo una postura erguida y estable.']::text[],
  'intermedio',
  'Ejercicio estático de empuje que exige gran estabilidad y fuerza para mantener el cuerpo elevado sobre las anillas con brazos extendidos.',
  ARRAY['Estabilidad articular', 'Fuerza de soporte']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Overhead squat con barra',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/overhead_squat_con_barra.webp',
  ARRAY['Paso 1: Sujeta la barra con un agarre amplio y elévala sobre tu cabeza manteniendo los brazos totalmente bloqueados.', 'Paso 2: Realiza una sentadilla profunda manteniendo el torso lo más erguido posible.', 'Paso 3: Asegura que el centro de gravedad de la barra permanezca alineado con tus talones.', 'Paso 4: Regresa a la posición vertical mediante una extensión completa de rodillas y caderas.']::text[],
  'avanzado',
  'Sentadilla completa con barra cargada por encima de la cabeza, desafiando la movilidad, el equilibrio y la estabilidad de todo el cuerpo.',
  ARRAY['Movilidad', 'Estabilidad de hombros', 'Fuerza funcional']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Handstand en paralelas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/handstand_en_paralelas.webp',
  ARRAY['Paso 1: Apoya las manos en las paralelas a la anchura de tus hombros.', 'Paso 2: Lanza las piernas hacia arriba controladamente hasta alcanzar la verticalidad.', 'Paso 3: Mantén los codos bloqueados y los hombros activos empujando las barras hacia el suelo.', 'Paso 4: Equilibra la postura activando el abdomen y ajustando con la presión de tus manos.']::text[],
  'avanzado',
  'Postura de inversión vertical apoyada sobre las manos en barras paralelas, mejorando el control corporal y la fuerza de hombros.',
  ARRAY['Fuerza de hombros', 'Equilibrio', 'Control postural']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Overhead lunge con barra',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/overhead_lunge_con_barra.webp',
  ARRAY['Paso 1: Sostén la barra sobre tu cabeza con los brazos extendidos y firmes.', 'Paso 2: Da un paso al frente y desciende hasta que la rodilla trasera quede cerca del suelo.', 'Paso 3: Mantén la barra alineada verticalmente sobre el centro de gravedad durante todo el recorrido.', 'Paso 4: Impúlsate para regresar a la posición inicial alternando las piernas.']::text[],
  'avanzado',
  'Zancada dinámica con carga mantenida por encima de la cabeza, requiriendo gran estabilidad central y de hombros.',
  ARRAY['Estabilidad', 'Fuerza unilateral', 'Coordinación']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Overhead squat con barra',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/overhead_squat_con_barra_v2.webp',
  ARRAY['Paso 1: Sujeta la barra con un agarre amplio y elévala sobre tu cabeza manteniendo los brazos totalmente bloqueados.', 'Paso 2: Realiza una sentadilla profunda manteniendo el torso lo más erguido posible.', 'Paso 3: Asegura que el centro de gravedad de la barra permanezca alineado con tus talones.', 'Paso 4: Regresa a la posición vertical mediante una extensión completa de rodillas y caderas.']::text[],
  'avanzado',
  'Sentadilla completa con barra cargada por encima de la cabeza, desafiando la movilidad, el equilibrio y la estabilidad de todo el cuerpo.',
  ARRAY['Movilidad', 'Estabilidad de hombros', 'Fuerza funcional']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Toes to bar',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/toes_to_bar.webp',
  ARRAY['Paso 1: Sujétate a la barra de dominadas con las manos separadas a la anchura de los hombros.', 'Paso 2: Activa el core y eleva las piernas de forma fluida llevando los pies hacia la barra.', 'Paso 3: Toca la barra con las puntas de los pies, manteniendo las piernas lo más estiradas posible.', 'Paso 4: Regresa a la posición inicial controlando el balanceo del cuerpo.']::text[],
  'avanzado',
  'Ejercicio de core en suspensión que consiste en elevar los pies hasta tocar la barra, trabajando la flexión abdominal explosiva.',
  ARRAY['Fuerza de core', 'Coordinación', 'Movilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Step-up en cajón con mancuernas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/step_up_en_cajon_con_mancuernas.webp',
  ARRAY['Paso 1: Sostén un par de mancuernas al lado del cuerpo y colócate frente al cajón.', 'Paso 2: Sube al cajón apoyando firmemente un pie y empujando para elevar todo el cuerpo.', 'Paso 3: Extiende la cadera completamente arriba antes de bajar de forma controlada.', 'Paso 4: Alterna los pies en cada repetición manteniendo el equilibrio.']::text[],
  'intermedio',
  'Ejercicio unilateral de tren inferior que utiliza un cajón como plataforma para ganar fuerza y potencia en la subida.',
  ARRAY['Fortalecimiento unilateral', 'Potencia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Handstand asistido de cara a la pared',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/handstand_asistido_de_cara_a_la_pared.webp',
  ARRAY['Paso 1: Colócate de espaldas a la pared y camina hacia arriba con los pies mientras acercas las manos al muro.', 'Paso 2: Mantén el cuerpo alineado y lo más cerca posible de la pared.', 'Paso 3: Empuja el suelo activamente con los hombros bloqueados.', 'Paso 4: Sostén la posición manteniendo una contracción fuerte de abdomen y glúteos.']::text[],
  'intermedio',
  'Progresión técnica para el pino (handstand) donde la pared sirve como apoyo para mantener la verticalidad y ganar fuerza en hombros.',
  ARRAY['Fuerza de hombros', 'Control postural', 'Equilibrio']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dip en barra fija',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/dip_en_barra_fija.webp',
  ARRAY['Paso 1: Súbete a la barra fija y mantén el equilibrio con brazos extendidos.', 'Paso 2: Flexiona los codos bajando el cuerpo hasta que el pecho toque la barra.', 'Paso 3: Empuja el cuerpo hacia arriba hasta la posición de extensión completa.', 'Paso 4: Mantén el core activo para evitar oscilaciones sobre la barra durante el movimiento.']::text[],
  'intermedio',
  'Ejercicio de empuje de alta intensidad para tríceps y pectorales que utiliza una barra fija para realizar un fondo vertical.',
  ARRAY['Fuerza de empuje', 'Hipertrofia']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Double-unders',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/double_unders.webp',
  ARRAY['Paso 1: Sujeta los mangos de la comba firmemente y mantén una postura erguida.', 'Paso 2: Realiza un salto vertical constante, generando el giro rápido de la cuerda mediante las muñecas.', 'Paso 3: Sincroniza el giro doble de la cuerda con la altura y el tempo de tu salto.', 'Paso 4: Mantén un aterrizaje suave sobre las puntas de los pies para absorber el impacto.']::text[],
  'avanzado',
  'Ejercicio de alta intensidad que consiste en saltar a la comba haciendo que la cuerda pase dos veces por debajo de los pies en un solo salto.',
  ARRAY['Resistencia cardiovascular', 'Coordinación', 'Agilidad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Handstand walk',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/handstand_walk.webp',
  ARRAY['Paso 1: Colócate en posición de pino (handstand) cerca de una pared o en un espacio abierto.', 'Paso 2: Despega una mano del suelo para avanzar mientras mantienes el centro de gravedad estable.', 'Paso 3: Alterna el apoyo de las manos manteniendo los codos bloqueados y el core contraído.', 'Paso 4: Mantén la mirada fija en un punto entre tus manos para facilitar el equilibrio.']::text[],
  'avanzado',
  'Desplazamiento caminando sobre las manos manteniendo el cuerpo en posición invertida, ideal para mejorar el equilibrio y la fuerza de hombros.',
  ARRAY['Equilibrio', 'Control motor', 'Fuerza de hombros']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Salto vertical',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/salto_vertical.webp',
  ARRAY['Paso 1: Colócate de pie con los pies a la anchura de los hombros.', 'Paso 2: Realiza una pequeña flexión de rodillas mientras balanceas los brazos hacia atrás.', 'Paso 3: Extiende explosivamente todo el cuerpo hacia arriba, lanzando los brazos hacia el techo.', 'Paso 4: Aterriza con suavidad, amortiguando el impacto con una ligera flexión de rodillas.']::text[],
  'intermedio',
  'Movimiento pliométrico explosivo destinado a maximizar la altura del salto mediante una rápida extensión de rodillas, caderas y tobillos.',
  ARRAY['Potencia', 'Velocidad', 'Explosividad']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Snatch a una mano con mancuerna',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/snatch_a_una_mano_con_mancuerna.webp',
  ARRAY['Paso 1: Colócate con la mancuerna entre tus pies y realiza una bisagra de cadera para sujetarla.', 'Paso 2: Tira de la mancuerna hacia arriba usando la potencia de las piernas y cadera.', 'Paso 3: Completa el movimiento con un tirón final y bloqueo de brazo por encima de la cabeza.', 'Paso 4: Controla el descenso de la mancuerna hacia el suelo manteniendo la espalda recta.']::text[],
  'avanzado',
  'Ejercicio técnico de potencia que consiste en llevar una mancuerna desde el suelo hasta la extensión completa por encima de la cabeza en un solo movimiento fluido.',
  ARRAY['Potencia', 'Coordinación', 'Fuerza unilateral']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancada hacia delante con peso corporal',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/zancada_hacia_delante_con_peso_corporal.webp',
  ARRAY['Paso 1: De pie, da un paso amplio hacia adelante con una pierna.', 'Paso 2: Desciende el centro de gravedad hasta que ambas rodillas formen un ángulo de 90 grados.', 'Paso 3: Mantén el torso erguido y el core activado durante toda la ejecución.', 'Paso 4: Impúlsate con la pierna delantera para regresar a la posición inicial y alterna.']::text[],
  'principiante',
  'Movimiento básico de tren inferior enfocado en el equilibrio, coordinación y fortalecimiento de las piernas mediante una zancada profunda.',
  ARRAY['Fortalecimiento', 'Equilibrio', 'Coordinación']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Paseo del granjero con mancuernas',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/paseo_del_granjero_con_mancuernas.webp',
  ARRAY['Paso 1: Sujeta una mancuerna pesada en cada mano a los costados de tu cuerpo.', 'Paso 2: Mantén los hombros atrás, el pecho erguido y el abdomen firme.', 'Paso 3: Camina con pasos cortos y controlados, evitando el balanceo lateral del cuerpo.', 'Paso 4: Mantén una postura impecable durante toda la distancia recorrida.']::text[],
  'intermedio',
  'Ejercicio de transporte de carga que desarrolla una fuerza de agarre excepcional y estabilidad postural bajo tensión.',
  ARRAY['Fuerza de agarre', 'Estabilidad del core', 'Acondicionamiento físico']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla libre con peso corporal',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/sentadilla_libre_con_peso_corporal.webp',
  ARRAY['Paso 1: Colócate de pie con los pies a la anchura de los hombros y puntas ligeramente hacia afuera.', 'Paso 2: Desciende flexionando caderas y rodillas, manteniendo el pecho erguido y talones apoyados.', 'Paso 3: Baja hasta que el pliegue de la cadera esté por debajo de la rodilla si tu movilidad lo permite.', 'Paso 4: Empuja desde el talón para volver a la posición erguida con una extensión completa de caderas.']::text[],
  'principiante',
  'Movimiento multiarticular fundamental para el tren inferior que mejora la fuerza, movilidad de cadera y salud de las rodillas.',
  ARRAY['Fuerza', 'Movilidad', 'Acondicionamiento']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Kettlebell swing',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/kettlebell_swing.webp',
  ARRAY['Paso 1: Sujeta la kettlebell con ambas manos y mantén una postura atlética con rodillas ligeramente flexionadas.', 'Paso 2: Inicia el balanceo mediante un empuje explosivo de cadera hacia adelante.', 'Paso 3: Deja que la inercia lleve la kettlebell hasta la altura del pecho o la cabeza.', 'Paso 4: Regresa controladamente a la posición inicial, manteniendo la espalda neutra en todo momento.']::text[],
  'intermedio',
  'Ejercicio balístico que utiliza la bisagra de cadera para propulsar una kettlebell, altamente efectivo para la cadena posterior y el sistema cardiovascular.',
  ARRAY['Potencia', 'Resistencia cardiovascular', 'Fuerza de cadena posterior']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Step-up pliométrico en cajón',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/step_up_pliometrico_en_cajon.webp',
  ARRAY['Paso 1: Colócate frente al cajón con un pie apoyado sobre la superficie.', 'Paso 2: Impúlsate explosivamente para subir al cajón, cambiando de pie en el aire si es posible.', 'Paso 3: Aterriza controladamente sobre el cajón y baja con suavidad.', 'Paso 4: Mantén un ritmo ágil, asegurando siempre una base de apoyo segura.']::text[],
  'avanzado',
  'Variante explosiva del step-up que añade un componente de salto para trabajar la potencia y la capacidad reactiva del tren inferior.',
  ARRAY['Potencia', 'Resistencia cardiovascular', 'Coordinación']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Wall ball shot',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/crossfit/wall_ball_shot.webp',
  ARRAY['Paso 1: Colócate frente a una pared sujetando el balón medicinal a la altura del pecho.', 'Paso 2: Realiza una sentadilla profunda manteniendo el torso erguido.', 'Paso 3: Al subir de la sentadilla, extiende explosivamente caderas y piernas mientras lanzas el balón hacia el objetivo marcado en la pared.', 'Paso 4: Atrapa el balón al rebote y desciende de inmediato a la siguiente repetición.']::text[],
  'intermedio',
  'Ejercicio metabólico que combina una sentadilla profunda con un lanzamiento de balón medicinal hacia un objetivo en la pared, requiriendo coordinación y potencia.',
  ARRAY['Resistencia cardiovascular', 'Potencia', 'Acondicionamiento físico']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión lateral de tronco con banda de resistencia (Oblicuos)',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/acondicionamiento/flexion_lateral_de_tronco_con_banda_de_resistencia_oblicuos.webp',
  ARRAY['Paso 1: Pisa un extremo de la banda con el pie y sujeta el otro extremo con la mano del mismo lado.', 'Paso 2: Manteniendo las piernas estables, inclina el tronco hacia el lado opuesto al de la mano que sujeta la banda.', 'Paso 3: Siente la contracción en los oblicuos y regresa lentamente a la posición erguida.', 'Paso 4: Asegúrate de mantener la espalda recta durante todo el movimiento sin rotar el torso.']::text[],
  'principiante',
  'Ejercicio de fortalecimiento para el core que utiliza la resistencia de una banda para enfatizar la contracción de los músculos oblicuos mediante una inclinación lateral.',
  ARRAY['Fortalecimiento de oblicuos', 'Estabilidad del core']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Estiramiento de isquiosurales con banda de resistencia',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/acondicionamiento/estiramiento_de_isquiosurales_con_banda_de_resistencia.webp',
  ARRAY['Paso 1: Túmbate boca arriba y coloca la banda en la planta de un pie mientras sujetas los extremos con las manos.', 'Paso 2: Manteniendo la rodilla estirada, tira suavemente de la banda para elevar la pierna hacia el techo.', 'Paso 3: Siente el estiramiento en la parte posterior del muslo, evitando elevar los hombros del suelo.', 'Paso 4: Mantén la posición de tensión controlada durante el tiempo indicado.']::text[],
  'principiante',
  'Ejercicio de flexibilidad pasiva que utiliza una banda para asistir la elevación de la pierna y elongar la musculatura posterior del muslo.',
  ARRAY['Flexibilidad isquiosural', 'Alivio de tensión']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de hombros frontal con banda de resistencia',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/acondicionamiento/press_de_hombros_frontal_con_banda_de_resistencia.webp',
  ARRAY['Paso 1: Písate el centro de la banda y sujeta los extremos a la altura de tus hombros con los codos flexionados.', 'Paso 2: Empuja la banda hacia arriba extendiendo los brazos por encima de la cabeza.', 'Paso 3: Controla el descenso regresando a la posición inicial al nivel de los hombros.', 'Paso 4: Mantén el core firme para evitar arquear la zona lumbar.']::text[],
  'intermedio',
  'Ejercicio de empuje vertical para el desarrollo de los hombros, utilizando una banda de resistencia para crear tensión continua en la musculatura deltoidea.',
  ARRAY['Hipertrofia de hombros', 'Fuerza de empuje']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dominadas asistidas con banda de resistencia',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/acondicionamiento/dominadas_asistidas_con_banda_de_resistencia.webp',
  ARRAY['Paso 1: Coloca la banda en la barra de dominadas y apoya un pie o rodilla en ella.', 'Paso 2: Sujeta la barra con agarre prono y realiza la dominada superando la resistencia de la banda.', 'Paso 3: Sube hasta que la barbilla pase la barra, controlando el movimiento.', 'Paso 4: Desciende lentamente aprovechando la asistencia de la banda para mantener la tensión.']::text[],
  'principiante',
  'Variante de dominada que utiliza una banda para asistir el movimiento de tracción, permitiendo completar el rango de recorrido a quienes están ganando fuerza.',
  ARRAY['Fuerza de tracción', 'Progresión en dominadas']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Pull-apart con banda de resistencia (Deltoides posterior)',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/acondicionamiento/pull_apart_con_banda_de_resistencia_deltoides_posterior.webp',
  ARRAY['Paso 1: Sujeta la banda frente a ti con los brazos estirados a la altura de los hombros.', 'Paso 2: Separa las manos estirando la banda lateralmente hasta que llegue a tocar tu pecho.', 'Paso 3: Mantén los brazos bloqueados y contrae los omóplatos al máximo en la fase final.', 'Paso 4: Regresa a la posición inicial controlando la resistencia elástica.']::text[],
  'principiante',
  'Ejercicio de aislamiento para la parte posterior del hombro y la estabilidad escapular, realizando una apertura horizontal con banda.',
  ARRAY['Salud de hombro', 'Fortalecimiento de deltoides posterior']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Face pull con banda de resistencia (Deltoides posterior)',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/acondicionamiento/face_pull_con_banda_de_resistencia_deltoides_posterior.webp',
  ARRAY['Paso 1: Engancha la banda a una altura media y sujeta los extremos con ambas manos.', 'Paso 2: Tracciona hacia tu cara, llevando los codos hacia afuera y atrás, por encima de las manos.', 'Paso 3: Realiza una contracción máxima de la parte superior de la espalda y hombros.', 'Paso 4: Regresa suavemente a la posición de brazos estirados.']::text[],
  'intermedio',
  'Movimiento de tracción horizontal que busca la rotación externa del hombro para fortalecer la parte posterior y mejorar la postura.',
  ARRAY['Postura', 'Estabilidad de hombro']::text[]
) on conflict do nothing;

insert into public.ejercicios (nombre, url_gif, url_preview, instrucciones, dificultad, descripcion, finalidad)
values (
  'Shoulder dislocations con banda de resistencia',
  '',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/synaptixfit/acondicionamiento/shoulder_dislocations_con_banda_de_resistencia.webp',
  ARRAY['Paso 1: Sujeta la banda con un agarre amplio frente a ti.', 'Paso 2: Eleva la banda pasando por encima de la cabeza hasta llevarla detrás de la espalda, siempre con brazos estirados.', 'Paso 3: Regresa a la posición frontal realizando el mismo movimiento circular.', 'Paso 4: Ajusta el ancho del agarre para facilitar el giro si hay tensión excesiva.']::text[],
  'principiante',
  'Ejercicio de movilidad dinámica para las articulaciones glenohumerales que consiste en pasar la banda de adelante hacia atrás con brazos rectos.',
  ARRAY['Movilidad de hombro', 'Calentamiento']::text[]
) on conflict do nothing;

-- Recrear v_ejercicios_completos con url_preview
create or replace view public.v_ejercicios_completos
with (security_invoker = true)
as
select
  e.id,
  e.nombre,
  e.url_gif,
  e.url_preview,
  e.instrucciones,
  e.dificultad,
  e.descripcion,
  e.finalidad,
  e.creado_en,
  e.actualizado_en,
  coalesce((select array_agg(distinct pc.nombre order by pc.nombre)
    from public.ejercicio_parte_cuerpo epc join public.partes_cuerpo pc on pc.id = epc.parte_cuerpo_id
    where epc.ejercicio_id = e.id), array[]::text[]) as partes_cuerpo,
  coalesce((select array_agg(distinct mt.nombre order by mt.nombre)
    from public.ejercicio_musculo_objetivo emo join public.musculos mt on mt.id = emo.musculo_id
    where emo.ejercicio_id = e.id), array[]::text[]) as musculos_objetivo,
  coalesce((select array_agg(distinct ms.nombre order by ms.nombre)
    from public.ejercicio_musculo_secundario ems join public.musculos ms on ms.id = ems.musculo_id
    where ems.ejercicio_id = e.id), array[]::text[]) as musculos_secundarios,
  coalesce((select array_agg(distinct eq.nombre order by eq.nombre)
    from public.ejercicio_equipamiento ee join public.equipamientos eq on eq.id = ee.equipamiento_id
    where ee.ejercicio_id = e.id), array[]::text[]) as equipamientos
from public.ejercicios e;
grant select on public.v_ejercicios_completos to anon, authenticated;
