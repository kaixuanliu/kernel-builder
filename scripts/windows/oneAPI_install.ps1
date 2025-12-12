# Intel oneAPI Base Toolkit Installation and Validation Script
$oneapi_version = "2025.2.1"
$url = "https://registrationcenter-download.intel.com/akdlm/IRC_NAS/f5881e61-dcdc-40f1-9bd9-717081ac623c/intel-oneapi-base-toolkit-2025.2.1.46_offline.exe"
$installer = "$env:TEMP\oneapi_installer.exe"

# Remove old installer if exists to avoid corruption
if (Test-Path $installer) {
    Write-Host "Removing old installer..." -ForegroundColor Yellow
    Remove-Item $installer -Force
}

# Download installer using WebClient for large files
Write-Host "Downloading Intel oneAPI Base Toolkit $oneapi_version (~3GB)..."
Write-Host "This may take several minutes, please wait..."

try {
    $webClient = New-Object System.Net.WebClient
    $webClient.DownloadFile($url, $installer)
    $webClient.Dispose()
} catch {
    throw "Download failed: $_"
}

# Check download success
if (Test-Path $installer) {
    $sizeMB = [math]::Round((Get-Item $installer).Length / 1MB, 2)
    Write-Host "Installer downloaded successfully: $installer" -ForegroundColor Green
    Write-Host "File size: $sizeMB MB" -ForegroundColor Green
    
    # Validate file size
    if ($sizeMB -lt 100) {
        throw "File size is too small ($sizeMB MB), download is corrupted. Expected ~3000 MB."
    }
} else {
    throw "Download failed"
}

# Install Intel oneAPI Base Toolkit
Write-Host "Installing Intel oneAPI Base Toolkit..."
Start-Process -FilePath $installer -ArgumentList "-s", "-a", "--silent", "--eula", "accept" -Wait -NoNewWindow

# Check installation result
if ($LASTEXITCODE -ne 0) {
    throw "Intel oneAPI installation failed with exit code $LASTEXITCODE"
}

# Clean up installer file
Remove-Item $installer -ErrorAction SilentlyContinue
Write-Host "Intel oneAPI Base Toolkit installed successfully" -ForegroundColor Green

# Verify installation
Write-Host ""
Write-Host "Verifying Intel oneAPI installation..." -ForegroundColor Cyan

# Check installation directory
$oneAPIPath = "C:\Program Files (x86)\Intel\oneAPI"
if (Test-Path $oneAPIPath) {
    Write-Host ""
    Write-Host "oneAPI installation directory found: $oneAPIPath" -ForegroundColor Green
    Write-Host ""
    Write-Host "Installed components:"
    Get-ChildItem $oneAPIPath | Select-Object Name | Format-Table -AutoSize
} else {
    throw "oneAPI installation directory not found at $oneAPIPath"
}

# Check compiler executable
$compilerPath = "$oneAPIPath\compiler\latest\bin\icx.exe"
if (Test-Path $compilerPath) {
    Write-Host "Intel C++ Compiler found at: $compilerPath" -ForegroundColor Green
    
    # Test compiler
    Write-Host ""
    Write-Host "Testing compiler..."
    try {
        $output = & $compilerPath --version 2>&1
        if ($LASTEXITCODE -eq 0 -or $output) {
            Write-Host "Compiler is working!" -ForegroundColor Green
            $output | ForEach-Object { Write-Host $_ }
        } else {
            Write-Host "Compiler found but returned error code $LASTEXITCODE" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Error testing compiler: $_" -ForegroundColor Yellow
    }
} else {
    Write-Host "Compiler executable not found at expected path: $compilerPath" -ForegroundColor Yellow
    Write-Host "Searching for icx.exe in oneAPI directory..."
    $foundCompilers = Get-ChildItem -Path $oneAPIPath -Recurse -Filter "icx.exe" -ErrorAction SilentlyContinue
    if ($foundCompilers) {
        Write-Host "Found compiler(s) at:"
        $foundCompilers | ForEach-Object { Write-Host "  $_" -ForegroundColor Cyan }
    }
}

# Display usage instructions
Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "To use Intel oneAPI tools in your shell, run:" -ForegroundColor Yellow
Write-Host '  & "C:\Program Files (x86)\Intel\oneAPI\setvars.bat" intel64' -ForegroundColor White
Write-Host "Or create a new PowerShell session and source the environment." -ForegroundColor Yellow
Write-Host "============================================================" -ForegroundColor Cyan
