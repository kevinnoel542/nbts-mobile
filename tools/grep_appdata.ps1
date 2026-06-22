$matches = Get-ChildItem -Path lib -Recurse -Include *.dart |
  Select-String -Pattern 'AppData\.|app_data\.dart'

foreach ($m in $matches) {
  Write-Output ($m.Path + ":" + $m.LineNumber + ": " + $m.Line.Trim())
}
Write-Output ("--- total matches: " + $matches.Count)
