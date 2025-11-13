# Nebula.Tools: Modules Maintenance =================================================================================================================

function Find-ModulesUpdates {
    <#
    .SYNOPSIS
        Checks installed modules for available updates using a chosen provider.
    .DESCRIPTION
        Uses one of:
          - PSResourceGet (v3): Get-InstalledPSResource + Find-PSResource
          - PowerShellGet (v2): Get-InstalledModule + Find-Module
        'Auto' uses PSResourceGet if available, otherwise falls back to PowerShellGet v2.
        Supports scope filtering.
    .PARAMETER Scope
        User | System | All | Unknown  (filter results by install location).
    .PARAMETER Provider
        Auto (default) | PSResourceGet | PowerShellGet
    .PARAMETER IncludePrerelease
        Consider pre-release versions.
    .EXAMPLE
        Find-ModulesUpdates -Scope User -Provider PSResourceGet
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('User','System','All','Unknown')]
        [string]$Scope = 'All',
        [ValidateSet('Auto','PSResourceGet','PowerShellGet')]
        [string]$Provider = 'Auto',
        [switch]$IncludePrerelease
    )

    function Get-ModuleScope([string]$installedLocation) {
        if ($installedLocation -imatch 'Program Files|ProgramData') { return 'System' }
        elseif ($installedLocation -imatch '\\Users\\')             { return 'User' }
        else                                                        { return 'Unknown' }
    }

    $hasPSRG = [bool](Get-Module -ListAvailable Microsoft.PowerShell.PSResourceGet)
    if ($Provider -eq 'Auto') { $Provider = if ($hasPSRG) { 'PSResourceGet' } else { 'PowerShellGet' } }

    $installed = @()
    if ($Provider -eq 'PSResourceGet') {
        Import-Module Microsoft.PowerShell.PSResourceGet -ErrorAction SilentlyContinue | Out-Null
        $installed = Get-InstalledPSResource -ErrorAction SilentlyContinue
    } else {
        $installed = Get-InstalledModule -ErrorAction SilentlyContinue
    }

    if (-not $installed) { return @() }

    $total = $installed.Count
    $idx = 0
    $updates = @()

    foreach ($mod in $installed) {
        $idx++
        Write-Progress -Activity "Checking for module updates..." `
            -Status "Checking $($mod.Name) ($idx of $total)" `
            -PercentComplete (($idx/$total)*100)

        try {
            if ($Provider -eq 'PSResourceGet') {
                $findParams = @{ Name = $mod.Name; ErrorAction = 'Stop' }
                if ($IncludePrerelease) { $findParams['Prerelease'] = $true }
                $latest = Find-PSResource @findParams
                if ($latest -and ([version]$latest.Version -gt [version]$mod.Version)) {
                    $scope = Get-ModuleScope $mod.InstalledLocation
                    if ($Scope -eq 'All' -or $Scope -eq $scope) {
                        $updates += [PSCustomObject]@{
                            Name             = $mod.Name
                            InstalledVersion = $mod.Version
                            LatestVersion    = $latest.Version
                            Scope            = $scope
                            # Provider         = 'PSResourceGet'
                            # Repository       = $latest.Repository
                        }
                    }
                }
            } else {
                $findParams = @{ Name = $mod.Name; ErrorAction = 'Stop' }
                if ($IncludePrerelease) { $findParams['AllowPrerelease'] = $true }
                $latest = Find-Module @findParams
                if ($latest -and ([version]$latest.Version -gt [version]$mod.Version)) {
                    $scope = Get-ModuleScope $mod.InstalledLocation
                    if ($Scope -eq 'All' -or $Scope -eq $scope) {
                        $updates += [PSCustomObject]@{
                            Name             = $mod.Name
                            InstalledVersion = $mod.Version
                            LatestVersion    = $latest.Version
                            Scope            = $scope
                            # Provider         = 'PowerShellGet'
                            # Repository       = $latest.Repository
                        }
                    }
                }
            }
        } catch {
            Write-Warning "Could not check updates for '$($mod.Name)': $($_.Exception.Message)"
        }
    }

    Write-Progress -Activity "Checking for module updates..." -Completed
    return $updates
}

function Remove-OldModuleVersions {
    <#
    .SYNOPSIS
        Remove older versions of a module, using PSResourceGet first, then PowerShellGet v2, then unmanaged folder delete.
    .DESCRIPTION
        Given a module name, this command:
          Enumerates all available versions on disk (Get-Module -ListAvailable).
          Determines which versions are tracked by PSResourceGet (v3) and/or PowerShellGet v2.
          Keeps the N most recent versions (default 1) and removes the rest.
           - Uses Uninstall-PSResource when the version is known to PSResourceGet.
           - Else uses Uninstall-Module when known to PowerShellGet v2.
           - Else removes the module folder (unmanaged copy) as a last resort.
        Supports -WhatIf/-Confirm via ShouldProcess.
    .PARAMETER Name
        Target module name (e.g., 'PSAppDeployToolkit').
    .PARAMETER Keep
        How many latest versions to keep. Default: 1.
    .PARAMETER Force
        Force removal where supported.
    .EXAMPLE
        Remove-OldModuleVersions -Name 'PSAppDeployToolkit'
    .EXAMPLE
        Remove-OldModuleVersions -Name 'MicrosoftPlaces' -Keep 2 -WhatIf
    .NOTES
        - Running in an elevated session may be required to remove versions under Program Files/ProgramData.
        - This function does not install anything; it only removes older versions.
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [Parameter(Mandatory, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$Name,
        [ValidateRange(1, 99)]
        [int]$Keep = 1,
        [switch]$Force
    )

    function Write-Section([string]$Text) { Write-Information "`n$Text" -InformationAction Continue }

    # Detect PSResourceGet availability
    $hasPSRG = [bool](Get-Module -ListAvailable Microsoft.PowerShell.PSResourceGet)
    if ($hasPSRG) {
        try { Import-Module Microsoft.PowerShell.PSResourceGet -ErrorAction Stop | Out-Null } catch { $hasPSRG = $false }
    }

    # Gather all available versions (on disk)
    $available = Get-Module -ListAvailable -Name $Name | Sort-Object Version
    if (-not $available) {
        Write-Warning "No modules named '$Name' were found on this machine."
        return
    }

    # Gather inventories v3 and v2
    $rgInstalled = @()
    if ($hasPSRG) {
        try { $rgInstalled = Get-InstalledPSResource -Name $Name -AllVersions -ErrorAction Stop } catch { $rgInstalled = @() }
    }
    $v2Installed = @()
    try { $v2Installed = Get-InstalledModule -Name $Name -AllVersions -ErrorAction Stop } catch { $v2Installed = @() }

    # Build version ledger
    $ledger =
        $available |
        Group-Object Version |
        ForEach-Object {
            $verText = $_.Name
            $ver     = [version]$verText
            $paths   = $_.Group | Select-Object -ExpandProperty ModuleBase -Unique

            $isV3 = $false
            if ($rgInstalled) {
                $isV3 = $null -ne ($rgInstalled | Where-Object { $_.Version -eq $verText })
            }
            $isV2 = $false
            if ($v2Installed) {
                $isV2 = $null -ne ($v2Installed | Where-Object { $_.Version -eq $verText })
            }

            [PSCustomObject]@{
                Version     = $ver
                VersionText = $verText
                Paths       = $paths
                TrackedV3   = $isV3
                TrackedV2   = $isV2
            }
        } | Sort-Object Version

    # Determine which versions to keep/remove
    $toKeep   = $ledger | Select-Object -Last $Keep
    $toRemove = $ledger | Select-Object -First ([math]::Max(0, $ledger.Count - $Keep))

    Write-Section "Module: $Name"
    Write-Information "Detected versions on disk:" -InformationAction Continue
    $ledger | ForEach-Object {
        $flag = if ($toKeep.Version -contains $_.Version) { "(keep)" } else { "" }
        $trk  = if ($_.TrackedV3 -and $_.TrackedV2) { "v3+v2" } elseif ($_.TrackedV3) { "v3" } elseif ($_.TrackedV2) { "v2" } else { "unmanaged" }
        Write-Information (" - {0} {1} [{2}]" -f $_.VersionText, $flag, $trk) -InformationAction Continue
        $_.Paths | ForEach-Object { Write-Information ("     {0}" -f $_) -InformationAction Continue }
    }

    if (-not $toRemove) {
        Write-Information "`nNothing to remove. Keeping latest $Keep version(s)." -InformationAction Continue
        return
    }

    Write-Section ("Will remove {0} version(s): {1}" -f $toRemove.Count, (($toRemove.VersionText) -join ", "))

    # Removal loop (prefer v3 -> v2 -> unmanaged folder)
    $results = New-Object System.Collections.Generic.List[object]

    foreach ($entry in $toRemove) {
        foreach ($path in $entry.Paths) {
            $action = "Remove $Name $($entry.VersionText) at $path"
            if ($PSCmdlet.ShouldProcess($action)) {
                $removed = $false
                $msg = $null

                # Try PSResourceGet (v3)
                if ($hasPSRG -and $entry.TrackedV3 -and -not $removed) {
                    try {
                        Uninstall-PSResource -Name $Name -Version $entry.VersionText -Quiet -ErrorAction Stop
                        $results.Add([PSCustomObject]@{ Version=$entry.VersionText; Path=$path; Method='Uninstall-PSResource'; Status='Removed'; Message=$null })
                        $removed = $true
                    } catch { $msg = $_.Exception.Message }
                }

                # Try PowerShellGet v2
                if (-not $removed -and $entry.TrackedV2) {
                    try {
                        Uninstall-Module -Name $Name -RequiredVersion $entry.VersionText -Force:$Force -ErrorAction Stop
                        $results.Add([PSCustomObject]@{ Version=$entry.VersionText; Path=$path; Method='Uninstall-Module'; Status='Removed'; Message=$null })
                        $removed = $true
                    } catch { $msg = $_.Exception.Message }
                }

                # As a last resort, remove the folder
                if (-not $removed) {
                    try {
                        if (Test-Path -LiteralPath $path) {
                            Remove-Item -LiteralPath $path -Recurse -Force:$Force -ErrorAction Stop
                            $results.Add([PSCustomObject]@{ Version=$entry.VersionText; Path=$path; Method='Remove-Item'; Status='Removed'; Message=$null })
                            $removed = $true
                        } else {
                            $results.Add([PSCustomObject]@{ Version=$entry.VersionText; Path=$path; Method='Remove-Item'; Status='Skipped'; Message='Path not found' })
                        }
                    } catch {
                        $results.Add([PSCustomObject]@{ Version=$entry.VersionText; Path=$path; Method='Remove-Item'; Status='Failed'; Message=$_.Exception.Message })
                    }
                }

                if (-not $removed -and $msg) {
                    $results.Add([PSCustomObject]@{ Version=$entry.VersionText; Path=$path; Method='(v3/v2)'; Status='Failed'; Message=$msg })
                }
            }
        }
    }

    Write-Section "Removal summary"
    $results | Sort-Object Version, Path | Format-Table -AutoSize

    # Show what's left (both inventories + disk)
    Write-Section "Remaining (inventories + disk)"
    if ($hasPSRG) {
        $rgAfter = Get-InstalledPSResource -Name $Name -AllVersions -ErrorAction SilentlyContinue
        Write-Information "Get-InstalledPSResource:" -InformationAction Continue
        if ($rgAfter) { $rgAfter | Format-Table Name, Version, InstalledLocation -AutoSize } else { Write-Information "(none)" -InformationAction Continue }
    }

    $v2After = Get-InstalledModule -Name $Name -AllVersions -ErrorAction SilentlyContinue
    Write-Information "`nGet-InstalledModule:" -InformationAction Continue
    if ($v2After) { $v2After | Format-Table Name, Version, InstalledLocation -AutoSize } else { Write-Information "(none)" -InformationAction Continue }

    $diskAfter = Get-Module -ListAvailable -Name $Name | Sort-Object Version
    Write-Information "`nGet-Module -ListAvailable:" -InformationAction Continue
    if ($diskAfter) { $diskAfter | Format-Table Name, Version, ModuleBase -AutoSize } else { Write-Information "(none)" -InformationAction Continue }
}

function Update-Modules {
    <#
    .SYNOPSIS
        Updates modules to the latest version using a chosen provider, with preview and admin checks.
    .DESCRIPTION
        v3-first capable: can use PSResourceGet (Install-PSResource) or PowerShellGet v2 (Install-Module).
        Adds:
          - -Provider Auto|PSResourceGet|PowerShellGet (default Auto prefers v3 if available)
          - -Preview (dry-run)
          - Admin check: System-scope updates are skipped with a warning if not elevated
          - -CleanupOld removes older versions using the corresponding uninstall cmdlet
    .PARAMETER Scope
        User | System | All | Unknown.
    .PARAMETER Provider
        Auto (default) | PSResourceGet | PowerShellGet
    .PARAMETER Name
        Optional name filter (wildcards allowed).
    .PARAMETER CleanupOld
        Remove older versions after successful update.
    .PARAMETER IncludePrerelease
        Consider pre-release versions.
    .PARAMETER Preview
        Show the plan and make no changes.
    .EXAMPLE
        Update-Modules -Scope User -Provider PSResourceGet -Preview
    #>

    [CmdletBinding(SupportsShouldProcess = $true)]
    param(
        [ValidateSet('User', 'System', 'All', 'Unknown')]
        [string]$Scope = 'All',
        [ValidateSet('Auto', 'PSResourceGet', 'PowerShellGet')]
        [string]$Provider = 'Auto',
        [string[]]$Name,
        [switch]$CleanupOld,
        [switch]$IncludePrerelease,
        [switch]$Preview
    )

    function Get-ModuleScope([string]$installedLocation) {
        if ($installedLocation -imatch 'Program Files|ProgramData') { return 'System' }
        elseif ($installedLocation -imatch '\\Users\\') { return 'User' }
        else { return 'Unknown' }
    }
    function Get-TargetScopeString([string]$scopeToken) {
        switch ($scopeToken) {
            'User' { return 'CurrentUser' }
            'System' { return 'AllUsers' }
            default { return 'CurrentUser' }
        }
    }
    function Test-IsAdministrator {
        try {
            $id = [Security.Principal.WindowsIdentity]::GetCurrent()
            $pri = New-Object Security.Principal.WindowsPrincipal($id)
            return $pri.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
        }
        catch { return $false }
    }

    $hasPSRG = [bool](Get-Module -ListAvailable Microsoft.PowerShell.PSResourceGet)
    if ($Provider -eq 'Auto') { $Provider = if ($hasPSRG) { 'PSResourceGet' } else { 'PowerShellGet' } }
    if ($Provider -eq 'PSResourceGet') {
        Import-Module Microsoft.PowerShell.PSResourceGet -ErrorAction SilentlyContinue | Out-Null
    }

    # Get installed list per provider
    $installed = @()
    if ($Provider -eq 'PSResourceGet') {
        $installed = Get-InstalledPSResource -ErrorAction SilentlyContinue
    }
    else {
        $installed = Get-InstalledModule -ErrorAction SilentlyContinue
    }
    if ($Name) {
        $patterns = $Name
        $installed = $installed | Where-Object {
            $n = $_.Name
            foreach ($p in $patterns) { if ($n -like $p) { return $true } }
            return $false
        }
    }
    if (-not $installed) {
        Write-Information "No installed modules found for the given filter/provider." -InformationAction Continue
        return
    }

    # Build update plan
    $toUpdate = @()
    $total = $installed.Count; $i = 0
    foreach ($mod in $installed) {
        $i++
        Write-Progress -Activity "Scanning for module updates..." `
            -Status   "Checking $($mod.Name) ($i of $total)" `
            -PercentComplete (($i / $total) * 100)
        try {
            if ($Provider -eq 'PSResourceGet') {
                $findParams = @{ Name = $mod.Name; ErrorAction = 'Stop' }
                if ($IncludePrerelease) { $findParams['Prerelease'] = $true }
                $latest = Find-PSResource @findParams
                if ($latest -and ([version]$latest.Version -gt [version]$mod.Version)) {
                    $scope = Get-ModuleScope $mod.InstalledLocation
                    if ($Scope -eq 'All' -or $Scope -eq $scope) {
                        $toUpdate += [PSCustomObject]@{
                            Name             = $mod.Name
                            InstalledVersion = [version]$mod.Version
                            LatestVersion    = [version]$latest.Version
                            Repo             = $latest.Repository
                            Scope            = $scope
                            TargetScope      = Get-TargetScopeString $scope
                            Provider         = 'PSResourceGet'
                        }
                    }
                }
            }
            else {
                $findParams = @{ Name = $mod.Name; ErrorAction = 'Stop' }
                if ($IncludePrerelease) { $findParams['AllowPrerelease'] = $true }
                $latest = Find-Module @findParams
                if ($latest -and ([version]$latest.Version -gt [version]$mod.Version)) {
                    $scope = Get-ModuleScope $mod.InstalledLocation
                    if ($Scope -eq 'All' -or $Scope -eq $scope) {
                        $toUpdate += [PSCustomObject]@{
                            Name             = $mod.Name
                            InstalledVersion = [version]$mod.Version
                            LatestVersion    = [version]$latest.Version
                            Repo             = $latest.Repository
                            Scope            = $scope
                            TargetScope      = Get-TargetScopeString $scope
                            Provider         = 'PowerShellGet'
                        }
                    }
                }
            }
        }
        catch {
            Write-Warning "Could not query '$($mod.Name)': $($_.Exception.Message)"
        }
    }
    Write-Progress -Activity "Scanning for module updates..." -Completed

    if (-not $toUpdate) {
        Write-Information "All good: no updates found for selected Scope/Provider." -InformationAction Continue
        return
    }

    # Admin gating for System scope
    $isAdmin = Test-IsAdministrator
    $sysItems = $toUpdate | Where-Object { $_.Scope -eq 'System' }
    if ($sysItems -and -not $isAdmin) {
        Write-Warning "Not elevated: System-scope updates will be skipped. Re-run PowerShell as Administrator to include them."
        $toUpdate = $toUpdate | Where-Object { $_.Scope -ne 'System' }
        if (-not $toUpdate) { return }
    }

    # Preview
    $toUpdate | Sort-Object Name | Format-Table Name, InstalledVersion, LatestVersion, Scope, Provider, Repo -AutoSize
    if ($Preview) {
        Write-Information "`nPreview mode: no changes will be made." -InformationAction Continue
        return $toUpdate
    }

    # Execute updates with matching provider
    $j = 0
    foreach ($item in $toUpdate) {
        $j++
        $desc = "Update $($item.Name) $($item.InstalledVersion) -> $($item.LatestVersion) ($($item.TargetScope)) via $($item.Provider)"
        Write-Progress -Activity "Updating modules..." -Status "$desc ($j of $($toUpdate.Count))" -PercentComplete (($j / $toUpdate.Count) * 100)

        if ($PSCmdlet.ShouldProcess($desc)) {
            try {
                if ($item.Provider -eq 'PSResourceGet') {
                    Install-PSResource -Name $item.Name -Version $item.LatestVersion.ToString() `
                        -Scope $item.TargetScope -TrustRepository -Quiet -ErrorAction Stop
                }
                else {
                    try {
                        $repo = if ($item.Repo) { $item.Repo } else { 'PSGallery' }
                        $r = Get-PSRepository -Name $repo -ErrorAction Stop
                        if ($r.InstallationPolicy -ne 'Trusted') {
                            Set-PSRepository -Name $repo -InstallationPolicy Trusted -ErrorAction SilentlyContinue
                        }
                    }
                    catch {}
                    Install-Module -Name $item.Name -RequiredVersion $item.LatestVersion.ToString() `
                        -Scope $item.TargetScope -Force -AllowClobber -ErrorAction Stop
                }
                Write-Information "Updated $($item.Name) to $($item.LatestVersion) ($($item.TargetScope))." -InformationAction Continue

                if ($CleanupOld) {
                    # Remove older versions using the same provider, fallback if needed
                    try {
                        if ($item.Provider -eq 'PSResourceGet') {
                            $all = Get-InstalledPSResource -Name $item.Name -AllVersions -ErrorAction SilentlyContinue |
                            Sort-Object Version
                            $older = $all | Select-Object -SkipLast 1
                            foreach ($ov in $older) {
                                $rmDesc = "Remove older (v3) $($item.Name) $($ov.Version)"
                                if ($PSCmdlet.ShouldProcess($rmDesc)) {
                                    try {
                                        Uninstall-PSResource -Name $item.Name -Version $ov.Version -Quiet -ErrorAction Stop
                                        Write-Information "Removed $($item.Name) $($ov.Version) via Uninstall-PSResource." -InformationAction Continue
                                    }
                                    catch {
                                        # Fallback to v2 if v3 uninstall failed to find it
                                        Uninstall-Module -Name $item.Name -RequiredVersion $ov.Version -Force -ErrorAction SilentlyContinue
                                    }
                                }
                            }
                        }
                        else {
                            $all = Get-InstalledModule -Name $item.Name -AllVersions -ErrorAction SilentlyContinue |
                            Sort-Object Version
                            $older = $all | Select-Object -SkipLast 1
                            foreach ($ov in $older) {
                                $rmDesc = "Remove older (v2) $($item.Name) $($ov.Version)"
                                if ($PSCmdlet.ShouldProcess($rmDesc)) {
                                    try {
                                        Uninstall-Module -Name $ov.Name -RequiredVersion $ov.Version -Force -ErrorAction Stop
                                        Write-Information "Removed $($ov.Name) $($ov.Version) via Uninstall-Module." -InformationAction Continue
                                    }
                                    catch {
                                        # Fallback to v3 if needed
                                        Uninstall-PSResource -Name $item.Name -Version $ov.Version -Quiet -ErrorAction SilentlyContinue
                                    }
                                }
                            }
                        }
                    }
                    catch {
                        Write-Warning "CleanupOld failed for $($item.Name): $($_.Exception.Message)"
                    }
                }

            }
            catch {
                Write-Warning "Update failed for $($item.Name): $($_.Exception.Message)"
            }
        }
    }

    Write-Progress -Activity "Updating modules ..." -Completed
}
