Add-Type -AssemblyName System.Drawing

$paths = @(
  'android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png',
  'android/app/src/main/res/mipmap-mdpi/ic_launcher.png',
  'ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png'
)

foreach ($p in $paths) {
  if (-not (Test-Path $p)) { Write-Output "MISSING: $p"; continue }
  $bmp = New-Object System.Drawing.Bitmap $p
  $w = $bmp.Width
  $h = $bmp.Height
  Write-Output ("--- " + $p + " ("+ $w + "x" + $h + ") ---")
  $samples = @(
    @([int]($w * 0.5), [int]($h * 0.5)),
    @([int]($w * 0.5), [int]($h * 0.25)),
    @([int]($w * 0.5), [int]($h * 0.75)),
    @([int]($w * 0.05), [int]($h * 0.05)),
    @([int]($w * 0.95), [int]($h * 0.95))
  )
  foreach ($s in $samples) {
    $c = $bmp.GetPixel($s[0], $s[1])
    Write-Output ("  (" + $s[0] + "," + $s[1] + ") = " + $c.A + "," + $c.R + "," + $c.G + "," + $c.B)
  }
  $bmp.Dispose()
}
