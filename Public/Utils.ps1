# Nebula.Tools: Utilities ===========================================================================================================================

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
    .PARAMETER RemoveDuplicates
        Remove duplicate lines before joining.
    .PARAMETER ShowOutput
        Write the joined string to the pipeline.
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
    .EXAMPLE
        Join-ClipboardLines -RemoveDuplicates
        Removes duplicate lines before joining.
    .EXAMPLE
        Join-ClipboardLines -ShowOutput
        Writes the joined string to the pipeline.
    .LINK
        https://kb.gioxx.org/Nebula/Tools/usage/utilities#join-clipboardlines
    .NOTES
        Author: Giovanni Solone

        Modification History:
        - 2026-02-03: Initial version.
        - 2026-02-05: Added RemoveDuplicates switch.
    #>
    [CmdletBinding()]
    param(
        [Parameter()]
        [string]$Separator = ', ',
        [Parameter()]
        [string]$Quote = '"',
        [Parameter()]
        [switch]$RemoveDuplicates,
        [Parameter()]
        [switch]$ShowOutput,
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

    $initialCount = $items.Count
    if ($RemoveDuplicates) {
        $items = $items | Select-Object -Unique
        $removed = $initialCount - $items.Count
    }

    if ([string]::IsNullOrEmpty($Quote)) {
        $joined = $items -join $Separator
    } else {
        $joined = ($items | ForEach-Object { "$Quote$_$Quote" }) -join $Separator
    }

    Write-Information "Items joined: $($items.Count)." -InformationAction Continue
    if ($RemoveDuplicates) {
        Write-Information "Duplicates removed: $removed." -InformationAction Continue
    }

    if (-not $NoClipboard) {
        if (Get-Command -Name Set-Clipboard -ErrorAction SilentlyContinue) {
            $joined | Set-Clipboard
            Write-Information "Output copied to clipboard." -InformationAction Continue
        } else {
            Write-Warning "Set-Clipboard not available in this session. Returning output only."
        }
    }

    if ($ShowOutput) {
        $joined
    }
}
