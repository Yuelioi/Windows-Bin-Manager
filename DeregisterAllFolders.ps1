# Define the script function
function Remove-SubfoldersFromPath {
    param (
        [string]$BasePath
    )

    # Get the current PATH environment variable
    $currentPath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)

    # Get the list of first-level subfolders in the specified base path
    $subfolders = Get-ChildItem -Path $BasePath -Directory

    # Initialize a list to store paths to remove
    $pathsToRemove = @()

    foreach ($folder in $subfolders) {
        $folderName = $folder.Name
        $folderPath = $folder.FullName

        # Skip folders that start with '.' or '_'
        if ($folderName.StartsWith('.') -or $folderName.StartsWith('_')) {
            continue
        }

        # Check if the folder is in the PATH
        if ($currentPath -like "*$folderPath*") {
            # Add the folder to the list of paths to remove
            $pathsToRemove += $folderPath
        }
    }

    if ($pathsToRemove.Length -eq 0) {
        Write-Output "No paths to remove."
        return
    }

    # Prompt user for confirmation
    $response = Read-Host "Do you want to remove the following paths from PATH? `n$($pathsToRemove -join "`n")`n(y/n)"
    if ($response -eq "y") {
        foreach ($pathToRemove in $pathsToRemove) {
            # Remove exact match of the folder path from PATH
            $currentPath = $currentPath.Replace("$pathToRemove;", "")
            $currentPath = $currentPath.Replace(";$pathToRemove", "")
            $currentPath = $currentPath.Replace("$pathToRemove", "")
        }
        # Remove any leading or trailing semicolons that might be left
        $currentPath = $currentPath.Trim(';')
        [System.Environment]::SetEnvironmentVariable('Path', $currentPath, [System.EnvironmentVariableTarget]::Machine)
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
Remove-SubfoldersFromPath -BasePath $currentDirectory

# Wait for user input before closing
Read-Host -Prompt "Press Enter to exit"
