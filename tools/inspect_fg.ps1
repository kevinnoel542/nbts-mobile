Add-Type -AssemblyName System.Drawing

$paths = @(
  'android/app/src/main/res/drawable-xxxhdpi/ic_launcher_foreground.png',
  'android/app/src/main/res/drawable-mdpi/ic_launcher_foreground.png'
)

foreach ($p in $paths) {
  if (-not (Test-Path $p)) { Write-Output "MISSING: $p"; continue }
  $bmp = New-Object System.Drawing.Bitmap $p
  $w = $bmp.Width
  $h = $bmp.Height
  Write-Output ("--- " + $p + " (" + $w + "x" + $h + ") ---")
  $samples = @(
    @([int]($w * 0.5), [int]($h * 0.5)),
    @([int]($w * 0.5), [int]($h * 0.40)),
    @([int]($w * 0.5), [int]($h * 0.60)),
    @([int]($w * 0.05), [int]($h * 0.05)),
    @([int]($w * 0.95), [int]($h * 0.95)),
    @([int]($w * 0.5), [int]($h * 0.20))
  )
  foreach ($s in $samples) {
    $c = $bmp.GetPixel($s[0], $s[1])
    Write-Output ("  (" + $s[0] + "," + $s[1] + ") = A" + $c.A + ",R" + $c.R + ",G" + $c.G + ",B" + $c.B)
  }
  $bmp.Dispose()
}
