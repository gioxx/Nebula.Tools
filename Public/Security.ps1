# Nebula.Tools: Security ============================================================================================================================

function New-RandomPassword {
    <#
    .SYNOPSIS
        Generates a random password with specified length and complexity.
    .DESCRIPTION
        This function generates a random password based on the specified length and complexity.
        The password is a combination of lowercase letters, uppercase letters, numbers, and special characters.
        The complexity of the password can be controlled using the -Simple switch.
        If -Simple is specified, the password will only contain lowercase letters, uppercase letters, numbers, and special characters.
        If -Simple is not specified, the password will contain all characters.
    .PARAMETER PasswordLength
        The length of the password to be generated. Default is 10 characters.
    .PARAMETER Simple
        A switch to generate a simplified password that contains only lowercase letters, uppercase letters, numbers, and a limited set of special characters.
    .PARAMETER Count
        The number of passwords to generate. Default is 1.
    .PARAMETER Clipboard
        A switch to copy the generated password(s) to the clipboard.
    .EXAMPLE
        New-RandomPassword -PasswordLength 15
        Generates one complex password of length 12.
    .EXAMPLE
        New-RandomPassword -PasswordLength 15 -Simple
        Generates one simplified password of length 12.
    .EXAMPLE
        New-RandomPassword -PasswordLength 15 -Count 5
        Generates five complex passwords of length 12.
    .EXAMPLE
        New-RandomPassword -PasswordLength 15 -Simple -Count 3
        Generates three simplified passwords of length 12.
    .EXAMPLE
        New-RandomPassword -PasswordLength 15 -Count 5 -Clipboard
        Generates five complex passwords of lenght 12 and copy to clipboard
    .NOTES
        Author: Giovanni Solone
    
        Credits:
        https://www.sharepointdiary.com/2020/04/powershell-generate-random-password.html
        
        Modification History:
        - 2025-12-11: Moved to Write-Information instead of Write-Host.
        - 2025-11-06: Added -Clipboard switch to copy generated passwords to clipboard.
            Renamed function from Get-RandomPassword to New-RandomPassword for consistency with PowerShell naming conventions.
            Aesthetic improvements to output messages.
            Removed comma from allowed special characters in simple mode to avoid potential issues in certain contexts (CSV).
            New default password length set to 12 for better security.
        - 2025-07-29: Initial version.
    #>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $false)]
        [ValidateRange(1, 256)]
        [int]$PasswordLength = 12,
        [Parameter()]
        [ValidateRange(1, 999)]
        [int]$Count = 1,
        [Parameter()]
        [switch]$Simple,
        [Parameter()]
        [switch]$Clipboard
    )

    # Define allowed special characters
    if ($Simple) {
        $AllowedSpecialChars = [char[]]'!.@#$_-'
    } else {
        $AllowedSpecialChars = [char[]](33..47 + 58..64 + 91..96 + 123..126)
    }

    # Define character sets
    $CharacterSet = @{
        Lowercase   = (97..122) | ForEach-Object { [char]$_ }
        Uppercase   = (65..90)  | ForEach-Object { [char]$_ }
        Numeric     = (48..57)  | ForEach-Object { [char]$_ }
        SpecialChar = $AllowedSpecialChars
    }

    # Combine all sets
    $StringSet = $CharacterSet.Uppercase + $CharacterSet.Lowercase + $CharacterSet.Numeric + $CharacterSet.SpecialChar

    $Passwords = @()

    # Generate requested number of passwords
    for ($i = 0; $i -lt $Count; $i++) {
        $Password = -join (Get-Random -Count $PasswordLength -InputObject $StringSet)
        $Passwords += $Password
    }

    # If Clipboard switch is active, copy all passwords to clipboard
    if ($Clipboard) {
        $PasswordsString = $Passwords -join "`r`n"
        $PasswordsString | Set-Clipboard
        Write-Information "Password(s) copied to clipboard." -InformationAction Continue
    }

    return $Passwords
}