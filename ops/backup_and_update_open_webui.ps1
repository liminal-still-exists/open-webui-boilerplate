$ErrorActionPreference = "Stop"

$config = . (Join-Path $PSScriptRoot "open_webui_config.ps1")

$projectDir = $config.ProjectDir
$pythonExe = $config.PythonExe
$pipArgs = @("-m", "pip")
$dataDir = $config.DataDir
$backupRoot = $config.BackupRoot
$serviceName = $config.ServiceName
$timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
$backupDir = Join-Path $backupRoot "open-webui-data-$timestamp"

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "[*] $Message" -ForegroundColor Cyan
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

function Get-OpenWebuiVersion {
    $version = & $pythonExe -m pip show open-webui 2>$null |
        Select-String "^Version:" |
        ForEach-Object { $_.ToString().Split(":", 2)[1].Trim() } |
        Select-Object -First 1

    if ([string]::IsNullOrWhiteSpace($version)) {
        return "(확인 불가)"
    }

    return $version
}

function Get-LatestOpenWebuiVersion {
    try {
        $response = Invoke-RestMethod -Uri "https://pypi.org/pypi/open-webui/json"
        $version = $response.info.version

        if ([string]::IsNullOrWhiteSpace($version)) {
            return "(확인 불가)"
        }

        return $version
    }
    catch {
        return "(확인 불가)"
    }
}

Write-Host "Open WebUI 백업 및 업데이트를 시작합니다." -ForegroundColor Green
Write-Host "작업 폴더: $projectDir"

Test-RequiredPath -Path $pythonExe -Description "Python 실행 파일"
Test-RequiredPath -Path $dataDir -Description "Open WebUI 데이터 폴더"

$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
$restartServiceAfterUpdate = $false
if ($service -and $service.Status -ne "Stopped") {
    $restartServiceAfterUpdate = $true
    Write-Host "$serviceName 서비스를 중지합니다." -ForegroundColor Yellow
    Stop-Service -Name $serviceName -Force
    $service.WaitForStatus("Stopped", [TimeSpan]::FromSeconds(60))
}

$runningProcess = Get-Process -Name "open-webui" -ErrorAction SilentlyContinue
if ($runningProcess) {
    Write-Host "실행 중인 open-webui 프로세스를 종료합니다." -ForegroundColor Yellow
    $runningProcess | Stop-Process -Force
    Start-Sleep -Seconds 2
}

$remainingProcess = Get-Process -Name "open-webui" -ErrorAction SilentlyContinue
if ($remainingProcess) {
    throw "open-webui 프로세스를 종료하지 못했습니다. 잠시 후 다시 시도해 주세요."
}

$currentVersion = Get-OpenWebuiVersion
$latestVersion = Get-LatestOpenWebuiVersion
Write-Host "현재 open-webui 버전: $currentVersion" -ForegroundColor Yellow
Write-Host "최신 open-webui 버전: $latestVersion" -ForegroundColor Yellow

if ($latestVersion -ne "(확인 불가)" -and $currentVersion -eq $latestVersion) {
    Write-Host ""
    Write-Host "이미 최신 버전입니다. 백업과 업데이트를 건너뜁니다." -ForegroundColor Green
    if ($restartServiceAfterUpdate) {
        Write-Host "$serviceName 서비스를 다시 시작합니다." -ForegroundColor Yellow
        Start-Service -Name $serviceName
        (Get-Service -Name $serviceName).WaitForStatus("Running", [TimeSpan]::FromSeconds(60))
    }
    exit 0
}

Write-Step "백업 폴더 생성"
New-Item -ItemType Directory -Path $backupRoot -Force | Out-Null

Write-Step "data 폴더 백업"
Copy-Item -LiteralPath $dataDir -Destination $backupDir -Recurse -Force

Write-Step "pip 업그레이드"
& $pythonExe @pipArgs install --upgrade pip

Write-Step "open-webui 업그레이드"
& $pythonExe @pipArgs install --upgrade open-webui

$updatedVersion = Get-OpenWebuiVersion

Write-Host ""
Write-Host "업데이트가 완료되었습니다." -ForegroundColor Green
Write-Host "버전: $currentVersion -> $updatedVersion"
Write-Host "data 백업 위치: $backupDir"
if ($restartServiceAfterUpdate) {
    Write-Host "$serviceName 서비스를 다시 시작합니다." -ForegroundColor Yellow
    Start-Service -Name $serviceName
    (Get-Service -Name $serviceName).WaitForStatus("Running", [TimeSpan]::FromSeconds(60))
}
