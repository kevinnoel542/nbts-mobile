$base = 'http://192.168.0.130:8003'

Write-Output '--- 401 body (any protected route) ---'
& curl.exe -sS -H 'Accept: application/json' "$base/api/v1/profile"
Write-Output ''
Write-Output ''

Write-Output '--- 405 body (login GET) ---'
& curl.exe -sS -H 'Accept: application/json' "$base/api/v1/auth/login"
Write-Output ''
Write-Output ''

Write-Output '--- POST /api/v1/auth/login (empty body) ---'
& curl.exe -sS -X POST -H 'Accept: application/json' -H 'Content-Type: application/json' -d '{}' "$base/api/v1/auth/login"
Write-Output ''
Write-Output ''

# Probe POST-only & register / OTP / public routes
$probes = @(
  @{ Method='POST'; Path='/api/v1/auth/register'; Body='{}' },
  @{ Method='POST'; Path='/api/v1/auth/otp/request'; Body='{}' },
  @{ Method='POST'; Path='/api/v1/auth/otp/verify'; Body='{}' },
  @{ Method='POST'; Path='/api/v1/auth/forgot-password'; Body='{}' },
  @{ Method='GET';  Path='/api/v1/auth/me' },
  @{ Method='GET';  Path='/api/v1/public/blood-centers' },
  @{ Method='GET';  Path='/api/v1/public/campaigns' },
  @{ Method='GET';  Path='/api/v1/public/stats' },
  @{ Method='GET';  Path='/api/v1/public/impact' },
  @{ Method='GET';  Path='/api/v1/stats/public' },
  @{ Method='GET';  Path='/api/v1/impact/public' },
  @{ Method='GET';  Path='/api/v1/blood-types' },
  @{ Method='GET';  Path='/api/v1/donation-types' },
  @{ Method='GET';  Path='/api/v1/regions' },
  @{ Method='GET';  Path='/api/v1/news' },
  @{ Method='GET';  Path='/api/v1/health-tips' },
  @{ Method='GET';  Path='/api/v1/eligibility-check' },
  @{ Method='POST'; Path='/api/v1/eligibility'; Body='{}' },
  @{ Method='GET';  Path='/api/v1/notifications' }
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

