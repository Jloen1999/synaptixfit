"""Textos de la tanda 4 «WOD» (ADR 0069) en es/en/fr/pt.

Uso: python tool/l10n_wod_tanda4.py && dart run tool/merge_arb.dart && flutter gen-l10n
"""
import json
from collections import OrderedDict
from pathlib import Path

PARTS = Path(__file__).resolve().parent.parent / 'lib' / 'presentation' / 'l10n' / 'parts'
LANGS = ('es', 'en', 'fr', 'pt')

# clave: (es, en, fr, pt)
TEXTS = {
    'trainingSectionWod': ('WOD', 'WOD', 'WOD', 'WOD'),
    # Pizarra.
    'wodAddMine': ('Añadir mi WOD', 'Add my WOD', 'Ajouter mon WOD', 'Adicionar o meu WOD'),
    'wodExamplePill': ('WOD de ejemplo', 'Example WOD', 'WOD d’exemple', 'WOD de exemplo'),
    'wodEdit': ('Editar', 'Edit', 'Modifier', 'Editar'),
    'wodChangeExample': ('Cambiar por otro', 'Pick another', 'En choisir un autre', 'Trocar por outro'),
    'wodTemplatesTitle': ('Elige un WOD de ejemplo', 'Pick an example WOD', 'Choisis un WOD d’exemple',
                          'Escolhe um WOD de exemplo'),
    'wodDefaultTitle': ('WOD de hoy', 'Today’s WOD', 'WOD du jour', 'WOD de hoje'),
    'wodBoardLabel': ('Pizarra del WOD', 'WOD board', 'Tableau du WOD', 'Quadro do WOD'),
    'wodFormatForTime': ('Por tiempo', 'For time', 'Contre la montre', 'Por tempo'),
    'wodFormatAmrap': ('AMRAP', 'AMRAP', 'AMRAP', 'AMRAP'),
    'wodFormatEmom': ('EMOM', 'EMOM', 'EMOM', 'EMOM'),
    'wodFormatTabata': ('Tabata', 'Tabata', 'Tabata', 'Tabata'),
    'wodFormatHelpForTime': (
        'Haz todo lo antes posible.',
        'Do everything as fast as you can.',
        'Fais tout le plus vite possible.',
        'Faz tudo o mais depressa possível.'),
    'wodFormatHelpAmrap': (
        'Haz todas las rondas que puedas antes de que se acabe el tiempo.',
        'Do as many rounds as you can before time runs out.',
        'Fais autant de tours que possible avant la fin du temps.',
        'Faz todas as rondas que conseguires antes de o tempo acabar.'),
    'wodFormatHelpEmom': (
        'Cada minuto haz lo que pone y descansa lo que sobre.',
        'Every minute, do what it says and rest for what is left.',
        'Chaque minute, fais ce qui est écrit et repose-toi le temps restant.',
        'A cada minuto faz o que está escrito e descansa o que sobrar.'),
    'wodFormatHelpTabata': (
        '8 rondas: 20 segundos a tope y 10 de descanso.',
        '8 rounds: 20 seconds all out and 10 of rest.',
        '8 tours : 20 secondes à fond et 10 de repos.',
        '8 rondas: 20 segundos a fundo e 10 de descanso.'),
    'wodHeadlineRounds': (
        '{count, plural, =0{0 rondas} =1{1 ronda} other{{count} rondas}}',
        '{count, plural, =0{0 rounds} =1{1 round} other{{count} rounds}}',
        '{count, plural, =0{0 tour} =1{1 tour} other{{count} tours}}',
        '{count, plural, =0{0 rondas} =1{1 ronda} other{{count} rondas}}'),
    'wodHeadlineMinutes': ('{format} {minutes} min', '{format} {minutes} min', '{format} {minutes} min',
                           '{format} {minutes} min'),
    'wodTimeCap': ('Límite: {minutes} min', 'Time cap: {minutes} min', 'Limite : {minutes} min',
                   'Limite: {minutes} min'),
    'wodNoTimeCap': ('Sin límite de tiempo', 'No time cap', 'Sans limite de temps', 'Sem limite de tempo'),
    'wodStrength': ('Fuerza', 'Strength', 'Force', 'Força'),
    'wodMaxReps': ('Las que puedas', 'As many as you can', 'Le plus possible', 'As que conseguires'),
    'wodQuantityCalories': ('{count} cal', '{count} cal', '{count} cal', '{count} cal'),
    'wodQuantityMeters': ('{count} m', '{count} m', '{count} m', '{count} m'),
    'wodKg': ('{kg} kg', '{kg} kg', '{kg} kg', '{kg} kg'),
    'wodDivisionLabel': ('¿Cómo lo haces?', 'How are you doing it?', 'Comment le fais-tu ?', 'Como o fazes?'),
    'wodDivisionRx': ('Rx', 'Rx', 'Rx', 'Rx'),
    'wodDivisionScaled': ('Adaptado', 'Scaled', 'Adapté', 'Adaptado'),
    'wodDivisionRxSpoken': ('Rx, tal cual está escrito', 'Rx, as written', 'Rx, tel qu’il est écrit',
                            'Rx, tal como está escrito'),
    'wodDivisionHelp': (
        'Rx = tal cual está escrito. Adaptado = con menos peso o un movimiento más fácil.',
        'Rx = as written. Scaled = with less weight or an easier movement.',
        'Rx = tel qu’il est écrit. Adapté = avec moins de poids ou un mouvement plus facile.',
        'Rx = tal como está escrito. Adaptado = com menos peso ou um movimento mais fácil.'),
    'wodBestMark': ('Tu mejor marca: {score}', 'Your best: {score}', 'Ton record : {score}',
                    'A tua melhor marca: {score}'),
    'wodNoBestMark': ('Aún no tienes marca en este WOD', 'No result for this WOD yet',
                      'Pas encore de résultat pour ce WOD', 'Ainda não tens marca neste WOD'),
    'wodTodayMark': ('Hoy: {score}', 'Today: {score}', 'Aujourd’hui : {score}', 'Hoje: {score}'),
    'wodTodayNone': ('Hoy aún no lo has hecho', 'Not done today yet', 'Pas encore fait aujourd’hui',
                     'Hoje ainda não o fizeste'),
    'wodStartTimer': ('Empezar cronómetro', 'Start timer', 'Lancer le chrono', 'Iniciar cronómetro'),
    'wodLogMark': ('Apuntar marca', 'Log result', 'Noter mon résultat', 'Registar marca'),
    # Mis marcas.
    'wodMarksTitle': ('Mis marcas', 'My results', 'Mes résultats', 'As minhas marcas'),
    'wodMarksEmptyTitle': ('Aún no tienes marcas', 'No results yet', 'Pas encore de résultats',
                           'Ainda não tens marcas'),
    'wodMarksEmptyMessage': (
        'Haz el WOD de hoy y guarda cómo te fue: aquí verás tus mejores marcas.',
        'Do today’s WOD and save how it went: your best results will show up here.',
        'Fais le WOD du jour et note ton résultat : tes records apparaîtront ici.',
        'Faz o WOD de hoje e guarda como correu: aqui vais ver as tuas melhores marcas.'),
    'wodMarkBest': ('Mejor marca', 'Best', 'Record', 'Melhor marca'),
    'wodScoreRoundsReps': (
        '{rounds, plural, =0{0 rondas} =1{1 ronda} other{{rounds} rondas}} + {reps} reps',
        '{rounds, plural, =0{0 rounds} =1{1 round} other{{rounds} rounds}} + {reps} reps',
        '{rounds, plural, =0{0 tour} =1{1 tour} other{{rounds} tours}} + {reps} reps',
        '{rounds, plural, =0{0 rondas} =1{1 ronda} other{{rounds} rondas}} + {reps} reps'),
    'wodScoreReps': (
        '{count, plural, =0{0 repeticiones} =1{1 repetición} other{{count} repeticiones}}',
        '{count, plural, =0{0 reps} =1{1 rep} other{{count} reps}}',
        '{count, plural, =0{0 répétition} =1{1 répétition} other{{count} répétitions}}',
        '{count, plural, =0{0 repetições} =1{1 repetição} other{{count} repetições}}'),
    'wodScoreCapped': ('Sin terminar: {score}', 'Not finished: {score}', 'Non terminé : {score}',
                       'Por terminar: {score}'),
    'wodMarkLine': ('{score} · {division}', '{score} · {division}', '{score} · {division}',
                    '{score} · {division}'),
    'wodMarkSaved': (
        'Marca guardada. La tienes en Entreno › WOD › Mis marcas.',
        'Result saved. Find it in Training › WOD › My results.',
        'Résultat enregistré. Retrouve-le dans Sport › WOD › Mes résultats.',
        'Marca guardada. Encontras em Treino › WOD › As minhas marcas.'),
    'wodMarkSavedBest': (
        '¡Mejor marca! La tienes en Entreno › WOD › Mis marcas.',
        'New best! Find it in Training › WOD › My results.',
        'Nouveau record ! Retrouve-le dans Sport › WOD › Mes résultats.',
        'Melhor marca! Encontras em Treino › WOD › As minhas marcas.'),
    # Hoja de la marca.
    'wodResultTitle': ('¿Cómo te fue?', 'How did it go?', 'Comment ça s’est passé ?', 'Como correu?'),
    'wodResultMinutes': ('Minutos', 'Minutes', 'Minutes', 'Minutos'),
    'wodResultSeconds': ('Segundos', 'Seconds', 'Secondes', 'Segundos'),
    'wodResultRounds': ('Rondas completas', 'Full rounds', 'Tours complets', 'Rondas completas'),
    'wodResultExtraReps': ('Repeticiones de más', 'Extra reps', 'Répétitions en plus', 'Repetições a mais'),
    'wodResultReps': ('Repeticiones', 'Reps', 'Répétitions', 'Repetições'),
    'wodResultCapped': ('No terminé a tiempo', 'I didn’t finish in time', 'Je n’ai pas fini à temps',
                        'Não terminei a tempo'),
    'wodResultCappedHelp': (
        'Apunta las repeticiones que llevabas.',
        'Log the reps you had done.',
        'Note les répétitions que tu avais faites.',
        'Regista as repetições que levavas.'),
    'wodResultSave': ('Guardar marca', 'Save result', 'Enregistrer', 'Guardar marca'),
    'wodResultInvalid': ('Escribe tu marca para guardarla.', 'Enter your result to save it.',
                         'Saisis ton résultat pour l’enregistrer.', 'Escreve a tua marca para a guardar.'),
    # WOD en marcha.
    'wodLivePause': ('Pausa', 'Pause', 'Pause', 'Pausa'),
    'wodLiveResume': ('Seguir', 'Resume', 'Reprendre', 'Continuar'),
    'wodLiveFinish': ('Terminar', 'Finish', 'Terminer', 'Terminar'),
    'wodLivePaused': ('En pausa', 'Paused', 'En pause', 'Em pausa'),
    'wodLiveWork': ('Trabajo', 'Work', 'Effort', 'Trabalho'),
    'wodLiveRest': ('Descanso', 'Rest', 'Repos', 'Descanso'),
    'wodLiveRoundOf': ('Ronda {round} de {total}', 'Round {round} of {total}', 'Tour {round} sur {total}',
                       'Ronda {round} de {total}'),
    'wodLiveMinuteOf': ('Minuto {round} de {total}', 'Minute {round} of {total}', 'Minute {round} sur {total}',
                        'Minuto {round} de {total}'),
    'wodLiveTimeLeft': ('Quedan', 'Time left', 'Il reste', 'Faltam'),
    'wodLiveElapsed': ('Llevas', 'Elapsed', 'Temps écoulé', 'Levas'),
    'wodLiveTimeUp': ('¡Tiempo!', 'Time!', 'Temps !', 'Tempo!'),
    'wodLiveClockLabel': ('Cronómetro: {time}', 'Timer: {time}', 'Chrono : {time}', 'Cronómetro: {time}'),
    'wodLiveAnnounceWork': ('Ronda {round}: trabajo', 'Round {round}: work', 'Tour {round} : effort',
                            'Ronda {round}: trabalho'),
    'wodLiveAnnounceRest': ('Descanso', 'Rest', 'Repos', 'Descanso'),
    'wodLiveAnnounceMinute': ('Minuto {round}', 'Minute {round}', 'Minute {round}', 'Minuto {round}'),
    'wodLiveAnnounceDone': ('Tiempo. WOD terminado.', 'Time. WOD finished.', 'Temps. WOD terminé.',
                            'Tempo. WOD terminado.'),
    'wodLiveExitTitle': ('¿Salir del WOD?', 'Leave the WOD?', 'Quitter le WOD ?', 'Sair do WOD?'),
    'wodLiveExitMessage': (
        'El cronómetro se perderá y no se guardará ninguna marca.',
        'The timer will be lost and no result will be saved.',
        'Le chrono sera perdu et aucun résultat ne sera enregistré.',
        'O cronómetro perde-se e não se guarda nenhuma marca.'),
    'wodLiveExitConfirm': ('Salir', 'Leave', 'Quitter', 'Sair'),
    'wodLiveExitStay': ('Seguir con el WOD', 'Stay in the WOD', 'Rester dans le WOD', 'Continuar o WOD'),
    'wodLiveMissingTitle': ('No hay ningún WOD en marcha', 'No WOD in progress', 'Aucun WOD en cours',
                            'Não há nenhum WOD em curso'),
    'wodLiveMissingMessage': (
        'Vuelve a Entreno › WOD y toca «Empezar cronómetro».',
        'Go back to Training › WOD and tap “Start timer”.',
        'Retourne dans Sport › WOD et touche « Lancer le chrono ».',
        'Volta a Treino › WOD e toca em «Iniciar cronómetro».'),
    'wodLiveGoToWod': ('Ir a WOD', 'Go to WOD', 'Aller à WOD', 'Ir para WOD'),
    'wodLiveTitle': ('WOD en marcha', 'WOD in progress', 'WOD en cours', 'WOD em curso'),
    # Editor.
    'wodEditorNewTitle': ('Mi WOD', 'My WOD', 'Mon WOD', 'O meu WOD'),
    'wodEditorEditTitle': ('Editar WOD', 'Edit WOD', 'Modifier le WOD', 'Editar WOD'),
    'wodEditorName': ('Título (opcional)', 'Title (optional)', 'Titre (facultatif)', 'Título (opcional)'),
    'wodEditorFormat': ('Formato', 'Format', 'Format', 'Formato'),
    'wodEditorTimeCap': ('Límite de tiempo', 'Time cap', 'Limite de temps', 'Limite de tempo'),
    'wodEditorDuration': ('Duración', 'Duration', 'Durée', 'Duração'),
    'wodEditorMinutes': ('{minutes} min', '{minutes} min', '{minutes} min', '{minutes} min'),
    'wodEditorNoCap': ('Sin límite', 'No cap', 'Sans limite', 'Sem limite'),
    'wodEditorRounds': ('Rondas', 'Rounds', 'Tours', 'Rondas'),
    'wodEditorStrength': ('Parte de fuerza (opcional)', 'Strength part (optional)',
                          'Partie force (facultatif)', 'Parte de força (opcional)'),
    'wodEditorStrengthHint': ('Ej.: Sentadilla 5 × 5', 'E.g. Squat 5 × 5', 'Ex. : Squat 5 × 5',
                              'Ex.: Agachamento 5 × 5'),
    'wodEditorMovements': ('Movimientos', 'Movements', 'Mouvements', 'Movimentos'),
    'wodEditorMovementN': ('Movimiento {n}', 'Movement {n}', 'Mouvement {n}', 'Movimento {n}'),
    'wodEditorMovementName': ('Nombre', 'Name', 'Nom', 'Nome'),
    'wodEditorQuantity': ('Cantidad', 'Amount', 'Quantité', 'Quantidade'),
    'wodEditorUnit': ('Unidad', 'Unit', 'Unité', 'Unidade'),
    'wodUnitNameReps': ('Repeticiones', 'Reps', 'Répétitions', 'Repetições'),
    'wodUnitNameCalories': ('Calorías', 'Calories', 'Calories', 'Calorias'),
    'wodUnitNameMeters': ('Metros', 'Metres', 'Mètres', 'Metros'),
    'wodEditorRxKg': ('Kg Rx (opcional)', 'Rx kg (optional)', 'Kg Rx (facultatif)', 'Kg Rx (opcional)'),
    'wodEditorScaledKg': ('Kg adaptado (opcional)', 'Scaled kg (optional)', 'Kg adapté (facultatif)',
                          'Kg adaptado (opcional)'),
    'wodEditorAddMovement': ('Añadir movimiento', 'Add movement', 'Ajouter un mouvement',
                             'Adicionar movimento'),
    'wodEditorRemoveMovement': ('Quitar movimiento {n}', 'Remove movement {n}', 'Retirer le mouvement {n}',
                                'Remover movimento {n}'),
    'wodEditorSave': ('Guardar WOD', 'Save WOD', 'Enregistrer le WOD', 'Guardar WOD'),
    'wodEditorDelete': ('Eliminar WOD', 'Delete WOD', 'Supprimer le WOD', 'Eliminar WOD'),
    'wodEditorDeleteTitle': ('¿Eliminar este WOD?', 'Delete this WOD?', 'Supprimer ce WOD ?',
                             'Eliminar este WOD?'),
    'wodEditorDeleteMessage': (
        'Se borrarán también sus marcas. Los entrenos ya apuntados se quedan.',
        'Its results will be deleted too. Workouts already logged stay.',
        'Ses résultats seront supprimés aussi. Les séances déjà notées restent.',
        'As suas marcas também são apagadas. Os treinos já registados ficam.'),
    'wodEditorNeedsMovement': (
        'Añade al menos un movimiento con nombre.',
        'Add at least one movement with a name.',
        'Ajoute au moins un mouvement avec un nom.',
        'Adiciona pelo menos um movimento com nome.'),
    'wodEditorTabataNote': (
        'Tabata dura siempre 4 minutos: 8 rondas de 20 segundos y 10 de descanso.',
        'Tabata always lasts 4 minutes: 8 rounds of 20 seconds and 10 of rest.',
        'Un Tabata dure toujours 4 minutes : 8 tours de 20 secondes et 10 de repos.',
        'Tabata dura sempre 4 minutos: 8 rondas de 20 segundos e 10 de descanso.'),
    'wodSavedWhere': ('WOD guardado. Lo tienes en Entreno › WOD.', 'WOD saved. Find it in Training › WOD.',
                      'WOD enregistré. Retrouve-le dans Sport › WOD.',
                      'WOD guardado. Encontras em Treino › WOD.'),
    'wodDeleted': ('WOD eliminado.', 'WOD deleted.', 'WOD supprimé.', 'WOD eliminado.'),
    'wodErrorNotFound': ('Ese WOD ya no existe.', 'That WOD no longer exists.', 'Ce WOD n’existe plus.',
                         'Esse WOD já não existe.'),
    # Plantillas de ejemplo: nombres propios y neutros.
    'wodTemplateTripleTen': ('Triple diez', 'Triple ten', 'Triple dix', 'Triplo dez'),
    'wodTemplateTwelveNonstop': ('Doce sin parar', 'Twelve non-stop', 'Douze sans arrêt', 'Doze sem parar'),
    'wodTemplateMinuteByMinute': ('Minuto a minuto', 'Minute by minute', 'Minute par minute',
                                  'Minuto a minuto'),
    'wodTemplateFourMinutes': ('Cuatro minutos', 'Four minutes', 'Quatre minutes', 'Quatro minutos'),
    'wodTemplateRunAndPush': ('Corre y empuja', 'Run and push', 'Cours et pousse', 'Corre e empurra'),
    'wodTemplateTwoDumbbells': ('Dos mancuernas', 'Two dumbbells', 'Deux haltères', 'Dois halteres'),
    'wodTemplateSwingClock': ('Reloj de balanceos', 'Swing clock', 'L’horloge des balancés',
                              'Relógio de balanços'),
    'wodTemplateLongList': ('La lista larga', 'The long list', 'La longue liste', 'A lista longa'),
    # Movimientos de las plantillas.
    'wodMoveAirSquat': ('Sentadillas', 'Air squats', 'Squats', 'Agachamentos'),
    'wodMovePushUp': ('Flexiones', 'Push-ups', 'Pompes', 'Flexões'),
    'wodMoveSitUp': ('Abdominales', 'Sit-ups', 'Abdos', 'Abdominais'),
    'wodMoveBurpee': ('Burpees', 'Burpees', 'Burpees', 'Burpees'),
    'wodMoveLunge': ('Zancadas', 'Lunges', 'Fentes', 'Afundos'),
    'wodMoveRun': ('Carrera', 'Run', 'Course', 'Corrida'),
    'wodMoveDumbbellThruster': ('Sentadilla con empuje (mancuernas)', 'Dumbbell thrusters',
                                'Thrusters avec haltères', 'Agachamento com impulso (halteres)'),
    'wodMoveDumbbellRow': ('Remo con mancuerna', 'Dumbbell rows', 'Rowing avec haltère', 'Remada com haltere'),
    'wodMoveKettlebellSwing': ('Balanceo con pesa rusa', 'Kettlebell swings', 'Balancés de kettlebell',
                               'Balanço com kettlebell'),
    'wodMoveJumpRope': ('Saltos de comba', 'Rope jumps', 'Sauts à la corde', 'Saltos à corda'),
}

INT = {'type': 'int'}
STRING = {'type': 'String'}
META = {
    'wodHeadlineRounds': {'placeholders': {'count': INT}},
    'wodHeadlineMinutes': {'placeholders': {'format': STRING, 'minutes': INT}},
    'wodTimeCap': {'placeholders': {'minutes': INT}},
    'wodQuantityCalories': {'placeholders': {'count': INT}},
    'wodQuantityMeters': {'placeholders': {'count': INT}},
    'wodKg': {'placeholders': {'kg': STRING}},
    'wodBestMark': {'placeholders': {'score': STRING}},
    'wodTodayMark': {'placeholders': {'score': STRING}},
    'wodScoreRoundsReps': {'placeholders': {'rounds': INT, 'reps': INT}},
    'wodScoreReps': {'placeholders': {'count': INT}},
    'wodScoreCapped': {'placeholders': {'score': STRING}},
    'wodMarkLine': {'placeholders': {'score': STRING, 'division': STRING}},
    'wodLiveRoundOf': {'placeholders': {'round': INT, 'total': INT}},
    'wodLiveMinuteOf': {'placeholders': {'round': INT, 'total': INT}},
    'wodLiveClockLabel': {'placeholders': {'time': STRING}},
    'wodLiveAnnounceWork': {'placeholders': {'round': INT}},
    'wodLiveAnnounceMinute': {'placeholders': {'round': INT}},
    'wodEditorMinutes': {'placeholders': {'minutes': INT}},
    'wodEditorMovementN': {'placeholders': {'n': INT}},
    'wodEditorRemoveMovement': {'placeholders': {'n': INT}},
}


def write(lang, texts):
    path = PARTS / f'app_{lang}_training.arb'
    data = json.loads(path.read_text(encoding='utf-8'), object_pairs_hook=OrderedDict)
    for key, value in texts.items():
        data[key] = value
        if lang == 'es' and key in META:
            data['@' + key] = META[key]
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')


for index, lang in enumerate(LANGS):
    write(lang, {k: v[index] for k, v in TEXTS.items()})
    print(lang, len(TEXTS))
