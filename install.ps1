$null = New-Item -ItemType Directory -Force -Path .\bin
$null = New-Item -ItemType Directory -Force -Path .\tmp

Write-Host "Downloading FFMPEG"
Invoke-WebRequest -Uri "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" -OutFile ".\tmp\ffmpeg.zip"
Write-Host "Installing FFMPEG"
Expand-Archive ".\tmp\ffmpeg.zip" -DestinationPath ".\tmp"
Move-Item -Path ".\tmp\ffmpeg-master-latest-win64-gpl\bin\*" -Destination ".\bin" -Force

Write-Host "Dowloading ImageMagick"
Invoke-WebRequest -Uri "https://imagemagick.org/archive/binaries/ImageMagick-7.1.1-33-portable-Q8-x64.zip" -OutFile ".\tmp\magick.zip"
Write-Host "Installing ImageMagick"
Expand-Archive ".\tmp\magick.zip" -DestinationPath ".\tmp"
Move-Item -Path ".\tmp\ImageMagick-7.1.1-33-portable-Q8-x64\*" -Destination ".\bin" -Force

Write-Host "Cleaning"
Remove-Item ".\tmp" -Recurse -Force

Write-Host "Installation finished"