import json, os, re

PREVIEW_DIR = 'D:\\Dataset\\Deporte\\lyfta\\preview\\webp'
JSON_PATH = 'supabase\\dataset_final.json'

with open(JSON_PATH, 'r', encoding='utf-8') as f:
    data = json.load(f)

count = 0
not_found = []
preview_files = set(os.listdir(PREVIEW_DIR))

for e in data:
    if e.get('fuente') != 'lyfta':
        continue

    video_url = e.get('url_video', '')
    if not video_url:
        continue

    # Extract video filename
    video_fname = video_url.split('/')[-1]  # e.g., 00161201-Assisted-Prone-Hamstring_Thighs_.mp4
    
    # Transform to preview filename:
    # 1. 201 -> 101 in the ID portion (first 8 chars)
    base = video_fname.replace('.mp4', '')  # 00161201-Assisted-Prone-Hamstring_Thighs_
    first_part = base[:8]        # 00161201
    rest = base[8:]              # -Assisted-Prone-Hamstring_Thighs_
    # Change the 3-digit suffix (positions 5-7) from 201 to 101
    transformed_id = first_part[:5] + '101' + first_part[8:]  # 00161101
    # Remove trailing underscore and add _small.webp
    rest = rest.rstrip('_')  # -Assisted-Prone-Hamstring_Thighs  (remove trailing `_`)
    preview_fname = transformed_id + rest + '_small.webp'

    # Build new URL
    base_url = '/'.join(video_url.split('/')[:-1])  # URL up to the file
    new_preview_url = base_url + '/' + preview_fname

    # Verify file exists
    if preview_fname not in preview_files:
        not_found.append((preview_fname, e.get('nombre_ejercicio', '')))
        continue

    e['url_preview'] = new_preview_url
    count += 1

print('Lyfta previews actualizados: %d' % count)

if not_found:
    print('\nPreviews NO encontradas en disco (%d):' % len(not_found))
    for fname, nombre in not_found[:10]:
        print('  %s  (%s)' % (fname, nombre))

# Save
with open(JSON_PATH, 'w', encoding='utf-8') as f:
    json.dump(data, f, ensure_ascii=False, indent=2)

print('\nGuardado en: %s' % JSON_PATH)
