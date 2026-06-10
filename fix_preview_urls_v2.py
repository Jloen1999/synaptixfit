import json, os, re

JSON_PATH = 'supabase/dataset_final.json'
PREVIEW_DIR = 'D:\\Dataset\\Deporte\\lyfta\\preview\\webp'

def get_descriptive(fname):
    name = fname.rsplit('.', 1)[0]
    name = re.sub(r'^\d+\-', '', name)
    name = re.sub(r'_small$', '', name)
    name = name.rstrip('_')
    return name

# Build preview lookup: descriptive_name -> actual_filename
preview_files = os.listdir(PREVIEW_DIR)
preview_lookup = {}
for pf in preview_files:
    desc = get_descriptive(pf)
    if desc not in preview_lookup:
        preview_lookup[desc] = pf
    else:
        preview_lookup[desc] = None

# Load dataset
with open(JSON_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

updated = 0
not_found = []

for e in data:
    if e.get('fuente') != 'lyfta':
        continue
    vu = e.get('url_video', '')
    if not vu:
        continue

    vfname = vu.split('/')[-1]
    video_desc = get_descriptive(vfname)

    if video_desc in preview_lookup and preview_lookup[video_desc] is not None:
        preview_fname = preview_lookup[video_desc]
        base_url = '/'.join(vu.split('/')[:-1])
        e['url_preview'] = base_url + '/' + preview_fname
        updated += 1
    else:
        e['url_preview'] = ''
        not_found.append((vfname, e.get('nombre_ejercicio', '')))

# Save
with open(JSON_PATH, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('Actualizadas: %d / 682 lyfta' % updated)
if not_found:
    print('\nSin preview en disco:')
    for vfname, nombre in not_found:
        print('  %s  (%s)' % (vfname[:60], nombre[:40]))
else:
    print('Todas las 682 previews tienen archivo local.')
