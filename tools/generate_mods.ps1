param(
    [string]$BaseName = "Hook Mod"
)

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$templatePath = Join-Path $scriptDir "template.lua"

if (-not (Test-Path $templatePath)) {
    Write-Host "Error: template.lua not found in $scriptDir" -ForegroundColor Red
    exit 1
}

$template = Get-Content $templatePath -Raw

# Ask for output directory
$defaultOutputDir = Split-Path -Parent $scriptDir
Write-Host ""
Write-Host "Output directory:" -ForegroundColor Cyan
Write-Host "  Press Enter for parent directory: $defaultOutputDir"
Write-Host "  Or enter a full path (e.g. C:\path\to\ue4ss\Mods)"
Write-Host ""
$outputInput = Read-Host "Output path"

if ([string]::IsNullOrWhiteSpace($outputInput)) {
    $outputDir = $defaultOutputDir
} else {
    $outputDir = $outputInput
}

if (-not (Test-Path $outputDir)) {
    Write-Host "Error: Output directory does not exist: $outputDir" -ForegroundColor Red
    exit 1
}

Write-Host "Using output directory: $outputDir" -ForegroundColor DarkGray

# Ask how many mods to create
Write-Host ""
Write-Host "How many '$BaseName' mods to generate? (1-26)" -ForegroundColor Cyan
Write-Host "  e.g. 10 = A through J, 26 = A through Z"
Write-Host ""
$countInput = Read-Host "Count"
$count = [int]$countInput

if ($count -lt 1 -or $count -gt 26) {
    Write-Host "Error: Count must be between 1 and 26" -ForegroundColor Red
    exit 1
}

# Generate letters A-Z (up to Count)
$letters = [char[]]([int][char]'A'..([int][char]'A' + $count - 1))

# Build exact list of folder names (always suffix)
$folderNames = @()
foreach ($letter in $letters) {
    $folderNames += "$($BaseName -replace ' ', '')$letter"
}

# Check which of these folders already exist
$existingFolders = $folderNames | Where-Object {
    Test-Path (Join-Path $outputDir $_)
}

# Ask about cleaning if any exist
if ($existingFolders.Count -gt 0) {
    Write-Host ""
    Write-Host "The following $($existingFolders.Count) mod folder(s) already exist:" -ForegroundColor Yellow
    foreach ($folder in $existingFolders) {
        Write-Host "  $folder" -ForegroundColor DarkYellow
    }
    Write-Host ""
    Write-Host "Options:" -ForegroundColor Cyan
    Write-Host "  [1] Clean (delete these folders and regenerate)"
    Write-Host "  [2] Overwrite (just replace main.lua and enabled.txt)"
    Write-Host "  [3] Cancel"
    Write-Host ""
    $cleanChoice = Read-Host "Choose (1, 2, or 3)"

    if ($cleanChoice -eq "3") {
        Write-Host "Cancelled." -ForegroundColor Red
        exit 0
    }

    if ($cleanChoice -eq "1") {
        Write-Host ""
        Write-Host "Cleaning..." -ForegroundColor Yellow
        foreach ($folder in $existingFolders) {
            $folderPath = Join-Path $outputDir $folder
            Write-Host "  Removing $folder" -ForegroundColor DarkGray
            Remove-Item $folderPath -Recurse -Force
        }
    }
}

# Generate mods
Write-Host ""
Write-Host "Generating $count mods..." -ForegroundColor Green

foreach ($letter in $letters) {
    $modName = "$BaseName $letter"
    $folderName = "$($BaseName -replace ' ', '')$letter"

    $modDir = Join-Path $outputDir $folderName
    $scriptsDir = Join-Path $modDir "scripts"
    $mainLua = Join-Path $scriptsDir "main.lua"
    $enabledTxt = Join-Path $modDir "enabled.txt"

    # Create directories
    if (-not (Test-Path $scriptsDir)) {
        New-Item -ItemType Directory -Path $scriptsDir -Force | Out-Null
    }

    # Substitute and write main.lua
    $content = $template -replace '\{\{MOD_NAME\}\}', $modName
    Set-Content -Path $mainLua -Value $content -NoNewline

    # Create enabled.txt
    Set-Content -Path $enabledTxt -Value "" -NoNewline

    Write-Host "  Created $folderName -> [$modName]" -ForegroundColor DarkGray
}

Write-Host ""
Write-Host "Done! Generated $count mods in $outputDir" -ForegroundColor Green
