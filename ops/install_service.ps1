$ErrorActionPreference = "Stop"

$config = . (Join-Path $PSScriptRoot "open_webui_config.ps1")

$projectDir = $config.ProjectDir
$nssmExe = $config.NssmExe
$appExe = $config.OpenWebuiExe
$logsDir = $config.LogsDir
$serviceName = $config.ServiceName
$displayName = $config.ServiceDisplayName
$port = $config.Port

function Test-RequiredPath {
    param(
        [string]$Path,
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Description 경로를 찾을 수 없습니다: $Path"
    }
}

Test-RequiredPath -Path $nssmExe -Description "nssm.exe"
Test-RequiredPath -Path $appExe -Description "open-webui.exe"

$description = "Open WebUI service on port $port"

New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

& $nssmExe install $serviceName $appExe "serve" "--port" $port
& $nssmExe set $serviceName AppDirectory $projectDir
& $nssmExe set $serviceName DisplayName $displayName
& $nssmExe set $serviceName Description $description
& $nssmExe set $serviceName Start SERVICE_AUTO_START
& sc.exe config $serviceName start= delayed-auto | Out-Null
& $nssmExe set $serviceName AppStdout (Join-Path $logsDir "open-webui-service.out.log")
& $nssmExe set $serviceName AppStderr (Join-Path $logsDir "open-webui-service.err.log")
& $nssmExe set $serviceName AppRotateFiles 1
& $nssmExe set $serviceName AppRotateOnline 1
& $nssmExe set $serviceName AppRotateBytes 10485760

Write-Host ""
Write-Host "서비스 등록이 완료되었습니다." -ForegroundColor Green
Write-Host "서비스 이름: $serviceName"
Write-Host "포트: $port"
Write-Host "시작 유형: 지연된 자동 시작"
Write-Host "로그 폴더: $logsDir"
Write-Host ""
Write-Host "시작 명령:"
Write-Host "  nssm start $serviceName"
