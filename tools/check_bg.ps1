Add-Type -AssemblyName System.Drawing
$paths = @(
  'android/app/src/main/res/drawable/background.png',
  'android/app/src/main/res/drawable-night/background.png',
  'android/app/src/main/res/drawable-v21/background.png'
)
foreach ($p in $paths) {
  if (-not (Test-Path $p)) { Write-Output "MISSING: $p"; continue }
  $bmp = New-Object System.Drawing.Bitmap $p
  $c = $bmp.GetPixel(0, 0)
  Write-Output ($p + " (" + $bmp.Width + "x" + $bmp.Height + ") = A" + $c.A + " R" + $c.R + " G" + $c.G + " B" + $c.B)
  $bmp.Dispose()
}
