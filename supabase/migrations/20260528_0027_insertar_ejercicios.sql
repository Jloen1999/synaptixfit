-- Migration: 0027_insertar_ejercicios
-- Objetivo: Insertar los 89 ejercicios del catalogo unificado
--           desde nuevos_ejercicios.json (sin duplicados).

-- Asegurar UNIQUE en nombre (DO block porque PG no soporta ADD CONSTRAINT IF NOT EXISTS)
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'ejercicios_nombre_unique'
      and conrelid = 'public.ejercicios'::regclass
  ) then
    alter table public.ejercicios add constraint ejercicios_nombre_unique unique (nombre);
  end if;
end $$;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevaciones con mancuernas (Frontal, Lateral y Posterior)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevaciones_con_mancuernas_frontal_lateral_y_posterior.mp4',
  '["Mantén el core firme y el pecho alto.", "Para las elevaciones frontales, levanta las mancuernas hacia el frente hasta la altura de los hombros.", "Para las elevaciones laterales, eleva los brazos hacia los lados con una ligera flexión de codo.", "Para las elevaciones posteriores, inclina el torso hacia adelante y eleva los brazos hacia los lados enfocándote en la contracción de la parte superior."]'::jsonb,
  'principiante',
  'Rutina combinada de hombros que involucra elevaciones frontales, laterales y pájaros o elevaciones posteriores para trabajar todas las cabezas del deltoides.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla Goblet (Variaciones de elevación)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_goblet_variaciones_de_elevacion.mp4',
  '["Sostén una mancuerna verticalmente pegada al pecho.", "Para enfocar los glúteos, apoya las puntas de los pies sobre unos discos pequeños y realiza la sentadilla.", "Para enfocar los cuádriceps, apoya los talones sobre los discos y mantén el torso más erguido durante el descenso.", "Desciende controladamente y empuja desde los pies para volver a la posición inicial."]'::jsonb,
  'intermedio',
  'Variaciones de la sentadilla Goblet utilizando discos para elevar las puntas de los pies (mayor énfasis en glúteos) o los talones (mayor énfasis en cuádriceps).',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de cuádriceps en máquina (Rotaciones de pie)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/extension_de_cuadriceps_en_maquina_rotaciones_de_pie.mp4',
  '["Siéntate en la máquina de extensión con la espalda totalmente apoyada en el respaldo.", "Ajusta el rodillo para que quede justo por encima de los empeines.", "Gira las puntas de los pies hacia afuera, hacia adentro o mantenlas neutrales según la porción del cuádriceps que desees priorizar.", "Extiende las rodillas completamente de manera controlada y regresa a la posición inicial sin dejar caer las placas de peso."]'::jsonb,
  'principiante',
  'Ejercicio de extensión de piernas en máquina modificando la rotación de las puntas de los pies para enfatizar diferentes porciones del cuádriceps.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Face Pull en polea alta',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/face_pull_en_polea_alta.mp4',
  '["Ajusta la polea a la altura del pecho superior o del rostro y utiliza un agarre de cuerda.", "Tira de la cuerda hacia tus ojos o frente, manteniendo los codos altos y alineados con los hombros.", "Evita encoger los hombros hacia las orejas para no sobrecargar el elevador de la escápula.", "Controla la fase excéntrica al extender los brazos de regreso a la posición inicial."]'::jsonb,
  'intermedio',
  'Tracción en polea alta con cuerda hacia el rostro, enfocada en el aislamiento del deltoides posterior y la retracción escapular adecuada.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'L-Sit en el suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/l_sit_en_el_suelo.mp4',
  '["Siéntate en el suelo con las piernas extendidas juntas frente a ti.", "Coloca las palmas de las manos en el suelo a los lados de las caderas, manteniendo los brazos completamente estirados.", "Empuja el suelo con las manos activando la depresión escapular, mientras contraes el abdomen para levantar los glúteos y las piernas del suelo.", "Mantén una flexión de cadera de 90 grados, formando una ''L'' con tu cuerpo, y sostén la posición de forma isométrica."]'::jsonb,
  'avanzado',
  'Ejercicio isométrico avanzado que utiliza el peso corporal; requiere fuerza en el core y flexibilidad para mantener el cuerpo elevado formando un ángulo de 90 grados.',
  'resistencia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Jalón al pecho en polea (Variaciones de agarre)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/jalon_al_pecho_en_polea_variaciones_de_agarre.mp4',
  '["Siéntate en la máquina de jalón asegurando los muslos firmemente bajo los rodillos de soporte.", "Para enfocar la espalda alta y el dorsal externo, utiliza un agarre prono ancho.", "Para un mayor enfoque en el dorsal inferior y los bíceps, utiliza un agarre supino estrecho.", "Tira de la barra hacia la parte superior del pecho deprimiendo las escápulas, y luego extiende los brazos de manera controlada."]'::jsonb,
  'principiante',
  'Diferentes variantes de agarre (ancho prono, estrecho supino y neutro) en el jalón al pecho para modificar la activación del dorsal ancho y la espalda alta.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps concentrado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_concentrado.mp4',
  '["Siéntate en un banco con las piernas separadas, sosteniendo una mancuerna con agarre supino.", "Apoya la parte posterior de tu brazo (tríceps) firmemente en la parte interna del muslo, o mantén el codo bloqueado al costado del torso sin que se desplace hacia atrás.", "Flexiona el codo para elevar la mancuerna hacia el hombro, contrayendo fuertemente el bíceps.", "Desciende la mancuerna de manera controlada hasta la extensión casi completa del brazo."]'::jsonb,
  'principiante',
  'Ejercicio de aislamiento para los bíceps realizado en posición sentada, enfocado en mantener la articulación del codo estable para maximizar la contracción.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión y extensión de muñecas sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/flexion_y_extension_de_munecas_sentado.mp4',
  '["Siéntate frente a un banco y apoya completamente tus antebrazos sobre la almohadilla, dejando las muñecas colgando en el borde.", "Para trabajar los flexores, agarra los discos con las palmas hacia arriba (supinación) y flexiona las muñecas hacia ti.", "Para trabajar los extensores, agarra los discos con las palmas hacia abajo (pronación) y levanta el dorso de las manos hacia arriba.", "Mantén el movimiento lento y controlado, evitando usar el impulso o levantar los codos del banco."]'::jsonb,
  'principiante',
  'Rutina de aislamiento enfocada en el desarrollo de los antebrazos, utilizando discos de pesas para trabajar tanto la cara anterior como posterior del antebrazo.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla isométrica en pared (Wall Sit)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_isometrica_en_pared_wall_sit.mp4',
  '["Apoya tu espalda completamente plana contra una pared sólida.", "Deslízate hacia abajo hasta que tus caderas y rodillas formen un ángulo de 90 grados, como si estuvieras sentado en una silla invisible.", "Mantén los pies firmemente apoyados en el suelo, alineados con el ancho de los hombros y las rodillas apuntando en dirección a las puntas de los pies.", "Contrae el abdomen y los cuádriceps para mantener la posición el tiempo estipulado sin usar las manos para apoyarte en los muslos."]'::jsonb,
  'principiante',
  'Ejercicio isométrico sin equipo que consiste en mantener una postura de sentadilla contra la pared, desarrollando resistencia y fuerza en las piernas.',
  'resistencia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Cruces en polea para hombros y espalda',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/cruces_en_polea_para_hombros_y_espalda.mp4',
  '["Posiciónate en el centro de una máquina de poleas cruzadas y sujeta los cables de forma opuesta (mano derecha al cable izquierdo y viceversa).", "Para enfocarte en los deltoides posteriores y trapecios, ajusta las poleas a una altura media-alta y realiza aperturas inversas (pájaros).", "Para enfocarte en los deltoides laterales, mantente erguido, con las poleas bajas, y eleva los brazos hacia los lados de manera cruzada.", "Controla siempre la fase excéntrica del movimiento (el retorno) para maximizar la tensión muscular."]'::jsonb,
  'intermedio',
  'Conjunto de variaciones utilizando poleas cruzadas (elevaciones laterales, frontales y pájaros) para trabajar de manera integral los deltoides y la musculatura alta de la espalda.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla pesada con mancuerna (Variaciones de enfoque)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_pesada_con_mancuerna_variaciones_de_enfoque.mp4',
  '["Sostén una mancuerna de manera vertical (estilo goblet) con ambas manos.", "Para enfatizar los cuádriceps, usa una postura al ancho de los hombros y desciende manteniendo el torso lo más vertical posible.", "Para enfatizar los glúteos, inclina ligeramente el torso hacia adelante durante el descenso para aumentar la flexión de la cadera.", "Para enfatizar la parte interna del muslo, separa las piernas más allá del ancho de los hombros (postura sumo) con las puntas de los pies orientadas hacia afuera antes de descender."]'::jsonb,
  'intermedio',
  'Sentadilla utilizando una mancuerna central con alteraciones en la postura y el ángulo del torso para desplazar el estímulo principal entre cuádriceps, glúteos y aductores.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Rutina de Core en Suelo (Crunches y Elevaciones de rodillas)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/rutina_de_core_en_suelo_crunches_y_elevaciones_de_rodillas.mp4',
  '["Acuéstate boca arriba sobre una esterilla con las manos detrás de la cabeza.", "Realiza flexiones laterales acercando el codo a la rodilla contraria alternadamente.", "Para la segunda variante, levanta las rodillas hacia el pecho manteniendo la zona lumbar firmemente presionada contra el suelo.", "Controla la respiración exhalando en la fase concéntrica y desciende de manera controlada."]'::jsonb,
  'principiante',
  'Secuencia de ejercicios de peso corporal enfocada en la activación del abdomen y los oblicuos, realizando flexiones laterales y encogimientos invertidos.',
  'resistencia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de Bíceps Sentado con Mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_sentado_con_mancuerna.mp4',
  '["Siéntate en un banco con la espalda recta y sujeta una mancuerna con agarre supino.", "Mantén el codo pegado al torso y alineado verticalmente; evita adelantarlo o balancearlo para no involucrar el deltoides anterior.", "Flexiona el codo para elevar la mancuerna contrayendo el bíceps en la parte superior.", "Desciende el peso de forma controlada hasta alcanzar la extensión casi completa del codo."]'::jsonb,
  'principiante',
  'Ejercicio de aislamiento para el bíceps braquial ejecutado en posición sentada para evitar el uso de inercia corporal. Se enfoca en mantener el codo fijo.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de Tríceps Tumbado (Rompecráneos)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/extension_de_triceps_tumbado_rompecraneos.mp4',
  '["Túmbate en un banco plano sosteniendo el peso sobre tu pecho con los brazos casi totalmente extendidos.", "Flexiona los codos para llevar el peso hacia tu frente o ligeramente por encima de la cabeza.", "Mantén los codos paralelos y apuntando hacia arriba; no permitas que se abran hacia los lados.", "Extiende los codos para volver a la posición inicial, apretando el tríceps al máximo en la parte alta."]'::jsonb,
  'intermedio',
  'Movimiento de extensión de codo tumbado que aísla las cabezas del tríceps. El análisis biomecánico se centra en el ángulo correcto del hombro para evitar estrés articular excesivo.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl Invertido con Barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_invertido_con_barra.mp4',
  '["Ponte de pie sosteniendo una barra con un agarre prono a la anchura de los hombros.", "Mantén los codos firmemente pegados a los costados y asegúrate de mantener las muñecas en posición neutra (rectas).", "Flexiona los codos para elevar la barra hacia la parte superior del pecho.", "Baja la barra de manera controlada, asegurándote de no quebrar las muñecas durante la fase excéntrica."]'::jsonb,
  'intermedio',
  'Variación del curl utilizando un agarre prono (palmas hacia abajo) para enfatizar el desarrollo de los músculos del antebrazo y la región braquial.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de Brazo a Una Mano (One-Arm Pushup)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/flexion_de_brazo_a_una_mano_one_arm_pushup.mp4',
  '["Colócate en posición de plancha y separa los pies más allá del ancho de los hombros para crear una amplia base de sustentación.", "Apoya una sola mano en el suelo alineada con el centro de tu pecho, rotándola ligeramente hacia afuera (aprox. 45 grados).", "Desciende de forma controlada flexionando el codo cerca del torso y evitando que la cadera colapse o rote.", "Empuja el suelo explosivamente para regresar a la posición de inicio, manteniendo la columna neutra."]'::jsonb,
  'avanzado',
  'Ejercicio avanzado de calistenia que exige alta tensión en toda la cadena cinética, desarrollando fuerza unilateral en el complejo articular del hombro y gran estabilidad en el core.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de Banca con Barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_banca_con_barra.mp4',
  '["Acuéstate sobre un banco plano con los pies anclados al suelo, retrayendo las escápulas y manteniendo un ligero arco lumbar.", "Sujeta la barra con un agarre ligeramente más ancho que los hombros y sácala de los soportes.", "Baja la barra hacia la parte inferior del esternón, manteniendo los codos en un ángulo de aproximadamente 45 a 60 grados respecto al torso.", "Empuja la barra de regreso hacia la posición inicial, describiendo una ligera curva hacia la línea de los hombros."]'::jsonb,
  'intermedio',
  'Movimiento compuesto de empuje horizontal fundamental. El video destaca la alineación correcta del codo y la trayectoria de la barra para optimizar el trabajo pectoral y reducir el pinzamiento subacromial.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Circuito de Tren Superior con Peso Libre',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/circuito_de_tren_superior_con_peso_libre.mp4',
  '["Curl Martillo: Realiza flexión de codos con agarre neutro para trabajar el braquiorradial.", "Pullover: Tumbado, lleva la mancuerna desde el pecho por encima de la cabeza y regresa, enfocándote en la expansión torácica y el dorsal.", "Patada de tríceps: Con el torso flexionado hacia adelante, extiende los codos hacia atrás de forma estricta.", "Elevaciones laterales: Abduce los brazos lateralmente hasta los 90 grados para estimular la porción medial del deltoides.", "Remo con barra: Con el torso a 45 grados y espalda recta, retrae las escápulas tirando de la barra hacia el abdomen."]'::jsonb,
  'intermedio',
  'Rutina metabólica y de hipertrofia compuesta por ejercicios multiplanares (Curl martillo, Pullover, Patada de tríceps, Elevaciones laterales y Remo) para un estímulo completo del tren superior.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de Hombros en Máquina Smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_hombros_en_maquina_smith.mp4',
  '["Siéntate en un banco con respaldo a unos 75-85 grados debajo de la barra de la máquina Smith.", "Sujeta la barra y asegúrate de que los antebrazos queden perfectamente verticales a lo largo del recorrido.", "No abras los codos a 90 grados; mételos levemente hacia adelante en el plano escapular.", "Desciende la barra controladamente hasta la altura de la barbilla o clavículas, y empuja hacia arriba sin hiper-extender los codos."]'::jsonb,
  'principiante',
  'Ejercicio de empuje vertical guiado. La instrucción biomecánica subraya la importancia de operar en el plano escapular (codos ligeramente adelantados) para salvaguardar la salud articular del hombro.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de Piernas (Variaciones de Posición de Pies)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/prensa_de_piernas_variaciones_de_posicion_de_pies.mp4',
  '["Acomódate en la máquina de prensa apoyando completamente la espalda y la zona lumbar en el respaldo.", "Para enfatizar los aductores, coloca los pies separados (postura sumo) en la zona media-alta de la plataforma.", "Para aislar el vasto lateral y el trabajo general del cuádriceps, coloca los pies más juntos en la parte baja o media.", "Para priorizar la cadena posterior (glúteos e isquiotibiales), apoya los pies en la parte superior de la plataforma.", "Desbloquea el seguro y desciende controladamente hasta que las rodillas formen un ángulo de 90 grados; empuja de regreso sin llegar a bloquear completamente las rodillas."]'::jsonb,
  'intermedio',
  'Ejercicio compuesto de empuje del tren inferior. El enfoque biomecánico ilustra cómo la modificación en la colocación de los pies en la plataforma altera el reclutamiento muscular entre cuádriceps, glúteos, isquiotibiales y aductores.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo Sentado en Polea (Variaciones de Agarre)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_sentado_en_polea_variaciones_de_agarre.mp4',
  '["Siéntate en el banco de la polea baja, apoya los pies en las plataformas y mantén las rodillas ligeramente flexionadas.", "Selecciona tu agarre: el maneral en V cerrado enfocará el estiramiento y contracción en el dorsal ancho.", "Un agarre más ancho y prono reclutará en mayor medida los romboides, deltoides posteriores y la porción media/inferior del trapecio.", "Mantén el torso erguido (evita el balanceo excesivo) y tira del agarre hacia tu abdomen o esternón, retrayendo las escápulas al máximo.", "Extiende los brazos de forma controlada durante la fase excéntrica, permitiendo que las escápulas se prolonguen hacia adelante."]'::jsonb,
  'intermedio',
  'Movimiento de tracción horizontal orientado al desarrollo del grosor de la espalda. Demuestra cómo alternar entre agarres (cerrado en V, neutro ancho y prono ancho) transfiere la tensión desde el dorsal ancho hacia la musculatura de la espalda alta.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Jalón al Pecho en Polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/jalon_al_pecho_en_polea_alta.mp4',
  '["Ajusta los rodillos de la máquina para que tus muslos queden firmemente anclados y siéntate frente a la polea.", "Sujeta la barra superior con un agarre prono, ligeramente más ancho que la anchura de los hombros.", "Tira de la barra hacia la parte superior del pecho (clavícula/esternón alto), sacando el pecho e inclinando el torso solo unos grados hacia atrás.", "Concéntrate en traccionar empujando los codos hacia abajo y ligeramente hacia el frente (plano escapular), evitando que se desplacen detrás de tu espalda.", "Controla el ascenso del peso hasta lograr una extensión completa y un estiramiento profundo del dorsal."]'::jsonb,
  'principiante',
  'Ejercicio de tracción vertical enfocado en la amplitud dorsal. El análisis corrige el error común de llevar los codos excesivamente hacia atrás o inclinar demasiado el torso, enfatizando el trabajo en el plano escapular.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla en Máquina Smith con Pies Adelantados',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_en_maquina_smith_con_pies_adelantados.mp4',
  '["Coloca la barra de la máquina Smith sobre la parte posterior de tus hombros (trapecios) y sujétala con ambas manos.", "Da un pequeño paso hacia adelante, de manera que tus pies queden ligeramente por delante de la línea vertical de la barra. Esta es la clave del ejercicio.", "Desciende de forma controlada flexionando las rodillas y caderas como si fueras a sentarte en una silla.", "Asegúrate de que tus rodillas sigan la línea de tus pies y mantén el torso lo más erguido posible.", "Empuja a través de los talones para volver a la posición inicial, contrayendo fuertemente los glúteos en la parte superior del movimiento."]'::jsonb,
  'intermedio',
  'Variación de la sentadilla donde los pies se posicionan ligeramente más adelantados para minimizar el riesgo de lesiones y lograr un enfoque de mayor aislamiento en los glúteos e isquiotibiales.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla Sissy (Asistida)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_sissy_asistida.mp4',
  '["Colócate de pie, separando las piernas al ancho de los hombros, y sujétate de un soporte firme con una o ambas manos para mantener el equilibrio.", "Mantén el torso y los muslos alineados en una línea recta contrayendo fuertemente los glúteos y el core.", "Desciende flexionando las rodillas hacia adelante mientras tus talones se elevan del suelo y tu cuerpo se inclina hacia atrás.", "Baja hasta que sientas un estiramiento profundo en los cuádriceps o hasta tu límite de movilidad.", "Empuja a través de la punta de los pies, extendiendo las rodillas para regresar a la posición inicial."]'::jsonb,
  'avanzado',
  'Ejercicio de aislamiento para los cuádriceps que implica una flexión profunda de rodillas mientras el torso se inclina hacia atrás, minimizando la implicación de la cadera.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press Militar con Barra (Agarre Supino / Underhand)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_militar_con_barra_agarre_supino_underhand.mp4',
  '["Siéntate en un banco con respaldo o permanece de pie, manteniendo una postura firme.", "Sujeta la barra con un agarre supino (palmas hacia ti), con las manos separadas a la anchura de los hombros.", "Inicia el movimiento con la barra apoyada en la parte superior del pecho/clavícula, con los codos apuntando hacia adelante.", "Empuja la barra hacia arriba hasta la extensión completa de los brazos, manteniendo la columna estable.", "Desciende de forma controlada hasta la posición inicial."]'::jsonb,
  'intermedio',
  'Variación del press de hombros utilizando un agarre supino (las palmas mirando hacia ti). Esta modificación biomecánica reduce la abducción del hombro, forzando a los codos a moverse en un plano más sagital (hacia adelante), lo que transfiere una gran parte del trabajo desde el deltoides lateral hacia el deltoides anterior y la porción clavicular del pectoral.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Estiramiento Dinámico Lumbar (Rodillas al Pecho Alternadas)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/estiramiento_dinamico_lumbar_rodillas_al_pecho_alternadas.mp4',
  '["Acuéstate boca arriba (decúbito supino) sobre una superficie cómoda, con las piernas extendidas.", "Flexiona una rodilla y llévala hacia tu pecho, sujetándola con ambas manos por debajo de la rótula (sobre la espinilla).", "Tira suavemente de la rodilla para aumentar el estiramiento en la zona lumbar y el glúteo de ese lado.", "Mantén la pierna contraria lo más extendida y pegada al suelo posible para estirar también el flexor de la cadera opuesta.", "Alterna el movimiento con la otra pierna de manera controlada."]'::jsonb,
  'principiante',
  'Movimiento de movilidad y estiramiento activo en posición supina. Se enfoca en liberar la tensión de la zona lumbar, estirar los glúteos de forma unilateral y promover la movilidad de la articulación de la cadera.',
  'movilidad'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press Militar con Barra Tras Nuca',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_militar_con_barra_tras_nuca.mp4',
  '["Siéntate en un banco (preferiblemente con soporte corto o sin respaldo para no estorbar la barra) o ponte de pie.", "Sujeta la barra con un agarre prono, ligeramente más ancho que los hombros.", "Saca la barra del soporte y posiciónala detrás de tu cabeza, a la altura de la base del cuello/parte superior de los trapecios.", "Empuja la barra directamente hacia arriba hasta extender los brazos.", "Desciende la barra lenta y controladamente detrás de la cabeza, pero NUNCA bajes más allá de la mitad de la oreja o la base del cráneo para evitar pinzamientos severos."]'::jsonb,
  'avanzado',
  'Ejercicio de empuje vertical muy controvertido por su exigencia articular. Al bajar la barra por detrás del cuello, se requiere una extrema rotación externa y abducción del hombro, lo que pone bajo gran estrés al manguito rotador y al ligamento glenohumeral. Aunque estimula los deltoides (especialmente el medio y posterior) y trapecios, el riesgo de lesión es significativamente mayor comparado con el press frontal.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión de Brazo (Push-up) - Técnica y Corrección',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/flexion_de_brazo_push_up_tecnica_y_correccion.mp4',
  '["Colócate en posición de plancha alta, con las manos apoyadas en el suelo a una anchura ligeramente mayor que la de los hombros.", "Apunta los dedos índices hacia adelante o ligeramente hacia afuera, evitando que se cierren hacia adentro.", "Mantén el core contraído y el cuerpo en línea recta desde la cabeza hasta los talones.", "Desciende flexionando los codos, asegurándote de que estos apunten hacia atrás y hacia los lados en un ángulo de unos 45 grados respecto a tu torso.", "Empuja el suelo para volver a la posición inicial, manteniendo la tensión en el pecho y tríceps."]'::jsonb,
  'principiante',
  'El video detalla la técnica óptima para la flexión de brazos tradicional. Subraya el error común de realizar el movimiento con las manos rotadas hacia adentro y los codos abiertos a 90 grados (en forma de ''T''), lo que aumenta el estrés en los hombros. La forma correcta requiere rotar las manos ligeramente hacia afuera y mantener los codos en un ángulo de aproximadamente 45 grados respecto al torso (forma de flecha).',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de hombros con mancuernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/press_de_hombros_con_mancuernas.mp4',
  '["Siéntate en un banco con respaldo y sostén una mancuerna en cada mano a la altura de los hombros.", "Alinea los codos ligeramente hacia adelante (aprox. 30 grados en el plano escapular), evitando abrirlos completamente a 180 grados.", "Empuja las mancuernas hacia arriba de forma controlada hasta que los brazos estén extendidos.", "Desciende lentamente hasta la posición inicial."]'::jsonb,
  'intermedio',
  'Ejercicio compuesto enfocado en el desarrollo de la musculatura de los hombros, realizado sentado con mancuernas. Se enfatiza la alineación correcta de los codos en el plano escapular para evitar lesiones.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Circuito de movilidad y corrección postural',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/circuito_de_movilidad_y_correccion_postural.mp4',
  '["Realiza pasadas de hombro con un palo o banda (dislocaciones) de adelante hacia atrás para abrir la caja torácica.", "Apoya la espalda plana contra la pared y desliza los brazos hacia arriba y abajo formando una ''W'' (ángeles de pared).", "Adopta una posición de zancada con la rodilla apoyada, contrae el abdomen y el glúteo, y avanza ligeramente para estirar el flexor de la cadera.", "Acuéstate boca arriba y eleva la cadera contrayendo los glúteos (puente de glúteos tradicional y a una pierna)."]'::jsonb,
  'principiante',
  'Rutina de 5 minutos diseñada para mejorar la postura corporal general. Combina dislocaciones de hombros, ángeles en la pared, estiramientos de flexores y activación de la cadena posterior.',
  'movilidad'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo sentado en polea',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_sentado_en_polea.mp4',
  '["Siéntate en la máquina de remo con las rodillas ligeramente flexionadas y el torso erguido.", "Selecciona el agarre: utiliza un agarre estrecho en V para enfocar el dorsal ancho, una barra recta con agarre prono ancho para enfatizar la espalda alta (romboides y deltoides posteriores), o un agarre supino.", "Tira del agarre hacia el abdomen o la parte inferior del pecho, retrayendo las escápulas activamente.", "Regresa el peso estirando los brazos sin perder la tensión ni encorvar la zona lumbar."]'::jsonb,
  'intermedio',
  'Ejercicio de tracción horizontal en máquina de poleas. El video explica de manera biomecánica cómo la selección del tipo de agarre redirige el estímulo hacia distintos grupos musculares de la espalda.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/curl_de_biceps_con_barra.mp4',
  '["Sujeta una barra con agarre supino (palmas hacia arriba) a la anchura de los hombros.", "Mantén el torso recto, el abdomen contraído y fija los codos a los costados del cuerpo.", "Flexiona los codos levantando el peso hacia los hombros, concentrando la contracción en los bíceps.", "Baja la barra de forma controlada hasta la extensión completa de los brazos sin permitir que los codos se desplacen hacia el frente."]'::jsonb,
  'principiante',
  'Ejercicio clásico de aislamiento para los flexores del codo. Se corrige el error común de mover los codos hacia adelante o encoger los hombros durante la fase concéntrica.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Variaciones de posición de pies en máquinas de pierna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/variaciones_de_posicion_de_pies_en_maquinas_de_pierna.mp4',
  '["Para enfatizar los glúteos y los isquiotibiales: coloca los pies más adelantados en la Máquina Smith, o en la posición superior de la plataforma en la Prensa de piernas.", "Para enfatizar los cuádriceps: posiciona los pies directamente bajo tu centro de gravedad en la Smith, o en la parte inferior de la plataforma en la Prensa.", "Para activar los aductores (parte interna del muslo): adopta una postura ancha (sumo) con las puntas de los pies rotadas hacia afuera.", "Realiza el patrón de sentadilla o empuje asegurando rango de movimiento y control excéntrico."]'::jsonb,
  'intermedio',
  'Guía biomecánica que demuestra cómo alterar la posición de los pies en la Máquina Smith y la Prensa de piernas transfiere el esfuerzo principal entre los cuádriceps, glúteos e isquiotibiales, o aductores.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/sentadilla_con_barra_sentadilla_trasera.mp4',
  '["Coloca la barra sobre la porción carnosa de los trapecios o deltoides posteriores, asegurándote de no apoyarla directamente sobre las vértebras cervicales.", "Separa los pies a una anchura cómoda (generalmente la de los hombros) con ligera rotación externa de las puntas.", "Inicia el descenso flexionando las rodillas y las caderas simultáneamente, manteniendo la columna neutra y evitando redondear la zona lumbar (butt wink) en la parte profunda.", "Empuja con toda la planta del pie de manera uniforme para ascender a la posición inicial."]'::jsonb,
  'avanzado',
  'Ejercicio multiarticular central para el tren inferior. Se analiza la ejecución segura destacando la colocación correcta de la barra, la alineación neutra de la columna y la trayectoria vertical.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Variaciones de Curl de bíceps en banco inclinado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/variaciones_de_curl_de_biceps_en_banco_inclinado.mp4',
  '["Variante Spider Curl (énfasis en acortamiento): Apoya el pecho boca abajo en el banco inclinado, dejando colgar los brazos perpendicularmente al suelo, y flexiona los codos sin mover los hombros.", "Variante Curl Inclinado Supino (énfasis en estiramiento): Siéntate boca arriba en el banco ajustado a 45-60 grados, dejando que los brazos cuelguen por detrás de la línea del torso.", "Levanta las mancuernas flexionando los codos mediante la contracción del bíceps.", "Baja el peso de forma lenta controlando la fase excéntrica."]'::jsonb,
  'intermedio',
  'Ejercicios para maximizar la tensión en diferentes puntos del rango de movimiento del bíceps usando un banco inclinado, incluyendo la variante de Spider Curl y el Curl inclinado estándar.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexiones de brazos',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/flexiones_de_brazos_en_suelo.mp4',
  '["Colócate en posición de plancha alta con las manos un poco más abiertas que la anchura de los hombros.", "Activa el core y aprieta los glúteos para mantener el cuerpo en una línea completamente recta.", "Desciende flexionando los codos. Asegúrate de que formen un ángulo de unos 45 grados respecto al torso, no a 90 grados (evita la forma de ''T'').", "Empuja el suelo con fuerza para regresar a la posición inicial bloqueando los codos."]'::jsonb,
  'principiante',
  'Movimiento base de calistenia para la cadena de empuje. Enfatiza la trayectoria articular correcta de los codos hacia atrás en ángulo (forma de flecha) para maximizar el empuje del pectoral y proteger la articulación del hombro.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevaciones de deltoides con mancuernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/elevaciones_de_deltoides_con_mancuernas.mp4',
  '["Siéntate en el borde de un banco con una mancuerna en cada mano, manteniendo el torso erguido.", "Para el deltoides anterior: eleva las mancuernas hacia adelante manteniendo una ligera flexión en los codos.", "Para el deltoides medio: eleva las mancuernas lateralmente hasta la altura de los hombros, controlando la bajada.", "Para el deltoides posterior (pájaros): inclina el torso hacia adelante, apoyando el pecho cerca de las rodillas, y realiza las elevaciones hacia atrás y arriba."]'::jsonb,
  'intermedio',
  'Variaciones de elevaciones con mancuernas en posición sentada para estimular y aislar específicamente las tres porciones del hombro (anterior, media y posterior).',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Circuito integral de core y abdomen',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/circuito_integral_de_core_y_abdomen.mp4',
  '["Abdomen total: Realiza encogimientos sentados (seated crunches), apoyando las manos atrás y llevando las rodillas al pecho.", "Abdomen superior: Acuéstate boca arriba y realiza abdominales de elevación completa con las piernas rectas (straight leg sit-up).", "Abdomen inferior: Con la espalda baja presionada contra el suelo, ejecuta elevaciones de piernas juntas (leg raises) y aleteos (flutter kicks).", "Core: En posición de plancha invertida o cuadrupedia (bear hold), realiza patadas hacia atrás (kickbacks) seguidas de escaladores (mountain climbers)."]'::jsonb,
  'principiante',
  'Rutina de calistenia sin equipo enfocada en fortalecer todas las regiones de la pared abdominal (superior, inferior y oblicuos) y el core general.',
  'resistencia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Peso muerto con barra (Rumano vs. Piernas Rígidas)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/peso_muerto_con_barra_rumano_vs_piernas_rigidas.mp4',
  '["Para el Peso Muerto Rumano (énfasis en glúteos): Mantén una flexión de rodilla más pronunciada (entre 15 y 20 grados) mientras empujas las caderas hacia atrás al descender.", "Para el Peso Muerto con Piernas Rígidas (énfasis en isquiotibiales): Mantén las piernas casi completamente extendidas (solo una microflexión) para maximizar el estiramiento en la parte posterior del muslo.", "En ambos casos, sujeta la barra al ancho de los hombros y bájala pegada a los muslos, asegurando que la columna vertebral permanezca completamente neutra.", "Revierte el movimiento contrayendo la cadena posterior hasta extender la cadera por completo, sin hiperextender la zona lumbar en la parte alta."]'::jsonb,
  'intermedio',
  'Análisis biomecánico del peso muerto que demuestra cómo modificar el grado de flexión de las rodillas para transferir el estímulo principal entre los glúteos y los isquiotibiales.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Rutina de estiramiento correctivo (5 minutos)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/rutina_de_estiramiento_correctivo_5_minutos.mp4',
  '["Realiza ejercicios de movilidad torácica con banda o palo (dislocaciones de hombro) para abrir la caja torácica.", "Ejecuta ángeles en la pared para fortalecer la musculatura estabilizadora de la escápula.", "Realiza estiramientos de los flexores de la cadera en posición de zancada (rodilla apoyada).", "Completa con variantes de puente de glúteo para activar la cadena posterior."]'::jsonb,
  'principiante',
  'Circuito de movilidad diseñado para compensar la postura cifótica resultante de largas jornadas de trabajo sedentario, promoviendo la extensión torácica y la apertura del complejo articular del hombro.',
  'movilidad'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Variaciones biomecánicas en Remo sentado',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/variaciones_biomecanicas_en_remo_sentado.mp4',
  '["Utiliza un agarre estrecho (V-bar) para un mayor énfasis en el dorsal ancho mediante un rango de movimiento más profundo.", "Emplea una barra recta (agarre prono) para activar con mayor intensidad la musculatura de la espalda alta (romboides, deltoides posterior).", "Mantén el torso erguido y retrasa las escápulas al traccionar.", "Controla la fase excéntrica evitando que los hombros se proyecten hacia adelante."]'::jsonb,
  'intermedio',
  'Guía sobre cómo la elección del implemento (mango) en el remo sentado altera la activación muscular de la espalda, priorizando diferentes fascículos del dorsal ancho y la musculatura escapular.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps: optimización de la ejecución',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_optimizacion_de_la_ejecucion.mp4',
  '["Sujeta una barra (EZ o recta) con agarre supino.", "Mantén los codos fijos a ambos lados del torso durante todo el movimiento.", "Flexiona los codos concentrando el esfuerzo en los bíceps.", "Evita el uso de inercia o balanceo del cuerpo para elevar la carga."]'::jsonb,
  'principiante',
  'Ejercicio de aislamiento para los flexores del codo que corrige errores técnicos comunes, como el balanceo del tronco o la protracción escapular, para garantizar el máximo estrés mecánico en el bíceps.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Variaciones técnicas en sentadilla con Smith Machine',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/variaciones_tecnicas_en_sentadilla_con_smith_machine.mp4',
  '["Pies adelantados: aumenta la flexión de cadera, enfatizando el trabajo en glúteos e isquiotibiales.", "Pies alineados con el centro de gravedad: aumenta la flexión de rodilla, priorizando el trabajo en cuádriceps.", "Postura abierta con rotación externa: incrementa la activación de los aductores (parte interna del muslo).", "Mantén la columna en posición neutra durante todo el rango de movimiento."]'::jsonb,
  'intermedio',
  'Demostración de cómo la manipulación de la posición de los pies en relación al centro de gravedad durante una sentadilla en Máquina Smith permite dirigir el estímulo hacia diferentes grupos musculares del tren inferior.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla con barra (Back Squat): técnica correcta',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/sentadilla_con_barra_back_squat_tecnica_correcta.mp4',
  '["Apoya la barra sobre los trapecios (no sobre las vértebras cervicales).", "Inicia el descenso flexionando rodillas y caderas, manteniendo la espalda recta.", "Desciende hasta que los muslos estén paralelos al suelo (o según la capacidad de movilidad).", "Regresa a la posición de inicio empujando desde toda la planta del pie."]'::jsonb,
  'avanzado',
  'Movimiento fundamental multiarticular. El análisis se centra en la correcta colocación de la barra (high bar), la profundidad necesaria para la activación de la cadena posterior y el mantenimiento de la integridad espinal.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Variaciones en Prensa de piernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/variaciones_en_prensa_de_piernas.mp4',
  '["Colocación alta en la plataforma: reduce la flexión de rodilla y aumenta la de cadera, favoreciendo el trabajo de glúteos e isquiotibiales.", "Colocación baja en la plataforma: aumenta la flexión de rodilla, enfatizando el trabajo en cuádriceps.", "Controla el descenso de la plataforma sin que la zona lumbar se despegue del respaldo.", "Empuja la plataforma sin bloquear completamente las rodillas en la parte superior."]'::jsonb,
  'intermedio',
  'Análisis sobre la importancia del posicionamiento del pie en la plataforma de la prensa de piernas para modular la implicación de cuádriceps versus glúteos e isquiotibiales.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Circuito de ejercicios abdominales',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/circuito_de_ejercicios_abdominales.mp4',
  '["Realiza encogimientos sentados para trabajar la musculatura global del abdomen.", "Ejecuta abdominales de elevación completa (sit-ups) con piernas estiradas para el abdomen superior.", "Realiza elevaciones de piernas y aleteos (flutter kicks) para enfocar el abdomen inferior.", "Incorpora escaladores (mountain climbers) para desafiar el core y la estabilidad."]'::jsonb,
  'principiante',
  'Rutina de ejercicios de calistenia diseñada para trabajar de forma integral la musculatura abdominal (superior, inferior y core) sin necesidad de equipamiento.',
  'resistencia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Variaciones en Elevaciones laterales con mancuernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/variaciones_en_elevaciones_laterales_con_mancuernas.mp4',
  '["Elevaciones frontales: brazos al frente para el deltoides anterior.", "Elevaciones laterales sentado: apertura lateral para el deltoides medio.", "Elevaciones sentado inclinado (pájaros): torso inclinado hacia adelante para el deltoides posterior.", "Controla el movimiento en ambas fases y evita el uso de impulso."]'::jsonb,
  'intermedio',
  'Ejercicios de aislamiento para los hombros. El video detalla cómo variar la posición del tronco o la dirección de la fuerza para estimular selectivamente las diferentes cabezas del deltoides.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Variaciones de Peso Muerto: Rumano vs. Piernas Rígidas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/variaciones_de_peso_muerto_rumano_vs_piernas_rigidas.mp4',
  '["Peso muerto rumano: mantén rodillas ligeramente flexionadas (15-20 grados) para enfatizar el trabajo en glúteos.", "Peso muerto piernas rígidas: mantén rodillas casi bloqueadas (microflexión) para maximizar el estiramiento en isquiotibiales.", "Mantén la barra siempre pegada a las piernas durante el movimiento.", "Garantiza que la columna se mantenga en posición neutra durante todo el ejercicio."]'::jsonb,
  'intermedio',
  'Análisis técnico de las variantes del peso muerto para la cadena posterior. Se enseña cómo la rodilla determina la carga entre glúteos e isquiotibiales.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Zancadas con mancuernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/zancadas_con_mancuernas.mp4',
  '["Ponte de pie sujetando una mancuerna en cada mano con los brazos relajados a los costados.", "Da un paso hacia adelante con una pierna, manteniendo el torso erguido o con una ligera inclinación natural hacia adelante.", "Flexiona ambas rodillas para descender las caderas de forma vertical, hasta que la rodilla trasera casi toque el suelo.", "Asegúrate de que la rodilla delantera esté estable y empuja firmemente con ese pie para regresar a la posición inicial."]'::jsonb,
  'intermedio',
  'Ejercicio unilateral de tren inferior enfocado en el desarrollo de los cuádriceps y glúteos. Se enfatiza el descenso controlado y el mantenimiento de la estabilidad para proteger la articulación de la rodilla y maximizar el estímulo.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Circuito de descompresión y movilidad espinal',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/circuito_de_descompresion_y_movilidad_espinal.mp4',
  '["Para la espalda alta: Siéntate en un banco, levanta un brazo, gira la palma, colócala sobre la rodilla opuesta y reclínate hacia atrás para estirar.", "Para la zona lumbar: Colócate en posición de cuadrupedia, abre ligeramente una rodilla y pasa el brazo contrario por debajo de tu cuerpo rotando la columna.", "Para descomprimir: Arrodíllate frente a un banco, apoya los codos apuntando hacia arriba, empuja las caderas hacia atrás y hunde el pecho para estirar hombros y dorsales."]'::jsonb,
  'principiante',
  'Rutina de tres pasos para aliviar la tensión en la espalda alta y baja. Incluye rotaciones torácicas y lumbares, y estiramientos pasivos de flexión de hombro para descomprimir la columna vertebral.',
  'movilidad'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión torácica pasiva',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/extension_toracica_pasiva.mp4',
  '["Coloca una almohada o cojín en el suelo o sobre tu cama.", "Acuéstate boca arriba de manera que la almohada soporte la transición entre tu zona lumbar y la espalda alta.", "Junta las plantas de los pies y deja caer las rodillas hacia los lados (posición de mariposa).", "Extiende los brazos estirados por encima de la cabeza y respira profundamente, manteniendo la posición de 5 a 10 minutos."]'::jsonb,
  'principiante',
  'Estiramiento pasivo de relajación ideal para revertir la postura encorvada derivada del trabajo de oficina. Ayuda a descomprimir la columna, aliviar la tensión y abrir la caja torácica.',
  'movilidad'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo inclinado en polea baja',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/remo_inclinado_en_polea_baja.mp4',
  '["Ponte de pie frente a una máquina de polea baja y sujeta una barra recta con ambas manos.", "Flexiona ligeramente las rodillas e inclina el torso hacia adelante desde las caderas, manteniendo la espalda completamente recta y el core activado.", "Tira de la barra hacia tu abdomen llevando los codos hacia atrás y retrayendo las escápulas.", "Extiende los brazos de forma controlada hasta la posición inicial sin dejar que la columna se encorve o los hombros colapsen."]'::jsonb,
  'intermedio',
  'Ejercicio de tracción horizontal realizado de pie con una polea baja. Se corrige la postura para evitar el encorvamiento de la zona lumbar, manteniendo la columna neutra para maximizar el trabajo en la espalda.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de bíceps con mancuernas (Alterno vs Simultáneo)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/curl_de_biceps_con_mancuernas_alterno_vs_simultaneo.mp4',
  '["Sujeta un par de mancuernas con los brazos extendidos.", "Para la versión alterna, flexiona un codo a la vez, supinando la muñeca (palma hacia arriba) durante el movimiento, y luego repite con el otro brazo.", "Para la versión simultánea, flexiona ambos codos a la vez.", "Mantén la parte superior de los brazos firme contra los costados y el torso estable durante todo el ejercicio."]'::jsonb,
  'principiante',
  'Variantes del curl de bíceps con mancuernas, demostrando cómo la ejecución unilateral o simultánea impacta en el reclutamiento de los estabilizadores del core y el esfuerzo general.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Parada de antebrazos (Forearm Stand)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/parada_de_antebrazos_forearm_stand.mp4',
  '["Colócate en posición de plancha sobre los antebrazos, asegurando que los codos estén alineados directamente debajo de los hombros y las palmas apoyadas en el suelo.", "Mantén la cabeza neutra, mirando hacia el espacio entre tus manos, no hacia tus pies.", "Camina con los pies hacia tus codos para elevar las caderas (posición de delfín o V invertida).", "Eleva una pierna y usa la otra para impulsarte suavemente, buscando el punto de equilibrio vertical."]'::jsonb,
  'avanzado',
  'Progresión de calistenia y gimnasia para lograr el equilibrio invertido sobre los antebrazos. Enfatiza la alineación de la cabeza, los codos y el uso de los pies para el impulso inicial.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Tracción facial con cuerda (Face Pull)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/traccion_facial_con_cuerda_face_pull.mp4',
  '["Ajusta la polea a la altura del pecho o ligeramente por encima.", "Sujeta la cuerda con un agarre prono (palmas hacia abajo o enfrentadas).", "Tira de la cuerda hacia tu rostro (nivel de los ojos o frente) separando las manos y llevando los codos hacia atrás y arriba.", "Asegúrate de rotar externamente los hombros en la parte final del movimiento, sintiendo la contracción en la parte posterior de los hombros."]'::jsonb,
  'intermedio',
  'Ejercicio esencial para la salud de los hombros y la postura. Corrige la tendencia a jalar con los bíceps (como un remo), enseñando la rotación externa adecuada para activar los deltoides posteriores y los rotadores externos.',
  'hipertrofia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Circuito de glúteos con banda de resistencia',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/demic/circuito_de_gluteos_con_banda_de_resistencia.mp4',
  '["Colócate en posición de cuadrupedia con una banda de resistencia por encima de las rodillas.", "Realiza abducciones de cadera (hidrantes) levantando una rodilla lateralmente.", "Ejecuta extensiones de cadera (patadas de burro) empujando el talón hacia el techo con la rodilla flexionada.", "Finaliza con abducciones de pierna extendida, elevando la pierna recta lateralmente y hacia arriba."]'::jsonb,
  'principiante',
  'Serie de ejercicios de aislamiento en cuadrupedia para activar y fortalecer los glúteos desde todos los ángulos utilizando una banda elástica para añadir resistencia.',
  'resistencia'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos en máquina Hack',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/elevacion_de_gemelos_en_maquina_hack.gif',
  '["Paso 1: Ajusta la máquina Hack cargando los discos adecuados según tu nivel.", "Paso 2: Colócate bajo las almohadillas apoyando únicamente el metatarso (la punta de los pies) en la base de la plataforma, dejando los talones suspendidos por fuera.", "Paso 3: Sujétate de los agarres de seguridad y libera el freno de la máquina.", "Paso 4: Realiza la fase concéntrica elevando los talones mediante una contracción máxima de los gemelos.", "Paso 5: Mantén la contracción isométrica durante un segundo en la parte más alta y desciende controladamente los talones hasta sentir un estiramiento profundo en el tríceps sural.", "Paso 6: Repite hasta completar el volumen de repeticiones pautado."]'::jsonb,
  'intermedio',
  'Ejercicio para gemelos. Zona: piernas (parte inferior). Equipo: máquina hack.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa de piernas a 45°',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/prensa_de_piernas_a_45.gif',
  '["Paso 1: Reclina el respaldo de la prensa de piernas a un ángulo donde tu cadera no se despegue del asiento en la fase más profunda.", "Paso 2: Siéntate apoyando firmemente la zona lumbar y coloca los pies en la plataforma superior separados a la anchura de los hombros (postura estándar).", "Paso 3: Desbloquea los seguros laterales de la plataforma.", "Paso 4: Ejecuta la fase excéntrica flexionando las rodillas de forma controlada hasta que formen un ángulo de 90 grados, o hasta donde tu movilidad de cadera lo permita sin curvar la espalda.", "Paso 5: Empuja con toda la planta del pie (priorizando el empuje desde los talones) para extender las piernas de vuelta a la posición inicial, evitando bloquear las rodillas por completo.", "Paso 6: Repite el patrón de movimiento asegurando una técnica estricta."]'::jsonb,
  'intermedio',
  'Ejercicio para glúteos. Zona: piernas (parte superior). Equipo: prensa de piernas.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación frontal con mancuernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/elevacion_frontal_con_mancuernas.gif',
  '["Paso 1: De pie, con los pies separados a la anchura de los hombros y el core activado, sujeta una mancuerna en cada mano con agarre prono descansando sobre los muslos.", "Paso 2: Manteniendo una levísima flexión en los codos, ejecuta una elevación frontal liderada por los hombros hasta que las mancuernas superen ligeramente la línea de la clavícula.", "Paso 3: Sostén la máxima contracción del deltoides anterior durante un segundo.", "Paso 4: Resiste el peso bajando las mancuernas de manera controlada y repite."]'::jsonb,
  'intermedio',
  'Ejercicio para deltoides. Zona: hombros. Equipo: mancuernas.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de muñeca inverso con mancuernas sobre banco',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/curl_de_muneca_inverso_con_mancuernas_sobre_banco.gif',
  '["Paso 1: Siéntate en un banco sosteniendo un par de mancuernas en agarre prono (palmas hacia el suelo).", "Paso 2: Apoya la longitud de los antebrazos sobre el banco o sobre tus propios muslos, dejando que las muñecas sobresalgan en el aire.", "Paso 3: Permite que el peso fuerce la flexión de la muñeca hacia abajo (estiramiento).", "Paso 4: Contrae los músculos extensores del antebrazo levantando los nudillos en dirección a ti.", "Paso 5: Haz una pausa arriba y desciende gradualmente."]'::jsonb,
  'intermedio',
  'Ejercicio para antebrazos. Zona: antebrazos. Equipo: mancuernas.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl martillo en banco Scott a una mano',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/curl_martillo_en_banco_scott_a_una_mano.gif',
  '["Paso 1: Ajusta la altura del asiento del banco Scott para que la axila repose cómodamente sobre el borde superior del cojín.", "Paso 2: Apoya firmemente el tríceps y el codo en la almohadilla inclinada, sosteniendo una mancuerna con agarre neutro (como un martillo).", "Paso 3: Flexiona el brazo aislando el músculo braquial y el bíceps, subiendo la mancuerna hacia el hombro frontal.", "Paso 4: Aprieta el músculo en la cima del recorrido y realiza la bajada lenta hasta estirar el brazo por completo sin que el codo pierda contacto con el acolchado."]'::jsonb,
  'intermedio',
  'Ejercicio para bíceps. Zona: brazos (parte superior). Equipo: mancuerna.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla Pistol con pesa rusa',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/sentadilla_pistol_con_pesa_rusa.gif',
  '["Paso 1: De pie, abraza una pesa rusa por los cuernos (agarre en copa) manteniéndola apretada contra el esternón para estabilizar el centro de gravedad.", "Paso 2: Levanta una pierna estirándola por completo hacia el frente, quedando en equilibrio sobre la pierna contraria.", "Paso 3: Flexiona la rodilla y cadera de la pierna de apoyo descendiendo en una sentadilla a una sola pierna lo más profundo que tu movilidad de tobillo te permita.", "Paso 4: Evita que el talón de la pierna activa se levante del suelo y utiliza toda la potencia de tus cuádriceps y glúteos para presionar y volver a levantarte.", "Paso 5: Alterna las piernas al finalizar las repeticiones pautadas."]'::jsonb,
  'intermedio',
  'Ejercicio para glúteos. Zona: piernas (parte superior). Equipo: pesa rusa.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Fondos imposibles',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/fondos_imposibles.gif',
  '["Paso 1: Posiciónate entre las barras paralelas sosteniendo el peso íntegro de tu cuerpo con los brazos estirados.", "Paso 2: Retrae las escápulas y cruza las piernas atrás para mayor compacidad del core.", "Paso 3: Mantén el torso lo más erguido y vertical posible (para maximizar la implicación de los tríceps sobre la del pecho) e inicia la bajada controlando la caída con la flexión de los codos hacia atrás.", "Paso 4: Detén el descenso cuando la porción superior del brazo quede en paralelo con el suelo.", "Paso 5: Empuja agresivamente contra las barras para bloquear los brazos arriba nuevamente."]'::jsonb,
  'intermedio',
  'Ejercicio para tríceps. Zona: brazos (parte superior). Equipo: peso corporal.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Flexión lateral con lastre sobre fitball',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/flexion_lateral_con_lastre_sobre_fitball.gif',
  '["Paso 1: Apoya el costado de la cadera contra la curvatura del fitball, afirmando los pies lateralmente contra el piso o una pared para generar tracción.", "Paso 2: Sostén un lastre (disco o mancuerna) abrazado al pecho o apoyado en la nuca.", "Paso 3: Deja caer tu torso lateralmente acompañando la curva de la pelota para estirar el abdomen oblicuo.", "Paso 4: Flexiona el tronco hacia arriba lateralmente utilizando la pared abdominal hasta alcanzar la contracción máxima y repite."]'::jsonb,
  'intermedio',
  'Ejercicio para abdomen. Zona: cintura. Equipo: lastre.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo al mentón a una mano con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/remo_al_menton_a_una_mano_con_mancuerna.gif',
  '["Paso 1: De pie, con postura neutra, deja colgando la mancuerna de manera relajada frente al muslo.", "Paso 2: Ejecuta la elevación vertical tirando primero desde el hombro y haciendo que el codo apunte siempre por encima de la línea de la muñeca (como si estuvieras tirando del arranque de una cortadora de césped verticalmente).", "Paso 3: Eleva la carga hasta el nivel de la barbilla sin encoger excesivamente los trapecios de forma compensatoria.", "Paso 4: Baja lentamente manteniendo el dominio de la carga en todo el recorrido."]'::jsonb,
  'intermedio',
  'Ejercicio para deltoides. Zona: hombros. Equipo: mancuerna.',
  'cardio'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de gemelos de pie con barra (Balanceo de tobillo)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/elevacion_de_gemelos_de_pie_con_barra_balanceo_de_tobillo.gif',
  '["Paso 1: Carga la barra sobre la porción carnosa de los trapecios (como en una sentadilla tradicional) estando de pie sobre una superficie firme.", "Paso 2: Ejecuta una elevación plantar (ponte de puntillas) reclutando con intensidad el músculo gastrocnemio.", "Paso 3: Sostén un instante la tensión pico arriba.", "Paso 4: En el retorno excéntrico, permite un ligero balanceo cediendo el peso de regreso sobre la planta del pie completa."]'::jsonb,
  'intermedio',
  'Ejercicio para gemelos. Zona: piernas (parte inferior). Equipo: barra.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Torsión de tronco tumbado con rodillas flexionadas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/torsion_de_tronco_tumbado_con_rodillas_flexionadas.gif',
  '["Paso 1: Tumbado en el suelo o colchoneta de espaldas, forma una T con tus brazos estabilizadores, y eleva los pies agrupando las rodillas dobladas hacia el ombligo.", "Paso 2: Deja oscilar pausadamente tus piernas fusionadas cayendo sobre un lateral hasta casi palpar el suelo (logrando estiramiento rotacional del oblicuo).", "Paso 3: Involucra tu musculatura del core y los oblícuos internos/externos para acarrear el peso del tren inferior de vuelta al centro del eje.", "Paso 4: Replícalo consecutivamente cediendo hacia la dirección anatómica contraria."]'::jsonb,
  'intermedio',
  'Ejercicio para glúteos. Zona: piernas (parte superior). Equipo: peso corporal.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Jalón frontal en máquina convergente',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/jalon_frontal_en_maquina_convergente.gif',
  '["Paso 1: Acomódate ajustando el tope acolchado a las rodillas para amarrar la estructura inferior y evitar que tu cuerpo se eleve.", "Paso 2: Alcanza los pivotes o empuñaduras de la máquina usando una asimetría abierta en el agarre prono.", "Paso 3: Impulsa el pecho hacia fuera y acciona el descenso bajando la resistencia no con las manos, sino intentando meter los codos hacia tus caderas.", "Paso 4: Junta los omóplatos poderosamente traccionando la carga hasta el pecho superior.", "Paso 5: Resiste pacientemente a la máquina mientras los cables/palancas ascienden y estiran las aletas dorsales."]'::jsonb,
  'intermedio',
  'Ejercicio para dorsales. Zona: espalda. Equipo: máquina convergente.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl de concentración de pie con mancuerna',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/curl_de_concentracion_de_pie_con_mancuerna.gif',
  '["Paso 1: Colócate semi-inclinado o de pie (con las piernas formando una base ancha), dejando pendular en vilo un brazo cargado con mancuerna, mientras usas el brazo adyacente amarrado al muslo de contrapeso.", "Paso 2: Fija con precisión robótica el ángulo de tu húmero activo manteniéndolo inmóvil como una columna al piso.", "Paso 3: Concentra toda la energía neural en accionar los picos del bíceps para enrollar el peso arriba sin alterar el eje central.", "Paso 4: Maximiza la retención sangüínea de la congestión y baja exhalando sin prisas."]'::jsonb,
  'intermedio',
  'Ejercicio para bíceps. Zona: brazos (parte superior). Equipo: mancuerna.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Prensa vertical en máquina Smith',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/prensa_vertical_en_maquina_smith.gif',
  '["Paso 1: Tumbado de espaldas bajo el pórtico de la máquina Smith, asienta las plantas de los pies sobre la barra transversal rotatoria.", "Paso 2: Destraba la traba de seguridad con la suela del calzado, asumiendo la carga perimetral en la flexión vertical.", "Paso 3: Impulsa perpendicularmente a 90 grados elevando la barra al techo con el vigor puro del cuádriceps y vastos femorales.", "Paso 4: Contén en la altitud sin que la rodilla cruja por exceso de bloqueo óseo y desciende asumiendo el lastre hacia tu ombligo."]'::jsonb,
  'intermedio',
  'Ejercicio para glúteos. Zona: piernas (parte superior). Equipo: máquina smith.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de rodillas colgado con impulso excéntrico',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/elevacion_de_rodillas_colgado_con_impulso_excentrico.gif',
  '["Paso 1: Suspéndete en cuelgue inactivo desde una barra para dominadas aguantando con tensión latente en la faja abdominal.", "Paso 2: Engrana y asciende con agresividad agrupando ambas rótulas unidas escalando hasta topar contra el pecho superior.", "Paso 3: Proyecta bruscamente y arroja como látigo las extremidades de forma reactiva al suelo, exigiendo el freno excéntrico máximo en la banda infraumbilical.", "Paso 4: Amortigua la violenta bajada aprovechando el vaivén elástico del estiramiento muscular consecuente para disparar la subida próxima."]'::jsonb,
  'intermedio',
  'Ejercicio para abdomen. Zona: cintura. Equipo: peso corporal.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Hiperextensión lumbar con lastre en fitball',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/hiperextension_lumbar_con_lastre_en_fitball.gif',
  '["Paso 1: Fija en balanza pélvica tu área púbica montada recostada cabalgando la bóveda de la pelota, bloqueando contra una tarima los tobillos posteriores para abolir desplazamientos indeseados.", "Paso 2: Emplaza adosado a la coronilla o pecho superior el peso elegido para lastrar (disco/mancuerna).", "Paso 3: Contrae con vigor sacro el canal lumbar para eregir el busto quebrado inferiormente transformándolo a ras horizontal estricto sin curvar o lesionar la zona hiperextendida.", "Paso 4: Aguanta a pulso la estática en la cumbre antes de hundir laxamente pero con protección el busto ciñéndose a la ronda del fitball."]'::jsonb,
  'intermedio',
  'Ejercicio para columna. Zona: espalda. Equipo: lastre.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Encogimientos abdominales en polea (Crunch en polea)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/encogimientos_abdominales_en_polea_crunch_en_polea.gif',
  '["Paso 1: Híncate genuflexionado u arrodillado con el lomo dirigido hacia las regletas de la estructura de poleas superiores.", "Paso 2: Pinza la soga accesoria entrelazándola próxima al cráneo sin jalar desde los brazos ni trapecios.", "Paso 3: Ejecuta un Crunch (encogimiento visceral) arrastrando por motor del transverso absólico toda la tensión de las planchas de plomo hacia hundir la cara a las cuencas de las rótulas.", "Paso 4: En este acortamiento del recto halla máxima dureza, mantén, y revierte dosificando lentamente re-expandiendo el tórax pero no el abdomen interno."]'::jsonb,
  'intermedio',
  'Ejercicio para abdomen. Zona: cintura. Equipo: polea.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Dominadas con agarre prono',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/dominadas_con_agarre_prono.mp4',
  '["Paso 1: Suspéndete de una barra de dominadas utilizando un agarre prono (palmas hacia adelante) ligeramente más ancho que la anchura de los hombros.", "Paso 2: Inicia el movimiento activando la escápula mediante una depresión y retracción escapular (junta y desciende los omóplatos).", "Paso 3: Realiza la fase concéntrica traccionando tu cuerpo hacia arriba, dirigiendo los codos hacia el suelo y ligeramente hacia atrás, hasta que la barbilla supere el nivel de la barra.", "Paso 4: Haz una pausa de un segundo logrando la máxima contracción del dorsal ancho y la musculatura de la espalda alta.", "Paso 5: Desciende de manera controlada (fase excéntrica) hasta la extensión completa de los brazos sin perder por completo la tensión en los hombros. Repite."]'::jsonb,
  'intermedio',
  'Ejercicio para dorsal ancho. Zona: espalda. Equipo: peso corporal.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Empuje de cadera con barra (Hip Thrust)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/empuje_de_cadera_con_barra_hip_thrust.mp4',
  '["Paso 1: Siéntate en el suelo apoyando la parte inferior de las escápulas (omóplatos) contra el borde de un banco plano. Coloca una barra con una almohadilla sobre el pliegue de tu cadera.", "Paso 2: Planta los pies firmemente en el suelo a una distancia que permita formar un ángulo de 90 grados en tus rodillas cuando la cadera esté completamente extendida.", "Paso 3: Mantén el mentón ligeramente pegado al pecho y la mirada hacia el frente para evitar la hiperextensión cervical y lumbar.", "Paso 4: Empuja a través de los talones y extiende las caderas verticalmente contrayendo fuertemente los glúteos en la parte superior.", "Paso 5: Realiza una retención isométrica de un segundo en el punto de máxima contracción y desciende la cadera controladamente. Repite."]'::jsonb,
  'intermedio',
  'Ejercicio para glúteos. Zona: piernas (parte superior). Equipo: barra.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Sentadilla dividida búlgara con mancuernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/sentadilla_dividida_bulgara_con_mancuernas.gif',
  '["Paso 1: Colócate de espaldas a un banco y apoya el empeine de un pie sobre él, mientras mantienes el pie contrario firme en el suelo, adelantado a una distancia prudente.", "Paso 2: Sujeta una mancuerna en cada mano, mantén el torso erguido y el core estable.", "Paso 3: Desciende controladamente flexionando la rodilla de la pierna delantera hasta que el muslo quede paralelo al suelo o la rodilla trasera casi roce la superficie.", "Paso 4: Para un mayor enfoque en el cuádriceps, mantén el torso recto. Si deseas mayor énfasis en el glúteo, inclina ligeramente el torso hacia adelante.", "Paso 5: Empuja verticalmente a través del pie delantero para retornar a la extensión inicial. Completa las repeticiones y cambia de pierna."]'::jsonb,
  'intermedio',
  'Ejercicio para cuádriceps. Zona: piernas (parte superior). Equipo: mancuernas.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl femoral tumbado en máquina',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/exercisedb/curl_femoral_tumbado_en_maquina.gif',
  '["Paso 1: Túmbate bocabajo en la máquina de curl femoral, asegurando que las rodillas queden alineadas con el eje de rotación de la máquina.", "Paso 2: Ajusta el rodillo para que descanse justo por encima de los talones (en la zona inferior de los gemelos).", "Paso 3: Sujétate de los manerales delanteros para anclar el torso al banco y evitar la elevación de la cadera.", "Paso 4: Flexiona las rodillas aplicando fuerza para llevar los talones hacia los glúteos de manera fluida y explosiva.", "Paso 5: Sostén la contracción durante un segundo en el tope del movimiento y posteriormente desciende el peso de manera excéntrica lenta y controlada. Repite."]'::jsonb,
  'intermedio',
  'Ejercicio para isquiotibiales. Zona: piernas (parte superior). Equipo: máquina de curl.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Aperturas en máquina contractora (Peck Deck)',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/aperturas_en_maquina_contractora_peck_deck.mp4',
  '["Paso 1: Siéntate en la máquina contractora ajustando la altura del asiento para que los codos queden alineados horizontalmente con la articulación glenohumeral.", "Paso 2: Apoya los antebrazos contra las almohadillas acolchadas y sujeta los agarres frontales manteniendo los codos en un ángulo de 90 grados.", "Paso 3: Realiza una aducción horizontal de los brazos uniendo las almohadillas frente al pecho mediante una contracción concéntrica del pectoral mayor.", "Paso 4: Mantén la contracción isométrica durante un segundo en el punto de máxima aproximación, sintiendo la congestión en las fibras esternales del pectoral.", "Paso 5: Controla la fase excéntrica abriendo los brazos lentamente hasta sentir un estiramiento profundo en la caja torácica anterior.", "Paso 6: Repite sin permitir que las pesas toquen la pila entre repeticiones, preservando la tensión continua en los pectorales."]'::jsonb,
  'intermedio',
  'Ejercicio para pectorales. Zona: pecho. Equipo: máquina contractora.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Elevación de piernas colgado en barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/elevacion_de_piernas_colgado_en_barra.mp4',
  '["Paso 1: Suspéndete de una barra de dominadas con agarre prono a la anchura de los hombros, dejando que las piernas cuelguen completamente extendidas y unidas.", "Paso 2: Activa la musculatura profunda del core contrayendo el transverso del abdomen y estabilizando la cintura escapular mediante una leve depresión de los omóplatos.", "Paso 3: Eleva las piernas extendidas hacia el frente mediante una flexión de cadera controlada, evitando cualquier balanceo pendular del tronco.", "Paso 4: Continúa la elevación hasta que las piernas alcancen un ángulo de 90 grados respecto al torso, o hasta el límite que tu flexibilidad isquiotibial permita sin comprometer la técnica.", "Paso 5: Mantén un segundo la contracción isométrica del recto abdominal en la posición más alta del recorrido.", "Paso 6: Desciende las piernas lentamente controlando la fase excéntrica y evitando la hiperextensión lumbar al llegar al punto más bajo. Repite."]'::jsonb,
  'intermedio',
  'Ejercicio para abdomen. Zona: cintura. Equipo: peso corporal.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Plancha abdominal isométrica',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/plancha_abdominal_isometrica.mp4',
  '["Paso 1: Colócate en decúbito prono sobre una superficie firme, apoyando los antebrazos en el suelo con los codos alineados verticalmente bajo la articulación glenohumeral.", "Paso 2: Apoya las puntas de los pies separadas a la anchura de las caderas y eleva el cuerpo formando una línea perfectamente recta desde los talones hasta la coronilla.", "Paso 3: Contrae el recto abdominal y el transverso del abdomen, manteniendo la pelvis en posición neutra sin anteversión ni retroversión pélvica.", "Paso 4: Activa los glúteos y el cuádriceps femoral para estabilizar la cadena cinética posterior y evitar el colapso de la cadera.", "Paso 5: Respira de forma controlada y diafragmática mientras mantienes la posición isométrica durante el tiempo prescrito sin comprometer la alineación corporal.", "Paso 6: Finaliza la serie descendiendo el cuerpo de manera controlada hasta apoyar las rodillas en el suelo."]'::jsonb,
  'intermedio',
  'Ejercicio para abdomen. Zona: cintura. Equipo: peso corporal.',
  'isometrico'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Torsión rusa en suelo',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/torsion_rusa_en_suelo.mp4',
  '["Paso 1: Siéntate en el suelo con las rodillas flexionadas y los talones apoyados, inclinando el torso hacia atrás hasta formar un ángulo de aproximadamente 45 grados con el suelo.", "Paso 2: Eleva los pies despegándolos del suelo para incrementar la activación del core y une las palmas de las manos frente al esternón.", "Paso 3: Rota el tronco hacia el flanco derecho llevando los brazos en bloque solidario, contrayendo intensamente los músculos oblicuo externo e interno del lado contralateral.", "Paso 4: Regresa al centro con control y rota hacia el flanco izquierdo replicando el mismo patrón biomecánico de rotación torácica.", "Paso 5: Mantén la pelvis orientada al frente y estabilizada durante toda la torsión, aislando el movimiento rotacional en la columna torácica y no en la lumbar.", "Paso 6: Continúa alternando los lados de forma rítmica y controlada hasta completar el volumen de repeticiones prescrito para cada lado."]'::jsonb,
  'intermedio',
  'Ejercicio para abdomen. Zona: cintura. Equipo: peso corporal.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Remo en barra T con apoyo pectoral',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/remo_en_barra_t_con_apoyo_pectoral.mp4',
  '["Paso 1: Carga los discos en un extremo de la barra olímpica y colócate a horcajadas sobre ella con el extremo cargado situado entre ambas piernas.", "Paso 2: Flexiona ligeramente las rodillas e inclina el torso hacia adelante realizando una bisagra de cadera, preservando la columna vertebral en alineación neutra durante todo el ejercicio.", "Paso 3: Sujeta el agarre en V con ambas manos y deja que la barra cuelgue con los brazos completamente extendidos, sintiendo la tracción inicial en los dorsales.", "Paso 4: Tracciona la barra hacia el pecho llevando los codos hacia atrás y hacia arriba, juntando las escápulas en el punto máximo del recorrido concéntrico.", "Paso 5: Mantén la contracción isométrica durante un segundo en la posición de máxima aducción escapular, sintiendo la activación profunda de dorsales, romboides y trapecios.", "Paso 6: Controla la fase excéntrica descendiendo la carga lentamente hasta estirar por completo la cadena cinética dorsal sin perder la tensión escapular."]'::jsonb,
  'intermedio',
  'Ejercicio para dorsal ancho. Zona: espalda. Equipo: barra en T.',
  'cardio'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de tríceps en polea alta',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/extension_de_triceps_en_polea_alta.mp4',
  '["Paso 1: Colócate frente a la polea alta con el accesorio de barra recta o cuerda enganchado y ajusta la polea a una altura ligeramente superior a la de tu cabeza.", "Paso 2: Sujeta el accesorio con agarre prono y posiciona los codos firmemente contra las paredes laterales del torso, manteniendo los húmeros perpendiculares al suelo.", "Paso 3: Inclina muy ligeramente el torso hacia adelante manteniendo la columna vertebral en posición neutra, las rodillas blandas y el core activado para estabilizar el tronco.", "Paso 4: Extiende los codos empujando el accesorio hacia el suelo mediante una contracción concéntrica aislada del tríceps braquial, sin desplazar los codos de su posición.", "Paso 5: Bloquea los codos en la posición más baja del recorrido, contrayendo intensamente las tres cabezas del tríceps durante un segundo en el pico de máxima activación.", "Paso 6: Controla la fase excéntrica permitiendo que el cable ascienda lentamente hasta la flexión completa de los codos, resistiendo la tracción de la polea durante todo el retorno."]'::jsonb,
  'intermedio',
  'Ejercicio para tríceps. Zona: brazos (parte superior). Equipo: polea.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Fondos de tríceps',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/fondos_de_triceps.mp4',
  '[]'::jsonb,
  'intermedio',
  'Ejercicio de tricep dips.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca plano con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/press_de_banca_plano_con_barra.mp4',
  '["Paso 1: Acuéstate en un banco plano realizando retracción escapular y apoyando firmemente la planta de ambos pies en el suelo para generar una base estable.", "Paso 2: Sujeta la barra con agarre prono a una anchura ligeramente superior a la de los hombros y descárgala del soporte con los brazos extendidos.", "Paso 3: Desciende la barra controladamente hacia la parte inferior del esternón, manteniendo los codos en un ángulo de aproximadamente 45 grados respecto al torso.", "Paso 4: Impulsa la barra verticalmente mediante una contracción potente del pectoral mayor y el tríceps braquial, exhalando durante la fase concéntrica.", "Paso 5: Extiende los brazos sin llegar al bloqueo articular completo para preservar la tensión muscular en los pectorales.", "Paso 6: Repite el movimiento manteniendo la posición escapular estable y el puente torácico durante toda la serie."]'::jsonb,
  'intermedio',
  'Ejercicio para pectorales. Zona: pecho. Equipo: barra.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Peso muerto convencional con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/peso_muerto_convencional_con_barra.mp4',
  '["Paso 1: Colócate con los pies separados a la anchura de las caderas y las tibias prácticamente en contacto con la barra cargada en el suelo.", "Paso 2: Realiza una bisagra de cadera flexionando las rodillas y desciende para sujetar la barra con agarre prono mixto o doble prono a la anchura de los hombros.", "Paso 3: Activa la musculatura del core mediante la maniobra de Valsalva, retrae las escápulas y posiciona la columna vertebral en alineación neutra.", "Paso 4: Inicia el levantamiento empujando contra el suelo con los talones y extendiendo simultáneamente las articulaciones de la cadera y las rodillas.", "Paso 5: Bloquea el movimiento en la posición erguida contrayendo los glúteos y manteniendo la lordosis lumbar fisiológica sin realizar hiperextensión.", "Paso 6: Desciende la barra de forma controlada realizando la bisagra de cadera inversa, manteniendo la barra próxima al cuerpo durante todo el descenso."]'::jsonb,
  'intermedio',
  'Ejercicio para columna. Zona: espalda. Equipo: barra.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Press de banca declinado con barra',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/press_de_banca_declinado_con_barra.mp4',
  '["Paso 1: Fija los tobillos en los soportes del banco declinado y acuéstate con la cabeza situada en la parte más baja de la plataforma.", "Paso 2: Sujeta la barra con agarre prono a una anchura ligeramente superior a los hombros y descárgala del soporte con los brazos extendidos.", "Paso 3: Desciende la barra controladamente hacia la porción inferior del esternón, enfatizando el trabajo de las fibras esternales e inferiores del pectoral mayor.", "Paso 4: Impulsa la barra verticalmente contrayendo la porción inferior del pecho y los tríceps braquiales, manteniendo las escápulas retraídas contra el banco.", "Paso 5: Evita el bloqueo completo de los codos en la posición superior para mantener la tensión mecánica constante en el músculo objetivo.", "Paso 6: Repite con un ritmo controlado, prestando especial atención a la fase excéntrica para maximizar el estímulo hipertrófico."]'::jsonb,
  'intermedio',
  'Ejercicio para pectorales. Zona: pecho. Equipo: barra.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Curl martillo con mancuernas',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/curl_martillo_con_mancuernas.mp4',
  '["Paso 1: De pie, con los pies separados a la anchura de los hombros y el core activado, sujeta una mancuerna en cada mano con agarre neutro.", "Paso 2: Mantén los codos adheridos a las costillas y los hombros estabilizados, evitando cualquier movimiento compensatorio del tronco.", "Paso 3: Flexiona los codos simultáneamente llevando las mancuernas hacia los hombros, preservando el agarre neutro durante todo el arco de movimiento.", "Paso 4: Contrae intensamente el bíceps braquial y el músculo braquial en la fase concéntrica, notando la congestión localizada en el vientre muscular.", "Paso 5: Mantén un segundo la contracción isométrica en la cima del recorrido concéntrico.", "Paso 6: Desciende las mancuernas de manera controlada durante la fase excéntrica hasta la extensión completa de los codos y repite."]'::jsonb,
  'intermedio',
  'Ejercicio para bíceps. Zona: brazos (parte superior). Equipo: mancuernas.',
  'fuerza'
) on conflict (nombre) do nothing;

insert into public.ejercicios (nombre, url_gif, instrucciones, dificultad, descripcion, finalidad)
values (
  'Extensión de piernas en máquina',
  'https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/gym_workout/extension_de_piernas_en_maquina.mp4',
  '["Paso 1: Siéntate en la máquina de extensión de piernas ajustando el respaldo para que el eje de rotación de la máquina quede perfectamente alineado con la articulación de la rodilla.", "Paso 2: Coloca el rodillo acolchado sobre la cara anterior de los tobillos, justo en la unión tibioperonea distal, y sujeta firmemente los agarres laterales.", "Paso 3: Mantén la espalda completamente apoyada contra el respaldo y las caderas en contacto con el asiento durante todo el movimiento.", "Paso 4: Extiende las piernas mediante una contracción concéntrica aislada del cuádriceps femoral hasta alcanzar la extensión articular completa controlada.", "Paso 5: Mantén la contracción isométrica durante un segundo en el pico de extensión, activando específicamente el vasto medial del cuádriceps.", "Paso 6: Desciende el peso de forma controlada durante la fase excéntrica sin permitir que las placas toquen la pila de pesas entre repeticiones."]'::jsonb,
  'intermedio',
  'Ejercicio para cuádriceps. Zona: piernas (parte superior). Equipo: máquina de extensión.',
  'fuerza'
) on conflict (nombre) do nothing;
