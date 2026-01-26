# Nebula.Tools: Active Directory ====================================================================================================================

function Find-ADAccountExpirations {
    <#
    .SYNOPSIS
        Finds Active Directory users with an account expiration date and optionally extends it.
    .DESCRIPTION
        Searches AD for users that have a valid account expiration value set.
        By default, only enabled accounts are returned; use -IncludeDisabled to include disabled accounts.
        You can filter by expiration date (TargetDate) and/or by email domain (FilterDomain),
        export results to CSV, and, if requested, extend the account expiration date.
        Output is objects by default (pipeline-friendly). Use -AsTable for formatted display.
        Use -WhatIf to simulate the extension without applying changes.
    .OUTPUTS
        PSCustomObject with: Name, SamAccountName, Email, AccountExpirationUTC.
        When -AsTable is used, output is formatted for display and not ideal for further pipeline use.
    .PARAMETER TargetDate
        Reference expiration date (string) in "yyyy-MM-dd" format or any DateTime-compatible format.
        If provided, the function matches accounts expiring on or before this date.
        Use -ExactDate to match only accounts expiring exactly on this date.
        If TargetDate is not specified and FilterDomain is not set, the function throws an error.
    .PARAMETER FilterDomain
        Filter on the user's email (e.g., "@contoso.com" or "contoso.com").
        The filter is treated as a wildcard and special characters are escaped.
        Matching is done against the Mail attribute and is case-insensitive.
    .PARAMETER ExactDate
        If present, match only accounts expiring exactly on TargetDate (same date).
        By default TargetDate matches expirations on or before the date.
    .PARAMETER ExportCsv
        If present, exports results to a CSV file in ExportPath (or current directory).
        The CSV includes additional fields: Department and Company.
    .PARAMETER ExportPath
        Output folder for the CSV export. Defaults to the current location.
        The file name is "AD_Users_Expires_<yyyy-MM-dd>.csv" or "AD_Users_Expires_ALL-DATES.csv".
    .PARAMETER AsTable
        If present, formats results as a table for display.
        When used, output is no longer a clean object stream for further pipeline processing.
    .PARAMETER IncludeDisabled
        If present, includes disabled accounts. By default, only enabled accounts are returned.
    .PARAMETER ExtendExpiration
        If present, extends the expiration for the matched accounts to the date provided in ExtendTo.
        The function uses ShouldProcess; use -WhatIf to preview changes safely.
    .PARAMETER ExtendTo
        New expiration date (string) to apply when using -ExtendExpiration.
        Must be a valid DateTime-compatible format.
    .PARAMETER TargetServer
        Server/Domain Controller used for AD queries and updates.
        If omitted, the default domain controller is used.
    .EXAMPLE
        Find-ADAccountExpirations -TargetDate "2027-01-01"

        Returns enabled accounts that expire on or before January 1, 2027.
    .EXAMPLE
        Find-ADAccountExpirations -FilterDomain "@contoso.com" -ExportCsv

        Finds enabled accounts with email in contoso.com and exports to CSV.
    .EXAMPLE
        Find-ADAccountExpirations -TargetDate "2027-01-01" -ExactDate

        Finds accounts expiring exactly on January 1, 2027.
    .EXAMPLE
        Find-ADAccountExpirations -FilterDomain "contoso.com" -IncludeDisabled -AsTable

        Includes disabled accounts and formats output as a table.
    .EXAMPLE
        Find-ADAccountExpirations -TargetDate "2027-01-01" -ExtendExpiration -ExtendTo "2027-12-31" -WhatIf

        Previews extending expiration to December 31, 2027 for matching accounts.
    .EXAMPLE
        Find-ADAccountExpirations -TargetServer "dc01.contoso.com" -FilterDomain "@contoso.com" |
        Select-Object -ExpandProperty Name

        Outputs only the Name values by keeping object output (no -AsTable).
    .NOTES
        Requirements: ActiveDirectory module (RSAT), permissions to read/modify AD users.
        Accounts with no expiration, or invalid/zero file time values are excluded.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        # Accept dates as strings to avoid PowerShell interpreting 2027-01-01 as arithmetic
        [string]$TargetDate,
        [string]$FilterDomain,
        [switch]$ExactDate,
        [switch]$ExportCsv,
        [string]$ExportPath,
        [switch]$AsTable,
        [switch]$IncludeDisabled,

        [switch]$ExtendExpiration,
        [string]$ExtendTo,

        [string]$TargetServer
    )

    try {
        Import-Module ActiveDirectory -ErrorAction Stop | Out-Null
    }
    catch {
        throw "ActiveDirectory module not available. Install RSAT or the AD module first."
    }

    $hasTargetDate = -not [string]::IsNullOrWhiteSpace($TargetDate)
    $hasExtendTo = -not [string]::IsNullOrWhiteSpace($ExtendTo)

    if ([string]::IsNullOrWhiteSpace($FilterDomain) -and -not $hasTargetDate) {
        throw "TargetDate is required when FilterDomain is not specified."
    }

    $TargetDateDT = $null
    if ($hasTargetDate) {
        try {
            $TargetDateDT = [DateTime]::Parse($TargetDate)
        }
        catch {
            throw "TargetDate is not a valid date: $TargetDate"
        }
    }

    $ExtendToDT = $null
    if ($ExtendExpiration) {
        if (-not $hasExtendTo) {
            throw "ExtendTo is required when using -ExtendExpiration."
        }
        try {
            $ExtendToDT = [DateTime]::Parse($ExtendTo)
        }
        catch {
            throw "ExtendTo is not a valid date: $ExtendTo"
        }
    }

    $csvLabel = if ($hasTargetDate) { $TargetDateDT.ToString('yyyy-MM-dd') } else { "ALL-DATES" }
    $exportRoot = if ($ExportPath) { $ExportPath } else { (Get-Location).Path }
    $csvPath = Join-Path $exportRoot "AD_Users_Expires_$csvLabel.csv"

    # Escape wildcard characters so the user can pass "@contoso.com" safely
    $emailPattern = $null
    if (-not [string]::IsNullOrWhiteSpace($FilterDomain)) {
        $emailPattern = '*' + [System.Management.Automation.WildcardPattern]::Escape($FilterDomain.Trim()) + '*'
    }

    $adProperties = @('accountExpires', 'mail')
    if ($ExportCsv) {
        $adProperties += 'department', 'company'
    }

    $adFilter = if ($IncludeDisabled) { '*' } else { 'Enabled -eq $true' }
    $adParams = @{
        Filter     = $adFilter
        Properties = $adProperties
    }
    if (-not [string]::IsNullOrWhiteSpace($TargetServer)) {
        $adParams['Server'] = $TargetServer
    }

    $rawResults = Get-ADUser @adParams |
    Where-Object {
        $fileTime = $_.accountExpires
        if (-not $fileTime) { return $false }
        if ($fileTime -eq 0 -or $fileTime -eq 9223372036854775807) { return $false }
        try {
            $expirationDate = ([DateTime]::FromFileTimeUtc([Int64]$fileTime)).Date
        }
        catch {
            return $false
        }

        (
            -not $hasTargetDate -or
            (
                ($ExactDate -and $expirationDate -eq $TargetDateDT.Date) -or
                (-not $ExactDate -and $expirationDate -le $TargetDateDT.Date)
            )
        ) -and
        (
            -not $emailPattern -or
            (
                -not [string]::IsNullOrWhiteSpace($_.mail) -and
                $_.mail -like $emailPattern
            )
        )
    } |
    Select-Object `
        Name,
        SamAccountName,
        DistinguishedName,
        mail,
        department,
        company,
        accountExpires

    $rawResults = @($rawResults)

    $results = $rawResults | Select-Object `
        Name,
        SamAccountName,
        DistinguishedName,
        @{ n = 'Email'; e = { $_.mail } },
        @{ n = 'AccountExpirationUTC'; e = { try { [DateTime]::FromFileTimeUtc([Int64]$_.accountExpires) } catch { $null } } },
        @{ n = 'AccountExpirationLocal'; e = { try { [DateTime]::FromFileTime([Int64]$_.accountExpires) } catch { $null } } }

    $results = @($results)

    $displayResults = $results |
    Select-Object Name, SamAccountName, Email, AccountExpirationUTC |
    Sort-Object AccountExpirationUTC

    if ($AsTable) {
        $displayResults | Format-Table -AutoSize
    }
    else {
        $displayResults
    }

    if ($ExportCsv) {
        if (-not (Test-Path -Path $exportRoot)) {
            throw "ExportPath does not exist: $exportRoot"
        }

        if (Test-Path $csvPath) {
            Write-Information "$csvPath already exists. Deleting it first ..." -InformationAction Continue
            Remove-Item -Path $csvPath -Force
        }

        $exportResults = $rawResults | Select-Object `
            Name,
            SamAccountName,
            DistinguishedName,
            @{ n = 'Email'; e = { $_.mail } },
            @{ n = 'Department'; e = { $_.department } },
            @{ n = 'Company'; e = { $_.company } },
            @{ n = 'AccountExpirationUTC'; e = { [DateTime]::FromFileTimeUtc($_.accountExpires) } },
            @{ n = 'AccountExpirationLocal'; e = { [DateTime]::FromFileTime($_.accountExpires) } }

        $exportResults | Export-Csv -Path $csvPath -NoTypeInformation -Encoding UTF8
        Write-Information "CSV exported to $csvPath" -InformationAction Continue
    }

    if ($ExtendExpiration) {
        Write-Information "" -InformationAction Continue
        Write-Information "About to set account expiration for $($results.Count) user(s) to:" -InformationAction Continue
        Write-Information "  $ExtendToDT" -InformationAction Continue
        Write-Information "Tip: use -WhatIf to preview safely." -InformationAction Continue
        Write-Information "" -InformationAction Continue

        foreach ($u in $results) {
            $label = "$($u.SamAccountName) ($($u.Email))"

            if ($PSCmdlet.ShouldProcess($label, "Set account expiration to $ExtendToDT")) {
                $setParams = @{
                    Identity = $u.SamAccountName
                    DateTime = $ExtendToDT
                }
                if (-not [string]::IsNullOrWhiteSpace($TargetServer)) {
                    $setParams['Server'] = $TargetServer
                }
                Set-ADAccountExpiration @setParams
            }
        }

        Write-Information "" -InformationAction Continue
        Write-Information "Done." -InformationAction Continue
    }
}
