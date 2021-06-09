# File Name: GenerateSampleFiles.ps1
# Script Author: Chris Hansen
# GitHub: https://github.com/chris-t-hansen
# Date: 2021-06-08
# This script will generate a series of dummy data files that can be used to test the archiving process.
# License: MIT

# All parameters are optional and set to default values. Any of them can be modified.
# Parameters include: The directory to create the dummy files, the number of dummy files to create, the percentage of empty files, the percentage of files with only a header, the max number of rows in a file, and the separator. You may also create a log file of everything the script does if you'd like. The default will be a log directory in the Dummy folder location, but this can be customized as well.
Param(
    # Folder to create the dummy files. This assumes a Windows location but can be set as appropriate for your system.
    [Parameter(Mandatory=$false)]
	[string]$FolderName = "C:\DummyFiles\",

    # The number of dummy files for the process to generate. Default value is 1,000 files.
    [Parameter(Mandatory=$false)]
	[int]$FileCount = 1000,

	# The total percentage of empty files and header-only files cannot exceed 100.
	# The percentage of empty files the process should create. This can be any int between 1 and 100
    [Parameter(Mandatory=$false)]
	[int]$EmptyPercent = 10,

	# The percentage of files containing only a header the process should create. This can be any int between 1 and 100
    [Parameter(Mandatory=$false)]
	[int]$HeaderOnlyPercent = 20,

	# The maximum number of rows in a file.
    [Parameter(Mandatory=$false)]
	[int]$MaxRowCount = 1000,

	# The separator to use in the file.
	[Parameter(Mandatory=$false)]
	[string]$SeparatorValue = ",",

	# Detailed Logging. Set as "Y" to create detailed log file.
    [Parameter(Mandatory=$false)]
	[string]$DetailedLogging = "N",

	# Detailed Logging Folder Location. Default is a folder called Log within the DummyFiles folder but this can be customized to a folder of your choosing.
    [Parameter(Mandatory=$false)]
	[string]$FolderNameLogging = $FolderName + "Log\"
)

# Script Start Time
[DateTime]$ScriptStartDateTime = Get-Date

# Custom Function to write to log file. This will retry if any errors are encountered.
# This function adds lines to a file one at a time.
function WriteFile
{
    Param(
		[string]$FileWriteName
		,[string]$FileWriteValue
	)
	$isWritten = $false
	$attempts = 0
	$limit = 10
	do
	{
		try
		{
			$attempts++
			Add-Content -Path $FileWriteName -Value $FileWriteValue -ErrorAction Stop
			$isWritten = $true
		}
		catch
		{
            Write-Host "Attempt to write $FileWriteValue failed on attempt: $attempts. Trying again."
			if ($attempts -eq $limit)
			{
				Write-Host "Write for $FileWriteValue failed after $attempts attempts. Aborting."
			}
			Start-Sleep -Seconds 1
		}
	} until (( $isWritten ) -or ($attempts -gt $limit))
}

# Make sure the entered path is valid.
If (!(Test-Path -LiteralPath $FolderName -IsValid))
{
	[string]$ErrorMessage = "The entered folder: " + $FolderName + " is not valid. Existing script."
	Write-Host $ErrorMessage
	exit
}

# Check if the folder for dummy folders exists.
If (!(Test-Path -LiteralPath $FolderName -PathType Container))
{
	New-Item -ItemType Directory -Force -Path $FolderName
}

# Create the logging directory and logging file if it DetailedLogging is on.
If ($DetailedLogging -eq "Y")
{
	# Make sure the logging folder is valid.
	If(!(Test-Path -LiteralPath $FolderNameLogging -IsValid))
	{
		[string]$ErrorMessage = "The entered folder for logging: " + $FolderNameLogging + " is not valid. Exiting script."
		Write-Host $ErrorMessage
		exit
	}

	# Check if the log directory exists and create it if not
	If(!(Test-Path -LiteralPath $FolderNameLogging -PathType Container))
	{
		New-Item -ItemType Directory -Force -Path $FolderNameLogging
	}

	# Create a Log File. Set to your directory.
	[string]$StartDateTimeVariable = get-date -f "yyyyMMdd_HHmmss"
	[string]$LogFile = $FolderNameLogging + "Log_" + $StartDateTimeVariable + ".txt"
	New-Item $LogFile -ItemType file

	# Start the logging file.
	[string]$CurrentUserName = [Environment]::UserName
	[string]$MessageValue = "GenerateSampleFiles.ps1 execution started by $CurrentUserName on $StartDateTimeVariable `r`n"
	WriteFile -FileWriteName $LogFile -FileWriteValue $MessageValue
}

# Log the folder creation.
If ($DetailedLogging -eq "Y")
{
	WriteFile -FileWriteName $LogFile -FileWriteValue "Folder locations for dummy files and log files are both valid and created."
}

# Verify that file counts and percentages are valid.
If ($FileCount -lt 1)
{
	[string]$ErrorMessage = "The file count of : " + $FileCount + " is less than one. Negative or zero valued file counts are not allowed. Exiting script."
	Write-Host $ErrorMessage
	If ($DetailedLogging -eq "Y")
	{
		WriteFile -FileWriteName $LogFile -FileWriteValue $ErrorMessage
	}
	exit
}

[int]$TotalPercent = $EmptyPercent + $HeaderOnlyPercent
If ($TotalPercent -gt 100 -or $EmptyPercent -lt 0 -or $HeaderOnlyPercent -lt 0)
{
	[string]$ErrorMessage = "The total percentage of empty or header-only files cannot exceed 100 and neither of them can be less than 0. The values entered are: " + $FileCount + " is less than one. Negative or zero valued file counts are not allowed. Exiting script."
	Write-Host $ErrorMessage
	If ($DetailedLogging -eq "Y")
	{
		WriteFile -FileWriteName $LogFile -FileWriteValue $ErrorMessage
	}
	exit
}

# Create dummy files
If ($DetailedLogging -eq "Y")
{
	[string]$MessageValue = "Creating " + $FileCount + " dummy files in " + $FolderName + ". Approx " + $EmptyPercent +"% will be empty files. Approx " + $HeaderOnlyPercent + "% will have a header only. The rest of the files will have a random number of rows up to " + $MaxRowCount + " and use a " + $SeparatorValue + " as a separator.`r`n"
	WriteFile -FileWriteName $LogFile -FileWriteValue $MessageValue
}

# Create a header for our dummy files.
[string]$HeaderValue = "ID" + $SeparatorValue + "DateVal" + $SeparatorValue + "StringVal1" + $SeparatorValue + "StringVal2" + $SeparatorValue + "NumVal"
# Get the current date for use in the file.
[DateTime]$CurrentDate = Get-Date

# Create a range of characters to create randomized strings from all ASCII values
[int[]]$ASCIIVals = (65..90)+(97..122)+(35..38)
[string[]]$CharVals = foreach($ASCIIVal in $ASCIIVals)
{
	#$CharVal = [char]$ASCIIVal
	#$CharVal
	[char]$ASCIIVal
}

# Add 0 to 9 to the array.
$CharVals = $CharVals + (0..9)

foreach($i in 1..$FileCount)
{
	# Create a unique file name for the dummy file.
	[string]$FileNameDateTimeVariable = get-date -f "yyyyMMdd_HHmmss"
	[string]$FileName = $FolderName + "File" + $i.ToString() + "_" + $FileNameDateTimeVariable + ".txt"

	# Determine the contents of the file. Will choose a number between 1 and 100 (Max value is not inclusive
	[int]$RandomNumber = Get-Random -Minimum 1 -Maximum 101
	[int]$RowCount = 0
	If ($RandomNumber -le $EmptyPercent)
	{
		[string]$FileType = "Empty"
	} elseif($RandomNumber -gt $EmptyPercent -and $RandomNumber -le $TotalPercent)
	{
		[string]$FileType = "Header Only"
	} else {
		[string]$FileType = "With Data"
		$RowCount = Get-Random -Minimum 1 -Maximum ($MaxRowCount + 1)
	}	
	
	# Time the file creations started
	[DateTime]$FileStartDateTime = Get-Date

	# Create the new file
	New-Item $FileName -ItemType file

	# If the new file is not empty, add the header row to it.
	If(!($FileType -eq "Empty"))
	{
		WriteFile -FileWriteName $FileName -FileWriteValue $HeaderValue
		# If the file has data, add rows. (If it is Header only, this will skip and just go to the next file.)
		If($FileType -eq "With Data")
		{
			foreach($n in 1..$RowCount)
			{
				[int]$DateModifier = Get-Random -Minimum -1000 -Maximum 1
				[String]$RowDateVal = $CurrentDate.AddDays($DateModifier).ToString("yyyy-MM-dd")
				# Set random string lengths for our dummy data
				[int]$RowStringLength1 = Get-Random -Minimum 5 -Maximum 20
				[int]$RowStringLength2 = Get-Random -Minimum 5 -Maximum 20
				# Create random strings of letters by choosing from an array of char values and joining them together.
				# Calculating the random characters every time was slow. I created the array above and use that to generate random text.
				#[String]$RowStringVal1 = -join(1..$RowStringLength1 | ForEach {((65..90)+(97..122) | Foreach-Object {[char]$_})+(0..9) | Get-Random})
				#[String]$RowStringVal2 = -join(1..$RowStringLength2 | ForEach {((65..90)+(97..122) | Foreach-Object {[char]$_})+(0..9) | Get-Random})
				[String]$RowStringVal1 = -join ($CharVals | Get-Random -count $RowStringLength1)
				[String]$RowStringVal2 = -join ($CharVals | Get-Random -count $RowStringLength2)
				# Create random number to inlcude in the dummy data.
				[int]$RowNumVal = Get-Random -Maximum 1000000
				# Write the value to the file.
				[string]$RowVal = $n.ToString() + $SeparatorValue + $RowDateVal + $SeparatorValue + $RowStringVal1 + $SeparatorValue + $RowStringVal2 + $SeparatorValue + $RowNumVal.ToString()
				WriteFile -FileWriteName $FileName -FileWriteValue $RowVal
			}
		}
	}
	# Time the file creations completed
	[DateTime]$FileEndDateTime = Get-Date

	If ($DetailedLogging -eq "Y")
	{
		# Time it took to create the new file.
		[TimeSpan]$TotalFileTime = NEW-TIMESPAN –Start $FileStartDateTime –End $FileEndDateTime
		[string]$TotalFileSeconds = $TotalFileTime.TotalSeconds.ToString()
		[string]$RowCountDesc = if($FileType -eq "With Data") {" with $RowCount rows"} else {""}
		[string]$MessageValue = "Created a file called " + $FileName + ". The file type will be " + $FileType + $RowCountDesc + " in " + $TotalFileSeconds + " seconds."
		WriteFile -FileWriteName $LogFile -FileWriteValue $MessageValue
	}
}

# Script Start Time
[DateTime]$ScriptEndDateTime = Get-Date

# Close the log file.
If ($DetailedLogging -eq "Y")
{
	[TimeSpan]$TotalScriptTime = NEW-TIMESPAN –Start $ScriptStartDateTime –End $ScriptEndDateTime
	[string]$TotalSeconds = $TotalScriptTime.TotalSeconds.ToString()
	[string]$EndDateTimeVariable = get-date -f "yyyyMMdd_HHmmss"
	[string]$MessageValue = "GenerateSampleFiles.ps1 completed on $EndDateTimeVariable in $TotalSeconds seconds."
	WriteFile -FileWriteName $LogFile -FileWriteValue $MessageValue
}
