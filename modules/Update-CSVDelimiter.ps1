<#
.SYNOPSIS
    Update the delimiter of a CSV file between comma and semicolon.
.DESCRIPTION
    This function allows you to update the delimiter of a CSV file between comma and semicolon.
.PARAMETER FilePath
    The path to the CSV file that you want to update.
.PARAMETER Encoding
    The encoding of the CSV file. Default is "ISO-8859-1".
.PARAMETER ToComma
    A switch to convert the delimiter from semicolon (;) to comma (,).
.PARAMETER ToSemicolon
    A switch to convert the delimiter from comma (,) to semicolon (;).
.EXAMPLE
    Update-CSVDelimiter -FilePath "path\to\file.csv" -ToComma
    Update-CSVDelimiter -FilePath "path\to\file.csv" -ToSemicolon
.NOTES
    Author: Giovanni Solone

    Modification History:
    - 2025-07-29: Initial version.
#>
function Update-CSVDelimiter {
    param (
        [string]$FilePath,
        [string]$Encoding = "ISO-8859-1",   # Default encoding, can be changed
        [switch]$ToComma,                   # Switch to convert ";" to ","
        [switch]$ToSemicolon                # Switch to convert "," to ";"
    )

    if (Test-Path $FilePath) {
        try {
            $content = Get-Content -Path $FilePath -Encoding $Encoding
            
            # Determine the direction of the conversion
            if ($ToComma) {
                $newContent = $content -replace ';', ',' # Convert ";" to ","
            } elseif ($ToSemicolon) {
                $newContent = $content -replace ',', ';' # Convert "," to ";"
            } else {
                $newContent = $content -replace ',', ';' # Default behavior: Convert "," to ";"
            }
            
            $newContent | Out-File -FilePath $FilePath -Encoding $Encoding -Force
            Write-Output "Conversion successfully completed."

        } catch {
            Write-Output "An error occurred: $_"
        }
    } else {
        Write-Output "The specified file does not exist."
    }
}

# Export functions
Export-ModuleMember -Function Update-CSVDelimiter