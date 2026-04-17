$ErrorActionPreference = "Stop"

$config = . (Join-Path $PSScriptRoot "open_webui_config.ps1")

$projectDir = $config.ProjectDir
$logsDir = $config.LogsDir
$serviceName = $config.ServiceName
$displayName = $config.ServiceDisplayName
$port = $config.Port
$appExe = $config.OpenWebuiExe

function Ensure-Admin {
    $currentIdentity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentIdentity)
    if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        throw "관리자 권한 PowerShell에서 실행해야 합니다."
    }
}

function Find-NssmPath {
    $localNssm = $config.NssmExe
    if (Test-Path -LiteralPath $localNssm) {
        return $localNssm
    }

    throw "bin\nssm.exe를 찾을 수 없습니다. 프로젝트 로컬 NSSM 바이너리를 확인해 주세요."
}

function Test-RequiredPath {
    param(
        [string]$Path,
        [string]$Description
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        throw "$Description 경로를 찾을 수 없습니다: $Path"
    }
}

function Remove-ServiceIfExists {
    param([string]$Name)

    $existing = Get-Service -Name $Name -ErrorAction SilentlyContinue
    if ($existing) {
        & $nssm stop $Name confirm | Out-Null
        & $nssm remove $Name confirm | Out-Null
    }
}

function Install-NssmService {
    param(
        [string]$Name,
        [string]$DisplayName,
        [string]$ExecutablePath,
        [int]$ListenPort
    )

    & $nssm install $Name $ExecutablePath "serve" "--port" $ListenPort | Out-Null
    & $nssm set $Name DisplayName $DisplayName | Out-Null
    & $nssm set $Name Description "Open WebUI service on port $ListenPort" | Out-Null
    & $nssm set $Name AppDirectory $projectDir | Out-Null
    & $nssm set $Name Start SERVICE_AUTO_START | Out-Null
    & $nssm set $Name AppStdout (Join-Path $logsDir "open-webui-service.out.log") | Out-Null
    & $nssm set $Name AppStderr (Join-Path $logsDir "open-webui-service.err.log") | Out-Null
    & $nssm set $Name AppRotateFiles 1 | Out-Null
    & $nssm set $Name AppRotateOnline 1 | Out-Null
    & $nssm set $Name AppRotateBytes 1048576 | Out-Null

    sc.exe config $Name start= delayed-auto | Out-Null
    if ($LASTEXITCODE -ne 0) {
        throw "$Name 서비스의 시작 유형을 자동(지연된 시작)으로 설정하지 못했습니다."
    }
}

Ensure-Admin

Test-RequiredPath -Path $appExe -Description "open-webui.exe"
New-Item -ItemType Directory -Force -Path $logsDir | Out-Null

$nssm = Find-NssmPath

Remove-ServiceIfExists -Name $serviceName
Install-NssmService -Name $serviceName -DisplayName $displayName -ExecutablePath $appExe -ListenPort $port

& $nssm start $serviceName | Out-Null

Get-Service $serviceName | Select-Object Name,Status,StartType
