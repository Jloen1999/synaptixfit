# 0018. Leer la matrícula sin guardar el documento y sin enviar datos personales a la IA

* **Estado:** Aprobado
* **Fecha:** 2026-10-24
* **Autores:** SynaptixFit

## Contexto
Añadir las asignaturas una a una es lento. La carta de pago o el resguardo de matrícula las trae todas,
pero también trae datos sensibles: nombre, DNI o NIE, domicilio, cuenta bancaria, importes y
referencias de pago. Reconocer formatos de universidades distintas pide IA (DeepSeek, proveedor
externo), y no queremos que esos datos salgan del servidor ni que se guarden.

## Decisión
* **Permiso expreso cada vez.** La pantalla explica qué se lee, qué se quita y que el documento no se
  guarda; sin marcar el permiso no se puede elegir el PDF, y el servidor rechaza la lectura sin
  `consent=true` (`ENROLLMENT_CONSENT_REQUIRED`).
* **Nada se guarda.** El PDF se lee en memoria (PDFBox; hasta 6 MB Spring no crea archivo temporal,
  `spring.servlet.multipart.file-size-threshold`), se extrae el texto y se descarta. No hay
  tabla ni archivo en R2. Solo se guarda lo que el usuario elige después: su carrera y sus asignaturas.
* **Minimización antes de la IA.** `PersonalDataRedactor` (dominio) quita DNI/NIE, IBAN y cuentas,
  correos, teléfonos y series de 9 o más cifras, las líneas con etiquetas personales (alumno,
  domicilio, NIF, cuenta…), las que empiezan por un código postal y las que contienen dos o más
  palabras del nombre del usuario. La IA recibe solo ese texto y solo se le pide centro, titulación,
  curso y asignaturas.
* **El usuario decide.** La lectura se cruza con el catálogo (universidad, carrera y asignaturas) y se
  muestra para revisar; se añaden solo las elegidas (`ApplyEnrollmentUseCase`).

## Consecuencias
* **Positivas:** alta de asignaturas en un paso; ningún dato personal de la matrícula persiste ni llega
  al proveedor de IA de forma reconocible; cumple minimización y limitación de la finalidad (RGPD).
* **Negativas:** el filtrado es por reglas: un formato raro podría dejar pasar un dato suelto (por eso
  el permiso explica que el texto restante lo lee la IA). En concreto, un nombre sin etiqueta que no
  coincida con el de la cuenta (o si la cuenta tiene una sola palabra) no se quita; un PDF escaneado (sin texto) no se puede leer
  (`AI_ATTACHMENT_UNSUPPORTED`). Los tests usan solo datos inventados.
