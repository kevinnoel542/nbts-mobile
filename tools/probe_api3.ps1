$base = 'http://192.168.0.119:8002'

Write-Output '--- POST /api/v1/auth/register (empty body, shows required fields) ---'
& curl.exe -sS -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{}' "$base/api/v1/auth/register"
Write-Output ''
Write-Output ''

Write-Output '--- POST /api/v1/auth/login (with phone+password, shows what happens) ---'
& curl.exe -sS -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{\"identifier\":\"test\",\"password\":\"test\"}' "$base/api/v1/auth/login"
Write-Output ''
Write-Output ''

Write-Output '--- /api/v1/eligibility (POST with empty) ---'
& curl.exe -sS -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{}' "$base/api/v1/eligibility"
Write-Output ''
Write-Output ''

# Probe more potential routes
$probes = @(
  @{ Method='GET';  Path='/api/v1/centers/public' },
  @{ Method='GET';  Path='/api/v1/campaigns/public' },
  @{ Method='GET';  Path='/api/v1/auth/logout' },
  @{ Method='POST'; Path='/api/v1/auth/logout'; Body='{}' },
  @{ Method='GET';  Path='/api/v1/user' },
  @{ Method='GET';  Path='/api/v1/blood-requests' },
  @{ Method='GET';  Path='/api/v1/centers/list' },
  @{ Method='GET';  Path='/api/v1/donations/me' },
  @{ Method='GET';  Path='/api/v1/donations/history' },
  @{ Method='GET';  Path='/api/v1/appointments/upcoming' },
  @{ Method='GET';  Path='/api/v1/profile/me' },
  @{ Method='GET';  Path='/api/v1/dashboard' },
  @{ Method='GET';  Path='/api/v1/home' },
  @{ Method='GET';  Path='/sanctum/csrf-cookie' },
  @{ Method='GET';  Path='/api/v1/impact-stats' },
  @{ Method='GET';  Path='/api/v1/stats/national' },
  @{ Method='GET';  Path='/api/v1/national-stats' }
)

foreach ($p in $probes) {
  $u = $base + $p.Path
  if ($p.Method -eq 'POST') {
    $code = & curl.exe -sS -o NUL -w '%{http_code}' -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d $p.Body $u
  } else {
    $code = & curl.exe -sS -o NUL -w '%{http_code}' -H 'Accept: application/json' $u
  }
  Write-Output ("{0,-6} {1,-50} -> {2}" -f $p.Method, $p.Path, $code)
}

Write-Output ''
Write-Output '--- Show first 60 lines of /api/v1 404 trace (looks for route list hints) ---'
& curl.exe -sS -H 'Accept: application/json' "$base/api/v1" | Select-Object -First 60
