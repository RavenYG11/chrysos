$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath (Split-Path -Parent $PSScriptRoot)
$flutterCommand = Get-Command flutter -ErrorAction SilentlyContinue
if ($flutterCommand) {
  & $flutterCommand.Source build web --no-web-resources-cdn --no-wasm-dry-run
} else {
  $packageConfig = Get-Content -LiteralPath '.dart_tool/package_config.json' -Raw | ConvertFrom-Json
  $flutterPackage = $packageConfig.packages | Where-Object { $_.name -eq 'flutter' } | Select-Object -First 1
  if (-not $flutterPackage) { throw 'Flutter SDK not found. Add Flutter to PATH and run flutter pub get.' }
  $sdkRoot = Split-Path -Parent (Split-Path -Parent ([Uri]$flutterPackage.rootUri).LocalPath)
  & (Join-Path $sdkRoot 'bin/cache/dart-sdk/bin/dart.exe') (Join-Path $sdkRoot 'bin/cache/flutter_tools.snapshot') build web --no-web-resources-cdn --no-wasm-dry-run
}
if ($LASTEXITCODE -ne 0) { throw 'Flutter web build failed.' }
node tool/preview-server.mjs
