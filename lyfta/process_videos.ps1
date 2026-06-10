$videoDir = "D:\Dataset\Deporte\lyfta\video"
$previewDir = "D:\Dataset\Deporte\lyfta\preview"
$imagesDir = "D:\Dataset\Deporte\lyfta\images"

# 1. List all video names as numbered list
$videos = Get-ChildItem $videoDir -Filter "*.mp4" | Sort-Object Name
$i = 1
foreach ($v in $videos) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($v.Name)
    Write-Host "$i. $name"
    $i++
}

# 2. Create images directory if not exists
New-Item -ItemType Directory $imagesDir -Force | Out-Null

# 3. Build video key map (descriptive part after number prefix)
$videoMap = @{}
foreach ($v in $videos) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($v.Name)
    $key = $name -replace '^\d+-', ''
    $key = $key -replace '_$', ''
    $videoMap[$key] = $v.FullName
}

# 4. Match and move preview images
$previews = Get-ChildItem $previewDir -Filter "*.png" | Sort-Object Name
$moved = 0
$notFound = 0

foreach ($p in $previews) {
    $name = [System.IO.Path]::GetFileNameWithoutExtension($p.Name)
    $cleaned = $name
    
    # Strip trailing _small, _720, _1080, etc
    do {
        $prev = $cleaned
        $cleaned = $cleaned -replace '_(?:small|\d+)$', ''
    } while ($cleaned -ne $prev)
    
    # Strip leading number prefix
    $cleaned = $cleaned -replace '^\d+-', ''
    $cleaned = $cleaned -replace '_$', ''
    
    if ($videoMap.ContainsKey($cleaned)) {
        Write-Host "Moving: $($p.Name) -> images\"
        Move-Item -Path $p.FullName -Destination "$imagesDir\$($p.Name)" -Force
        $moved++
    } else {
        $notFound++
    }
}

Write-Host ""
Write-Host "=== Summary ==="
Write-Host "Videos found: $($videos.Count)"
Write-Host "Images moved: $moved"
Write-Host "Images not matched: $notFound"
