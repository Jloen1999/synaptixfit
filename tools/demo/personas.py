"""Personas demo de SynaptixFit: perfil, asignaturas, apuntes, rutina, plazos, retos, publicaciones y hábitos diarios.

seed_demo.py recorre estos datos día a día. Los días se cuentan respecto a hoy: d = -35 es hace cinco
semanas, d = 0 es hoy y d > 0 es el futuro. wd es el día de la semana (0 = lunes … 6 = domingo).
Las funciones de hábitos son deterministas (se apoyan en d), así dos ejecuciones dan el mismo histórico.
"""
from __future__ import annotations

import random


def _h(d: int, *values):
    """Elige un valor de la lista de forma determinista según el día (misma elección en cada ejecución)."""
    return values[random.Random(d * 7919 + len(values)).randrange(len(values))]


# ------------------------------------------------------------------------------------------- apuntes

NOTE_GLUCOLISIS = """# Glucólisis y su regulación

La glucólisis es la ruta citosólica que oxida una molécula de **glucosa (6C)** hasta **dos de piruvato (3C)**. Se divide en dos fases:

1. **Fase preparatoria (pasos 1-5):** se *invierten* 2 ATP. La hexoquinasa fosforila la glucosa a glucosa-6-fosfato (la atrapa en la célula) y la fosfofructoquinasa-1 (PFK-1) forma fructosa-1,6-bisfosfato, que la aldolasa rompe en dos triosas fosfato.
2. **Fase de beneficio (pasos 6-10):** cada gliceraldehído-3-fosfato se oxida (gliceraldehído-3-P deshidrogenasa, se reduce NAD⁺ a NADH) y se generan 4 ATP por fosforilación a nivel de sustrato (fosfoglicerato quinasa y piruvato quinasa).

**Balance neto:** Glucosa + 2 NAD⁺ + 2 ADP + 2 Pi → 2 piruvato + 2 NADH + 2 ATP + 2 H₂O.

## Puntos de control (pasos irreversibles)

| Enzima | Activadores | Inhibidores |
|---|---|---|
| Hexoquinasa | — | Glucosa-6-fosfato (producto) |
| **PFK-1** (paso limitante) | AMP, fructosa-2,6-bisfosfato | ATP, citrato, H⁺ |
| Piruvato quinasa | Fructosa-1,6-bisfosfato (*feed-forward*) | ATP, alanina, fosforilación (glucagón) |

La **fructosa-2,6-bisfosfato** es la señal hormonal clave: la insulina aumenta su concentración (activa la glucólisis y frena la gluconeogénesis); el glucagón la reduce.

## Destino del piruvato

- **Aerobiosis:** piruvato deshidrogenasa → acetil-CoA → ciclo de Krebs.
- **Anaerobiosis (músculo en esfuerzo intenso):** lactato deshidrogenasa regenera NAD⁺ y permite que la glucólisis siga.
- **Levaduras:** fermentación alcohólica (etanol + CO₂).

> Truco de examen: «la PFK-1 manda». Si preguntan por qué el citrato frena la glucólisis, la respuesta es que indica que el ciclo de Krebs ya está saturado de sustrato.
"""

NOTE_KREBS = """# Ciclo de Krebs (ácidos tricarboxílicos)

Ocurre en la **matriz mitocondrial**. Cada vuelta oxida un acetil-CoA (2C) a 2 CO₂ y recoge la energía en coenzimas reducidas.

**Pasos y enzimas:**
1. Citrato sintasa: acetil-CoA + oxalacetato → citrato.
2. Aconitasa: citrato → isocitrato.
3. **Isocitrato deshidrogenasa** → α-cetoglutarato + CO₂ + NADH (*paso limitante*).
4. **α-cetoglutarato deshidrogenasa** → succinil-CoA + CO₂ + NADH.
5. Succinil-CoA sintetasa → succinato + GTP.
6. Succinato deshidrogenasa → fumarato + FADH₂ (es también el complejo II de la cadena respiratoria).
7. Fumarasa → malato.
8. Malato deshidrogenasa → oxalacetato + NADH.

**Rendimiento por acetil-CoA:** 3 NADH + 1 FADH₂ + 1 GTP ≈ 10 ATP tras la fosforilación oxidativa.

## Regulación
- Se activa con ADP y Ca²⁺ (contracción muscular).
- Se inhibe con NADH, ATP y succinil-CoA.

## Carácter anfibólico
El ciclo también **aporta precursores**: el α-cetoglutarato y el oxalacetato dan aminoácidos; el succinil-CoA, el grupo hemo; el citrato sale al citosol para la síntesis de ácidos grasos. Las reacciones **anapleróticas** (piruvato carboxilasa) reponen el oxalacetato.
"""

NOTE_ENZIMAS = """# Cinética enzimática: Michaelis-Menten

Modelo: E + S ⇌ ES → E + P. Suponiendo estado estacionario de ES:

**v₀ = Vmax · [S] / (Km + [S])**

- **Km**: concentración de sustrato a la que v₀ = Vmax/2. Km bajo → mayor afinidad aparente.
- **Vmax** = kcat · [E]total. **kcat** (número de recambio): moléculas de S convertidas por segundo y sitio activo.
- **Eficiencia catalítica:** kcat/Km (límite por difusión ≈ 10⁸-10⁹ M⁻¹s⁻¹).

## Linealización de Lineweaver-Burk
1/v₀ = (Km/Vmax)·(1/[S]) + 1/Vmax → pendiente Km/Vmax, corte en Y = 1/Vmax, corte en X = −1/Km.

## Tipos de inhibición reversible
| Tipo | Se une a | Km aparente | Vmax aparente |
|---|---|---|---|
| Competitiva | E libre | Aumenta | No cambia |
| Acompetitiva | Complejo ES | Disminuye | Disminuye |
| No competitiva (mixta pura) | E y ES por igual | No cambia | Disminuye |

Ejemplo clínico: el metotrexato inhibe competitivamente la dihidrofolato reductasa.
"""

NOTE_GRAM = """# Pared bacteriana: Gram positivas vs Gram negativas

**Tinción de Gram:** cristal violeta → lugol (mordiente) → alcohol-acetona (decoloración) → safranina (contraste).

| | Gram + | Gram − |
|---|---|---|
| Peptidoglucano | Grueso (20-80 nm), muchas capas | Fino (2-7 nm) |
| Ácidos teicoicos | Sí | No |
| Membrana externa | No | Sí, con **LPS** (endotoxina, lípido A) |
| Espacio periplásmico | Mínimo | Amplio |
| Color tras la tinción | Violeta | Rosa |

**Por qué funciona:** el alcohol deshidrata el peptidoglucano grueso y atrapa el complejo cristal violeta-yodo; en las Gram negativas disuelve la membrana externa y el colorante se escapa.

**Relevancia práctica:** la penicilina inhibe la transpeptidación del peptidoglucano y es más eficaz en Gram positivas; la membrana externa de las Gram negativas frena muchos antibióticos.

*Práctica 3:* E. coli salió rosa y S. aureus violeta, como esperábamos. Ojo con decolorar de más.
"""

NOTE_LAMBERT = """# Espectrofotometría UV-Vis y ley de Lambert-Beer

**A = ε · l · c**
- A: absorbancia (adimensional), A = −log T.
- ε: coeficiente de absortividad molar (M⁻¹·cm⁻¹), propio de la sustancia y de la longitud de onda.
- l: paso óptico de la cubeta (normalmente 1 cm).
- c: concentración molar.

**Recta de calibrado:** se miden patrones de concentración conocida a la λ de máxima absorción; la pendiente es ε·l. La ley es lineal aproximadamente entre A = 0,1 y 1,0.

**Desviaciones:** concentraciones altas (interacciones entre moléculas), luz no monocromática, dispersión por turbidez, reacciones químicas del analito.

Ejemplo: proteínas a 280 nm (triptófano y tirosina); ácidos nucleicos a 260 nm. La relación A260/A280 ≈ 1,8 indica DNA puro.
"""

NOTE_INTEGRALES = """# Integración por partes y cambio de variable

## Cambio de variable
Si la integral tiene la forma ∫ f(g(x))·g'(x) dx, se hace u = g(x), du = g'(x) dx:
∫ 2x·cos(x²) dx → u = x² → ∫ cos u du = sen(x²) + C.

## Integración por partes
**∫ u dv = u·v − ∫ v du**

Regla **ALPES** para elegir u (lo que antes aparezca): Arcoseno/arcotangente, Logaritmos, Polinomios, Exponenciales, Senos/cosenos.

Ejemplos resueltos:
- ∫ x·eˣ dx: u = x, dv = eˣ dx → x·eˣ − eˣ + C.
- ∫ ln x dx: u = ln x, dv = dx → x·ln x − x + C.
- ∫ eˣ·sen x dx: dos veces por partes y aparece la integral original → (eˣ/2)(sen x − cos x) + C.

## Integrales impropias (tema 4)
∫₁^∞ 1/xᵖ dx converge si p > 1 (vale 1/(p−1)) y diverge si p ≤ 1. Criterio de comparación: si 0 ≤ f ≤ g y ∫g converge, ∫f converge.

> Recordatorio del profe: en el parcial siempre cae una por partes «cíclica» y una impropia con parámetro.
"""

NOTE_CACHE = """# Jerarquía de memoria y memoria caché

**Principio de localidad:** temporal (lo que se usó se volverá a usar) y espacial (se usarán direcciones cercanas). Por eso funciona la caché.

## Parámetros
- Tamaño de bloque (línea), número de conjuntos, asociatividad (directa, n-vías, totalmente asociativa).
- Dirección = **etiqueta | índice | desplazamiento**. Desplazamiento = log₂(tamaño de bloque); índice = log₂(nº de conjuntos).

Ejemplo: caché de 32 KiB, bloques de 64 B, 4 vías, direcciones de 32 bits → 512 líneas / 4 = 128 conjuntos → 7 bits de índice, 6 de desplazamiento, 19 de etiqueta.

## Rendimiento
**Tiempo medio de acceso = t_acierto + tasa_fallos × penalización**. Con t = 1 ciclo, 5 % de fallos y 100 ciclos de penalización → 6 ciclos.

## Tipos de fallo (las 3 C)
Obligatorios (primer acceso), de capacidad (no cabe el conjunto de trabajo) y de conflicto (varias direcciones al mismo conjunto).

## Escritura
Write-through (+ buffer de escritura) frente a write-back (bit de sucio). Políticas de reemplazo: LRU, FIFO, aleatoria.
"""

NOTE_TCPIP = """# Modelo TCP/IP y subnetting

| Capa | Protocolos | Unidad |
|---|---|---|
| Aplicación | HTTP, DNS, SMTP | Mensaje |
| Transporte | TCP, UDP | Segmento / datagrama |
| Internet | IP, ICMP | Paquete |
| Acceso a red | Ethernet, Wi-Fi | Trama |

**TCP:** orientado a conexión (three-way handshake SYN, SYN-ACK, ACK), control de flujo con ventana deslizante y control de congestión (slow start, AIMD). **UDP:** sin conexión, cabecera de 8 bytes, útil para DNS y streaming.

## Subnetting rápido
Red 192.168.10.0/24 que hay que dividir en 6 subredes → 3 bits prestados → /27 → 32 direcciones, **30 hosts útiles** por subred.
Subredes: .0, .32, .64, .96, .128, .160, .192, .224. Broadcast de la primera: 192.168.10.31.

Fórmulas: hosts = 2ʰ − 2; subredes = 2ˢ. Máscara /27 = 255.255.255.224.
"""

NOTE_SOLID = """# Principios SOLID

- **S — Responsabilidad única:** una clase, un motivo para cambiar.
- **O — Abierto/cerrado:** abierto a extensión, cerrado a modificación (polimorfismo, estrategia).
- **L — Sustitución de Liskov:** un subtipo debe poder usarse donde se espera el tipo base sin romper el contrato (el clásico rectángulo/cuadrado lo viola).
- **I — Segregación de interfaces:** mejor varias interfaces pequeñas que una «gorda».
- **D — Inversión de dependencias:** los módulos de alto nivel dependen de abstracciones, no de detalles (puertos y adaptadores).

Relación con la práctica: el proyecto de la asignatura pide arquitectura en capas; los repositorios se inyectan como interfaces para poder hacer tests con dobles.
"""

NOTE_CONTROL_CONST = """# Control de constitucionalidad en España

El **Tribunal Constitucional** (arts. 159-165 CE; LOTC 2/1979) es el intérprete supremo de la Constitución y tiene el **monopolio de rechazo** de las normas con rango de ley.

## Recurso de inconstitucionalidad (control abstracto)
- **Legitimados (art. 162.1.a CE):** Presidente del Gobierno, Defensor del Pueblo, 50 diputados, 50 senadores, órganos ejecutivos y asambleas de las CC. AA. (estas, solo respecto de leyes que afecten a su ámbito).
- **Plazo:** 3 meses desde la publicación de la ley (ampliable a 9 meses con el procedimiento del art. 33.2 LOTC).
- No suspende la ley, salvo cuando el Gobierno impugna una ley autonómica (art. 161.2 CE).

## Cuestión de inconstitucionalidad (control concreto)
- La plantea un **juez o tribunal** de oficio o a instancia de parte cuando una norma con rango de ley aplicable al caso y **de cuya validez dependa el fallo** pueda ser contraria a la CE (art. 163 CE).
- Se plantea concluido el procedimiento y dentro del plazo para dictar sentencia, tras oír a las partes y al Ministerio Fiscal (art. 35 LOTC): **juicio de relevancia** y **juicio de aplicabilidad**.

## Efectos de las sentencias (art. 164 CE)
Valor de **cosa juzgada**, efectos frente a todos (*erga omnes*) y publicación en el BOE. La declaración de inconstitucionalidad conlleva la nulidad, aunque el TC puede modular los efectos (sentencias interpretativas, prospectivas).

> Para el parcial: diferenciar bien legitimación, plazo y si suspende o no.
"""

NOTE_AMPARO = """# Derechos fundamentales y recurso de amparo

**Ámbito (art. 53.2 CE):** derechos de los arts. 14 a 29 (sección 1.ª del capítulo II) y la objeción de conciencia del art. 30.2.

## Garantías
1. **Reserva de ley orgánica** para su desarrollo (art. 81 CE) y respeto del **contenido esencial** (art. 53.1).
2. **Procedimiento preferente y sumario** ante los tribunales ordinarios (amparo judicial).
3. **Recurso de amparo constitucional** ante el TC.

## Requisitos del amparo (LOTC, arts. 41-58)
- Agotar la vía judicial previa (subsidiariedad).
- Invocar el derecho vulnerado en cuanto se conozca la lesión.
- **Especial trascendencia constitucional** (reforma de la LO 6/2007): el recurrente debe justificarla; el TC la aprecia (STC 155/2009 enumera los supuestos).
- Plazos: 20 días (actos judiciales), 3 meses (actos parlamentarios sin fuerza de ley), 20 días tras agotar la vía judicial (actos del Gobierno o la Administración).

## Ejemplo
Vulneración del derecho a la tutela judicial efectiva (art. 24) por falta de motivación de una sentencia → incidente de nulidad de actuaciones → amparo.
"""

NOTE_SOCIEDADES = """# Sociedades de capital: SA y SL

Regulación: **Real Decreto Legislativo 1/2010** (Ley de Sociedades de Capital, LSC).

| | Sociedad Anónima | Sociedad Limitada |
|---|---|---|
| Capital mínimo | 60.000 € (desembolso mínimo del 25 %) | 1 € (régimen de formación sucesiva si < 3.000 €, reforma de 2022) |
| Capital dividido en | Acciones (libre transmisión por regla general) | Participaciones (transmisión restringida, derecho de adquisición preferente) |
| Responsabilidad de los socios | Limitada a lo aportado | Limitada a lo aportado |
| Órganos | Junta general y administración | Junta general y administración |

**Constitución:** escritura pública + inscripción en el Registro Mercantil (adquiere personalidad jurídica con la inscripción).

**Administradores:** deberes de diligencia y de lealtad (arts. 225-232 LSC); acción social e individual de responsabilidad.

**Junta general:** ordinaria en los 6 primeros meses del ejercicio (aprobar cuentas, aplicación del resultado). Quórum reforzado en la SA para modificar estatutos.
"""

NOTE_PROCESAL = """# Juicio ordinario y juicio verbal (LEC 1/2000)

**Criterio de la cuantía (reforma de 2023):** juicio verbal hasta **15.000 €**; ordinario por encima o cuantía inestimable. Además hay materias que van siempre a uno u otro (p. ej., derechos honoríficos, impugnación de acuerdos sociales → ordinario; desahucio por falta de pago → verbal).

## Juicio ordinario
Demanda → contestación (20 días) → **audiencia previa** (intento de acuerdo, excepciones procesales, fijación de hechos controvertidos, proposición de prueba) → juicio → sentencia.

## Juicio verbal
Demanda → contestación escrita (10 días) → vista (si alguna parte la pide o el tribunal la considera necesaria) → sentencia.

Recordatorio: la falta de contestación no supone allanamiento (rebeldía ≠ admisión de hechos).
"""

NOTE_DIP_FOROS = """# Competencia judicial internacional: Reglamento Bruselas I bis

**Reglamento (UE) 1215/2012** para materia civil y mercantil cuando el demandado está domiciliado en un Estado miembro.

1. **Foro general (art. 4):** domicilio del demandado.
2. **Foros especiales (art. 7):** en contratos, el lugar de cumplimiento de la obligación (compraventa de mercaderías: donde se entregaron; prestación de servicios: donde se prestaron); en responsabilidad extracontractual, el lugar del hecho dañoso (teoría de la ubicuidad: acción u origen del daño, caso *Bier*).
3. **Foros de protección:** consumidores, trabajadores y seguros: la parte débil puede demandar en su domicilio y solo puede ser demandada allí.
4. **Competencias exclusivas (art. 24):** inmuebles, sociedades, registros, propiedad industrial, ejecución.
5. **Sumisión expresa (art. 25) y tácita (art. 26):** comparecer sin impugnar la competencia.

Litispendencia (art. 29): conoce el tribunal que se acudió primero (*prior tempore*).
"""

NOTE_LETRA = """# La letra de cambio (Ley 19/1985, Cambiaria y del Cheque)

**Requisitos formales (art. 1):** denominación «letra de cambio», mandato puro y simple de pagar una suma, nombre del librado, vencimiento, lugar de pago, nombre del tomador, fecha y lugar de libramiento y firma del librador.

**Sujetos:** librador (emite), librado (debe pagar; con la aceptación pasa a ser aceptante, obligado principal), tomador (beneficiario), endosante/endosatario y avalista.

**Endoso:** transmite los derechos; el endosante garantiza la aceptación y el pago (responsabilidad solidaria).

**Acciones:** directa contra el aceptante y su avalista; de regreso contra endosantes y librador, previo protesto o declaración equivalente. **Juicio cambiario** (arts. 819 y ss. LEC): requerimiento de pago y embargo inmediato.
"""

NOTE_SUPERCOMP = """# Supercompensación y periodización

**Síndrome general de adaptación (Selye):** alarma → resistencia → agotamiento. El entrenamiento aplica una carga, el rendimiento cae (fatiga) y, con recuperación suficiente, sube por encima del nivel inicial: **supercompensación**.

Si el siguiente estímulo llega demasiado pronto se acumula fatiga (riesgo de sobreentrenamiento); si llega tarde, se pierde la adaptación.

## Periodización
- **Lineal (clásica, Matveyev):** volumen alto → intensidad alta a medida que se acerca la competición.
- **Ondulante:** cambia volumen e intensidad entre sesiones o semanas.
- **Por bloques (Issurin):** acumulación → transformación → realización.

**Semana de descarga (deload):** bajar el volumen un 40-60 % cada 3-5 semanas para disipar fatiga manteniendo la intensidad.

## Control de carga
Carga de sesión = RPE × minutos (Foster). **ACWR** = carga aguda (7 días) / crónica (28 días); la zona 0,8-1,3 se asocia a menor riesgo de lesión (Gabbett, 2016).
"""

NOTE_SISTEMAS = """# Sistemas energéticos

| Sistema | Sustrato | Duración dominante | Ejemplo |
|---|---|---|---|
| Fosfágenos (ATP-PCr) | Fosfocreatina | 0-10 s | Sprint de 60 m, 1RM |
| Glucólisis anaeróbica | Glucógeno → lactato | 10 s - 2 min | 400 m |
| Oxidativo | Glucosa, ácidos grasos | > 2 min | Media maratón |

Los tres funcionan a la vez; cambia cuál predomina. El **lactato** no es un residuo: se reutiliza (ciclo de Cori, lanzadera lactato entre fibras).

**VO₂máx:** consumo máximo de oxígeno (ml·kg⁻¹·min⁻¹). **Umbrales:** VT1 (≈ 2 mmol/L de lactato) y VT2 (≈ 4 mmol/L).
"""

NOTE_PALANCAS = """# Biomecánica: palancas y momento de fuerza

**Momento (torque) = F · d⊥**, distancia perpendicular entre la línea de acción de la fuerza y el eje.

Tipos de palanca en el cuerpo:
- **1.er género** (eje en medio): extensión de cuello (atlanto-occipital).
- **2.º género** (resistencia en medio): ponerse de puntillas (el eje en los metatarsos).
- **3.er género** (potencia en medio, la más frecuente): flexión de codo con el bíceps. Pierde fuerza y gana velocidad y amplitud.

**Aplicación a la sentadilla:** cuanto más se adelanta el tronco, mayor es el brazo de momento en la cadera (más glúteo e isquios); con más flexión de rodilla y tronco erguido, más momento en la rodilla (más cuádriceps).
"""

NOTE_PROVISIONES = """# Provisiones y contingencias (NRV 15.ª PGC)

**Provisión:** obligación actual (legal, contractual o implícita) derivada de sucesos pasados, de cuantía o vencimiento **inciertos**, cuya cancelación es **probable** que suponga una salida de recursos.

- Se registra por el **valor actual** de la mejor estimación del importe necesario (si el efecto financiero es significativo, vencimiento > 1 año).
- Cada cierre se revisa: actualización financiera (gasto financiero, cuenta 660) y ajustes de estimación.
- **Pasivo contingente:** obligación posible o no probable → no se registra, solo se informa en la memoria.

Asiento típico (litigio con probabilidad alta, 12.000 €):
(678/62x) Gastos … 12.000 a (14x) Provisión para otras responsabilidades … 12.000

Al resolverse: si se paga menos, la diferencia va a **exceso de provisiones (795)**.
"""

NOTE_TAE = """# Capitalización compuesta y TAE

**Capital final:** Cₙ = C₀ · (1 + i)ⁿ. Con fraccionamiento m veces al año: i_m = j_m / m, y el **tanto efectivo anual equivalente**:

**TAE = (1 + i_m)^m − 1**

Ejemplo: nominal del 6 % con pagos mensuales → i₁₂ = 0,5 % → TAE = 1,005¹² − 1 = **6,17 %**.

**Valor actual de una renta constante pospagable:** VA = C · [1 − (1 + i)⁻ⁿ] / i.
Préstamo francés: la cuota es constante; al principio se paga sobre todo interés y al final, sobre todo capital.

> En el parcial no dejan calculadora financiera: practicar con la tabla de factores.
"""

NOTE_DAFO = """# Análisis DAFO y cinco fuerzas de Porter

**DAFO:** Debilidades y Fortalezas (internas); Amenazas y Oportunidades (externas). Se cruza en estrategias **FO** (ofensivas), **DO** (reorientación), **FA** (defensivas) y **DA** (supervivencia).

**Cinco fuerzas (Porter, 1979):** rivalidad entre competidores, amenaza de nuevos entrantes, amenaza de sustitutivos, poder de negociación de proveedores y de clientes. Cuanto más intensas, menor rentabilidad potencial del sector.

Caso del trabajo en grupo: cadena de gimnasios low-cost. Barreras de entrada bajas, sustitutivos fuertes (apps y entrenamiento en casa) y clientes con poco coste de cambio → márgenes estrechos; la ventaja viene de la escala y de la ubicación.
"""

QUICK_NOTES_LUCIA = [
    ("bioq", "Dudas para tutoría de Bioquímica", "- ¿Por qué el ΔG de la aldolasa es positivo y aun así la reacción avanza?\n- Repasar la lanzadera malato-aspartato.\n- Preguntar si entra β-oxidación en el parcial."),
    ("micro", "Medios de cultivo (práctica 2)", "Medio selectivo: inhibe a unos y deja crecer a otros (MacConkey para Gram −). Medio diferencial: distingue por una reacción (lactosa + rojo neutro → colonias rosas)."),
    ("histo", "Tejido epitelial — clasificación", "Según capas: simple, estratificado, pseudoestratificado. Según la forma de la capa superficial: plano, cúbico, cilíndrico. Ejemplos: endotelio (simple plano), epidermis (estratificado plano queratinizado), tráquea (pseudoestratificado ciliado)."),
    ("histo", "Tejido conectivo", "Fibras: colágeno (tipo I resistencia, tipo III reticular), elásticas. Células: fibroblastos, macrófagos, mastocitos, plasmáticas. Laxo vs denso regular (tendones) vs denso irregular (dermis)."),
    ("tib", "Centrifugación diferencial", "Fuerza centrífuga relativa (g) = 1,118·10⁻⁵ · r · rpm². Orden de sedimentación: núcleos → mitocondrias → microsomas → ribosomas."),
    ("ingles", "Vocabulary — lab report", "Hypothesis, yield, assay, to stain, to culture, supernatant, pellet, fume hood. Passive voice in Methods: «The samples were incubated at 37 °C»."),
]


# ------------------------------------------------------------------------------------------ preguntas

QUIZ_BIOQ = [
    {"type": "MULTIPLE_CHOICE", "statement": "¿Cuál es el balance neto de ATP de la glucólisis por molécula de glucosa?",
     "options": ["2 ATP", "4 ATP", "36 ATP", "0 ATP"], "correctAnswer": "2 ATP",
     "explanation": "Se producen 4 ATP y se invierten 2 en la fase preparatoria."},
    {"type": "MULTIPLE_CHOICE", "statement": "¿Qué enzima es el principal punto de control de la glucólisis?",
     "options": ["Hexoquinasa", "Fosfofructoquinasa-1", "Aldolasa", "Enolasa"], "correctAnswer": "Fosfofructoquinasa-1",
     "explanation": "La PFK-1 cataliza el paso comprometido y la regulan ATP, AMP, citrato y fructosa-2,6-bisfosfato."},
    {"type": "MULTIPLE_CHOICE", "statement": "Un inhibidor competitivo…",
     "options": ["Aumenta la Km aparente", "Disminuye la Vmax", "Se une solo al complejo ES", "Disminuye la Km"],
     "correctAnswer": "Aumenta la Km aparente", "explanation": "Compite por el sitio activo: hace falta más sustrato para llegar a Vmax/2."},
    {"type": "FILL_IN_BLANK", "statement": "El paso limitante del ciclo de Krebs lo cataliza la ____ deshidrogenasa.",
     "correctAnswer": "isocitrato", "explanation": "La isocitrato deshidrogenasa se activa con ADP y Ca²⁺."},
]

QUIZ_CONST = [
    {"type": "MULTIPLE_CHOICE", "statement": "¿Cuál es el plazo general para interponer un recurso de inconstitucionalidad?",
     "options": ["20 días", "3 meses", "6 meses", "1 año"], "correctAnswer": "3 meses",
     "explanation": "Art. 33.1 LOTC: tres meses desde la publicación de la ley."},
    {"type": "MULTIPLE_CHOICE", "statement": "¿Quién puede plantear una cuestión de inconstitucionalidad?",
     "options": ["Cualquier ciudadano", "50 diputados", "Un juez o tribunal", "El Defensor del Pueblo"],
     "correctAnswer": "Un juez o tribunal", "explanation": "Art. 163 CE: control concreto que plantea el órgano judicial."},
    {"type": "MULTIPLE_CHOICE", "statement": "¿Qué derechos protege el recurso de amparo?",
     "options": ["Todos los del Título I", "Arts. 14 a 29 y 30.2", "Solo el art. 24", "Los principios rectores"],
     "correctAnswer": "Arts. 14 a 29 y 30.2", "explanation": "Art. 53.2 CE."},
    {"type": "FILL_IN_BLANK", "statement": "Desde 2007 el recurrente en amparo debe justificar la especial ____ constitucional.",
     "correctAnswer": "trascendencia", "explanation": "Reforma de la LOTC por la LO 6/2007."},
    {"type": "MULTIPLE_CHOICE", "statement": "¿Suspende la ley impugnada un recurso de inconstitucionalidad del Presidente del Gobierno contra una ley autonómica?",
     "options": ["No, nunca", "Sí, si invoca el art. 161.2 CE", "Solo si lo pide el Senado", "Solo leyes orgánicas"],
     "correctAnswer": "Sí, si invoca el art. 161.2 CE", "explanation": "La suspensión dura 5 meses salvo que el TC la ratifique o levante."},
]

QUIZ_PROCESAL = [
    {"type": "MULTIPLE_CHOICE", "statement": "Tras la reforma de 2023, ¿hasta qué cuantía se tramita el juicio verbal?",
     "options": ["6.000 €", "15.000 €", "30.000 €", "3.000 €"], "correctAnswer": "15.000 €",
     "explanation": "Art. 250.2 LEC tras el RDL 6/2023."},
    {"type": "MULTIPLE_CHOICE", "statement": "¿En qué trámite se fijan los hechos controvertidos en el juicio ordinario?",
     "options": ["Demanda", "Audiencia previa", "Juicio", "Diligencias finales"], "correctAnswer": "Audiencia previa",
     "explanation": "Art. 428 LEC."},
    {"type": "FILL_IN_BLANK", "statement": "En el juicio ordinario el demandado tiene ____ días para contestar.",
     "correctAnswer": "20", "explanation": "Art. 404 LEC."},
]

QUIZ_REDES = [
    {"type": "MULTIPLE_CHOICE", "statement": "¿Cuántos hosts útiles tiene una subred /27?",
     "options": ["30", "32", "62", "14"], "correctAnswer": "30", "explanation": "2⁵ − 2 = 30."},
    {"type": "MULTIPLE_CHOICE", "statement": "¿Qué protocolo de transporte usa normalmente DNS para consultas?",
     "options": ["TCP", "UDP", "ICMP", "ARP"], "correctAnswer": "UDP", "explanation": "Puerto 53 sobre UDP; TCP para transferencias de zona."},
    {"type": "FILL_IN_BLANK", "statement": "La máscara /26 en notación decimal es 255.255.255.____",
     "correctAnswer": "192", "explanation": "Dos bits a 1 en el último octeto: 128 + 64."},
]


# --------------------------------------------------------------------------------------- comentarios

COMMENTS = {
    "lucia": ["¡Qué crack! 💪", "Esa constancia es envidiable", "¡Vamos! Ánimo con todo", "Me apunto a la próxima 🙌"],
    "pablo": ["Buenísimo 🔥", "Toca descansar también eh", "Brutal, a por más", "Así se hace"],
    "marta": ["¡Enhorabuena!", "Qué disciplina 👏", "¡Ánimo con los exámenes!", "Inspiras a cualquiera"],
    "andres": ["Bien ahí 💪", "Ojo con la técnica en las últimas series", "Grande, sigue así", "Esa progresión mola"],
    "sara": ["¡Me encanta! 😍", "¡Qué bien lo llevas!", "Eres un ejemplo 🙌", "¡A tope! 💥", "Orgullosa de ti"],
}


# ------------------------------------------------------------------------------------------- personas

def _lucia_training(d, wd):
    if wd in (0, 1, 3, 4) and d != -17:
        return {"rpe": 8 if wd == 4 else 7, "minutes": _h(d, 65, 70, 72, 68)}
    return None


def _pablo_training(d, wd):
    if d <= -9:
        return {"rpe": 6, "minutes": _h(d, 42, 45, 48)} if wd in (1, 3, 5) else None
    if d == -8:
        return None
    if -7 <= d <= -1:
        return None if d == -4 else {"rpe": _h(d, 8, 8, 9), "minutes": _h(d, 65, 70, 75)}
    return {"rpe": 9, "minutes": 60}


def _marta_training(d, wd):
    if d >= -27 and wd in (1, 4):
        return {"rpe": 6, "minutes": _h(d, 45, 48, 50)}
    return None


def _andres_training(d, wd):
    if d <= -7:
        return {"rpe": 7 if wd == 5 else 8, "minutes": _h(d, 85, 90, 88)} if wd <= 5 else None
    if -6 <= d <= -1:
        return {"rpe": 6, "minutes": 70} if wd in (1, 3, 5) else None
    return None


def _sara_training(d, wd):
    if d <= -8:
        return {"rpe": 7, "minutes": 45} if wd in (0, 2, 4) else None
    if -7 <= d <= -1:
        return {"rpe": 7, "minutes": 55} if wd in (0, 1, 3, 4) else None
    return {"rpe": 7, "minutes": 50} if wd in (0, 1, 3, 4) else None


def _checkin(sleep, stress, energy, soreness, ready=True, notes=None, pains=None):
    return {"sleepQuality": sleep, "stress": stress, "energy": energy, "soreness": soreness,
            "painZones": pains or [], "readyToTrain": ready, **({"notes": notes} if notes else {})}


def _lucia_checkin(d, wd):
    # Duerme bien casi siempre; el estrés sube un poco algunos días de laboratorio.
    return _checkin(_h(d, 4, 4, 5, 4, 3, 4, 4), _h(d, 3, 2, 3, 3, 3, 2, 3), _h(d, 4, 4, 4, 5, 4, 4, 3),
                    _h(d, 2, 2, 3, 2, 2, 2, 2))


def _pablo_checkin(d, wd):
    if d == -8:
        return None
    if d <= -9:
        return _checkin(4, 2, 4, 2) if d % 3 != 0 else None
    if d == 0:
        return _checkin(2, 5, 2, 5, ready=False, notes="Gemelos cargadísimos y he dormido 5 h. Parcial el jueves.",
                        pains=["gemelos", "rodilla"])
    return _checkin(_h(d, 3, 2, 3), _h(d, 4, 5, 4), _h(d, 3, 3, 2), _h(d, 3, 4, 4))


def _marta_checkin(d, wd):
    if d >= -12 or d % 2 == 0:
        return _checkin(_h(d, 4, 3, 4), _h(d, 3, 3, 4), _h(d, 3, 4, 3), _h(d, 2, 1, 2))
    return None


def _andres_checkin(d, wd):
    if d % 7 == 3:
        return None
    return _checkin(_h(d, 5, 4, 4), 2, _h(d, 4, 5, 4), _h(d, 3, 2, 3) if d <= -7 else 2)


def _sara_checkin(d, wd):
    if d >= -9 or d % 5 != 0:
        return _checkin(_h(d, 4, 4, 3), _h(d, 2, 3, 2), _h(d, 4, 4, 5), _h(d, 2, 2, 3))
    return None


PERSONAS = [
    {
        "key": "lucia",
        "email": "lucia.fernandez",
        "name": "Lucía Fernández",
        "privacy": "FRIENDS",
        "summary": "Biotecnología (UEx), 2.º curso. Gimnasio 4 días, carga académica alta, racha de más de un mes, coleccionista de insignias.",
        "wellness": {"age": 20, "sex": "FEMALE", "city": "Badajoz", "weightKg": 61.5, "heightCm": 166,
                     "activityLevel": "MODERATE", "primaryGoal": "HYPERTROPHY",
                     "goals": ["Ganar fuerza en tren inferior", "Mantener la constancia en época de exámenes"],
                     "equipment": ["Gimnasio completo"], "availableDays": [1, 2, 4, 5], "minutesPerSession": 70},
        "academic": {"semester": 3, "modality": "IN_PERSON", "semesterCredits": 30, "weeklyStudyHoursGoal": 15,
                     "targetGpa": 4.4},
        "catalog": {"university": "Universidad de Extremadura", "degree": "Grado en Biotecnología", "course": 2,
                    "semester": 1},
        "subjects": {
            "bioq": {"name": "Bioquímica estructural", "perceivedDifficulty": 5, "priority": "HIGH", "teacher": "Dr. Javier Morales"},
            "histo": {"name": "Histología", "perceivedDifficulty": 4, "priority": "HIGH", "teacher": "Dra. Carmen Rubio"},
            "micro": {"name": "Microbiología", "perceivedDifficulty": 3, "priority": "MEDIUM", "teacher": "Dr. Luis Paredes"},
            "tib": {"name": "Técnicas instrumentales básicas", "perceivedDifficulty": 3, "priority": "MEDIUM", "teacher": "Dra. Elena Sanz"},
        },
        "manual_subjects": [
            {"key": "ingles", "name": "Inglés científico B2", "credits": 3, "perceivedDifficulty": 2, "priority": "LOW",
             "teacher": "Helen Parker", "description": "Optativa de idioma: redacción de informes de laboratorio en inglés."},
        ],
        "notif": {"activeCategories": ["CONFLICT", "FATIGUE_ALERT", "MILESTONE", "SOCIAL", "ACADEMIC"],
                  "quietHoursStart": "23:00", "quietHoursEnd": "07:00", "dailyLimit": 12, "mode": "NORMAL"},
        "routine": {
            "name": "Torso-Pierna 4 días · Hipertrofia", "visibility": "PUBLIC", "goal": "HYPERTROPHY", "weeks": 8,
            "description": "Torso/pierna en 4 días con progresión de cargas del 2,5 % semanal y descarga en la semana 6.",
            "week_types": ["ADAPTATION", "LOAD", "LOAD", "LOAD", "PEAK", "DELOAD", "LOAD", "PEAK"],
            "days": [
                (1, "Torso A · fuerza", [("Press de banca con barra", 4, 6, 150, 37.5), ("Remo con barra y agarre prono", 4, 8, 120, 35),
                                          ("Press de hombros con mancuernas sentado", 3, 10, 90, 10), ("Jalón de pie con cuerda en polea alta", 3, 10, 90, 35)]),
                (2, "Pierna A · cuádriceps", [("Sentadilla trasera con barra", 4, 6, 180, 55), ("Prensa de piernas a 45°", 3, 10, 120, 100),
                                               ("Zancada hacia atrás con mancuerna", 3, 12, 90, 10), ("Crunch abdominal (recto abdominal superior)", 3, 15, 60, None)]),
                (4, "Torso B · hipertrofia", [("Press de banca con mancuerna", 4, 10, 90, 14), ("Remo sentado en polea baja con agarre estrecho", 4, 10, 90, 16),
                                               ("Elevación lateral con mancuernas sentado", 3, 15, 60, 5), ("Curl de bíceps con mancuernas de pie", 3, 12, 60, None)]),
                (5, "Pierna B · cadena posterior", [("Peso muerto rumano con barra (glúteo mayor)", 4, 5, 180, 60), ("Hip thrust con barra", 4, 10, 120, 70),
                                                     ("Zancada hacia atrás con mancuerna", 3, 10, 90, 12), ("Carrera en cinta rodante", 1, 1, 60, None, {"targetDurationSeconds": 600, "distanceMeters": 1600})]),
            ],
        },
        "training": _lucia_training,
        "checkin": _lucia_checkin,
        "focus": lambda d, wd: [(25, "bioq"), (25, "bioq")] if wd < 5 and d % 2 == 0 else ([(25, "histo")] if wd < 5 else []),
        "classes": [
            (0, "09:00", "11:00", "bioq", "THEORY", "Aula 1.3 · Facultad de Ciencias"), (0, "11:30", "13:30", "micro", "PRACTICE", "Laboratorio de Microbiología"),
            (1, "09:00", "11:00", "histo", "THEORY", "Aula 2.1"), (1, "11:30", "13:30", "tib", "PRACTICE", "Laboratorio de Técnicas"),
            (2, "09:00", "11:00", "bioq", "THEORY", "Aula 1.3 · Facultad de Ciencias"), (2, "11:30", "13:30", "bioq", "PRACTICE", "Laboratorio de Bioquímica"),
            (3, "09:00", "11:00", "histo", "THEORY", "Aula 2.1"), (3, "11:30", "13:30", "tib", "THEORY", "Aula 2.4"),
            (4, "09:00", "11:00", "micro", "THEORY", "Aula 1.1"), (4, "11:30", "12:30", "ingles", "THEORY", "Aula de idiomas"),
        ],
        "class_p": 0.95,
        "study": [
            (0, "16:00", "18:00", "bioq", "Glucólisis y regulación: problemas del boletín 3", "HIGH"),
            (1, "16:00", "18:00", "histo", "Tejido conectivo: atlas y preparaciones", "MEDIUM"),
            (2, "16:00", "18:00", "micro", "Crecimiento bacteriano y medios de cultivo", "MEDIUM"),
            (3, "16:00", "18:00", "bioq", "Ciclo de Krebs y cadena respiratoria", "HIGH"),
            (4, "16:00", "17:30", "tib", "Espectrofotometría: rectas de calibrado", "MEDIUM"),
            (0, "20:30", "22:00", "histo", "Repaso tejido epitelial", "MEDIUM"),
            (2, "20:30", "22:00", "bioq", "Cinética enzimática: ejercicios de Km y Vmax", "HIGH"),
            (5, "10:00", "12:30", "bioq", "Repaso semanal de Bioquímica", "HIGH"),
        ],
        "study_p": 0.9,
        "sport_time": ("18:15", 75),
        "notes": [
            {"subject": "bioq", "title": "Glucólisis y su regulación", "content": NOTE_GLUCOLISIS, "visibility": "FRIENDS", "day": -33, "material": True},
            {"subject": "bioq", "title": "Ciclo de Krebs", "content": NOTE_KREBS, "visibility": "FRIENDS", "day": -27, "material": True},
            {"subject": "bioq", "title": "Cinética enzimática: Michaelis-Menten", "content": NOTE_ENZIMAS, "visibility": "PRIVATE", "day": -20, "material": True},
            {"subject": "micro", "title": "Pared bacteriana: Gram + y Gram −", "content": NOTE_GRAM, "visibility": "FRIENDS", "day": -24, "material": True},
            {"subject": "tib", "title": "Espectrofotometría y ley de Lambert-Beer", "content": NOTE_LAMBERT, "visibility": "PUBLIC", "day": -12, "material": False},
        ] + [{"subject": s, "title": t, "content": c, "visibility": "PRIVATE", "day": -31 + i * 4, "material": False, "quick": i % 2 == 0}
             for i, (s, t, c) in enumerate(QUICK_NOTES_LUCIA)],
        "quizzes": [{"subject": "bioq", "title": "Autoevaluación: metabolismo energético", "questions": QUIZ_BIOQ, "day": -15}],
        "review": {"diligence": 0.85, "qualities": (4, 5, 4, 3)},
        "deadlines": [
            {"key": "gram", "title": "Informe de prácticas: tinción de Gram", "type": "ASSIGNMENT", "due": (-14, "23:59"), "difficulty": "MEDIUM", "subject": "micro", "complete": -15,
             "description": "Informe de la práctica 3 con fotografías de las preparaciones."},
            {"key": "parcial_bioq", "title": "Primer parcial de Bioquímica estructural", "type": "EXAM", "due": (-9, "09:00"), "difficulty": "HIGH", "subject": "bioq", "complete": -9,
             "description": "Temas 1-4: glúcidos, glucólisis, Krebs y enzimas."},
            {"key": "cuest_micro", "title": "Cuestionario online de Microbiología", "type": "OTHER", "due": (3, "23:59"), "difficulty": "LOW", "subject": "micro"},
            {"key": "seminario", "title": "Seminario: espectrofotometría aplicada", "type": "PRESENTATION", "due": (5, "12:00"), "difficulty": "MEDIUM", "subject": "tib",
             "description": "Presentación en grupo de 10 minutos."},
            {"key": "parcial_histo", "title": "Examen parcial de Histología", "type": "EXAM", "due": (12, "09:00"), "difficulty": "HIGH", "subject": "histo",
             "description": "Teoría + reconocimiento de preparaciones al microscopio."},
        ],
        "challenges": [
            {"title": "16 entrenos este cuatrimestre", "type": "FITNESS", "goal": "Entrenar al menos 4 días por semana hasta mediados de octubre.",
             "visibility": "FRIENDS", "difficulty": "MEDIUM", "start": -34, "end": 40, "sessionTarget": 16},
            {"title": "Superar el primer parcial de Bioquímica", "type": "ACADEMIC", "goal": "Llegar al parcial con todo el temario repasado.",
             "visibility": "FRIENDS", "difficulty": "HIGH", "start": -30, "end": 25, "subject": "bioq",
             "milestones": [{"title": "Entregar el informe de Gram", "weight": 30, "difficulty": "MEDIUM", "deadline": "gram"},
                            {"title": "Repasar enzimas con el test", "weight": 30, "difficulty": "MEDIUM", "complete": -11},
                            {"title": "Presentarme al primer parcial", "weight": 40, "difficulty": "HIGH", "deadline": "parcial_bioq"}]},
        ],
        "final_challenges": [
            {"title": "Preparar el parcial de Histología", "type": "ACADEMIC", "goal": "Llegar al examen con el atlas completo y dos simulacros.",
             "visibility": "FRIENDS", "difficulty": "HIGH", "start": -5, "end": 13, "subject": "histo",
             "milestones": [{"title": "Atlas de tejidos completado", "weight": 25, "difficulty": "MEDIUM", "complete_now": True},
                            {"title": "Sesión de repaso de tejido conectivo", "weight": 25, "difficulty": "MEDIUM", "block": ("histo", 1)},
                            {"title": "Simulacro de reconocimiento", "weight": 20, "difficulty": "MEDIUM"},
                            {"title": "Examen parcial de Histología", "weight": 30, "difficulty": "HIGH", "deadline": "parcial_histo"}]},
        ],
        "posts": [
            (-30, "ROUTINE", "Arranco nueva rutina torso-pierna de 8 semanas. ¡A por el cuatrimestre! 🏋️‍♀️"),
            (-9, "MILESTONE_REACHED", "Primer parcial de Bioquímica hecho. Creo que ha ido bien, ¡ahora a descansar un poco!"),
            (-3, "SESSION_COMPLETED", "Nuevo récord en hip thrust: 80 kg x 8 🍑🔥"),
        ],
        "likes_p": 0.55, "comment_p": 0.2,
        "training_plan": {"plannedSessions": 4, "intensity": "MODERATE", "minutesPerSession": 70},
        "study_plans": [(-5, "Arranque del cuatrimestre"), (-4, "Semana de laboratorios"), (-3, "Bioquímica a fondo"),
                        (-2, "Semana del parcial"), (-1, "Después del parcial"), (0, "Histología y seminario")],
        "weights": [(-28, 61.8), (-21, 61.6), (-14, 61.9), (-7, 62.1)],
        "wellbeing": {"stress": 6, "sleep": 7.0},
        "ai": {"summary_note": "Glucólisis y su regulación"},
    },
    {
        "key": "pablo",
        "email": "pablo.ruiz",
        "name": "Pablo Ruiz",
        "privacy": "FRIENDS",
        "summary": "Ingeniería Informática (UEx), 2.º curso. Running y calistenia. Exámenes esta semana (modo exámenes) y ACWR en sobreentrenamiento.",
        "wellness": {"age": 19, "sex": "MALE", "city": "Cáceres", "weightKg": 70, "heightCm": 178,
                     "activityLevel": "HIGH", "primaryGoal": "STRENGTH_ENDURANCE",
                     "goals": ["Correr la San Silvestre en menos de 45 min", "Conseguir 10 dominadas seguidas"],
                     "equipment": ["Barra de dominadas", "Paralelas", "Cinta de correr"], "availableDays": [2, 4, 6], "minutesPerSession": 50},
        "academic": {"semester": 3, "modality": "IN_PERSON", "semesterCredits": 30, "weeklyStudyHoursGoal": 12,
                     "targetGpa": 3.5},
        "catalog": {"university": "Universidad de Extremadura", "degree": "Grado en Ingeniería Informática en Tecnologías de la Información",
                    "course": 2, "semester": 1},
        "subjects": {
            "mates": {"name": "AMPLIACIÓN DE MATEMÁTICAS", "perceivedDifficulty": 5, "priority": "HIGH", "teacher": "Dr. Antonio Gil"},
            "ec": {"name": "ESTRUCTURA DE COMPUTADORES", "perceivedDifficulty": 4, "priority": "HIGH", "teacher": "Dra. Rosa Delgado"},
            "redes": {"name": "FUNDAMENTOS DE REDES", "perceivedDifficulty": 3, "priority": "MEDIUM", "teacher": "Dr. Mario Cano"},
            "ipo": {"name": "INTERACCIÓN PERSONA-ORDENADOR", "perceivedDifficulty": 2, "priority": "LOW"},
            "mdp": {"name": "METODOLOGÍA Y DESARROLLO DE PROGRAMAS", "perceivedDifficulty": 3, "priority": "MEDIUM"},
        },
        "manual_subjects": [],
        "notif": {"activeCategories": ["FATIGUE_ALERT", "MILESTONE", "ACADEMIC"],
                  "quietHoursStart": "00:00", "quietHoursEnd": "08:00", "dailyLimit": 6, "mode": "EXAMS"},
        "routine": {
            "name": "San Silvestre + calistenia", "visibility": "FRIENDS", "goal": "STRENGTH_ENDURANCE", "weeks": 8,
            "description": "Tres días: rodaje, calistenia y series. Objetivo: 10K por debajo de 45 minutos.",
            "week_types": ["ADAPTATION", "LOAD", "LOAD", "LOAD", "PEAK", "LOAD", "LOAD", "PEAK"],
            "days": [
                (2, "Rodaje + core", [("Carrera en cinta rodante", 1, 1, 60, None, {"targetDurationSeconds": 2100, "distanceMeters": 5500}),
                                       ("Plancha con paso de mancuerna", 3, 12, 60, None)]),
                (4, "Calistenia empuje-tirón", [("Dominadas con agarre prono", 5, 6, 120, None), ("Fondos en barras paralelas", 4, 10, 90, None),
                                                 ("Flexión de brazos", 4, 15, 60, None), ("Sentadilla pistol", 3, 6, 90, None)]),
                (6, "Series y tirada", [("Carrera en cinta rodante", 1, 1, 60, None, {"targetDurationSeconds": 2700, "distanceMeters": 7500}),
                                         ("Salto a la comba", 3, 1, 60, None, {"targetDurationSeconds": 120})]),
            ],
        },
        "training": _pablo_training,
        "checkin": _pablo_checkin,
        "focus": lambda d, wd: ([(25, "mates")] * 3 + [(25, "ec")]) if d >= -7 else ([(25, "mdp")] if wd in (1, 3) else []),
        "classes": [
            (0, "08:30", "10:30", "mates", "THEORY", "Aula A2 · Escuela Politécnica"), (0, "10:30", "12:30", "ec", "THEORY", "Aula A2"),
            (1, "08:30", "10:30", "redes", "THEORY", "Aula A5"), (1, "10:30", "12:30", "mdp", "PRACTICE", "Laboratorio L3"),
            (2, "08:30", "10:30", "mates", "PRACTICE", "Aula A2"), (2, "10:30", "12:30", "ipo", "THEORY", "Aula A4"),
            (3, "08:30", "10:30", "ec", "PRACTICE", "Laboratorio de Arquitectura"), (3, "10:30", "12:30", "redes", "PRACTICE", "Laboratorio de Redes"),
        ],
        "class_p": 0.8,
        "study": [
            (0, "17:00", "19:00", "mates", "Integrales por partes: hoja de problemas 4", "HIGH"),
            (2, "17:00", "19:00", "ec", "Problemas de caché y TMA", "HIGH"),
            (3, "17:00", "18:30", "redes", "Subnetting y VLSM", "MEDIUM"),
        ],
        "study_extra_last_week": [
            (None, "16:00", "19:00", "mates", "Exámenes de años anteriores de Ampliación", "HIGH"),
            (None, "21:00", "23:00", "ec", "Repaso de memoria virtual y TLB", "HIGH"),
        ],
        "study_p": 0.6, "study_p_last_week": 0.85,
        "sport_time": ("19:30", 60),
        "notes": [
            {"subject": "mates", "title": "Integración por partes y cambio de variable", "content": NOTE_INTEGRALES, "visibility": "FRIENDS", "day": -26, "material": True},
            {"subject": "ec", "title": "Jerarquía de memoria y caché", "content": NOTE_CACHE, "visibility": "FRIENDS", "day": -19, "material": True},
            {"subject": "redes", "title": "Modelo TCP/IP y subnetting", "content": NOTE_TCPIP, "visibility": "PUBLIC", "day": -16, "material": True},
            {"subject": "mdp", "title": "Principios SOLID", "content": NOTE_SOLID, "visibility": "PUBLIC", "day": -22, "material": False},
        ],
        "quizzes": [{"subject": "redes", "title": "Test rápido de subnetting", "questions": QUIZ_REDES, "day": -13}],
        "review": {"diligence": 0.35, "qualities": (3, 2, 4, 3)},
        "deadlines": [
            {"key": "p1", "title": "Práctica 1: jerarquía de memoria", "type": "ASSIGNMENT", "due": (-10, "23:59"), "difficulty": "MEDIUM", "subject": "ec", "complete": -11},
            {"key": "subnet", "title": "Entrega de ejercicios de subnetting", "type": "ASSIGNMENT", "due": (-3, "23:59"), "difficulty": "LOW", "subject": "redes"},
            {"key": "p2", "title": "Práctica 2: simulador de caché", "type": "ASSIGNMENT", "due": (2, "23:59"), "difficulty": "HIGH", "subject": "ec",
             "description": "Simulador en C de una caché asociativa por conjuntos con política LRU."},
            {"key": "parcial_mates", "title": "Parcial de Ampliación de Matemáticas", "type": "EXAM", "due": (3, "09:00"), "difficulty": "HIGH", "subject": "mates",
             "description": "Integrales, series y ecuaciones diferenciales de primer orden."},
            {"key": "parcial_ec", "title": "Parcial de Estructura de Computadores", "type": "EXAM", "due": (6, "10:00"), "difficulty": "HIGH", "subject": "ec"},
            {"key": "examen_redes", "title": "Examen de Fundamentos de Redes", "type": "EXAM", "due": (13, "09:00"), "difficulty": "MEDIUM", "subject": "redes"},
        ],
        "challenges": [
            {"title": "San Silvestre: 24 entrenamientos", "type": "FITNESS", "goal": "Llegar en forma a la carrera de fin de año.",
             "visibility": "PUBLIC", "difficulty": "HIGH", "start": -34, "end": 70, "sessionTarget": 24},
        ],
        "final_challenges": [
            {"title": "Aprobar Ampliación de Matemáticas", "type": "ACADEMIC", "goal": "Aprobar el parcial del jueves sin dejar la práctica 2.",
             "visibility": "FRIENDS", "difficulty": "HIGH", "start": -7, "end": 7, "subject": "mates",
             "milestones": [{"title": "Hacer dos exámenes de años anteriores", "weight": 25, "difficulty": "MEDIUM", "complete_now": True},
                            {"title": "Sesión de problemas de integrales", "weight": 25, "difficulty": "MEDIUM", "block": ("mates", 1)},
                            {"title": "Entregar la práctica 2", "weight": 20, "difficulty": "HIGH", "deadline": "p2"},
                            {"title": "Parcial de Ampliación", "weight": 30, "difficulty": "HIGH", "deadline": "parcial_mates"}]},
        ],
        "posts": [
            (-20, "SESSION_COMPLETED", "10K en 47:12. Queda menos para bajar de 45 🏃‍♂️"),
            (-2, "SESSION_COMPLETED", "Correr para despejarme entre tanto parcial… creo que me estoy pasando 😅"),
        ],
        "likes_p": 0.35, "comment_p": 0.15,
        "training_plan": {"plannedSessions": 3, "intensity": "MODERATE", "minutesPerSession": 50},
        "training_plan_last": {"plannedSessions": 3, "intensity": "LOW", "minutesPerSession": 40, "notes": "Semana de exámenes: bajar volumen."},
        "study_plans": [(-1, "Semana de repaso intensivo"), (0, "Semana de parciales")],
        "weights": [(-21, 69.6), (-7, 68.9)],
        "wellbeing": {"stress": 8, "sleep": 5.5},
        "exam_mode_from": -6,
    },
    {
        "key": "marta",
        "usage_focus": "ACADEMIC",
        "email": "marta.gomez",
        "name": "Marta Gómez",
        "privacy": "FRIENDS",
        "summary": "Derecho (Universidad de Granada), 4.º curso. Principiante en fuerza. Usa mucho el repaso espaciado, flashcards y tests.",
        "wellness": {"age": 22, "sex": "FEMALE", "city": "Granada", "weightKg": 57, "heightCm": 162,
                     "activityLevel": "LIGHT", "primaryGoal": "MOBILITY",
                     "goals": ["Empezar a entrenar fuerza sin lesionarme", "Dormir mejor en época de exámenes"],
                     "equipment": ["Mancuernas", "Gimnasio de la universidad"], "availableDays": [2, 5], "minutesPerSession": 45},
        "academic": {"university": "Universidad de Granada", "degree": "Grado en Derecho", "semester": 7, "modality": "IN_PERSON",
                     "semesterCredits": 30, "weeklyStudyHoursGoal": 18, "targetGpa": 4.0},
        "catalog": None,
        "subjects": {},
        "manual_subjects": [
            {"key": "const", "name": "Derecho Constitucional III", "credits": 6, "perceivedDifficulty": 4, "priority": "HIGH",
             "teacher": "Dra. Inmaculada Torres", "description": "Tribunal Constitucional, procesos constitucionales y derechos fundamentales."},
            {"key": "merc", "name": "Derecho Mercantil II", "credits": 6, "perceivedDifficulty": 4, "priority": "HIGH",
             "teacher": "Dr. Fernando Ortega", "description": "Sociedades de capital, títulos valores y concurso."},
            {"key": "proc", "name": "Derecho Procesal Civil", "credits": 6, "perceivedDifficulty": 5, "priority": "HIGH",
             "teacher": "Dra. Marina Castro", "description": "Juicio ordinario, juicio verbal, recursos y ejecución."},
            {"key": "dip", "name": "Derecho Internacional Privado", "credits": 6, "perceivedDifficulty": 3, "priority": "MEDIUM",
             "teacher": "Dr. Pedro Aranda", "description": "Competencia judicial internacional y ley aplicable."},
        ],
        "notif": {"activeCategories": ["CONFLICT", "FATIGUE_ALERT", "MILESTONE", "SOCIAL", "ACADEMIC"],
                  "quietHoursStart": "22:30", "quietHoursEnd": "08:00", "dailyLimit": 10, "mode": "NORMAL"},
        "routine": {
            "name": "Fuerza para principiantes · cuerpo completo", "visibility": "PRIVATE", "goal": "HYPERTROPHY", "weeks": 8,
            "description": "Dos días a la semana de cuerpo completo con pesos ligeros y técnica.",
            "week_types": ["ADAPTATION", "ADAPTATION", "LOAD", "LOAD", "LOAD", "DELOAD", "LOAD", "LOAD"],
            "days": [
                (2, "Cuerpo completo A", [("Sentadilla sumo con mancuerna", 3, 12, 90, 6), ("Press de banca con mancuerna", 3, 12, 90, 5),
                                           ("Remo sentado en polea baja con agarre estrecho", 3, 12, 90, 6), ("Puente de glúteos", 3, 15, 60, None)]),
                (5, "Cuerpo completo B", [("Zancada hacia atrás con mancuerna", 3, 10, 90, 4), ("Jalón de pie con cuerda en polea alta", 3, 12, 90, 20),
                                           ("Ciclismo indoor en bicicleta estática", 1, 1, 60, None, {"targetDurationSeconds": 900}),
                                           ("Plancha de rodillas", 3, 1, 60, None, {"isometricSeconds": 30})]),
            ],
        },
        "training": _marta_training,
        "checkin": _marta_checkin,
        "focus": lambda d, wd: [(25, "const"), (25, "const"), (25, "proc")] if d >= -12 else ([(25, "const"), (25, "merc")] if d % 3 != 0 else []),
        "classes": [
            (0, "15:30", "17:30", "const", "THEORY", "Aula 12 · Facultad de Derecho"), (0, "17:30", "19:30", "merc", "THEORY", "Aula 12"),
            (1, "15:30", "17:30", "proc", "THEORY", "Aula 8"), (1, "17:30", "19:00", "dip", "THEORY", "Aula 8"),
            (2, "15:30", "17:30", "const", "PRACTICE", "Seminario 3"), (2, "17:30", "19:30", "proc", "PRACTICE", "Seminario 3"),
            (3, "15:30", "17:30", "merc", "PRACTICE", "Aula 12"), (3, "17:30", "19:00", "dip", "PRACTICE", "Aula 5"),
        ],
        "class_p": 0.92,
        "study": [
            (0, "09:30", "12:00", "const", "Procesos constitucionales: esquemas", "HIGH"),
            (1, "09:30", "12:00", "proc", "Juicio ordinario: casos prácticos", "HIGH"),
            (2, "09:30", "12:00", "merc", "Sociedades de capital", "MEDIUM"),
            (3, "09:30", "12:00", "const", "Derechos fundamentales y amparo", "HIGH"),
            (4, "09:30", "12:00", "dip", "Reglamento Bruselas I bis", "MEDIUM"),
            (5, "10:00", "13:00", "proc", "Repaso semanal con flashcards", "HIGH"),
        ],
        "study_p": 0.85,
        "sport_time": ("13:00", 50),
        "notes": [
            {"subject": "const", "title": "Control de constitucionalidad", "content": NOTE_CONTROL_CONST, "visibility": "PUBLIC", "day": -32, "material": True},
            {"subject": "const", "title": "Derechos fundamentales y recurso de amparo", "content": NOTE_AMPARO, "visibility": "FRIENDS", "day": -25, "material": True},
            {"subject": "merc", "title": "Sociedades de capital: SA y SL", "content": NOTE_SOCIEDADES, "visibility": "FRIENDS", "day": -29, "material": True},
            {"subject": "proc", "title": "Juicio ordinario y juicio verbal", "content": NOTE_PROCESAL, "visibility": "PRIVATE", "day": -21, "material": True},
            {"subject": "merc", "title": "La letra de cambio", "content": NOTE_LETRA, "visibility": "FRIENDS", "day": -3, "material": True},
            {"subject": "dip", "title": "Competencia judicial internacional (Bruselas I bis)", "content": NOTE_DIP_FOROS, "visibility": "PUBLIC", "day": -1, "material": True},
        ],
        "quizzes": [{"subject": "const", "title": "Test: procesos constitucionales", "questions": QUIZ_CONST, "day": -18},
                    {"subject": "proc", "title": "Test: LEC — juicio ordinario y verbal", "questions": QUIZ_PROCESAL, "day": -10}],
        "tests": [(-16, 0), (-9, 0), (-6, 1), (-2, 0)],
        "flashcards": True,
        "review": {"diligence": 1.0, "qualities": (4, 3, 5, 3, 4), "skip_days": [-1]},
        "deadlines": [
            {"key": "sentencia", "title": "Comentario de la STC 31/2010", "type": "ASSIGNMENT", "due": (-12, "23:59"), "difficulty": "MEDIUM", "subject": "const", "complete": -13},
            {"key": "parcial_merc", "title": "Parcial de Derecho Mercantil II", "type": "EXAM", "due": (-5, "16:00"), "difficulty": "HIGH", "subject": "merc", "complete": -5},
            {"key": "caso_proc", "title": "Caso práctico de Procesal: audiencia previa", "type": "ASSIGNMENT", "due": (4, "23:59"), "difficulty": "MEDIUM", "subject": "proc"},
            {"key": "parcial_const", "title": "Parcial de Derecho Constitucional III", "type": "EXAM", "due": (9, "16:00"), "difficulty": "HIGH", "subject": "const",
             "description": "Procesos constitucionales y derechos fundamentales."},
            {"key": "expo_dip", "title": "Exposición: competencia judicial internacional", "type": "PRESENTATION", "due": (15, "17:30"), "difficulty": "MEDIUM", "subject": "dip"},
        ],
        "challenges": [
            {"title": "Mis primeros 10 entrenamientos", "type": "FITNESS", "goal": "Coger el hábito de entrenar dos días por semana.",
             "visibility": "FRIENDS", "difficulty": "LOW", "start": -28, "end": 30, "sessionTarget": 10},
        ],
        "final_challenges": [
            {"title": "Dominar Constitucional antes del parcial", "type": "ACADEMIC", "goal": "Llegar al parcial con los esquemas, tests y repasos al día.",
             "visibility": "PUBLIC", "difficulty": "HIGH", "start": -14, "end": 10, "subject": "const",
             "milestones": [{"title": "Esquema de procesos constitucionales", "weight": 20, "difficulty": "MEDIUM", "note": "Control de constitucionalidad", "complete_now": True},
                            {"title": "Tres tests de práctica aprobados", "weight": 20, "difficulty": "MEDIUM", "complete_now": True},
                            {"title": "Repaso de derechos fundamentales", "weight": 25, "difficulty": "MEDIUM", "block": ("const", 1)},
                            {"title": "Parcial de Constitucional", "weight": 35, "difficulty": "HIGH", "deadline": "parcial_const"}]},
        ],
        "posts": [
            (-5, "MILESTONE_REACHED", "Parcial de Mercantil fuera ✔️ Las flashcards me han salvado la vida."),
        ],
        "likes_p": 0.5, "comment_p": 0.25,
        "training_plan": {"plannedSessions": 2, "intensity": "LOW", "minutesPerSession": 45},
        "study_plans": [(-4, "Rutina de estudio"), (-3, "Semana de Mercantil"), (-2, "Recta final del parcial"), (-1, "Comentario y repaso"), (0, "Constitucional a fondo")],
        "weights": [(-21, 57.2), (-7, 57.5)],
        "goal_change": (-14, "HYPERTROPHY"),
        "wellbeing": {"stress": 6, "sleep": 7.0},
        "ai": {"flashcards_notes": ["Control de constitucionalidad", "Derechos fundamentales y recurso de amparo"]},
    },
    {
        "key": "andres",
        "usage_focus": "FITNESS",
        "email": "andres.molina",
        "name": "Andrés Molina",
        "privacy": "PUBLIC",
        "summary": "Ciencias de la Actividad Física y del Deporte (Universidad de Granada), 3.º. Deportista avanzado (6 días), poco estudio, semana de descarga.",
        "wellness": {"age": 21, "sex": "MALE", "city": "Granada", "weightKg": 78, "heightCm": 181,
                     "activityLevel": "HIGH", "primaryGoal": "MAX_STRENGTH",
                     "goals": ["Sentadilla de 160 kg", "Mantener el porcentaje de grasa"],
                     "equipment": ["Gimnasio completo", "Pista de atletismo"], "availableDays": [1, 2, 3, 4, 5, 6], "minutesPerSession": 90},
        "academic": {"university": "Universidad de Granada", "degree": "Grado en Ciencias de la Actividad Física y del Deporte",
                     "semester": 5, "modality": "IN_PERSON", "semesterCredits": 30, "weeklyStudyHoursGoal": 6, "targetGpa": 3.2},
        "catalog": None,
        "subjects": {},
        "manual_subjects": [
            {"key": "fisio", "name": "Fisiología del Ejercicio", "credits": 6, "perceivedDifficulty": 3, "priority": "MEDIUM", "teacher": "Dr. Raúl Jiménez"},
            {"key": "biomec", "name": "Biomecánica del Movimiento Humano", "credits": 6, "perceivedDifficulty": 4, "priority": "HIGH", "teacher": "Dra. Sonia Vega"},
            {"key": "teoria", "name": "Teoría y Práctica del Entrenamiento Deportivo", "credits": 6, "perceivedDifficulty": 2, "priority": "MEDIUM", "teacher": "Dr. Iván Prieto"},
            {"key": "estad", "name": "Estadística aplicada al Deporte", "credits": 6, "perceivedDifficulty": 4, "priority": "LOW"},
        ],
        "notif": {"activeCategories": ["CONFLICT", "FATIGUE_ALERT", "MILESTONE", "SOCIAL", "ACADEMIC"],
                  "quietHoursStart": "23:30", "quietHoursEnd": "07:00", "dailyLimit": 20, "mode": "NORMAL"},
        "routine": {
            "name": "Fuerza máxima 6 días · bloque de otoño", "visibility": "PUBLIC", "goal": "MAX_STRENGTH", "weeks": 7,
            "description": "Bloque de fuerza con días pesados y ligeros; semana 6 de descarga.",
            "week_types": ["LOAD", "LOAD", "LOAD", "PEAK", "LOAD", "DELOAD", "LOAD"],
            "days": [
                (1, "Sentadilla pesada", [("Sentadilla trasera con barra", 5, 3, 240, 140), ("Prensa de piernas a 45°", 4, 8, 120, 200), ("Crunch abdominal (recto abdominal superior)", 3, 20, 60, None)]),
                (2, "Press banca pesado", [("Press de banca con barra", 5, 3, 240, 100), ("Remo con barra y agarre prono", 4, 6, 150, 80), ("Fondos en barras paralelas", 3, 10, 90, None)]),
                (3, "Peso muerto", [("Peso muerto sumo con barra", 5, 2, 240, 170), ("Hip thrust con barra", 4, 8, 120, 140), ("Dominadas lastradas con agarre prono", 4, 5, 150, 15)]),
                (4, "Hombro y accesorios", [("Press militar de pie en máquina Smith", 5, 5, 180, 60), ("Elevación lateral con mancuernas sentado", 4, 12, 60, 12), ("Remo sentado en polea baja con agarre estrecho", 4, 10, 90, 36)]),
                (5, "Sentadilla técnica", [("Sentadilla trasera con barra", 4, 5, 180, 115), ("Zancada hacia atrás con barra", 3, 8, 120, 60), ("Carrera en cinta rodante", 1, 1, 60, None, {"targetDurationSeconds": 900, "distanceMeters": 3000})]),
                (6, "Banca volumen", [("Press de banca con barra", 4, 8, 150, 80), ("Jalón de pie con cuerda en polea alta", 4, 10, 90, 70), ("Extensión de tríceps en polea alta", 3, 12, 60, 30)]),
            ],
        },
        "routine_ai": {"durationWeeks": 6, "goal": "MAX_STRENGTH"},
        "training": _andres_training,
        "checkin": _andres_checkin,
        "focus": lambda d, wd: [(25, "biomec")] if wd == 6 else [],
        "classes": [
            (0, "08:00", "10:00", "fisio", "THEORY", "Aula Magna · Facultad de Ciencias del Deporte"),
            (1, "08:00", "10:00", "biomec", "THEORY", "Aula 3"), (1, "10:00", "12:00", "teoria", "PRACTICE", "Pabellón polideportivo"),
            (2, "08:00", "10:00", "estad", "THEORY", "Aula de informática"),
            (3, "08:00", "10:00", "biomec", "PRACTICE", "Laboratorio de Biomecánica"), (3, "10:00", "12:00", "fisio", "PRACTICE", "Laboratorio de Fisiología"),
            (4, "08:00", "10:00", "teoria", "THEORY", "Aula 3"),
        ],
        "class_p": 0.8,
        "study": [
            (1, "19:30", "21:00", "biomec", "Palancas y momentos articulares", "HIGH"),
            (3, "19:30", "21:00", "fisio", "Sistemas energéticos y umbrales", "MEDIUM"),
            (6, "11:00", "12:30", "estad", "Prácticas de SPSS", "LOW"),
        ],
        "study_p": 0.5,
        "sport_time": ("17:00", 90),
        "notes": [
            {"subject": "teoria", "title": "Supercompensación y periodización", "content": NOTE_SUPERCOMP, "visibility": "PUBLIC", "day": -30, "material": False},
            {"subject": "fisio", "title": "Sistemas energéticos", "content": NOTE_SISTEMAS, "visibility": "PUBLIC", "day": -23, "material": True},
            {"subject": "biomec", "title": "Palancas y momento de fuerza", "content": NOTE_PALANCAS, "visibility": "FRIENDS", "day": -17, "material": False},
        ],
        "quizzes": [],
        "review": {"diligence": 0.5, "qualities": (4, 3)},
        "deadlines": [
            {"key": "vo2", "title": "Informe de laboratorio: test de VO₂máx", "type": "ASSIGNMENT", "due": (-7, "23:59"), "difficulty": "MEDIUM", "subject": "fisio", "complete": -7},
            {"key": "biomec", "title": "Trabajo de Biomecánica: análisis de la sentadilla", "type": "ASSIGNMENT", "due": (6, "23:59"), "difficulty": "HIGH", "subject": "biomec",
             "description": "Análisis cinemático con vídeo en el plano sagital y Kinovea."},
            {"key": "examen_fisio", "title": "Examen de Fisiología del Ejercicio", "type": "EXAM", "due": (18, "10:00"), "difficulty": "MEDIUM", "subject": "fisio"},
        ],
        "challenges": [
            {"title": "24 sesiones en el bloque de fuerza", "type": "FITNESS", "goal": "Completar el bloque de fuerza sin saltarme sesiones.",
             "visibility": "PUBLIC", "difficulty": "HIGH", "start": -35, "end": 10, "sessionTarget": 24},
        ],
        "final_challenges": [
            {"title": "Entregar el trabajo de Biomecánica", "type": "ACADEMIC", "goal": "Terminar el análisis de la sentadilla a tiempo.",
             "visibility": "PUBLIC", "difficulty": "MEDIUM", "start": -3, "end": 7, "subject": "biomec",
             "milestones": [{"title": "Grabar los vídeos en el laboratorio", "weight": 30, "difficulty": "LOW", "complete_now": True},
                            {"title": "Análisis con Kinovea", "weight": 30, "difficulty": "MEDIUM", "block": ("biomec", 1)},
                            {"title": "Entregar el trabajo", "weight": 40, "difficulty": "HIGH", "deadline": "biomec"}]},
        ],
        "posts": [
            (-27, "SESSION_COMPLETED", "Sentadilla 145 kg x 3 limpia. El bloque va según lo previsto 🏋️"),
            (-13, "SESSION_COMPLETED", "Peso muerto 180 kg 🔥 Nuevo PR"),
            (-6, "ROUTINE", "Semana de descarga: menos volumen, misma técnica. El descanso también es entrenamiento."),
        ],
        "likes_p": 0.4, "comment_p": 0.2,
        "training_plan": {"plannedSessions": 6, "intensity": "HIGH", "minutesPerSession": 90},
        "training_plan_last": {"plannedSessions": 3, "intensity": "LOW", "minutesPerSession": 70, "notes": "Descarga: 50 % del volumen."},
        "study_plans": [],
        "weights": [(-28, 78.3), (-21, 78.6), (-14, 78.9), (-7, 79.2)],
        "wellbeing": {"stress": 3, "sleep": 8.0},
        "hide_badge": "Primeros pasos",
    },
    {
        "key": "sara",
        "email": "sara.lopez",
        "name": "Sara López",
        "privacy": "PUBLIC",
        "summary": "Doble Grado ADE + Informática (UEx), 2.º. Constante pero moderada (3 días), muy social: publica, comenta y da me gusta.",
        "wellness": {"age": 20, "sex": "FEMALE", "city": "Badajoz", "weightKg": 64, "heightCm": 169,
                     "activityLevel": "MODERATE", "primaryGoal": "METABOLIC_CONDITIONING",
                     "goals": ["Mejorar la resistencia", "Entrenar con amigas"],
                     "equipment": ["Gimnasio completo"], "availableDays": [1, 3, 5], "minutesPerSession": 50},
        "academic": {"semester": 3, "modality": "HYBRID", "semesterCredits": 36, "weeklyStudyHoursGoal": 10, "targetGpa": 3.8},
        "catalog": {"university": "Universidad de Extremadura", "degree": "Doble Grado en ADE e Ingeniería Informática en Ingeniería del Software",
                    "course": 2, "semester": 1},
        "subjects": {
            "conta": {"name": "CONTABILIDAD FINANCIERA II", "perceivedDifficulty": 4, "priority": "HIGH", "teacher": "Dra. Pilar Méndez"},
            "mof": {"name": "MATEMÁTICAS DE LAS OPERACIONES FINANCIERAS", "perceivedDifficulty": 4, "priority": "HIGH"},
            "adm": {"name": "ADMINISTRACIÓN DE LA EMPRESA", "perceivedDifficulty": 2, "priority": "MEDIUM"},
            "eco": {"name": "ESTADÍSTICA E INTRODUCCIÓN A LA ECONOMETRÍA", "perceivedDifficulty": 4, "priority": "MEDIUM"},
            "bd": {"name": "BASES DE DATOS", "perceivedDifficulty": 3, "priority": "MEDIUM"},
        },
        "manual_subjects": [],
        "notif": {"activeCategories": ["CONFLICT", "FATIGUE_ALERT", "MILESTONE", "SOCIAL", "ACADEMIC"],
                  "quietHoursStart": "00:00", "quietHoursEnd": "08:30", "dailyLimit": 30, "mode": "NORMAL"},
        "routine": {
            "name": "Full body 3 días · acondicionamiento", "visibility": "PUBLIC", "goal": "METABOLIC_CONDITIONING", "weeks": 8,
            "description": "Cuerpo completo en circuito con bici al final de cada sesión.",
            "week_types": ["ADAPTATION", "LOAD", "LOAD", "LOAD", "PEAK", "DELOAD", "LOAD", "PEAK"],
            "days": [
                (1, "Full body A", [("Hip thrust con barra", 3, 12, 90, 40), ("Jalón de pie con cuerda en polea alta", 3, 12, 60, 30),
                                     ("Zancada hacia atrás con mancuerna", 3, 12, 60, 6), ("Ciclismo indoor en bicicleta estática", 1, 1, 60, None, {"targetDurationSeconds": 900})]),
                (3, "Full body B", [("Prensa de piernas a 45°", 3, 12, 90, 80), ("Remo sentado en polea baja con agarre estrecho", 3, 12, 60, 30),
                                     ("Elevación lateral con mancuernas sentado", 3, 15, 60, 4), ("Salto a la comba", 3, 1, 60, None, {"targetDurationSeconds": 90})]),
                (5, "Full body C", [("Sentadilla sumo con mancuerna", 3, 15, 60, 10), ("Press de banca con mancuerna", 3, 12, 60, 8),
                                     ("Puente de glúteos", 3, 20, 60, None), ("Carrera en cinta rodante", 1, 1, 60, None, {"targetDurationSeconds": 1200, "distanceMeters": 3000})]),
            ],
        },
        "training": _sara_training,
        "checkin": _sara_checkin,
        "focus": lambda d, wd: [(25, "conta")] if wd < 5 and d % 2 == 0 else [],
        "classes": [
            (0, "09:00", "11:00", "conta", "THEORY", "Aula 0.5 · Facultad de Económicas"), (0, "11:00", "13:00", "mof", "THEORY", "Aula 0.5"),
            (1, "09:00", "11:00", "eco", "THEORY", "Aula 1.2"), (1, "11:00", "13:00", "bd", "PRACTICE", "Laboratorio 2"),
            (2, "09:00", "11:00", "adm", "THEORY", "Aula 0.5"), (2, "11:00", "13:00", "conta", "PRACTICE", "Aula 0.7"),
            (3, "09:00", "11:00", "mof", "PRACTICE", "Aula 0.7"), (3, "11:00", "13:00", "eco", "PRACTICE", "Aula de informática"),
        ],
        "class_p": 0.88,
        "study": [
            (0, "17:00", "19:00", "conta", "Provisiones: ejercicios del tema 5", "HIGH"),
            (1, "17:00", "18:30", "mof", "Rentas y préstamo francés", "HIGH"),
            (2, "17:00", "18:30", "eco", "Regresión lineal por MCO", "MEDIUM"),
            (3, "17:00", "19:00", "bd", "Normalización y SQL", "MEDIUM"),
        ],
        "study_p": 0.75,
        "sport_time": ("19:30", 55),
        "notes": [
            {"subject": "conta", "title": "Provisiones y contingencias", "content": NOTE_PROVISIONES, "visibility": "PUBLIC", "day": -24, "material": True},
            {"subject": "mof", "title": "Capitalización compuesta y TAE", "content": NOTE_TAE, "visibility": "PUBLIC", "day": -18, "material": True},
            {"subject": "adm", "title": "DAFO y cinco fuerzas de Porter", "content": NOTE_DAFO, "visibility": "FRIENDS", "day": -11, "material": False},
        ],
        "quizzes": [],
        "review": {"diligence": 0.7, "qualities": (4, 3, 4)},
        "deadlines": [
            {"key": "caso_prov", "title": "Caso práctico de provisiones", "type": "ASSIGNMENT", "due": (-8, "23:59"), "difficulty": "MEDIUM", "subject": "conta", "complete": -9},
            {"key": "dafo", "title": "Presentación: análisis DAFO de un gimnasio low-cost", "type": "PRESENTATION", "due": (5, "11:00"), "difficulty": "MEDIUM", "subject": "adm"},
            {"key": "parcial_mof", "title": "Parcial de Matemáticas Financieras", "type": "EXAM", "due": (10, "09:00"), "difficulty": "HIGH", "subject": "mof"},
            {"key": "examen_conta", "title": "Examen de Contabilidad Financiera II", "type": "EXAM", "due": (16, "09:00"), "difficulty": "HIGH", "subject": "conta"},
        ],
        "challenges": [
            {"title": "Tres entrenos por semana", "type": "FITNESS", "goal": "No bajar de tres entrenos semanales hasta noviembre.",
             "visibility": "PUBLIC", "difficulty": "MEDIUM", "start": -35, "end": 14, "sessionTarget": 18},
        ],
        "final_challenges": [
            {"title": "Cerrar Contabilidad Financiera II", "type": "ACADEMIC", "goal": "Llegar al examen con los casos prácticos resueltos.",
             "visibility": "PUBLIC", "difficulty": "HIGH", "start": -10, "end": 17, "subject": "conta",
             "milestones": [{"title": "Caso práctico de provisiones", "weight": 25, "difficulty": "MEDIUM", "deadline": "caso_prov"},
                            {"title": "Repasar el tema 5 en grupo", "weight": 25, "difficulty": "LOW", "block": ("conta", 1)},
                            {"title": "Examen de Contabilidad II", "weight": 50, "difficulty": "HIGH", "deadline": "examen_conta"}]},
        ],
        "posts": [
            (-33, "ROUTINE", "Primera semana con SynaptixFit: rutina full body lista y horario de clases importado 📅"),
            (-26, "SESSION_COMPLETED", "Sesión de pierna con las chicas del grupo 💪 ¿Quién se apunta el jueves?"),
            (-19, "CHALLENGE", "Me he propuesto tres entrenos por semana hasta noviembre. ¿Alguien se une al reto?"),
            (-14, "SESSION_COMPLETED", "Hoy tocaba bici + comba y casi muero, pero aquí sigo 😂"),
            (-8, "MILESTONE_REACHED", "Caso práctico de provisiones entregado. Contabilidad, no podrás conmigo 📚"),
            (-4, "SESSION_COMPLETED", "Cuatro entrenos esta semana. Me estoy viniendo arriba 🔥"),
            (-1, "ROUTINE", "Domingo de planificar la semana: estudio por la mañana, gym por la tarde ✨"),
        ],
        "likes_p": 0.95, "comment_p": 0.45,
        "training_plan": {"plannedSessions": 3, "intensity": "MODERATE", "minutesPerSession": 50},
        "training_plan_last": {"plannedSessions": 4, "intensity": "MODERATE", "minutesPerSession": 55},
        "study_plans": [(-3, "Semana organizada"), (-2, "Casos prácticos"), (0, "Presentación DAFO")],
        "weights": [(-21, 63.6), (-7, 63.1)],
        "wellbeing": {"stress": 4, "sleep": 7.5},
    },
    {
        "key": "admin",
        "email": "admin",
        "name": "Admin Demo SynaptixFit",
        "privacy": "PRIVATE",
        "summary": "Cuenta de administración para el panel de administración (usuarios, métricas, moderación, auditoría y catálogo de ejercicios).",
        "admin": True,
        "wellness": {"age": 30, "sex": "PREFER_NOT_TO_SAY", "city": "Madrid", "weightKg": 70, "heightCm": 172,
                     "activityLevel": "LIGHT", "primaryGoal": "MOBILITY", "goals": [], "equipment": [],
                     "availableDays": [2, 4], "minutesPerSession": 30},
        "academic": {"university": "Equipo SynaptixFit", "degree": "Administración de la plataforma", "semester": 1,
                     "modality": "ONLINE", "semesterCredits": 6, "weeklyStudyHoursGoal": 0},
        "catalog": None,
        "subjects": {},
        "manual_subjects": [{"key": "ops", "name": "Operación de la plataforma", "credits": 1, "perceivedDifficulty": 1, "priority": "LOW"}],
        "notif": None,
    },
]

# Amistades: (día, quién envía, quién recibe, día en que se acepta o None si queda pendiente).
FRIENDSHIPS = [
    (-34, "sara", "lucia", -34), (-34, "sara", "pablo", -33), (-33, "sara", "marta", -33), (-32, "sara", "andres", -32),
    (-32, "lucia", "pablo", -31), (-30, "lucia", "marta", -30), (-29, "andres", "pablo", -29), (-25, "lucia", "andres", -24),
    (-2, "andres", "marta", None),
]
