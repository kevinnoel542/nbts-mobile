Add-Type -AssemblyName System.Drawing
$paths = @(
  'ios/Runner/Assets.xcassets/LaunchBackground.imageset/background.png',
  'ios/Runner/Assets.xcassets/LaunchBackground.imageset/darkbackground.png'
)
foreach ($p in $paths) {
  if (-not (Test-Path $p)) { Write-Output "MISSING: $p"; continue }
  $bmp = New-Object System.Drawing.Bitmap $p
  $c = $bmp.GetPixel(0, 0)
  Write-Output ($p + " (" + $bmp.Width + "x" + $bmp.Height + ") = A" + $c.A + " R" + $c.R + " G" + $c.G + " B" + $c.B)
  $bmp.Dispose()
}
