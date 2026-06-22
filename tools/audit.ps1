Add-Type -AssemblyName System.Drawing

function Show-Pixels {
  param([string]$path, [string]$label)
  if (-not (Test-Path $path)) { Write-Output ("MISSING: " + $label + " -> " + $path); return }
  $bmp = New-Object System.Drawing.Bitmap $path
  $w = $bmp.Width; $h = $bmp.Height
  $cx = [int]($w * 0.5); $cy = [int]($h * 0.5)
  $center = $bmp.GetPixel($cx, $cy)
  $tl = $bmp.GetPixel([int]($w * 0.05), [int]($h * 0.05))
  $br = $bmp.GetPixel([int]($w * 0.95), [int]($h * 0.95))
  Write-Output ($label + " (" + $w + "x" + $h + ")")
  Write-Output ("  center  = A" + $center.A + " R" + $center.R + " G" + $center.G + " B" + $center.B)
  Write-Output ("  top-lt  = A" + $tl.A + " R" + $tl.R + " G" + $tl.G + " B" + $tl.B)
  Write-Output ("  bot-rt  = A" + $br.A + " R" + $br.R + " G" + $br.G + " B" + $br.B)
  $bmp.Dispose()
}

Write-Output "=== SOURCE ASSETS ==="
Show-Pixels "assets/icon/app_icon.png" "app_icon.png"
Show-Pixels "assets/icon/app_icon_foreground.png" "app_icon_foreground.png"

Write-Output ""
Write-Output "=== ANDROID LAUNCHER (non-adaptive ic_launcher.png) ==="
Show-Pixels "android/app/src/main/res/mipmap-mdpi/ic_launcher.png" "mdpi/ic_launcher.png"
Show-Pixels "android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png" "xxxhdpi/ic_launcher.png"

Write-Output ""
Write-Output "=== ANDROID ADAPTIVE FOREGROUND ==="
Show-Pixels "android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png" "mdpi/ic_launcher_foreground.png"
Show-Pixels "android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png" "xxxhdpi/ic_launcher_foreground.png"

Write-Output ""
Write-Output "=== iOS APP ICON ==="
Show-Pixels "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png" "iOS 1024@1x"
Show-Pixels "ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png" "iOS 60@3x"

Write-Output ""
Write-Output "=== ANDROID NATIVE SPLASH ==="
Show-Pixels "android/app/src/main/res/drawable-mdpi/splash.png" "android splash mdpi"
Show-Pixels "android/app/src/main/res/drawable-xxxhdpi/splash.png" "android splash xxxhdpi"
Show-Pixels "android/app/src/main/res/drawable-night-mdpi/splash.png" "android splash night mdpi"

Write-Output ""
Write-Output "=== iOS LAUNCH IMAGE ==="
Show-Pixels "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png" "iOS launch @1x"
Show-Pixels "ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png" "iOS launch @3x"
