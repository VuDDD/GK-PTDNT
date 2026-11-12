param(
    [string]$Device = "chrome"
)

$ErrorActionPreference = "Stop"
$AppDir = $PSScriptRoot
$GkRoot = Split-Path -Parent $AppDir
$EmulatorDataDir = Join-Path $GkRoot "emulator_data"
$SyncScript = Join-Path $GkRoot "sync_to_firebase.mjs"

function Test-LocalPort {
    param([int]$Port)
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $async = $client.BeginConnect("127.0.0.1", $Port, $null, $null)
        $connected = $async.AsyncWaitHandle.WaitOne(250, $false)
        if ($connected -and $client.Connected) {
            $client.EndConnect($async) | Out-Null
            return $true
        }
        return $false
    } catch {
        return $false
    } finally {
        $client.Dispose()
    }
}

function Test-EmulatorHasData {
    try {
        $authResp = Invoke-RestMethod -Method Post `
            -Uri "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/projects/gk-ptdnt/accounts:query" `
            -Headers @{ Authorization = "Bearer owner"; "Content-Type" = "application/json" } `
            -Body '{"returnUserInfo":true}' `
            -TimeoutSec 3
        $hasUsers = ($authResp.userInfo -and $authResp.userInfo.Count -gt 0)

        $fsResp = Invoke-RestMethod -Uri "http://127.0.0.1:8080/v1/projects/gk-ptdnt/databases/(default)/documents/products" `
            -Headers @{ Authorization = "Bearer owner" } `
            -TimeoutSec 3
        $hasDocs = ($fsResp.documents -and $fsResp.documents.Count -gt 0)

        return ($hasUsers -or $hasDocs)
    } catch {
        return $false
    }
}

function Test-HasServiceAccount {
    param([string]$RootDir)
    if (Test-Path (Join-Path $RootDir "serviceAccountKey.json")) {
        return $true
    }
    $matched = Get-ChildItem -Path $RootDir -Filter "*firebase-adminsdk*.json" -ErrorAction SilentlyContinue
    return ($null -ne $matched -and @($matched).Count -gt 0)
}

function Invoke-DatabaseSync {
    param(
        [string]$RootDir,
        [string]$DataDir,
        [string]$SyncJs
    )
    try {
        Push-Location $RootDir
        # Chỉ ghi đè emulator_data/ nếu Emulator thực sự có tài khoản hoặc sản phẩm (tránh ghi đè rỗng).
        # Dùng cmd /c để tránh lỗi PowerShell NativeCommandError từ Node v24 UV_HANDLE_CLOSING trên stderr.
        if (Test-EmulatorHasData) {
            cmd /c "npx firebase-tools emulators:export `"$DataDir`" --force >nul 2>&1"
        }
        cmd /c "node `"$SyncJs`" --export-local-only >nul 2>&1"
        if (Test-HasServiceAccount -RootDir $RootDir) {
            cmd /c "node `"$SyncJs`" >nul 2>&1"
        }
    } catch {
        # Bỏ qua lỗi tạm thời trong background sync để không làm gián đoạn Flutter CLI
    } finally {
        Pop-Location
    }
}

$startedEmulatorHere = $false
$emulatorProcess = $null

$portsReady = (Test-LocalPort 8080) -and (Test-LocalPort 9099) -and (Test-LocalPort 9199)
if (-not $portsReady) {
    Write-Host "[1/3] Dang khoi dong Firebase Emulator Suite (nap tu emulator_data/)..." -ForegroundColor Cyan
    $emulatorArgs = "/c cd /d `"$GkRoot`" && npx firebase-tools emulators:start --only auth,firestore,storage --import=./emulator_data --export-on-exit=./emulator_data"
    $emulatorProcess = Start-Process -FilePath "cmd.exe" -ArgumentList $emulatorArgs -PassThru -WindowStyle Minimized
    $startedEmulatorHere = $true

    $deadline = (Get-Date).AddSeconds(60)
    while ((Get-Date) -lt $deadline) {
        if ((Test-LocalPort 8080) -and (Test-LocalPort 9099) -and (Test-LocalPort 9199)) {
            $portsReady = $true
            break
        }
        Start-Sleep -Seconds 1
    }

    if (-not $portsReady) {
        Write-Host "[Loi] Firebase Emulator chua san sang sau 60s. Kiem tra lai cua so Emulator." -ForegroundColor Red
        exit 1
    }
    Write-Host "[1/3] Firebase Emulator Suite da san sang (UI: http://localhost:4000)." -ForegroundColor Green
} else {
    Write-Host "[1/3] Firebase Emulator Suite dang chay san." -ForegroundColor Green
}

# Đồng bộ ngay ảnh từ thư mục product_images/ + local_products.json và khôi phục Admin nếu Emulator trống.
Push-Location $GkRoot
try {
    $prevPref = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    & node $SyncScript --hydrate-emulator
    if (Test-EmulatorHasData) {
        cmd /c "npx firebase-tools emulators:export `"$EmulatorDataDir`" --force >nul 2>&1"
    }
} finally {
    $ErrorActionPreference = $prevPref
    Pop-Location
}

if ($Device -like "emulator-*") {
    $adbPath = Join-Path $env:LOCALAPPDATA "Android\Sdk\platform-tools\adb.exe"
    if (Test-Path $adbPath) {
        & $adbPath reverse tcp:9199 tcp:9199 2>$null | Out-Null
    }
}

$initialSnapshot = ""
try {
    $initialSnapshot = Invoke-RestMethod `
        -Uri "http://127.0.0.1:8080/v1/projects/gk-ptdnt/databases/(default)/documents/products" `
        -Headers @{ Authorization = "Bearer owner" } `
        -TimeoutSec 3 | ConvertTo-Json -Compress -Depth 6
} catch {
    $initialSnapshot = "{}"
}

$getLocalFilesStamp = {
    param([string]$RootDir)
    $parts = @()
    $localJson = Join-Path $RootDir "local_products.json"
    if (Test-Path $localJson) {
        $f = Get-Item $localJson
        $parts += "$($f.Name):$($f.Length):$($f.LastWriteTimeUtc.Ticks)"
    }
    $imgDir = Join-Path $RootDir "product_images"
    if (Test-Path $imgDir) {
        Get-ChildItem -Path $imgDir -File | Sort-Object Name | ForEach-Object {
            if ($_.Name -ne ".upload_cache.json") {
                $parts += "$($_.Name):$($_.Length):$($_.LastWriteTimeUtc.Ticks)"
            }
        }
    }
    return ($parts -join "|")
}
$initialLocalStamp = & $getLocalFilesStamp $GkRoot

Write-Host "[2/3] Bat tien trinh tu dong dong bo du lieu & anh tu may tinh song song..." -ForegroundColor Cyan
$syncJob = Start-Job -ScriptBlock {
    param($RootDir, $DataDir, $SyncJs, $StartSnap, $StartLocalStamp)
    $lastSnapshot = $StartSnap
    $lastLocalStamp = $StartLocalStamp
    $firestoreUri = "http://127.0.0.1:8080/v1/projects/gk-ptdnt/databases/(default)/documents/products"
    $authUri = "http://127.0.0.1:9099/identitytoolkit.googleapis.com/v1/projects/gk-ptdnt/accounts:query"

    function Read-LocalStamp {
        param([string]$Dir)
        $parts = @()
        $localJson = Join-Path $Dir "local_products.json"
        if (Test-Path $localJson) {
            $f = Get-Item $localJson
            $parts += "$($f.Name):$($f.Length):$($f.LastWriteTimeUtc.Ticks)"
        }
        $imgDir = Join-Path $Dir "product_images"
        if (Test-Path $imgDir) {
            Get-ChildItem -Path $imgDir -File | Sort-Object Name | ForEach-Object {
                if ($_.Name -ne ".upload_cache.json") {
                    $parts += "$($_.Name):$($_.Length):$($_.LastWriteTimeUtc.Ticks)"
                }
            }
        }
        return ($parts -join "|")
    }

    while ($true) {
        Start-Sleep -Seconds 10
        try {
            $rawJson = Invoke-RestMethod -Uri $firestoreUri -Headers @{ Authorization = "Bearer owner" } -TimeoutSec 3 | ConvertTo-Json -Compress -Depth 6
            $currentLocalStamp = Read-LocalStamp -Dir $RootDir

            if ($rawJson -ne $lastSnapshot) {
                $authResp = Invoke-RestMethod -Method Post -Uri $authUri `
                    -Headers @{ Authorization = "Bearer owner"; "Content-Type" = "application/json" } `
                    -Body '{"returnUserInfo":true}' -TimeoutSec 3
                $hasUsers = ($authResp.userInfo -and $authResp.userInfo.Count -gt 0)

                if ($hasUsers) {
                    Set-Location $RootDir
                    cmd /c "npx firebase-tools emulators:export `"$DataDir`" --force >nul 2>&1"
                    cmd /c "node `"$SyncJs`" --export-local-only >nul 2>&1"
                    $hasSa = (Test-Path (Join-Path $RootDir "serviceAccountKey.json")) -or (@(Get-ChildItem -Path $RootDir -Filter "*firebase-adminsdk*.json" -ErrorAction SilentlyContinue).Count -gt 0)
                    if ($hasSa) {
                        cmd /c "node `"$SyncJs`" >nul 2>&1"
                    }
                    $lastSnapshot = Invoke-RestMethod -Uri $firestoreUri -Headers @{ Authorization = "Bearer owner" } -TimeoutSec 3 | ConvertTo-Json -Compress -Depth 6
                    $lastLocalStamp = Read-LocalStamp -Dir $RootDir
                }
            } elseif ($currentLocalStamp -ne $lastLocalStamp) {
                # Người dùng vừa thêm/sửa ảnh trong product_images/ hoặc sửa local_products.json trên máy tính
                Set-Location $RootDir
                cmd /c "node `"$SyncJs`" --sync-local-to-emulator >nul 2>&1"
                cmd /c "npx firebase-tools emulators:export `"$DataDir`" --force >nul 2>&1"
                $hasSa = (Test-Path (Join-Path $RootDir "serviceAccountKey.json")) -or (@(Get-ChildItem -Path $RootDir -Filter "*firebase-adminsdk*.json" -ErrorAction SilentlyContinue).Count -gt 0)
                if ($hasSa) {
                    cmd /c "node `"$SyncJs`" >nul 2>&1"
                }
                $lastSnapshot = Invoke-RestMethod -Uri $firestoreUri -Headers @{ Authorization = "Bearer owner" } -TimeoutSec 3 | ConvertTo-Json -Compress -Depth 6
                $lastLocalStamp = Read-LocalStamp -Dir $RootDir
            }
        } catch {
            # Cho lan kiem tra tiep theo
        }
    }
} -ArgumentList $GkRoot, $EmulatorDataDir, $SyncScript, $initialSnapshot, $initialLocalStamp

try {
    Write-Host "[3/3] Dang chay: flutter run -d $Device --dart-define=USE_EMULATOR=true" -ForegroundColor Cyan
    if (Test-HasServiceAccount -RootDir $GkRoot) {
        Write-Host "      Che do dong bo: product_images/ & local_products.json <-> Emulator <-> emulator_data/ -> Cloud (gk-ptdnt)" -ForegroundColor DarkGray
    } else {
        Write-Host "      Che do dong bo: product_images/ & local_products.json <-> Emulator <-> emulator_data/" -ForegroundColor DarkGray
    }

    Push-Location $AppDir
    & flutter run -d $Device --dart-define=USE_EMULATOR=true
} finally {
    Pop-Location
    Write-Host "`n[Dong bo cuoi] Dang luu toan bo thay doi database & anh vao may..." -ForegroundColor Cyan
    if ($syncJob) {
        Stop-Job -Job $syncJob -ErrorAction SilentlyContinue
        Remove-Job -Job $syncJob -Force -ErrorAction SilentlyContinue
    }
    Invoke-DatabaseSync -RootDir $GkRoot -DataDir $EmulatorDataDir -SyncJs $SyncScript
    Write-Host "[Hoan tat] Da cap nhat database & anh vao emulator_data/, product_images/ va local_products.json." -ForegroundColor Green
    if ($startedEmulatorHere -and $emulatorProcess -and (-not $emulatorProcess.HasExited)) {
        Write-Host "[Luu y] Cua so Firebase Emulator dang thu nho duoi taskbar (co the de chay tiep hoac nhan Ctrl+C de tat)." -ForegroundColor Yellow
    }
}
