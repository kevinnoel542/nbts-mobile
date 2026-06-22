param(
  [string]$OutDir = "assets/icon"
)

Add-Type -AssemblyName System.Drawing

if (!(Test-Path $OutDir)) {
  New-Item -ItemType Directory -Path $OutDir -Force | Out-Null
}

function New-DropPath {
  param(
    [int]$size,
    [double]$scale = 1.0
  )
  $cx = $size * 0.5
  $halfH = $size * 0.34 * $scale
  $halfW = $size * 0.30 * $scale
  $top = $cx - $halfH
  $bot = $cx + $halfH
  $widestY = $cx + ($halfH * 0.30)
  $rightX = $cx + $halfW
  $leftX = $cx - $halfW
  $cp1Y = $cx - ($halfH * 0.45)
  $cp2X = $cx + ($halfW * 0.40)
  $cp3X = $cx - ($halfW * 0.40)

  $p = New-Object System.Drawing.Drawing2D.GraphicsPath
  $p.AddBezier([int]$cx, [int]$top, [int]$cp2X, [int]$cp1Y, [int]$rightX, [int]($cx - $halfH * 0.10), [int]$rightX, [int]$widestY)
  $p.AddBezier([int]$rightX, [int]$widestY, [int]$rightX, [int]($cx + $halfH * 0.55), [int]($cx + $halfW * 0.55), [int]$bot, [int]$cx, [int]$bot)
  $p.AddBezier([int]$cx, [int]$bot, [int]($cx - $halfW * 0.55), [int]$bot, [int]$leftX, [int]($cx + $halfH * 0.55), [int]$leftX, [int]$widestY)
  $p.AddBezier([int]$leftX, [int]$widestY, [int]$leftX, [int]($cx - $halfH * 0.10), [int]$cp3X, [int]$cp1Y, [int]$cx, [int]$top)
  $p.CloseFigure()
  return $p
}

function Save-Icon {
  param(
    [int]$size,
    [string]$path,
    [string]$mode  # 'square' or 'adaptive'
  )

  $bmp = New-Object System.Drawing.Bitmap $size, $size
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

  if ($mode -eq 'square') {
    $bg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 198, 40, 40))
    $g.FillRectangle($bg, 0, 0, $size, $size)
    $bg.Dispose()
    $drop = New-DropPath -size $size -scale 1.0
  } else {
    $g.Clear([System.Drawing.Color]::Transparent)
    $drop = New-DropPath -size $size -scale 0.62
  }

  $white = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::White)
  $g.FillPath($white, $drop)

  $white.Dispose()
  $drop.Dispose()
  $g.Dispose()
  $bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png)
  $bmp.Dispose()
}

Save-Icon -size 1024 -path (Join-Path $OutDir "app_icon.png") -mode 'square'
Save-Icon -size 1024 -path (Join-Path $OutDir "app_icon_foreground.png") -mode 'adaptive'

Write-Output "done"
