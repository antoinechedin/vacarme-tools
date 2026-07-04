Push-Location $PSScriptRoot
$Magick = ".\..\bin\magick.exe"

# Layers choice
$layers = Get-ChildItem -Directory -Path ./* -Filter *_layer

if ($null -eq $layers) {
    throw [System.IO.FileNotFoundException] "Couldn't find any map layers"
}

if ($layers.Count -gt 1) {
    $layerChoice = [System.Management.Automation.Host.ChoiceDescription[]](@())
    for ($i = 0; $i -lt $layers.Count; $i++) {
        $layerChoice += New-Object System.Management.Automation.Host.ChoiceDescription("&$($layers[$i].Name)")
    }

    $layerDirectory = $layers[$Host.Ui.PromptForChoice("Map", "Select a layer", $layerChoice, 0)]
}
else {
    $layerDirectory = $layers[0]
}


# Picture choice
$pictures = Get-ChildItem -File -Path ./$($layerDirectory.Name)/* -Include "*.png", "*.jpg", "*.jpeg"

if ($null -eq $pictures) {
    throw [System.IO.FileNotFoundException] "World map file not found."
}

if ($pictures.Count -gt 1) {
    $pictureChoice = [System.Management.Automation.Host.ChoiceDescription[]](@())
    for ($i = 0; $i -lt $pictures.Count; $i++) {
        $pictureChoice += New-Object System.Management.Automation.Host.ChoiceDescription("&$($pictures[$i].Name)")
    }

    $pictureFile = $pictures[$Host.Ui.PromptForChoice("Map", "Select a picture", $pictureChoice, 0)]
}
else {
    $pictureFile = $pictures[0]
}

# Zoom level choice
$zoomLevelChoice = [System.Management.Automation.Host.ChoiceDescription[]](@())
for ($i = 0; $i -lt 8; $i++) {
    $zoomLevelChoice += ((New-Object System.Management.Automation.Host.ChoiceDescription("Zoom &$i", "Zoom $i")))
}
$zoomLevelChoice += ((New-Object System.Management.Automation.Host.ChoiceDescription("&All", "All")))
$zoomLevel = $Host.Ui.PromptForChoice("Zoom", "Select a zoom level", $zoomLevelChoice, 8)


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
# $PrevExtent = $null
$LevelParams = @(".\$($layerDirectory.Name)\$($pictureFile.Name)")

# All zoom export
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

        $LevelParams += ".\$($layerDirectory.Name)\$i$($pictureFile.Extension)"
    
        if ($i -lt $Divisors.Length - 1) {
            $LevelParams += "+delete"
        }
    
        # $PrevExtent = $Extent
    }
}
else {
    $i = $zoomLevel
    $Pow = 1 -shl ($Sizes.Length - $i - 1)
    $Divisor = $Divisors[$i]
    $Extent = @{x = $Divisor.x * $Sizes[$i]; y = $Divisor.y * $Sizes[$i] }
    $Scale = @{x = $Extent.x / $Pow ; y = $Extent.y / $Pow }

    $LevelParams += <# "-extent", "$($Extent.x)x$($Extent.y)", #> "-scale", "$($Scale.x)x$($Scale.y)", ".\img\$($layerDirectory.Name)\$i$($pictureFile.Extension)"
}

$null = New-Item -ItemType Directory -Force -Path .\img\$($layerDirectory.Name)

Write-Host "Exporting world map in progress"
& $Magick $LevelParams

Write-Host "Done"

Write-Host "Updating world map tiles"
$i = if ($zoomLevel -eq 8) { 0 } else { $zoomLevel }
for (; $i -lt 8; $i++) {
    $null = New-Item -ItemType Directory -Force -Path .\img\$($layerDirectory.Name)\$i
    & $Magick .\img\$($layerDirectory.Name)\$i$($pictureFile.Extension) -quality 30 -crop 256x256 -set filename:title "%[fx:page.y/256]_%[fx:page.x/256]" +repage +adjoin .\img\$($layerDirectory.Name)\$i\%[filename:title]$($pictureFile.Extension)
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
