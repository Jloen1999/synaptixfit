param(
    [string]$InputJson = "d:\Dataset\Deporte\lyfta\ejercicios.json",
    [string]$OutputJson = "d:\Dataset\Deporte\lyfta\ejercicios.json"
)

$data = Get-Content -Raw $InputJson | ConvertFrom-Json

foreach ($item in $data) {
    $name = $item.nombre_ejercicio

    # Global replacements (case-insensitive)
    $name = [regex]::Replace($name, '\(plate loaded\)', '(cargado con disco)', 'IgnoreCase')
    $name = [regex]::Replace($name, '\bhand[- ]?squeeze\b', 'apretón de manos', 'IgnoreCase')
    $name = [regex]::Replace($name, '\bweighted\b', 'con lastre', 'IgnoreCase')
    $name = [regex]::Replace($name, '\bgripper\s+manos\b', 'gripper de manos', 'IgnoreCase')
    $name = [regex]::Replace($name, '\bbare[- ]?hand\b', 'a mano descubierta', 'IgnoreCase')

    # Grip specific
    $name = [regex]::Replace($name, '\b(cerrad[oa]|close)[- ]?grip\b', 'con agarre cerrado', 'IgnoreCase')
    $name = [regex]::Replace($name, '\b(reverse|revers|supino)[- ]?grip\b', 'con agarre supino', 'IgnoreCase')
    $name = [regex]::Replace($name, '\b(neutral)[- ]?grip\b', 'con agarre neutro', 'IgnoreCase')

    # Wrist roller literal
    $name = [regex]::Replace($name, '\bwrist[- ]?roller\b', 'rodillo de muñeca', 'IgnoreCase')

    # Reorder common pattern: 'Sentado ... press' -> 'Press sentado ...'
    if ($name -match '^(Sentado)\s+(.+?)\s+(press|Press|Press de|press de)\b') {
        $m = [regex]::Match($name, '^(Sentado)\s+(.+?)\s+(press|Press|Press de|press de)\b')
        $rest = $name.Substring($m.Length).Trim()
        $name = "Press sentado $($m.Groups[2].Value) $rest".Trim()
    }

    # Clean duplicate words
    $name = [regex]::Replace($name, '\b(agarre\s+agarre)\b', 'agarre', 'IgnoreCase')
    $name = [regex]::Replace($name, '\s{2,}', ' ')

    # Capitalize first letter and preserve existing acronyms (EZ, V, Z)
    if ($name.Length -gt 0) {
        $first = $name.Substring(0,1).ToUpperInvariant()
        $rest = $name.Substring(1)
        $name = "$first$rest"
        $name = [regex]::Replace($name, '\bEz\b', 'EZ')
        $name = [regex]::Replace($name, '\bV\b', 'V')
        $name = [regex]::Replace($name, '\bZ\b', 'Z')
    }

    # Update equipment if name indicates lastre
    if ($name -match 'con lastre' -and $item.equipamientos -and ($item.equipamientos -contains 'sin equipamiento')) {
        $item.equipamientos = @('lastre')
    }

    # Specific cleanup: translate English fragments left
    $name = [regex]::Replace($name, '\bhand\b', 'mano', 'IgnoreCase')
    $name = [regex]::Replace($name, '\bstanding\b', 'de pie', 'IgnoreCase')

    $item.nombre_ejercicio = $name.Trim()
}

# Save back
$data | ConvertTo-Json -Depth 8 | Set-Content -Path $OutputJson -Encoding UTF8
Write-Host "Polished $($data.Count) exercise names in $OutputJson"
