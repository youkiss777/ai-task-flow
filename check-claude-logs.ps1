# Claude for Desktop ログ確認スクリプト
# MCPで Claude Code 追加失敗後のログ分析用

Write-Host "=== Claude for Desktop ログ確認 ===" -ForegroundColor Green

# ログディレクトリの場所を確認
$logPaths = @(
    "$env:APPDATA\Claude\logs",
    "$env:LOCALAPPDATA\Claude\logs"
)

foreach ($path in $logPaths) {
    if (Test-Path $path) {
        Write-Host "`n=== ログディレクトリ: $path ===" -ForegroundColor Yellow
        
        # 最新の5つのログファイルを取得
        $logs = Get-ChildItem $path -Recurse | Sort-Object LastWriteTime -Descending | Select-Object -First 5
        
        foreach ($log in $logs) {
            Write-Host "`n--- $($log.Name) (更新: $($log.LastWriteTime)) ---" -ForegroundColor Cyan
            
            # ファイル内容を確認（エラー関連を重点的に）
            $content = Get-Content $log.FullName -ErrorAction SilentlyContinue
            
            if ($content) {
                # エラー、MCP、claude_code関連の行を抽出
                $relevantLines = $content | Where-Object { 
                    $_ -match "error|ERROR|Error|failed|FAILED|Failed|mcp|MCP|claude_code|exception|Exception|EXCEPTION" 
                }
                
                if ($relevantLines) {
                    Write-Host "関連するエラー/警告:" -ForegroundColor Red
                    $relevantLines | Select-Object -Last 10 | ForEach-Object { 
                        Write-Host "  $_" -ForegroundColor White 
                    }
                } else {
                    Write-Host "エラー関連の記述は見つかりませんでした" -ForegroundColor Green
                    # 最後の数行を表示
                    $content | Select-Object -Last 5 | ForEach-Object { 
                        Write-Host "  $_" -ForegroundColor Gray 
                    }
                }
            } else {
                Write-Host "ファイルが空またはアクセスできません" -ForegroundColor Yellow
            }
        }
    } else {
        Write-Host "ログディレクトリが見つかりません: $path" -ForegroundColor Red
    }
}

# 設定ファイルの現在の状態も確認
Write-Host "`n=== 現在の設定ファイル ===" -ForegroundColor Yellow
$configPath = "$env:APPDATA\Claude\claude_desktop_config.json"
if (Test-Path $configPath) {
    Write-Host "設定ファイル内容:" -ForegroundColor Green
    Get-Content $configPath | Write-Host
} else {
    Write-Host "設定ファイルが見つかりません: $configPath" -ForegroundColor Red
}

# MCPサーバーのプロセス状況も確認
Write-Host "`n=== 現在のMCP関連プロセス ===" -ForegroundColor Yellow
Get-Process | Where-Object { $_.ProcessName -like "*claude*" -or $_.ProcessName -like "*node*" } | 
Select-Object ProcessName, Id, StartTime, CPU | Format-Table

Write-Host "`n=== 分析完了 ===" -ForegroundColor Green
