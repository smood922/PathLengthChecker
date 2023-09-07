function Get-PathLengths {
# Output the length of all files and folders in the given directory path.
[CmdletBinding()]
param
(
    [Parameter(HelpMessage = 'The directory to scan path lengths in. Subdirectories will be scanned as well.')]
    [string] $DirectoryPathToScan = 'C:\Temp',

    [Parameter(HelpMessage = 'Only paths this length or longer will be included in the results. Set this to 260 to find problematic paths in Windows.')]
    [int] $MinimumPathLengthsToShow = 0,

    [Parameter(HelpMessage = 'If the results should be written to the console or not. Can be slow if there are many results.')]
    [bool] $WriteResultsToConsole = $false,

    [Parameter(HelpMessage = 'If the results should be shown in a Grid View or not once the scanning completes.')]
    [bool] $WriteResultsToGridView = $true,

    [Parameter(HelpMessage = 'If the results should be written to a file or not.')]
    [bool] $WriteResultsToFile = $false,

    [Parameter(HelpMessage = 'The file path to write the results to when $WriteResultsToFile is true.')]
    [string] $ResultsFilePath = 'C:\Temp\PathLengths.txt'
	
    [Parameter(HelpMessage = 'Set this to $true if you want to replace the root path.')]
    [bool] $ReplacePath = $false,
 
    [Parameter(HelpMessage = 'The replacement root path. Everything under $DirectoryPathToScan will be replaced in the output.')]
    [string] $ReplaceFilePath = 'C:\Temp\PathLengths.txt'
)

# Display the time that this script started running.
[datetime] $startTime = Get-Date
Write-Verbose "Starting script at '$startTime'." -Verbose

# Ensure output directory exists
[string] $resultsFileDirectoryPath = Split-Path $ResultsFilePath -Parent
if (!(Test-Path $resultsFileDirectoryPath)) { New-Item $resultsFileDirectoryPath -ItemType Directory }

# Open a new file stream (nice and fast) to write all the paths and their lengths to it.
if ($WriteResultsToFile) { $fileStream = New-Object System.IO.StreamWriter($ResultsFilePath, $false) }

$filePathsAndLengths = [System.Collections.ArrayList]::new()

# Get all file and directory paths and write them if applicable.
Get-ChildItem -Path $DirectoryPathToScan -Recurse -Force |
    Select-Object -Property @{Name = "FullNameLength"; Expression = { ($_.FullName.Length) } }, FullName |
    Sort-Object -Property FullNameLength -Descending |
    ForEach-Object {

    $filePath = $_.FullName
    $length = $_.FullNameLength

 	if ($ReplacePath) {
		$filePath.replace($filePath,$ReplaceFilePath)
  		$length = $filePath.Length
  	}

    # If this path is long enough, add it to the results.
    if ($length -ge $MinimumPathLengthsToShow)
    {
        [string] $lineOutput = "$length : $filePath"

        if ($WriteResultsToConsole) { Write-Output $lineOutput }

        if ($WriteResultsToFile) { $fileStream.WriteLine($lineOutput) }

        $filePathsAndLengths.Add($_) > $null
    }
}

if ($WriteResultsToFile) { $fileStream.Close() }

# Display the time that this script finished running, and how long it took to run.
[datetime] $finishTime = Get-Date
[timespan] $elapsedTime = $finishTime - $startTime
Write-Verbose "Finished script at '$finishTime'. Took '$elapsedTime' to run." -Verbose

if ($WriteResultsToGridView) { $filePathsAndLengths | Out-GridView -Title "Paths under '$DirectoryPathToScan' longer than '$MinimumPathLengthsToShow'." }
}
