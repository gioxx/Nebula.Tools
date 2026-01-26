# Nebula.Tools: Active Directory ====================================================================================================================

function Find-ADAccountExpirations {
    <#
    .SYNOPSIS
        Finds Active Directory users with an account expiration date and optionally extends it.
    .DESCRIPTION
        Searches AD for enabled users with an account expiration date.
        You can filter by expiration date (TargetDate) and/or by email domain (FilterDomain),
        export results to CSV, and, if requested, extend the account expiration date.
        Use -WhatIf to simulate the extension without applying changes.
    .PARAMETER TargetDate
        Reference expiration date (string) in "yyyy-MM-dd" format or any DateTime-compatible format.
        If not specified and FilterDomain is not set, the function throws an error.
    .PARAMETER FilterDomain
        Filter on the user's email (e.g., "@contoso.com"). The filter is treated as a wildcard
        and special characters are escaped.
    .PARAMETER ExactDate
        If present, match only accounts expiring exactly on TargetDate (same date). By default
        TargetDate matches expirations on or before the date.
    .PARAMETER ExportCsv
        If present, exports results to a CSV file.
    .PARAMETER ExportPath
        Output folder for the CSV export. Defaults to the current location.
    .PARAMETER ExtendExpiration
        If present, extends the expiration for the matched accounts to the date provided in ExtendTo.
    .PARAMETER ExtendTo
        New expiration date (string) to apply when using -ExtendExpiration.
    .PARAMETER TargetServer
        Server/Domain Controller used for AD queries and updates.
        If omitted, the default domain controller is used.
    .EXAMPLE
        Find-ADAccountExpirations -TargetDate "2027-01-01"
    .EXAMPLE
        Find-ADAccountExpirations -FilterDomain "@contoso.com" -ExportCsv
    .EXAMPLE
        Find-ADAccountExpirations -TargetDate "2027-01-01" -ExtendExpiration -ExtendTo "2027-12-31" -WhatIf
    .NOTES
        Requirements: ActiveDirectory module, permissions to read/modify AD users.
    #>
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        # Accept dates as strings to avoid PowerShell interpreting 2027-01-01 as arithmetic
        [string]$TargetDate,
        [string]$FilterDomain,
        [switch]$ExactDate,
        [switch]$ExportCsv,
        [string]$ExportPath,

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

    $adParams = @{
        Filter     = 'Enabled -eq $true'
        Properties = $adProperties
    }
    if (-not [string]::IsNullOrWhiteSpace($TargetServer)) {
        $adParams['Server'] = $TargetServer
    }

    $rawResults = Get-ADUser @adParams |
    Where-Object {
        $expirationDate = ([DateTime]::FromFileTimeUtc($_.accountExpires)).Date

        $_.accountExpires -ne 0 -and
        $_.accountExpires -ne 9223372036854775807 -and
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
        @{ n = 'AccountExpirationUTC'; e = { [DateTime]::FromFileTimeUtc($_.accountExpires) } },
        @{ n = 'AccountExpirationLocal'; e = { [DateTime]::FromFileTime($_.accountExpires) } }

    $results = @($results)

    if ($hasTargetDate) {
        $results |
        Select-Object Name, SamAccountName, Email, AccountExpirationUTC |
        Sort-Object AccountExpirationUTC |
        Format-Table -AutoSize
    }
    else {
        $results |
        Select-Object Name, SamAccountName, Email, AccountExpirationUTC |
        Sort-Object AccountExpirationUTC |
        Format-Table -AutoSize
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
