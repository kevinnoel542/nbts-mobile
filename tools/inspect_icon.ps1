Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap 'assets/icon/app_icon.png'
Write-Output ("Size: " + $bmp.Width + "x" + $bmp.Height)

$points = @(
  @(512, 512),
  @(512, 300),
  @(512, 700),
  @(300, 600),
  @(700, 600),
  @(50, 50),
  @(512, 50),
  @(512, 950),
  @(950, 512),
  @(100, 512),
  @(512, 220),
  @(512, 860)
)

foreach ($p in $points) {
  $c = $bmp.GetPixel($p[0], $p[1])
  Write-Output ("(" + $p[0] + "," + $p[1] + ") = " + $c.A + "," + $c.R + "," + $c.G + "," + $c.B)
}

$bmp.Dispose()

$bmp2 = New-Object System.Drawing.Bitmap 'assets/icon/app_icon_foreground.png'
Write-Output ("--- foreground ---")
Write-Output ("Size: " + $bmp2.Width + "x" + $bmp2.Height)
foreach ($p in $points) {
  $c = $bmp2.GetPixel($p[0], $p[1])
  Write-Output ("(" + $p[0] + "," + $p[1] + ") = " + $c.A + "," + $c.R + "," + $c.G + "," + $c.B)
}
$bmp2.Dispose()
