"""Textos de la tanda 5 «Añadir al calendario en dos pasos» (ADR 0070) en es/en/fr/pt.

Uso: python tool/l10n_add_sheet_tanda5.py && dart run tool/merge_arb.dart && flutter gen-l10n
"""
import json
from collections import OrderedDict
from pathlib import Path

PARTS = Path(__file__).resolve().parent.parent / 'lib' / 'presentation' / 'l10n' / 'parts'
LANGS = ('es', 'en', 'fr', 'pt')

# clave: (es, en, fr, pt)
TEXTS = {
    'plannerAddStepWhat': ('¿Qué quieres añadir?', 'What do you want to add?', 'Que veux-tu ajouter ?',
                           'O que queres adicionar?'),
    'plannerAddKindDeadline': ('Entrega o examen', 'Deadline or exam', 'Rendu ou examen', 'Entrega ou exame'),
    'plannerAddKindGym': ('Gimnasio', 'Gym', 'Salle de sport', 'Ginásio'),
    'plannerAddKindSport': ('Deporte', 'Sport', 'Sport', 'Desporto'),
    'plannerAddKindRest': ('Descanso, comida o sueño', 'Rest, meal or sleep', 'Repos, repas ou sommeil',
                           'Descanso, refeição ou sono'),
    'plannerAddChangeKind': ('Cambiar tipo', 'Change type', 'Changer de type', 'Mudar tipo'),
    # Acción principal: «Añadir estudio», «Añadir partido de pádel», «Añadir WOD».
    'plannerAddWhat': ('Añadir {what}', 'Add {what}', 'Ajouter {what}', 'Adicionar {what}'),
    'plannerAddGymWhat': ('entreno de gimnasio', 'gym workout', 'séance de salle', 'treino de ginásio'),
    'plannerAddPersonalWhat': ('evento personal', 'personal event', 'événement personnel', 'evento pessoal'),
    'plannerAddGymFree': ('Sesión libre', 'Free session', 'Séance libre', 'Sessão livre'),
    'plannerAddSportWhich': ('¿Cuál?', 'Which one?', 'Lequel ?', 'Qual?'),
    'plannerAddSportMode': ('¿Partido o entreno?', 'Match or training?', 'Match ou entraînement ?',
                            'Jogo ou treino?'),
    'plannerAddSportMatchOf': ('Partido de {sport}', '{sport} match', 'Match de {sport}', 'Jogo de {sport}'),
    'plannerAddSportTrainingOf': ('Entreno de {sport}', '{sport} training', 'Entraînement de {sport}',
                                  'Treino de {sport}'),
    'plannerAddSportOtherName': ('¿Qué deporte?', 'Which sport?', 'Quel sport ?', 'Que desporto?'),
    'plannerAddRestWhich': ('¿Cuál de los tres?', 'Which of the three?', 'Lequel des trois ?', 'Qual dos três?'),
    'plannerAddSpreadBack': ('Añadir solo un entreno', 'Add just one workout', 'Ajouter une seule séance',
                             'Adicionar só um treino'),
    'plannerFieldRoom': ('Aula', 'Room', 'Salle', 'Sala'),
    # «Distribuir rutina» pasa a llamarse así y vive dentro de «Gimnasio».
    'plannerDistributeAction': ('Repartir mi rutina en la semana', 'Spread my routine across the week',
                                'Répartir ma routine sur la semaine', 'Distribuir a minha rotina pela semana'),
}

STRING = {'type': 'String'}
META = {
    'plannerAddWhat': {'placeholders': {'what': STRING}},
    'plannerAddSportMatchOf': {'placeholders': {'sport': STRING}},
    'plannerAddSportTrainingOf': {'placeholders': {'sport': STRING}},
}

# Sin uso desde que la hoja no lleva pestañas.
REMOVED = ('plannerTabBlock', 'plannerTabRoutine')


def write(lang, texts):
    path = PARTS / f'app_{lang}_planner.arb'
    data = json.loads(path.read_text(encoding='utf-8'), object_pairs_hook=OrderedDict)
    for key in REMOVED:
        data.pop(key, None)
        data.pop('@' + key, None)
    for key, value in texts.items():
        data[key] = value
        if lang == 'es' and key in META:
            data['@' + key] = META[key]
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')


for index, lang in enumerate(LANGS):
    write(lang, {k: v[index] for k, v in TEXTS.items()})
    print(lang, len(TEXTS))
