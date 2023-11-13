#-------------------------------------------------------------------------------
#-- ↓ 設定 ここから -----------------------------------------------------------

#-------------------
# (1) インストール
#-------------------
# (1-1) フォルダ名
$InstName = "setup-sample"
# (1-2) 場所
#  Default: $($Env:LOCALAPPDATA)\$InstName
$InstDir = "$($Env:LOCALAPPDATA)\$InstName"

#---------------------
# (2) ショートカット
#---------------------
# (2-1) フォルダ名
$ShortcutName = "セットアップ サンプル"
# (2-2) 場所
#      Default: $($Env:APPDATA)\Microsoft\Windows\Start Menu\Programs\$ShortcutName
$ShortcutDir = "$($Env:APPDATA)\Microsoft\Windows\Start Menu\Programs\$ShortcutName"
# (2-3) ショートカット名／実行ファイル／アイコン
$ShortcutItem = @(
	@("01アプリケーション", "c:\windows\system32\notepad.exe", "c:\windows\system32\SHELL32.dll, 24"),
	@("02テキスト", "sample.txt", "sample.ico")
)

#-- ↑ 設定 ここまで -----------------------------------------------------------
#-------------------------------------------------------------------------------
