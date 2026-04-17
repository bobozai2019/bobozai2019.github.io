$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$indexPath = Join-Path $root "index.html"
$stylesPath = Join-Path $root "styles.css"

if (-not (Test-Path $indexPath)) {
  throw "Missing index.html"
}

if (-not (Test-Path $stylesPath)) {
  throw "Missing styles.css"
}

$index = Get-Content -Raw -Path $indexPath
$styles = Get-Content -Raw -Path $stylesPath

$checks = @(
  [pscustomobject]@{
    Name = "new Godot analysis project is linked"
    Pass = $index.Contains("https://github.com/bobozai2019/godot-project-analysis")
  }
  [pscustomobject]@{
    Name = "hero positions the site around game AI programming"
    Pass = $index.Contains("AI Game Programmer")
  }
  [pscustomobject]@{
    Name = "Godot analysis project is presented as a core project"
    Pass = $index.Contains("Godot Project Analysis")
  }
  [pscustomobject]@{
    Name = "project capabilities mention Layer 0-4 pipeline"
    Pass = $index.Contains("Layer 0-4")
  }
  [pscustomobject]@{
    Name = "dark technical visual system is present"
    Pass = $styles.Contains("--bg:") -and $styles.Contains(".signal-panel")
  }
)

$failed = @($checks | Where-Object { -not $_.Pass })

if ($failed.Count -gt 0) {
  foreach ($check in $failed) {
    Write-Host "FAIL: $($check.Name)"
  }
  exit 1
}

foreach ($check in $checks) {
  Write-Host "PASS: $($check.Name)"
}
