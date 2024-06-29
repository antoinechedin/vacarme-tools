Push-Location $PSScriptRoot

$null = New-Item -ItemType Directory -Force -Path .\bin
$null = New-Item -ItemType Directory -Force -Path .\tmp

$Url = "https://imagemagick.org/archive/binaries"
$Response = Invoke-WebRequest -Uri $Url
if ($Response.Content -match "(ImageMagick-7\.[0-9]+\.[0-9]+-[0-9]+-portable-Q8-x64).zip") {
    Write-Host "Dowloading ImageMagick"
    Invoke-WebRequest -Uri "$Url/$($Matches[0])" -OutFile ".\tmp\magick.zip"
    Write-Host "Installing ImageMagick"
    Expand-Archive ".\tmp\magick.zip" -DestinationPath ".\tmp"
    Move-Item -Path ".\tmp\$($Matches[1])\*" -Destination ".\bin" -Force

    Write-Host "Cleaning"
    Remove-Item ".\tmp" -Recurse -Force

    Write-Host "Installation finished"
}
else {
    Write-Error "Can't find ImageMagick 7 binaries"
}
