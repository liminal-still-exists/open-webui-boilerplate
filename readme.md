# 목적
- 이 폴더의 역할은 Open WebUI 앱을 로컬 포트 `18445`에서 실행하고 Windows 서비스로 운영하는 것이다.
- 외부 공개 URL, HTTPS, 경로 분기, 공용 리버스 프록시 구성은 이 폴더에서 맡지 않는다.

# 운영 기준 파일
- 설정: `.\ops\open_webui_config.ps1`
- 서비스 설치: `.\ops\register_windows_services.ps1`
- 서비스 재시작: `.\ops\restart_service.ps1`
- 백업 및 업데이트: `.\ops\backup_and_update_open_webui.ps1`
- 수동 직접 실행: `.\run_open_webui.ps1`

# GitHub 보관 기준
이 저장소는 Open WebUI 운영 환경을 다시 세우기 위한 보일러플레이트 용도다.

커밋 대상:
- `.\ops\*.ps1`
- `.\run_open_webui.ps1`
- `.\readme.md`
- `.\bin\nssm.exe`
- `.\.gitignore`

커밋 제외 대상:
- `.\venv\`
- `.\logs\`
- `.\backups\`
- `.\.webui_secret_key`
- `.\venv\Lib\site-packages\open_webui\data`

즉 GitHub 저장소만으로는 운영 데이터 복구까지 되지 않는다. 실제 복구를 위해서는 최소한 `data` 폴더와 필요 시 `.webui_secret_key`를 별도 백업해야 한다.

# 서비스 운영
서비스로 운영하는 것을 기본 기준으로 삼는다.

서비스 설치:

```powershell
.\ops\register_windows_services.ps1
```

서비스 재시작:

```powershell
.\ops\restart_service.ps1
```

서비스 상태 확인:

```powershell
Get-Service -Name OpenWebUI
```

서비스 로그 확인:

```powershell
Get-Content .\logs\open-webui-service.out.log -Tail 100
Get-Content .\logs\open-webui-service.err.log -Tail 100
```

# 접속 주소
- 로컬 주소: `http://127.0.0.1:18445`
- 외부 URL이 실패하면 먼저 `OpenWebUI` 서비스 상태와 로컬 포트 응답을 확인한다.

로컬 포트 확인:

```powershell
Invoke-WebRequest -UseBasicParsing http://127.0.0.1:18445
```

# 직접 실행
서비스가 아니라 콘솔에서 직접 띄워야 할 때만 아래 파일을 사용한다.

```powershell
.\run_open_webui.ps1
```

# 설치 방법
처음 구성할 때는 아래 순서로 설치한다.

```powershell
cd .\open-webui
python -m venv venv
.\venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install open-webui
```

# 현재 구조
- 이 폴더는 Open WebUI를 파이썬 `venv`에 설치해서 실행하는 작업 폴더다.
- 데이터는 기본적으로 `.\venv\Lib\site-packages\open_webui\data` 아래에 저장된다.
- 코드와 데이터가 분리된 구조가 아니라, 패키지 내부에 데이터가 같이 들어가는 형태다.
- 포트와 주요 경로는 `.\ops\open_webui_config.ps1` 한 군데에서 관리한다.

# 실제 데이터 위치
핵심 데이터 폴더는 아래 경로다.

```text
.\venv\Lib\site-packages\open_webui\data
```

주요 구성은 대략 다음과 같다.
- `webui.db`: 사용자, 채팅, 설정 등 핵심 DB
- `uploads`: 업로드한 원본 파일
- `vector_db`: 지식베이스와 RAG용 벡터 데이터
- `cache`: 캐시 데이터

# 백업 대상
업데이트 목적이라면 필수 백업 대상은 아래 하나다.

```text
.\venv\Lib\site-packages\open_webui\data
```

설명:
- `data` 폴더가 가장 중요하다.
- 현재 구조에서는 업데이트 리스크가 거의 이 경로에 집중된다.
- `.webui_secret_key`는 `venv` 바깥 경로에 있으므로, 단순 패키지 업데이트만 할 때는 필수 백업 대상으로 보지 않아도 된다.
- 다만 폴더 전체 이동, 전체 재설치, 다른 PC 복원까지 고려하면 `.webui_secret_key`도 같이 백업하는 편이 더 안전하다.

# 업데이트 방법
기존 `venv`는 그대로 두고, 백업 후 업데이트하는 방식으로 관리한다.

가장 간단한 방법은 아래 파일을 실행하는 것이다.

```powershell
.\ops\backup_and_update_open_webui.ps1
```

현재 스크립트 동작:
- Open WebUI 실행 중이면 중단한다.
- 현재 설치 버전과 PyPI 최신 버전을 비교한다.
- 이미 최신이면 백업과 업데이트를 건너뛴다.
- 최신이 아니면 `data` 폴더를 먼저 백업한다.
- 그다음 `pip`와 `open-webui`를 업데이트한다.
- 마지막에 버전 변경 결과와 백업 위치를 출력한다.

수동 업데이트 절차:
1. Open WebUI를 종료한다.
2. `.\venv\Lib\site-packages\open_webui\data`를 다른 위치에 복사해 백업한다.
3. PowerShell에서 `venv`를 활성화한다.
4. `open-webui` 패키지를 업데이트한다.
5. 실행 후 정상 동작 여부를 확인한다.
6. 문제 발생 시 백업한 `data`를 원래 위치로 복구한다.

예시:

```powershell
.\venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install --upgrade open-webui
```

자동 백업을 사용한 경우 백업 폴더는 아래 형식으로 생성된다.

```text
.\backups\open-webui-data-YYYYMMDD-HHMMSS
```
