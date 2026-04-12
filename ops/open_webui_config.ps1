$projectDir = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$venvDir = Join-Path $projectDir "venv"

return @{
    ProjectDir = $projectDir
    VenvDir = $venvDir
    Port = 18445
    DataDir = Join-Path $venvDir "Lib\site-packages\open_webui\data"
    PythonExe = Join-Path $venvDir "Scripts\python.exe"
    OpenWebuiExe = Join-Path $venvDir "Scripts\open-webui.exe"
    LogsDir = Join-Path $projectDir "logs"
    BackupRoot = Join-Path $projectDir "backups"
    NssmExe = Join-Path $projectDir "bin\nssm.exe"
    ServiceName = "OpenWebUI"
    ServiceDisplayName = "Open WebUI"
}
