$ErrorActionPreference = "Stop"

$config = . (Join-Path $PSScriptRoot "ops\open_webui_config.ps1")

Set-Location $config.ProjectDir

& $config.OpenWebuiExe "serve" "--port" $config.Port
