$base = 'http://192.168.0.130:8003'
$paths = @(
  '/api/v1',
  '/api/v1/',
  '/api/v1/centers',
  '/api/v1/blood-centers',
  '/api/v1/campaigns',
  '/api/v1/articles',
  '/api/v1/stats',
  '/api/v1/impact',
  '/api/v1/eligibility',
  '/api/v1/auth/login',
  '/api/v1/profile',
  '/api/v1/me',
  '/api/v1/donations',
  '/api/v1/appointments',
  '/api/centers',
  '/api/blood-centers',
  '/api/campaigns',
  '/api/stats'
)

if (-not (Test-Path tools/api_dump)) { New-Item -ItemType Directory -Path tools/api_dump -Force | Out-Null }

foreach ($p in $paths) {
  $u = $base + $p
  $safe = ($p -replace '[/]', '_').Trim('_')
  if ([string]::IsNullOrEmpty($safe)) { $safe = 'root' }
  $out = "tools/api_dump/$safe.txt"
  $result = & curl.exe -sS -H 'Accept: application/json' -H 'X-Requested-With: XMLHttpRequest' -o $out -w '%{http_code}|%{content_type}|%{size_download}' $u 2>&1
  Write-Output ("$p  ->  $result")
}

