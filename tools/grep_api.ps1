$matches = Get-ChildItem -Path lib -Recurse -Include *.dart |
  Select-String -Pattern 'ApiClient|ApiConfig|api_client\.dart|api_config\.dart|192\.168|package:http'

foreach ($m in $matches) {
  Write-Output ($m.Path + ":" + $m.LineNumber + ": " + $m.Line.Trim())
}
Write-Output ("--- total matches: " + $matches.Count)
