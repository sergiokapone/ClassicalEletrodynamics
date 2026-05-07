# ================================================================
#  make_video.ps1
#
#  Запуск з папки де лежить StokeParams.tex:
#    powershell -ExecutionPolicy Bypass -File make_video.ps1
#
#  Потрібно: lualatex, pdftoppm (poppler), ffmpeg
# ================================================================

# --- що крутимо ---
$ANGLE_VAR = "CHI"       # "CHI" або "PSI"

$FROM  = -90
$TO    =  90
$STEP  =   5

$FIXED_PSI = 45          # фіксований PSI якщо крутимо CHI
$FIXED_CHI = 15          # фіксований CHI якщо крутимо PSI

$DPI       = 300         # роздільність PNG
$FRAMERATE = 10          # кадрів в секунду
$OUTPUT    = "poincare.mkv"
$TMPDIR    = "_frames"

# ----------------------------------------------------------------
if (Test-Path $TMPDIR) { Remove-Item $TMPDIR -Recurse -Force }
New-Item -ItemType Directory -Path $TMPDIR | Out-Null

$src = Get-Content "StokeParams.tex" -Raw -Encoding UTF8

$count = 0
$angles = $FROM..$TO | Where-Object { ($_ - $FROM) % $STEP -eq 0 }

foreach ($angle in $angles) {
    $count++
    $frame = "{0:D3}" -f $count

    Write-Host "Фрейм $frame  кут = $angle градусів"

    if ($ANGLE_VAR -eq "CHI") {
        $psi = $FIXED_PSI
        $chi = $angle
    } else {
        $psi = $angle
        $chi = $FIXED_CHI
    }

    $tex = [regex]::Replace($src,
        '(?<=\\def\\myPsi\{)[^}]*(?=\})', "$psi")
    $tex = [regex]::Replace($tex,
        '(?<=\\def\\myChi\{)[^}]*(?=\})', "$chi")

    $frameTex = "$TMPDIR\frame_$frame.tex"
    Set-Content -Path $frameTex -Value $tex -Encoding UTF8

    # компілюємо
    $result = & lualatex --interaction=nonstopmode `
                         --output-directory="$TMPDIR" `
                         "$frameTex" 2>&1

    $framePdf = "$TMPDIR\frame_$frame.pdf"
    if (-not (Test-Path $framePdf)) {
        Write-Host "  ПОМИЛКА lualatex для фрейму $frame. Лог:"
        Write-Host ($result | Select-Object -Last 20 | Out-String)
        continue
    }

    # PDF -> PNG через pdftoppm
    $pngBase = "$TMPDIR\frame_$frame"
    & pdftoppm -png -r $DPI -singlefile "$framePdf" "$pngBase"

    if (-not (Test-Path "$pngBase.png")) {
        if (Test-Path "$pngBase-1.png") {
            Rename-Item "$pngBase-1.png" "$pngBase.png"
        } else {
            Write-Host "  ПОМИЛКА: PNG не створено для фрейму $frame"
        }
    }
}

# ----------------------------------------------------------------
Write-Host ""
Write-Host "Збираю відео з $count фреймів..."

& ffmpeg -y `
         -framerate $FRAMERATE `
         -i "$TMPDIR\frame_%03d.png" `
         -vf "scale=trunc(iw/2)*2:trunc(ih/2)*2" `
         -c:v libx264 `
         -pix_fmt yuv420p `
         $OUTPUT

if (Test-Path $OUTPUT) {
    Write-Host "Готово!  Файл: $OUTPUT"
} else {
    Write-Host "ПОМИЛКА: відео не створено."
}