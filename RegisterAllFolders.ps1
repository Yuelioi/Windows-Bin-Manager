# Define the script function
function Add-SubfoldersToPath {
    param (
        [string]$BasePath
    )

    # Get the current PATH environment variable
    $currentPath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)

    # Get the list of first-level subfolders in the specified base path
    $subfolders = Get-ChildItem -Path $BasePath -Directory

    # Initialize a list to store new paths
    $newPaths = @()

    foreach ($folder in $subfolders) {
        $folderName = $folder.Name
        $folderPath = $folder.FullName

        # Skip folders that start with '.' or '_'
        if ($folderName.StartsWith('.') -or $folderName.StartsWith('_')) {
            continue
        }

        # Check if the folder is already in the PATH
        if ($currentPath -notlike "*$folderPath*") {
            # Append the folder to the list of new paths
            $newPaths += $folderPath
        }
    }

    if ($newPaths.Length -eq 0) {
        Write-Output "No new paths to add."
        return
    }

    # Prompt user for confirmation
    $response = Read-Host "Do you want to add the following paths to PATH? `n$($newPaths -join "`n")`n(y/n)"
    if ($response -eq "y") {
        $newPathsString = $newPaths -join ";"
        $updatedPath = "$currentPath;$newPathsString"
        [System.Environment]::SetEnvironmentVariable('Path', $updatedPath, [System.EnvironmentVariableTarget]::Machine)
        Write-Output "PATH updated successfully"
    } else {
        Write-Output "Operation cancelled by user."
    }
}

# Get the current directory
$currentDirectory = (Get-Location).Path

# Check for administrator privileges
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Output "Not running as administrator. Restarting with elevated privileges..."
    # Restart with elevated privileges and pass the original directory as an argument
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = "powershell.exe"
    $psi.Arguments = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -OriginalDirectory `"$currentDirectory`""
    $psi.Verb = "runas"
    [System.Diagnostics.Process]::Start($psi) | Out-Null
    exit
}

# Check if the original directory was passed as an argument
if ($args.Length -eq 2 -and $args[0] -eq "-OriginalDirectory") {
    $currentDirectory = $args[1]
    Set-Location -Path $currentDirectory
}

# Call the function with the current directory
Add-SubfoldersToPath -BasePath $currentDirectory

# Wait for user input before closing
Read-Host -Prompt "Press Enter to exit"
