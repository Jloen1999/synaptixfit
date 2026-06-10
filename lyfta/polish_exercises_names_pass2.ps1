param(
    [string]$InputJson = "d:\Dataset\Deporte\lyfta\ejercicios.json",
    [string]$OutputJson = "d:\Dataset\Deporte\lyfta\ejercicios.json"
)

$data = Get-Content -Raw $InputJson | ConvertFrom-Json

foreach ($item in $data) {
    $name = $item.nombre_ejercicio

    # Replace remaining 'grip' and 'squeeze'
    $name = [regex]::Replace($name, '\bgrip\b', 'agarre', 'IgnoreCase')
    $name = [regex]::Replace($name, '\bsqueeze\b', 'apretón', 'IgnoreCase')

    # Reorder 'Sentado por encima de la cabeza <movimiento> con ...' -> '<Movimiento> sentado por encima de la cabeza con ...'
    $m = [regex]::Match($name, '^(Sentado por encima de la cabeza)\s+(.+?)\s+(con\b.*)$', 'IgnoreCase')
    if ($m.Success) {
        $mov = $m.Groups[2].Value.Trim()
        $rest = $m.Groups[3].Value.Trim()
        $name = "$mov sentado por encima de la cabeza $rest"
    }

    # Clean leftover English fragments like 'squeeze press'
    $name = [regex]::Replace($name, 'squeeze press', 'press de apretón', 'IgnoreCase')
    $name = [regex]::Replace($name, 'hand squeeze', 'apretón de manos', 'IgnoreCase')

    # Specific translations for common English exercise names left literal
    $name = [regex]::Replace($name, '\bPush[- ]?up\b', 'flexión', 'IgnoreCase')
    $name = [regex]::Replace($name, '\bBench dips\b', 'fondos en banco', 'IgnoreCase')
    $name = [regex]::Replace($name, '\bRomanian deadlift\b', 'peso muerto rumano', 'IgnoreCase')
    $name = [regex]::Replace($name, '\bStiff[- ]?leg deadlift\b', 'peso muerto piernas rígidas', 'IgnoreCase')
    $name = [regex]::Replace($name, '\bLeft\b', 'Izquierda', 'IgnoreCase')
    $name = [regex]::Replace($name, '\bRight\b', 'Derecha', 'IgnoreCase')
    $name = [regex]::Replace($name, '\bDips\b', 'Fondos', 'IgnoreCase')
    $name = [regex]::Replace($name, '\bDips en paralelas\b', 'Fondos en paralelas', 'IgnoreCase')
    $name = [regex]::Replace($name, 'flexión\s+inclinado', 'flexión inclinada', 'IgnoreCase')
    $name = [regex]::Replace($name, 'flexión\s+declinado', 'flexión declinada', 'IgnoreCase')

    # Normalize spacing and capitalize
    $name = [regex]::Replace($name, '\s{2,}', ' ')
    if ($name.Length -gt 0) { $name = $name.Substring(0,1).ToUpperInvariant() + $name.Substring(1) }

    # If name starts with a bracketed tag, ensure the first letter after the tag is capitalized
    $name = $name.Trim()
    $m2 = [regex]::Match($name, '^(\[[^\]]+\]\s*)([a-záéíóúñü])', 'IgnoreCase')
    if ($m2.Success) {
        $prefix = $m2.Groups[1].Value
        $first = $m2.Groups[2].Value.ToUpperInvariant()
        $rest = $name.Substring($prefix.Length + 1)
        $name = "$prefix$first$rest"
    }

    $item.nombre_ejercicio = $name
}

$data | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputJson -Encoding UTF8
Write-Host "Second polish applied to $($data.Count) exercises in $OutputJson"
