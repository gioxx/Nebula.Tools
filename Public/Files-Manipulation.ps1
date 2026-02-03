# Nebula.Tools: Files manipulation ==================================================================================================================

function Join-ClipboardLines {
    <#
    .SYNOPSIS
        Join clipboard lines into a single PowerShell-ready string.
    .DESCRIPTION
        Reads the clipboard, splits by line, trims each entry, removes empty lines,
        then joins them with a separator and optional quoting.
    .PARAMETER Separator
        String used between items. Default is ", ".
    .PARAMETER Quote
        Quote character to wrap each item. Default is the double-quote (").
        Use empty string to disable quoting.
    .PARAMETER NoClipboard
        Do not copy the resulting string back to the clipboard.
    .EXAMPLE
        Join-ClipboardLines
        Returns a string like: "A", "B", "C"
    .EXAMPLE
        Join-ClipboardLines -Separator ', ' -Quote '"'
        Copies the output to the clipboard (default behavior).
    .EXAMPLE
        Join-ClipboardLines -NoClipboard
        Returns the output only (no clipboard write).
    .NOTES
        Author: Giovanni Solone

        Modification History:
        - 2026-02-03: Initial version.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Separator = ', ',
        [Parameter()]
        [string]$Quote = '"',
        [Parameter()]
        [switch]$NoClipboard
    )

    if (-not (Get-Command -Name Get-Clipboard -ErrorAction SilentlyContinue)) {
        Write-Error "Clipboard not available in this session."
        return
    }

    $raw = Get-Clipboard -Raw
    if ([string]::IsNullOrWhiteSpace($raw)) {
        Write-Warning "Clipboard is empty."
        return
    }

    $items = $raw -split "\r?\n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -ne '' }
    if (-not $items -or $items.Count -eq 0) {
        Write-Warning "No non-empty lines found in clipboard."
        return
    }

    if ([string]::IsNullOrEmpty($Quote)) {
        $joined = $items -join $Separator
    } else {
        $joined = ($items | ForEach-Object { "$Quote$_$Quote" }) -join $Separator
    }

    if (-not $NoClipboard) {
        if (Get-Command -Name Set-Clipboard -ErrorAction SilentlyContinue) {
            $joined | Set-Clipboard
            Write-Information "Output copied to clipboard." -InformationAction Continue
        } else {
            Write-Warning "Set-Clipboard not available in this session. Returning output only."
        }
    }

    return $joined
}

function Update-CSVDelimiter {
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
        - 2025-11-12: Moved to Write-Information instead of Write-Host.
        - 2025-11-06: Aesthetic improvements to output messages.
        - 2025-07-29: Initial version.
    #>
    [CmdletBinding()]
    param (
        [string]$FilePath,
        [string]$Encoding = "ISO-8859-15",  # Default encoding, can be changed
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
            Write-Information "Conversion successfully completed." -InformationAction Continue

        } catch {
            Write-Error "An error occurred: $_"
        }
    } else {
        Write-Error "The specified file does not exist." -InformationAction Continue
    }
}
