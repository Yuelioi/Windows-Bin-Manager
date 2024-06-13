# Define the script function
function Add-SubfoldersToPath {
    param (
        [string]$BasePath = "C:\bin"
    )

    # Get the current PATH environment variable
    $currentPath = [System.Environment]::GetEnvironmentVariable('Path', [System.EnvironmentVariableTarget]::Machine)

    # Get the list of first-level subfolders in the specified base path
    $subfolders = Get-ChildItem -Path $BasePath -Directory

    # Initialize a list to store new paths
    $newPaths = @()

    foreach ($folder in $subfolders) {
        $folderPath = $folder.FullName

        # Check if the folder is already in the PATH
        if ($currentPath -notlike "*$folderPath*") {
            # Append the folder to the list of new paths
            $newPaths += $folderPath
            Write-Output "Adding $folderPath to PATH"
        } else {
            Write-Output "$folderPath is already in the PATH"
        }
    }

    # Join the new paths with semicolons and append to the current PATH
    if ($newPaths.Length -gt 0) {
        $newPathsString = $newPaths -join ";"
        $updatedPath = "$currentPath;$newPathsString"
        [System.Environment]::SetEnvironmentVariable('Path', $updatedPath, [System.EnvironmentVariableTarget]::Machine)
        Write-Output "PATH updated successfully"
    } else {
        Write-Output "No new paths to add"
    }
}

# Call the function with the base path
Add-SubfoldersToPath "C:\bin"
