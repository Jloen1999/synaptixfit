"""Textos de la tanda 3 «Deportes» (ADR 0068) en es/en/fr/pt.

Uso: python tool/l10n_sports_tanda3.py && dart run tool/merge_arb.dart && flutter gen-l10n
"""
import json
from collections import OrderedDict
from pathlib import Path

PARTS = Path(__file__).resolve().parent.parent / 'lib' / 'presentation' / 'l10n' / 'parts'
LANGS = ('es', 'en', 'fr', 'pt')

# clave: (es, en, fr, pt)
TEXTS = {
    # Cambios de textos que ya existían.
    'trainingSectionRun': ('Deportes', 'Sports', 'Sports', 'Desportos'),
    'runCreateWorkout': ('Crear entreno guiado', 'Create guided workout', 'Créer un entraînement guidé',
                         'Criar treino guiado'),
    'runWorkoutsEmptyMessage': (
        'Crea uno con «Crear entreno guiado»: te guía paso a paso mientras corres.',
        'Create one with “Create guided workout”: it guides you step by step while you run.',
        'Crée-en un avec « Créer un entraînement guidé » : il te guide pas à pas pendant la course.',
        'Cria um com «Criar treino guiado»: guia-te passo a passo enquanto corres.'),
    'runWorkoutSavedWhere': (
        'Entreno guardado. Lo tienes en Entreno › Deportes › Entrenos guiados.',
        'Workout saved. Find it in Training › Sports › Guided workouts.',
        'Entraînement enregistré. Retrouve-le dans Sport › Sports › Entraînements guidés.',
        'Treino guardado. Encontras em Treino › Desportos › Treinos guiados.'),
    'trainingPastActivitySavedRun': (
        'Actividad apuntada. La tienes en Entreno › Deportes › Últimas actividades.',
        'Activity logged. Find it in Training › Sports › Latest activities.',
        'Activité notée. Retrouve-la dans Sport › Sports › Dernières activités.',
        'Atividade registada. Encontras em Treino › Desportos › Últimas atividades.'),
    'runActivitiesEmptyMessage': (
        'Elige un deporte arriba y apunta lo que hiciste, o graba tu primera carrera.',
        'Pick a sport above and log what you did, or record your first run.',
        'Choisis un sport ci-dessus et note ce que tu as fait, ou enregistre ta première course.',
        'Escolhe um desporto acima e regista o que fizeste, ou grava a tua primeira corrida.'),
    # Rejilla de deportes.
    'sportsGridTitle': ('Elige un deporte', 'Pick a sport', 'Choisis un sport', 'Escolhe um desporto'),
    'sportEnduranceTitle': ('Correr, andar o bici', 'Run, walk or bike', 'Courir, marcher ou vélo',
                            'Correr, andar ou bicicleta'),
    'sportEnduranceSubtitle': ('Con GPS o apuntado', 'With GPS or logged', 'Avec GPS ou noté',
                               'Com GPS ou registado'),
    'sportFootball': ('Fútbol', 'Football', 'Football', 'Futebol'),
    'sportPadel': ('Pádel', 'Padel', 'Padel', 'Padel'),
    'sportSwim': ('Natación', 'Swimming', 'Natation', 'Natação'),
    'sportBasketball': ('Baloncesto', 'Basketball', 'Basket', 'Basquetebol'),
    'sportTennis': ('Tenis', 'Tennis', 'Tennis', 'Ténis'),
    'sportVolleyball': ('Vóley', 'Volleyball', 'Volley', 'Voleibol'),
    'sportOther': ('Otro deporte', 'Another sport', 'Autre sport', 'Outro desporto'),
    'sportMatchSubtitle': ('Partido o entreno', 'Match or practice', 'Match ou entraînement', 'Jogo ou treino'),
    'sportSwimSubtitle': ('Largos y metros', 'Laps and metres', 'Longueurs et mètres', 'Piscinas e metros'),
    'sportOtherSubtitle': ('Yoga, escalada, baile…', 'Yoga, climbing, dance…', 'Yoga, escalade, danse…',
                           'Ioga, escalada, dança…'),
    # Correr, andar o bici.
    'sportRunStart': ('Empezar', 'Start', 'Commencer', 'Começar'),
    'sportRunStartHint': ('Graba la ruta con el GPS del móvil.', 'Records your route with your phone’s GPS.',
                          'Enregistre le parcours avec le GPS du téléphone.',
                          'Grava o percurso com o GPS do telemóvel.'),
    'sportLogDone': ('Apuntar una ya hecha', 'Log one you already did', 'Noter une sortie déjà faite',
                     'Registar uma já feita'),
    'sportGuidedHint': ('Series que la app te va diciendo mientras corres',
                        'Intervals the app calls out while you run',
                        'Des séries que l’app t’annonce pendant ta course',
                        'Séries que a app te vai dizendo enquanto corres'),
    # Formulario por deporte.
    'sportModeLabel': ('¿Qué fue?', 'What was it?', 'C’était quoi ?', 'O que foi?'),
    'sportModeMatch': ('Partido', 'Match', 'Match', 'Jogo'),
    'sportModeTraining': ('Entreno o clase', 'Practice or class', 'Entraînement ou cours', 'Treino ou aula'),
    'sportResultTitle': ('Resultado (opcional)', 'Result (optional)', 'Résultat (facultatif)',
                         'Resultado (opcional)'),
    'sportResultLabel': ('¿Cómo acabó?', 'How did it end?', 'Comment ça s’est fini ?', 'Como acabou?'),
    'sportResultWin': ('Ganado', 'Won', 'Gagné', 'Ganho'),
    'sportResultDraw': ('Empate', 'Draw', 'Nul', 'Empate'),
    'sportResultLoss': ('Perdido', 'Lost', 'Perdu', 'Perdido'),
    'sportScoreLabel': ('Marcador (opcional)', 'Score (optional)', 'Score (facultatif)', 'Marcador (opcional)'),
    'sportScoreHint': ('Como quieras: 3-2, 6-4 6-3…', 'Any way you like: 3-2, 6-4 6-3…',
                       'Comme tu veux : 3-2, 6-4 6-3…', 'Como quiseres: 3-2, 6-4 6-3…'),
    'sportSaveMatch': ('Guardar partido', 'Save match', 'Enregistrer le match', 'Guardar jogo'),
    'sportSaveTraining': ('Guardar entreno', 'Save practice', 'Enregistrer l’entraînement', 'Guardar treino'),
    'sportOtherNameLabel': ('¿Qué deporte fue?', 'Which sport was it?', 'Quel sport était-ce ?',
                            'Que desporto foi?'),
    'sportOtherNameRequired': ('Escribe qué deporte fue.', 'Type which sport it was.',
                               'Écris de quel sport il s’agit.', 'Escreve que desporto foi.'),
    # Otro deporte.
    'sportOtherSearch': ('Buscar o escribir un deporte', 'Search or type a sport', 'Chercher ou écrire un sport',
                         'Procurar ou escrever um desporto'),
    'sportOtherAdd': ('Añadir «{name}»', 'Add “{name}”', 'Ajouter « {name} »', 'Adicionar «{name}»'),
    'sportSuggestYoga': ('Yoga', 'Yoga', 'Yoga', 'Ioga'),
    'sportSuggestClimbing': ('Escalada', 'Climbing', 'Escalade', 'Escalada'),
    'sportSuggestDance': ('Baile', 'Dance', 'Danse', 'Dança'),
    'sportSuggestMartial': ('Artes marciales', 'Martial arts', 'Arts martiaux', 'Artes marciais'),
    'sportSuggestHiking': ('Senderismo', 'Hiking', 'Randonnée', 'Caminhada'),
    'sportSuggestSkating': ('Patinaje', 'Skating', 'Patinage', 'Patinagem'),
}

# Avisos que nombraban el apartado «Correr»: ahora se llama «Deportes».
RENAMED = {
    'training': {
        'runLeavePauseWhere': (
            'Queda guardada. La sigues en Entreno › Deportes, con «Seguir con la carrera».',
            'It stays saved. Continue it in Training › Sports with “Continue the run”.',
            'Elle reste enregistrée. Reprends-la dans Sport › Sports avec « Reprendre la course ».',
            'Fica guardada. Continua em Treino › Desportos com «Continuar a corrida».'),
        'runPausedWhere': (
            'Carrera en pausa. Síguela en Entreno › Deportes con «Seguir con la carrera».',
            'Run paused. Continue it in Training › Sports with “Continue the run”.',
            'Course en pause. Reprends-la dans Sport › Sports avec « Reprendre la course ».',
            'Corrida em pausa. Continua em Treino › Desportos com «Continuar a corrida».'),
        'runSavedWhere': (
            'Carrera guardada. La tienes en Entreno › Deportes › Últimas actividades.',
            'Run saved. Find it in Training › Sports › Latest activities.',
            'Course enregistrée. Retrouve-la dans Sport › Sports › Dernières activités.',
            'Corrida guardada. Encontras em Treino › Desportos › Últimas atividades.'),
        'runQueuedWhere': (
            'Sin conexión: se subirá sola. La verás en Entreno › Deportes.',
            'Offline: it will upload itself. You’ll see it in Training › Sports.',
            'Hors connexion : elle s’enverra toute seule. Tu la verras dans Sport › Sports.',
            'Sem ligação: vai ser enviada sozinha. Vais vê-la em Treino › Desportos.'),
        'runBackToRun': ('Volver a Deportes', 'Back to Sports', 'Retour à Sports', 'Voltar a Desportos'),
        'runQueuedProgress': (
            'Guardada en este móvil. Volviendo a Deportes…', 'Saved on this phone. Going back to Sports…',
            'Enregistrée sur ce téléphone. Retour à Sports…', 'Guardada neste telemóvel. A voltar a Desportos…'),
        'runDiscardedProgress': (
            'Carrera descartada. Volviendo a Deportes…', 'Run discarded. Going back to Sports…',
            'Course abandonnée. Retour à Sports…', 'Corrida descartada. A voltar a Desportos…'),
        'trainingTemplatesCreatedWithRuns': (
            'Listo: «{name}» ya es tu rutina. Sus carreras están en Entreno › Deportes.',
            'Done: “{name}” is now your routine. Its runs are in Training › Sports.',
            'C’est fait : « {name} » est ta routine. Ses sorties sont dans Sport › Sports.',
            'Feito: «{name}» já é a tua rotina. As corridas estão em Treino › Desportos.'),
        'trainingTemplateRunHint': (
            'Al usarla, estas carreras se crean en Entreno › Deportes.',
            'When you use it, these runs are added to Training › Sports.',
            'En l’utilisant, ces courses sont créées dans Sport › Sports.',
            'Ao usá-lo, estas corridas são criadas em Treino › Desportos.'),
    },
    'challenges': {
        'challengesRuleGoRun': ('Ir a Deportes', 'Go to Sports', 'Aller à Sports', 'Ir para Desportos'),
        'challengesRuleHelpRuns': (
            'Cuenta cada carrera que grabas en Entreno › Deportes.',
            'Each run you record in Training › Sports counts.',
            'Chaque course que tu enregistres dans Sport › Sports compte.',
            'Conta cada corrida que gravas em Treino › Desportos.'),
    },
}

META = {
    'sportOtherAdd': {
        'description': 'Otro deporte: fila para apuntar el deporte escrito en el buscador.',
        'placeholders': {'name': {'type': 'String'}},
    },
}

def write(module, lang, texts):
    path = PARTS / f'app_{lang}_{module}.arb'
    data = json.loads(path.read_text(encoding='utf-8'), object_pairs_hook=OrderedDict)
    for key, value in texts.items():
        data[key] = value
        if lang == 'es' and key in META:
            data['@' + key] = META[key]
    path.write_text(json.dumps(data, ensure_ascii=False, indent=2) + '\n', encoding='utf-8', newline='\n')


for index, lang in enumerate(LANGS):
    write('training', lang, {k: v[index] for k, v in {**TEXTS, **RENAMED['training']}.items()})
    write('challenges', lang, {k: v[index] for k, v in RENAMED['challenges'].items()})
    print(lang, len(TEXTS) + sum(len(v) for v in RENAMED.values()))
