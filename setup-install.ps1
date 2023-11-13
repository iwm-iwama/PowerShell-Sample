#------------------
# Ver.iwm20231111
#------------------
# Administrators
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")) { Start-Process PowerShell.exe "-File `"$PSCommandPath`"" -Verb RunAs; exit }

# 絶対パス取得
$ThisDir = Split-Path -Parent $PSCommandPath

# 設定ファイル読込
."${ThisDir}\setup-config.ps1"

Write-Host " セットアップ [${ShortcutName}] " -ForegroundColor White -BackgroundColor Blue
Write-Host
Write-Host "(1) インストール場所" -ForegroundColor Yellow
Write-Host "    $($InstDir.Replace("`\", "`n    `\"))" -ForegroundColor Gray
Write-Host
Write-Host "(2-1) ショートカット場所" -ForegroundColor Yellow
Write-Host "    $($ShortcutDir.Replace("`\", "`n    `\"))" -ForegroundColor Gray
Write-Host
Write-Host "(2-2) ショートカット・アイテム" -ForegroundColor Yellow
Write-Host "    [0]ショートカット名"        -ForegroundColor Magenta
Write-Host "    [1]実行ファイル"            -ForegroundColor Cyan
Write-Host "    [2]アイコンファイル"        -ForegroundColor Green
$ShortcutItem | ForEach-Object {
	Write-Host
	Write-Host "    $($_[0])" -ForegroundColor Magenta
	Write-Host "    $($_[1])" -ForegroundColor Cyan
	Write-Host "    $($_[2])" -ForegroundColor Green
}
Write-Host

# アンインストール・ファイル名
$UninstFn = "setup-uninstall.ps1"
$UninstBatFn = "${UninstFn}.bat"

# インストール済のとき
if (Test-Path "${InstDir}\${UninstFn}") {
	Write-Host "[Err] 既にインストール済です。" -ForegroundColor Red
	Write-Host "      アンインストールしてから再実行してください。" -ForegroundColor Magenta
	Write-Host "(END)" -NoNewline -ForegroundColor White
	Read-Host > $null
	exit
}

# 同名のショートカットが存在するとき
$ShortcutItem | ForEach-Object {
	if (Test-Path "${ShortcutDir}\$($_[0]).lnk") {
		Write-Host "既存のショートカット " -NoNewline -ForegroundColor Red
		Write-Host $_[0]                   -NoNewline  -ForegroundColor Magenta
		Write-Host " を上書きします。"     -ForegroundColor Red
	}
}

# インストール開始
Write-Host
Write-Host "インストールしますか? [Y/n] " -NoNewline -ForegroundColor Yellow
$key = Read-Host
Write-Host

if ($key.ToLower() -ne "y") {
	exit
}

$UninstCode = (@"
# $($myInvocation.MyCommand.name) により生成 $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
"@) + "`n" + (@'
# Administrators
if (!([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole("Administrators")) { Start-Process PowerShell.exe "-File `"$PSCommandPath`"" -Verb RunAs; exit }
$ErrorActionPreference = "silentlycontinue"
$UninstallList = @"
'@)

# アンインストール・ファイル作成
$TmpDir = $Env:TEMP
$SetupFiles = "${ThisDir}\setup-files"

Get-ChildItem $SetupFiles -File | ForEach-Object {
	$UninstCode += "`n`t${InstDir}\${_}"
}

Get-ChildItem $SetupFiles -Directory | ForEach-Object {
	$UninstCode += "`n`t${InstDir}\${_}\"
}

$UninstCode += "`n" + (@"
	${InstDir}\${UninstFn}
	${InstDir}\${UninstBatFn}
	${TmpDir}\${UninstFn}
"@)

# インストール・フォルダ作成
if (Test-Path $InstDir) {
}
else {
	$UninstCode += "`n`t${InstDir}\"
	Write-Host "Mkdir    > " -NoNewline -ForegroundColor Blue
	Write-Host "${InstDir}\"
	New-Item $InstDir -ItemType Directory > $null
}

# ファイル／フォルダコピー
Copy-Item "${SetupFiles}\*" $InstDir -Recurse -Force

# ショートカット・フォルダ作成
if (!(Test-Path $ShortcutDir)) {
	Write-Host "Mkdir    > " -NoNewline -ForegroundColor Blue
	Write-Host "${ShortcutDir}\"
	New-Item $ShortcutDir -ItemType Directory > $null
}

# WshShell 使用
$WshShell = New-Object -comObject WScript.Shell

# プログラム・ショートカット作成
$ShortcutItem | ForEach-Object {
	$s0 = "${ShortcutDir}\$($_[0].Trim()).lnk"
	$UninstCode += "`n`t${s0}"
	Write-Host "Shortcut > " -NoNewline -ForegroundColor Blue
	Write-Host $s0
	$Wsh = $WshShell.CreateShortcut($s0)
	# 実行ファイル
	$s1 = $_[1].Trim()
	if ($s1.Length) {
		if (Test-Path $s1) {
			$Wsh.TargetPath = $s1
		}
		else {
			$Wsh.TargetPath = "${InstDir}\${s1}"
		}
	}
	# アイコン
	$a2 = $_[2].split(",")
	$s20 = $a2[0].Trim()
	if ($s20.Length) {
		if (Test-Path $s20) {
			$Wsh.IconLocation = $_[2]
		}
		else {
			$Wsh.IconLocation = "${InstDir}\$($_[2])"
		}
	}
	$Wsh.WorkingDirectory = ""
	$Wsh.Save()
}

# アンインストール・ショートカット作成
$s1 = "${ShortcutDir}\アンインストール - ${InstName}.lnk"
$UninstCode += "`n`t${s1}"
Write-Host "Shortcut > " -NoNewline -ForegroundColor Blue
Write-Host $s1
$Wsh = $WshShell.CreateShortcut($s1)
$Wsh.TargetPath = "${InstDir}\${UninstBatFn}"
$Wsh.IconLocation = "$($Env:SystemRoot)\System32\shell32.dll, 131"
$Wsh.WorkingDirectory = ""
$Wsh.WindowStyle = 7
$Wsh.Save()

$UninstCode += "`n" + (@'
"@
$UninstallList.Split("`n") | ForEach-Object {
	$_ = $_.Trim()
	if (Test-Path $_ -PathType Container) {
		Write-Host "Rmdir > " -NoNewline -ForegroundColor Blue
		Write-Host $_
		Remove-Item $_ -Recurse -Force
	}
	elseif (Test-Path $_ -PathType Leaf) {
		Write-Host "Rm    > " -NoNewline -ForegroundColor Blue
		Write-Host $_
		Remove-Item $_ -Force
	}
}
'@) + "`n" + (@"
`$ShortcutDir = "${ShortcutDir}"
"@) + "`n" + (@'
if (!(Test-Path "${ShortcutDir}\*")) {
	Write-Host "Rmdir > " -NoNewline -ForegroundColor Blue
	Write-Host $ShortcutDir
	Remove-Item $ShortcutDir -Recurse -Force
}
$ErrorActionPreference = "continue"
Write-Host
Write-Host "アンインストール終了" -ForegroundColor Yellow
Write-Host "(END)" -NoNewline -ForegroundColor White
Read-Host > $null
exit
'@)

$UninstCode | Out-File "${InstDir}\${UninstFn}" -Encoding utf8

# Shift_JIS + `r`n
(@"
:: $($myInvocation.MyCommand.name) により生成 $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
@echo off
copy "${InstDir}\${UninstFn}" "${TmpDir}"
cd "${TmpDir}"
start /min PowerShell.exe -File "${InstDir}\${UninstFn}"
exit
"@) | Out-File "${InstDir}\${UninstBatFn}" -Encoding default

# 終了
Write-Host
Write-Host "(END)" -NoNewline -ForegroundColor White
Read-Host > $null
exit
