Push-Location $PSScriptRoot
$Magick = ".\..\bin\magick.exe"

$files = Get-ChildItem -File -Path ./* -Include ("*.png", "*.jpg", "*.jpeg")

if ($null -eq $files) {
    throw [System.IO.FileNotFoundException] "World map file not found."
}

if ($files.Count -gt 1) {
    $mapChoice = [System.Management.Automation.Host.ChoiceDescription[]](@())
    for ($i = 0; $i -lt $files.Count; $i++) {
        $mapChoice += ((New-Object System.Management.Automation.Host.ChoiceDescription("$($files[$i].Name) &$i", "$($files[$i].Name)")))
    }

    $mapFile = $files[$Host.Ui.PromptForChoice("Map", "Choose the world map you want to use", $mapChoice, 0)].Name
}
else {
    $mapFile = $files[0]
}
$zoomChoice = [System.Management.Automation.Host.ChoiceDescription[]](@())
for ($i = 0; $i -lt 8; $i++) {
    $zoomChoice += ((New-Object System.Management.Automation.Host.ChoiceDescription("Zoom &$i", "Zoom $i")))
}
$zoomChoice += ((New-Object System.Management.Automation.Host.ChoiceDescription("&All", "All")))

$zoomLevel = $Host.Ui.PromptForChoice("Zoom", "Choose the zoom level you want to create", $zoomChoice, 8)

$Sizes = @(
    32768,
    16384,
    8192,
    4096,
    2048,
    1024,
    512,
    256
)

# TODO: automatically compute Divisors
<# $Divisors = @(
    @{x = 1; y = 1 },
    @{x = 2; y = 2 },
    @{x = 4; y = 3 },
    @{x = 8; y = 6 },
    @{x = 16; y = 12 },
    @{x = 32; y = 24 },
    @{x = 64; y = 48 },
    @{x = 127; y = 95 }
) #>
$Divisors = @(
    @{x = 1; y = 1 },
    @{x = 2; y = 2 },
    @{x = 4; y = 4 },
    @{x = 8; y = 8 },
    @{x = 16; y = 16 },
    @{x = 32; y = 32 },
    @{x = 64; y = 64 },
    @{x = 128; y = 128 }
)

# Prepare magick command params
$PrevExtent = $null
$LevelParams = @(".\$mapFile")

if (8 -eq $zoomLevel) {
    $LevelParams += "-write"
    for ($i = 0; $i -lt $Divisors.Length; $i++) {
        $Pow = 1 -shl ($Sizes.Length - $i - 1)
        $Divisor = $Divisors[$i]
        $Extent = @{x = $Divisor.x * $Sizes[$i]; y = $Divisor.y * $Sizes[$i] }
        $Scale = @{x = $Extent.x / $Pow ; y = $Extent.y / $Pow }

        <# if (($null -eq $PrevExtent) -or ($PrevExtent.x -ne $Extent.x) -or ($PrevExtent.y -ne $Extent.y)) {
            $LevelParams += "mpr:map", "-extent", "$($Extent.x)x$($Extent.y)"
            if ($i -lt $Divisors.Length - 1) {
                $LevelParams += "-write"
            }
        } #>
        
        $LevelParams += "mpr:tmp"
        if (($Scale.x -ne $Extent.x) -or ($Scale.y -ne $Extent.y)) {
            $LevelParams += "-scale", "$($Scale.x)x$($Scale.y)"
            if ($i -lt $Divisors.Length - 1) {
                $LevelParams += "-write"
            }
        }

        $LevelParams += ".\img\$i.jpg"
    
        if ($i -lt $Divisors.Length - 1) {
            $LevelParams += "+delete"
        }
    
        $PrevExtent = $Extent
    }
}
else {
    $i = $zoomLevel
    $Pow = 1 -shl ($Sizes.Length - $i - 1)
    $Divisor = $Divisors[$i]
    $Extent = @{x = $Divisor.x * $Sizes[$i]; y = $Divisor.y * $Sizes[$i] }
    $Scale = @{x = $Extent.x / $Pow ; y = $Extent.y / $Pow }

    $LevelParams += <# "-extent", "$($Extent.x)x$($Extent.y)", #> "-scale", "$($Scale.x)x$($Scale.y)", ".\img\$i.jpg"
}

$null = New-Item -ItemType Directory -Force -Path .\img

Write-Host "Exporting world map in progress"
& $Magick $LevelParams

Write-Host "Done"

Write-Host "Updating world map tiles"
$i = if ($zoomLevel -eq 8) { 0 } else { $zoomLevel }
for (; $i -lt 8; $i++) {
    $null = New-Item -ItemType Directory -Force -Path .\img\$i
    & $Magick .\img\$i.jpg -crop 256x256 -set filename:title "%[fx:page.y/256]_%[fx:page.x/256]" +repage +adjoin .\img\$i\%[filename:title].jpg
    if ($zoomLevel -ne 8) {
        break
    }
}

Write-Host "Done"

<# & $magick .\map_original.png `
-write mpr:map -extent 32768x32768 -write mpr:tmp -scale 256x256      -write .\out\0.jpg +delete `
                                          mpr:tmp -scale 512x512      -write .\out\1.jpg +delete `
       mpr:map -extent 32768x24576 -write mpr:tmp -scale 1024x768     -write .\out\2.jpg +delete `
                                          mpr:tmp -scale 2048x1536    -write .\out\3.jpg +delete `
                                          mpr:tmp -scale 4096x3072    -write .\out\4.jpg +delete `
                                          mpr:tmp -scale 8192x6144    -write .\out\5.jpg +delete `
                                          mpr:tmp -scale 16384x12288  -write .\out\6.jpg +delete `
       mpr:map -extent 32512x24320                                           .\out\7.jpg #>

<# for ($i = 0; $i -lt 8; $i++) {
    magick .\img\$i.jpg -crop 256x256 -set filename:title "%[fx:page.y/256]_%[fx:page.x/256]" +repage +adjoin .\out\$i\%[filename:title].jpg
} #>
