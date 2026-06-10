param(
    [string]$InputPath = "D:\Dataset\Deporte\lyfta\video_list.txt",
    [string]$OutputPath = "D:\Dataset\Deporte\lyfta\ejercicios.json"
)

$SourceName = "lyfta"

$EquipmentMap = [ordered]@{
    'Barbell' = 'barra'
    'EZ-Barbell' = 'barra EZ'
    'Dumbbell' = 'mancuerna'
    'Dumbbells' = 'mancuernas'
    'Cable' = 'polea'
    'Kettlebell' = 'kettlebell'
    'Lever' = 'máquina de palanca'
    'Smith' = 'máquina Smith'
    'Band' = 'banda elástica'
    'Bodyweight' = 'peso corporal'
    'Exercise-Ball' = 'fitball'
    'Medicine-Ball' = 'balón medicinal'
    'Suspension' = 'suspensión'
    'Ring' = 'anillas'
    'Landmine' = 'landmine'
    'Plate' = 'disco'
    'Wrist-Roller' = 'rodillo de muñeca'
}

$PositionMap = [ordered]@{
    'Standing' = 'de pie'
    'Seated' = 'sentado'
    'Lying' = 'tumbado'
    'Prone' = 'en prono'
    'Supine' = 'en supino'
    'Kneeling' = 'de rodillas'
    'Hanging' = 'colgado'
    'Wall' = 'en pared'
    'Floor' = 'en el suelo'
    'Bench' = 'en banco'
    'Stability-Ball' = 'en fitball'
    'Exercise-Ball' = 'en fitball'
    'On-Step' = 'en escalón'
    'On-Stability-Ball' = 'en fitball'
}

$ModifierMap = [ordered]@{
    'Assisted' = 'asistido'
    'Weighted' = 'lastrado'
    'Alternate' = 'alterno'
    'Alternating' = 'alterno'
    'Single' = 'unilateral'
    'One-Arm' = 'a una mano'
    'Two-Arm' = 'a dos manos'
    'One-Leg' = 'a una pierna'
    'Single-Leg' = 'a una pierna'
    'Double' = 'doble'
    'Half-Kneeling' = 'medio arrodillado'
    'Half-Kneel' = 'medio arrodillado'
    'Reverse' = 'inverso'
    'Reversed' = 'inverso'
    'Close-Grip' = 'agarre cerrado'
    'Wide-Grip' = 'agarre ancho'
    'Neutral-Grip' = 'agarre neutro'
    'Reverse-Grip' = 'agarre supino'
    'Underhand' = 'supino'
    'Overhand' = 'prono'
    'Incline' = 'inclinado'
    'Decline' = 'declinado'
    'High' = 'alto'
    'Low' = 'bajo'
    'Rear' = 'posterior'
    'Front' = 'frontal'
    'Lateral' = 'lateral'
    'Cross-Over' = 'cruzado'
    'Cross' = 'cruzado'
    'Twisting' = 'con giro'
    'Twist' = 'giro'
    'Behind-Back' = 'detrás de la espalda'
    'Behind' = 'detrás'
    'Overhead' = 'por encima de la cabeza'
    'Pike' = 'en pica'
    'Bridge' = 'sobre banco'
    'Pulley' = 'en polea'
}

function Remove-NoiseTokens {
    param([string]$Core)

    $clean = $Core
    $clean = [regex]::Replace($clean, '\((female|male|VERSION-\d+|VERSION \d+|WRONG-RIGHT)\)', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '-\(VERSION-\d+\)', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '-\(female\)|-\(male\)', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '-FIX\d*', '', 'IgnoreCase')
    $clean = [regex]::Replace($clean, '_+', '_')
    $clean = $clean.Trim('_', '-', ' ')
    return $clean
}

function Format-ExerciseTitle {
    param([string]$Text)

    $acronyms = @('ez', 'v', 'z', 'ii', 'iii', 'iv')
    $words = ($Text.ToLowerInvariant() -split '\s+') | Where-Object { $_ -ne '' }
    $formatted = New-Object System.Collections.Generic.List[string]

    for ($index = 0; $index -lt $words.Count; $index++) {
        $word = $words[$index]
        $segments = $word -split '-'
        $outputSegments = New-Object System.Collections.Generic.List[string]

        for ($segmentIndex = 0; $segmentIndex -lt $segments.Count; $segmentIndex++) {
            $segment = $segments[$segmentIndex]
            if ($segment -match '^[0-9]+$') {
                $outputSegments.Add($segment)
                continue
            }

            if ($acronyms -contains $segment) {
                $outputSegments.Add($segment.ToUpperInvariant())
                continue
            }

            if ($index -eq 0 -and $segmentIndex -eq 0) {
                $outputSegments.Add($segment.Substring(0, 1).ToUpperInvariant() + $segment.Substring(1))
                continue
            }

            $outputSegments.Add($segment)
        }

        $formatted.Add($outputSegments -join '-')
    }

    return ($formatted -join ' ').Trim()
}

function Get-PrimaryEquipment {
    param([string]$Core)

    foreach ($key in $EquipmentMap.Keys) {
        if ($Core.StartsWith($key + '-', [System.StringComparison]::OrdinalIgnoreCase)) {
            return @($EquipmentMap[$key], ($Core.Substring($key.Length + 1)))
        }
        if ($Core -ieq $key) {
            return @($EquipmentMap[$key], '')
        }
    }

    return @('', $Core)
}

function Get-MovementLabel {
    param([string]$Core)

    switch -Regex ($Core) {
        'Assisted-Prone-Hamstring' { return 'curl femoral asistido en prono' }
        'Prone-Hamstring' { return 'curl femoral en prono' }
        'Hamstring-Stretch' { return 'estiramiento de isquiotibiales' }
        'Wrist-Roller' { return 'rodillo de muñeca' }
        'Standing-Hand-Squeeze' { return 'apretón de manos de pie' }
        'Weighted-Standing-Hand-Squeeze' { return 'apretón de manos de pie con carga' }
        'Lever-Gripper-Hands' { return 'gripper de manos' }
        'Close-Grip-Bench-Press' { return 'press de banca con agarre cerrado' }
        'Close-Grip-Curl' { return 'curl con agarre cerrado' }
        'Reverse-Grip-Preacher-Curl' { return 'curl predicador con agarre supino' }
        'Reverse-Grip-Pushdown' { return 'jalón de tríceps con agarre supino' }
        'Bench-Press' { return 'press de banca' }
        'Incline-Bench-Press' { return 'press de banca inclinado' }
        'Decline-Bench-Press' { return 'press de banca declinado' }
        'Floor-Press' { return 'press en el suelo' }
        'Chest-Press' { return 'press de pecho' }
        'Shoulder-Press' { return 'press de hombros' }
        'Military-Press' { return 'press militar' }
        'Push-Press' { return 'push press' }
        'Z-Press' { return 'press Z' }
        'Svend-Press' { return 'press Svend' }
        'Bench-Dip' { return 'fondos en banco' }
        'Dip' { return 'fondos' }
        'Push-Up' { return 'flexión de brazos' }
        'Pull-Up' { return 'dominada' }
        'Chin-Up' { return 'dominada supina' }
        'Pulldown' { return 'jalón al pecho' }
        'Row' { return 'remo' }
        'Fly' { return 'aperturas' }
        'Rear-Delt-Raise' { return 'elevación posterior' }
        'Lateral-Raise' { return 'elevación lateral' }
        'Front-Raise' { return 'elevación frontal' }
        'Shoulder-Press' { return 'press de hombros' }
        'Bicep-Curl' { return 'curl de bíceps' }
        'Biceps-Curl' { return 'curl de bíceps' }
        'Preacher-Curl' { return 'curl predicador' }
        'Hammer-Curl' { return 'curl martillo' }
        'Concentration-Curl' { return 'curl de concentración' }
        'Reverse-Curl' { return 'curl inverso' }
        'Wrist-Curl' { return 'curl de muñeca' }
        'Triceps-Extension' { return 'extensión de tríceps' }
        'Tricep-Extension' { return 'extensión de tríceps' }
        'Pushdown' { return 'jalón de tríceps' }
        'Dip-Floor' { return 'fondos en el suelo' }
        'Squat' { return 'sentadilla' }
        'Lunge' { return 'zancada' }
        'Step-Up' { return 'step-up' }
        'Deadlift' { return 'peso muerto' }
        'Good-Morning' { return 'buenos días' }
        'Leg-Press' { return 'prensa de piernas' }
        'Leg-Extension' { return 'extensión de piernas' }
        'Leg-Curl' { return 'curl femoral' }
        'Calf-Raise' { return 'elevación de gemelos' }
        'Calf-Press' { return 'prensa de gemelos' }
        'Crunch' { return 'crunch abdominal' }
        'Sit-Up' { return 'sit-up' }
        'Leg-Raise' { return 'elevación de piernas' }
        'Plank' { return 'plancha' }
        'Rollout' { return 'rollout' }
        'Bridge' { return 'puente' }
        'Twist' { return 'giro de tronco' }
        'Stretch' { return 'estiramiento' }
        'Hold' { return 'isométrico' }
        'Raise' { return 'elevación' }
        'Extension' { return 'extensión' }
        'Flexion' { return 'flexión' }
        'Snatch' { return 'snatch' }
        'Clean' { return 'clean' }
        'Jerk' { return 'jerk' }
        'Thruster' { return 'thruster' }
        'Swing' { return 'swing' }
        'Squat-and-Press' { return 'sentadilla y press' }
        default { return $null }
    }
}

function Convert-ToReadableName {
    param(
        [string]$Core,
        [string]$Equipment
    )

    $clean = Remove-NoiseTokens $Core

    $equipment = ''
    $remaining = $clean

    $equipmentPair = Get-PrimaryEquipment $remaining
    if ($equipmentPair[0]) {
        $equipment = $equipmentPair[0]
        $remaining = $equipmentPair[1]
    }

    $manualLabel = Get-MovementLabel $remaining
    if (-not $manualLabel) {
        $tokens = $remaining -split '-'
        $translated = foreach ($token in $tokens) {
            switch -Regex ($token) {
                '^One$' { 'una' }
                '^Two$' { 'dos' }
                '^Single$' { 'unilateral' }
                '^Alternate$' { 'alterno' }
                '^Alternating$' { 'alterno' }
                '^Standing$' { 'de pie' }
                '^Seated$' { 'sentado' }
                '^Lying$' { 'tumbado' }
                '^Prone$' { 'en prono' }
                '^Supine$' { 'en supino' }
                '^Kneeling$' { 'de rodillas' }
                '^Hanging$' { 'colgado' }
                '^Incline$' { 'inclinado' }
                '^Decline$' { 'declinado' }
                '^Flat$' { 'plano' }
                '^Front$' { 'frontal' }
                '^Rear$' { 'posterior' }
                '^Reverse$' { 'inverso' }
                '^Close$' { 'cerrado' }
                '^Wide$' { 'ancho' }
                '^Neutral$' { 'neutro' }
                '^Overhead$' { 'por encima de la cabeza' }
                '^Behind$' { 'detrás' }
                '^Lateral$' { 'lateral' }
                '^Twist$' { 'giro' }
                '^Crunch$' { 'crunch' }
                '^Press$' { 'press' }
                '^Curl$' { 'curl' }
                '^Fly$' { 'aperturas' }
                '^Row$' { 'remo' }
                '^Squat$' { 'sentadilla' }
                '^Lunge$' { 'zancada' }
                '^Step$' { 'step' }
                '^Up$' { 'up' }
                '^Deadlift$' { 'peso muerto' }
                '^Pull$' { 'jalón' }
                '^Push$' { 'push' }
                '^Dip$' { 'fondos' }
                '^Plank$' { 'plancha' }
                '^Bridge$' { 'puente' }
                '^Stretch$' { 'estiramiento' }
                '^Ball$' { 'fitball' }
                '^Bench$' { 'banco' }
                '^Floor$' { 'suelo' }
                '^Wall$' { 'pared' }
                '^Cable$' { 'polea' }
                '^Barbell$' { 'barra' }
                '^Dumbbell$' { 'mancuerna' }
                '^Dumbbells$' { 'mancuernas' }
                '^Kettlebell$' { 'kettlebell' }
                '^Lever$' { 'máquina de palanca' }
                '^Smith$' { 'Smith' }
                '^Band$' { 'banda elástica' }
                '^Bodyweight$' { 'peso corporal' }
                '^Exercise$' { 'ejercicio' }
                '^Medicine$' { 'medicinal' }
                '^Wrist$' { 'muñeca' }
                '^Forearm$' { 'antebrazo' }
                '^Forearms$' { 'antebrazos' }
                '^Chest$' { 'pecho' }
                '^Shoulder$' { 'hombro' }
                '^Shoulders$' { 'hombros' }
                '^Upper$' { 'superior' }
                '^Arms$' { 'brazos' }
                '^Thighs$' { 'muslos' }
                '^Waist$' { 'abdomen' }
                '^Back$' { 'espalda' }
                '^Hips$' { 'caderas' }
                '^Calves$' { 'gemelos' }
                '^Neck$' { 'cuello' }
                '^Feet$' { 'pies' }
                '^Hands$' { 'manos' }
                '^Pec$' { 'pectoral' }
                '^Rear-Delt$' { 'deltoide posterior' }
                '^Triceps$' { 'tríceps' }
                '^Tricep$' { 'tríceps' }
                '^Biceps$' { 'bíceps' }
                '^Bicep$' { 'bíceps' }
                '^Calf$' { 'gemelo' }
                '^Pike$' { 'en pica' }
                '^High$' { 'alto' }
                '^Low$' { 'bajo' }
                '^Cross$' { 'cruzado' }
                '^On$' { 'en' }
                '^With$' { 'con' }
                default { $token.ToLowerInvariant() }
            }
        }

        $label = ($translated -join ' ')
        $label = $label -replace '\bpress banca\b', 'press de banca'
        $label = $label -replace '\bpress pecho\b', 'press de pecho'
        $label = $label -replace '\bpress hombros\b', 'press de hombros'
        $label = $label -replace '\bcurl bíceps\b', 'curl de bíceps'
        $label = $label -replace '\bcurl muñeca\b', 'curl de muñeca'
        $label = $label -replace '\baperturas pecho\b', 'aperturas de pecho'
        $label = $label -replace '\bextensión tríceps\b', 'extensión de tríceps'
        $label = $label -replace '\bjalón tríceps\b', 'jalón de tríceps'
        $label = $label -replace '\bjalón pecho\b', 'jalón al pecho'
        $label = $label -replace '\bfondos banco\b', 'fondos en banco'
        $label = $label -replace '\belevación gemelos\b', 'elevación de gemelos'
        $label = $label -replace '\bsentadilla barra\b', 'sentadilla con barra'
        $label = $label -replace '\bzancada mancuerna\b', 'zancada con mancuerna'
        $label = $label -replace '\bpeso muerto barra\b', 'peso muerto con barra'
        $label = $label -replace '\bremo polea\b', 'remo en polea'
        $label = $label -replace '\bflexión de brazos peso corporal\b', 'flexión de brazos'
        $label = $label -replace '\bplancha peso corporal\b', 'plancha'
        $label = $label -replace '\bestiramiento de rodillas\b', 'estiramiento de rodillas'
        $label = $label -replace '\bpress de banca inclinado barra\b', 'press de banca inclinado con barra'
        $label = $label -replace '\bpress de banca declinado barra\b', 'press de banca declinado con barra'
        $label = $label -replace '\bpress de banca barra\b', 'press de banca con barra'
        $label = $label -replace '\bpress de pecho barra\b', 'press de pecho con barra'
        $label = $label -replace '\bpress de hombros barra\b', 'press de hombros con barra'
        $label = $label -replace '\bpress de banca mancuerna\b', 'press de banca con mancuerna'
        $label = $label -replace '\bpress de pecho mancuerna\b', 'press de pecho con mancuerna'
        $label = $label -replace '\bcurl de bíceps mancuerna\b', 'curl de bíceps con mancuerna'
        $label = $label -replace '\bcurl martillo mancuerna\b', 'curl martillo con mancuerna'
        $label = $label -replace '\belevación lateral mancuerna\b', 'elevación lateral con mancuerna'
        $label = $label -replace '\belevación frontal mancuerna\b', 'elevación frontal con mancuerna'
        $label = $label -replace '\belevación posterior mancuerna\b', 'elevación posterior con mancuerna'
        $label = $label -replace '\bflexión de brazos con peso corporal\b', 'flexión de brazos'
        $label = $label -replace '\bdominada con peso corporal\b', 'dominada'
        $label = $label -replace '\bfondos con peso corporal\b', 'fondos'
        $label = $label -replace '\bplancha en el suelo\b', 'plancha'
        $label = $label -replace '\bpeso muerto con barra\b', 'peso muerto con barra'
        $label = $label -replace '\bpress z\b', 'press Z'
        $label = $label -replace '\bsvend press\b', 'press Svend'
        $label = $label -replace '\bpush press\b', 'push press'
        $label = (Get-Culture).TextInfo.ToTitleCase($label)
        $label = $label -replace 'De Banca', 'de banca'
        $label = $label -replace 'De Pecho', 'de pecho'
        $label = $label -replace 'De Bíceps', 'de bíceps'
        $label = $label -replace 'De Muñeca', 'de muñeca'
        $label = $label -replace 'De Tríceps', 'de tríceps'
        $label = $label -replace 'En El Suelo', 'en el suelo'
        $label = $label -replace 'En Banco', 'en banco'
        $label = $label -replace 'En Polea', 'en polea'
        $label = $label -replace 'Con Barra', 'con barra'
        $label = $label -replace 'Con Mancuerna', 'con mancuerna'
        $label = $label -replace 'Con Mancuernas', 'con mancuernas'
        $label = $label -replace 'Con Kettlebell', 'con kettlebell'
        $label = $label -replace 'Con Banda Elástica', 'con banda elástica'
        $label = $label -replace 'De Pie', 'de pie'
        $label = $label -replace 'Sentado', 'sentado'
        $label = $label -replace 'Tumbado', 'tumbado'
        $label = $label -replace 'En Pared', 'en pared'
        $label = $label -replace 'En Fitball', 'en fitball'
        $label = $label.Trim()
    }
    else {
        $label = $manualLabel
    }

    $label = $label -replace '\s+', ' '
    if ($Equipment) {
        if ($label -match 'press|curl|remo|jalón|aperturas|extensión|fondos|sentadilla|zancada|step-up|peso muerto|elevación|flexión|dominada|plancha|puente|rollout|crunch|skull|thruster|swing') {
            if ($Equipment -eq 'peso corporal') {
                $label = $label -replace ' con peso corporal$', ''
                $label = $label -replace ' peso corporal$', ''
            } else {
                $label = "$label con $Equipment"
            }
        } elseif ($label -notmatch [regex]::Escape($Equipment)) {
            $label = "$label con $Equipment"
        }
    }

    return $label.Trim()
}

function Get-CategoryFromCore {
    param([string]$Core)

    switch -Regex ($Core) {
        'Chest|Pec|Push-Up|Press|Fly|Dip' { return 'Chest' }
        'Shoulder|Deltoid|Raise|Press|Face-Pull|Upright-Row|Snatch|Jerk|Clean|Halo' { return 'Shoulders' }
        'Bicep|Curl|Preacher|Hammer|Concentration|Waiter|Reverse-Curl|Biceps' { return 'Upper-Arms' }
        'Triceps|Pushdown|Extension|Dip' { return 'Upper-Arms' }
        'Forearm|Wrist|Grip|Roller|Pinch|Supination|Pronation|Hand-Squeeze' { return 'Forearms' }
        'Squat|Lunge|Step-Up|Leg-Press|Leg-Extension|Leg-Curl|Hamstring|Thigh|Sissy|Split-Squat|Deadlift|Goblet' { return 'Thighs' }
        'Calf|Gastrocnemius|Tibialis|Achilles|Toe|Shin' { return 'Calves' }
        'Crunch|Plank|Leg-Raise|Twist|Rollout|Hollow|Windmill|V-Up|Sit-Up|Ab|Pallof|Dead-Bug|Bridge|Planche|Dragon-Flag' { return 'Waist' }
        'Back|Row|Pull-Up|Pulldown|Reverse-Fly|Rear-Delt|Face-Pull|Hyperextension|Superman|Trunk-Rotation' { return 'Back' }
        'Neck|Chin-Tuck|Cervical|Scalene' { return 'Neck' }
        'Hip|Bridge|Glute|Pelvic|Kick|Deadlift' { return 'Hips' }
        'Hand|Finger' { return 'Hands' }
        'Foot' { return 'Feet' }
        'Stretch|Mobility|Yoga|Foam-Roll|Release' { return 'Stretching' }
        'Pilates|Crab|Chest-Lift|Hundred|Leg-Pull' { return 'Pilates' }
        'Weightlifting|Front-Hold|StrongMan' { return 'Weightlifting' }
        default { return 'General' }
    }
}

function Get-PartsBody {
    param([string]$Category)

    switch ($Category) {
        'Chest' { @('Tren superior', 'Pecho') }
        'Shoulders' { @('Tren superior', 'Hombros') }
        'Upper-Arms' { @('Tren superior', 'Brazos') }
        'Forearms' { @('Tren superior', 'Antebrazos') }
        'Thighs' { @('Tren inferior', 'Piernas') }
        'Calves' { @('Tren inferior', 'Piernas') }
        'Waist' { @('Core', 'Zona media') }
        'Back' { @('Tren superior', 'Espalda') }
        'Neck' { @('Tren superior', 'Cuello') }
        'Hips' { @('Tren inferior', 'Cadera') }
        'Hands' { @('Tren superior', 'Manos') }
        'Feet' { @('Tren inferior', 'Pies') }
        'Stretching' { @('Movilidad', 'Flexibilidad') }
        'Pilates' { @('Core', 'Movilidad') }
        'Weightlifting' { @('Tren superior', 'Cuerpo completo') }
        default { @('Cuerpo completo') }
    }
}

function Get-TargetMuscles {
    param([string]$Category, [string]$Core)

    switch ($Category) {
        'Chest' { @('Pectoral mayor') }
        'Shoulders' {
            if ($Core -match 'Rear|Rear-Delt|Reverse|Face-Pull') { @('Deltoides posterior') }
            elseif ($Core -match 'Front-Raise|Front|Arnold|Press') { @('Deltoides anterior') }
            else { @('Deltoides medio') }
        }
        'Upper-Arms' {
            if ($Core -match 'Triceps|Extension|Pushdown|Dip') { @('Tríceps braquial') }
            elseif ($Core -match 'Forearm|Wrist|Reverse-Curl') { @('Braquiorradial') }
            else { @('Bíceps braquial') }
        }
        'Forearms' { @('Flexores del antebrazo', 'Extensores del antebrazo') }
        'Thighs' {
            if ($Core -match 'Hamstring|Leg-Curl|Nordic|Inverse-Leg-Curl') { @('Isquiotibiales') }
            elseif ($Core -match 'Calf|Toe|Shin') { @('Gastrocnemio') }
            elseif ($Core -match 'Glute|Hip|Deadlift') { @('Glúteo mayor') }
            else { @('Cuádriceps') }
        }
        'Calves' { @('Gastrocnemio', 'Sóleo') }
        'Waist' { @('Recto abdominal', 'Oblicuos') }
        'Back' { @('Dorsal ancho', 'Romboides') }
        'Neck' { @('Esternocleidomastoideo', 'Escalenos') }
        'Hips' { @('Glúteo mayor', 'Isquiotibiales') }
        'Hands' { @('Flexores de los dedos', 'Músculos intrínsecos de la mano') }
        'Feet' { @('Músculos intrínsecos del pie', 'Tibial posterior') }
        'Stretching' { @('Grupo muscular objetivo del estiramiento') }
        'Pilates' { @('Recto abdominal', 'Transverso abdominal') }
        'Weightlifting' { @('Trapecio', 'Deltoides', 'Cuádriceps') }
        default { @('Grupo muscular principal') }
    }
}

function Get-SecondaryMuscles {
    param([string]$Category, [string]$Core)

    switch ($Category) {
        'Chest' { @('Deltoides anterior', 'Tríceps braquial') }
        'Shoulders' { @('Trapecio superior', 'Tríceps braquial') }
        'Upper-Arms' { @('Braquial', 'Braquiorradial') }
        'Forearms' { @('Flexores de muñeca', 'Extensores de muñeca') }
        'Thighs' { @('Glúteo mayor', 'Isquiotibiales') }
        'Calves' { @('Tibial anterior') }
        'Waist' { @('Transverso abdominal', 'Erectores espinales') }
        'Back' { @('Trapecio medio', 'Erectores espinales') }
        'Neck' { @('Trapecio superior') }
        'Hips' { @('Core', 'Erectores espinales') }
        'Hands' { @('Flexores de antebrazo') }
        'Feet' { @('Gemelos') }
        'Stretching' { @('Tejido conectivo', 'Movilidad articular') }
        'Pilates' { @('Glúteos', 'Flexores de cadera') }
        'Weightlifting' { @('Core', 'Trapecio superior', 'Glúteos') }
        default { @('Estabilizadores globales') }
    }
}

function Get-EquipmentList {
    param([string]$Core, [string]$Category)

    $items = New-Object System.Collections.Generic.List[string]

    if ($Core -match '^Assisted-') { $items.Add('asistencia') }
    if ($Core -match '^Bodyweight') { $items.Add('peso corporal') }
    if ($Core -match '^Exercise-Ball|Stability-Ball') { $items.Add('fitball') }
    if ($Core -match '^Medicine-Ball') { $items.Add('balón medicinal') }
    if ($Core -match '^Barbell') { $items.Add('barra') }
    if ($Core -match '^EZ-Barbell') { $items.Add('barra EZ') }
    if ($Core -match '^Dumbbells?') { $items.Add('mancuernas') }
    if ($Core -match '^Cable') { $items.Add('polea') }
    if ($Core -match '^Kettlebell') { $items.Add('kettlebell') }
    if ($Core -match '^Lever') { $items.Add('máquina de palanca') }
    if ($Core -match '^Smith') { $items.Add('máquina Smith') }
    if ($Core -match '^Band') { $items.Add('banda elástica') }
    if ($Core -match '^Suspension') { $items.Add('suspensión') }
    if ($Core -match '^Ring') { $items.Add('anillas') }
    if ($Core -match '^Landmine') { $items.Add('landmine') }
    if ($Core -match '^Wrist-Roller') { $items.Add('rodillo de muñeca') }
    if ($Core -match '^Plate') { $items.Add('disco') }

    if ($Core -match 'Bench') { $items.Add('banco') }
    if ($Core -match 'Wall') { $items.Add('pared') }
    if ($Core -match 'Floor') { $items.Add('suelo') }
    if ($Core -match 'Step') { $items.Add('escalón') }
    if ($Core -match 'Parallel-Bars') { $items.Add('barras paralelas') }
    if ($Core -match 'Staircase') { $items.Add('escalera') }
    if ($Core -match 'Foam-Roll') { $items.Add('rodillo de espuma') }
    if ($Core -match 'Towel') { $items.Add('toalla') }

    if ($items.Count -eq 0) {
        $items.Add('sin equipamiento')
    }

    return $items | Select-Object -Unique
}

function Get-Difficulty {
    param([string]$Core)

    if ($Core -match 'Handstand|Planche|Dragon-Flag|Muscle|Kipping|Pike-Push-Up|Clean-And-Jerk|Snatch|Jerk|Thruster|Front-Lever|Back-Lever') {
        return 'avanzado'
    }

    if ($Core -match 'Stretch|Mobility|Foam-Roll|Assisted|Wall|Bodyweight|Curl|Extension|Raise|Calf-Raise|Plank|Crunch|Crunches|Leg-Extension|Leg-Curl') {
        return 'principiante'
    }

    return 'intermedio'
}

function Get-Finality {
    param([string]$Core)

    if ($Core -match 'Stretch|Mobility|Foam-Roll') { return @('Movilidad', 'Flexibilidad') }
    if ($Core -match 'Handstand|Planche|Lever|Flag|Balance') { return @('Control corporal', 'Fuerza') }
    if ($Core -match 'Strength|Weightlifting|Clean|Snatch|Jerk|Deadlift|Squat|Press|Pull-Up|Row') { return @('Fuerza', 'Hipertrofia') }
    if ($Core -match 'Curl|Extension|Raise|Fly|Pushdown|Calf-Raise|Leg-Extension|Leg-Curl') { return @('Hipertrofia', 'Resistencia muscular') }
    if ($Core -match 'Crunch|Plank|Rollout|Twist|Leg-Raise|Dead-Bug|Pallof|Bridge') { return @('Resistencia muscular', 'Estabilidad') }

    return @('Hipertrofia')
}

function Get-Description {
    param([string]$Name, [string]$Category, [string]$Core)

    switch ($Category) {
        'Stretching' { return "Estiramiento orientado a mejorar la movilidad y reducir la rigidez en $Name." }
        'Waist' { return "Movimiento de core para reforzar la estabilidad del tronco y el control lumbopélvico." }
        'Back' { return "Ejercicio de tracción para desarrollar la espalda y mejorar la postura." }
        'Chest' { return "Ejercicio de empuje que enfatiza el pectoral y la fuerza del tren superior." }
        'Shoulders' { return "Movimiento de empuje o elevación para aislar y fortalecer el complejo del hombro." }
        'Upper-Arms' { return "Ejercicio de aislamiento para estimular el brazo y mejorar la fuerza local." }
        'Forearms' { return "Trabajo específico de antebrazo y agarre para reforzar la muñeca y la prensión." }
        'Thighs' { return "Ejercicio del tren inferior para desarrollar piernas, fuerza y estabilidad." }
        'Calves' { return "Trabajo analítico para fortalecer la pantorrilla y mejorar la propulsión del tobillo." }
        'Neck' { return "Trabajo específico del cuello para mejorar control, movilidad y resistencia isométrica." }
        'Hips' { return "Movimiento de cadena posterior para potenciar glúteos y cadera." }
        'Hands' { return "Ejercicio de agarre y mano para mejorar la fuerza de prensión." }
        'Feet' { return "Trabajo de pie y tobillo para reforzar la estabilidad distal." }
        'Pilates' { return "Ejercicio de control corporal y activación profunda del core." }
        'Weightlifting' { return "Movimiento de potencia y coordinación para el desarrollo atlético global." }
        default { return "Ejercicio del catálogo para desarrollo general de fuerza y acondicionamiento." }
    }
}

function Get-Instructions {
    param([string]$Name, [string]$Category, [string]$Core)

    if ($Category -eq 'Stretching') {
        return @(
            "Paso 1: Colócate en la posición inicial indicada por el estiramiento.",
            "Paso 2: Lleva el cuerpo hasta notar tensión suave, sin rebotes ni dolor.",
            "Paso 3: Mantén la postura unos segundos y respira de forma controlada."
        )
    }

    if ($Core -match 'Plank|Crunch|Rollout|Bridge|Dead-Bug|Hollow|Twist|Leg-Raise|Pallof|Vacuum') {
        return @(
            "Paso 1: Acomoda la pelvis y activa el abdomen antes de iniciar.",
            "Paso 2: Mantén la alineación del tronco mientras ejecutas el recorrido completo.",
            "Paso 3: Controla el regreso para no perder tensión en el core."
        )
    }

    if ($Core -match 'Squat|Lunge|Step-Up|Deadlift|Leg-Press|Leg-Curl|Leg-Extension|Calf-Raise|Hip-') {
        return @(
            "Paso 1: Sitúa los pies con la base estable y el abdomen firme.",
            "Paso 2: Ejecuta el movimiento con control, manteniendo la alineación de rodillas y cadera.",
            "Paso 3: Vuelve a la posición inicial sin perder estabilidad ni rango útil."
        )
    }

    if ($Core -match 'Press|Push-Up|Dip|Fly|Raise|Row|Pulldown|Curl|Extension|Pushdown|Face-Pull') {
        return @(
            "Paso 1: Ajusta la postura inicial y prepara el agarre o apoyo correspondiente.",
            "Paso 2: Realiza la fase concéntrica controlando el recorrido y evitando impulsos.",
            "Paso 3: Desciende de forma lenta hasta recuperar la posición de inicio."
        )
    }

    return @(
        "Paso 1: Adopta la posición inicial correcta y estabiliza el tronco.",
        "Paso 2: Ejecuta el movimiento con un rango controlado y sin compensaciones.",
        "Paso 3: Regresa a la posición inicial manteniendo la técnica y la respiración."
    )
}

function Normalize-ExerciseLine {
    param([string]$Line)

    if ($Line -notmatch '^\d+\.\s+(?<raw>.+)$') {
        return $null
    }

    $raw = $Matches['raw'].Trim()
    $core = $raw
    if ($core -match '^(?<id>\d+)-(?<slug>.+)$') {
        $core = $Matches['slug']
    }

    $slug = ($core -split '_')[0]
    $slug = $slug.Trim('_', '-', ' ')

    $category = Get-CategoryFromCore $slug
    $equipamientos = [string[]](Get-EquipmentList -Core $slug -Category $category)
    $equipment = if ($equipamientos.Count -gt 0) { $equipamientos[0] } else { 'sin equipamiento' }
    $name = Convert-ToReadableName -Core $slug -Equipment $equipment
    $name = Format-ExerciseTitle $name

    $urlBase = $raw
    $urlVideo = "https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/$SourceName/$urlBase.mp4"
    $urlPreview = "https://pub-150303d1abd547199a65ccac4b8fe45b.r2.dev/ejercicios/$SourceName/$urlBase.webp"

    [pscustomobject]@{
        fuente = $SourceName
        nombre_ejercicio = $name
        descripcion = Get-Description -Name $name -Category $category -Core $slug
        instrucciones = Get-Instructions -Name $name -Category $category -Core $slug
        dificultad = Get-Difficulty -Core $slug
        finalidad = [string[]](Get-Finality -Core $slug)
        partes_cuerpo = [string[]](Get-PartsBody -Category $category)
        musculos_objetivo = [string[]](Get-TargetMuscles -Category $category -Core $slug)
        musculos_secundarios = [string[]](Get-SecondaryMuscles -Category $category -Core $slug)
        equipamientos = $equipamientos
        url_video = $urlVideo
        url_preview = $urlPreview
    }
}

$items = Get-Content -Path $InputPath | ForEach-Object { Normalize-ExerciseLine $_ } | Where-Object { $_ -ne $null }

$json = $items | ConvertTo-Json -Depth 8
Set-Content -Path $OutputPath -Value $json -Encoding UTF8

Write-Host "Generated $($items.Count) exercises at $OutputPath"