function Decrypt-String {
    param (
        [string]$EncryptedString,
        [string]$KeyPath
    )

    # Load the key
    $keyString = Get-Content -Path $KeyPath
    $key = [Convert]::FromBase64String($keyString)

    # Decrypt the string
    $SecureString = ConvertTo-SecureString -String $EncryptedString -Key $key
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    $DecryptedString = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    return $DecryptedString
}

function Get-DecryptedSwitchBackupCredential {
    param (
        [string]$ConfigPath,
        [string]$KeyPath
    )

    # Load the Switch Backup Account Configuration
    $Config = Import-Clixml -Path $ConfigPath
    $decryptedPassword = Decrypt-String -EncryptedString $Config.Password -KeyPath $KeyPath
    $securePassword = $decryptedPassword | ConvertTo-SecureString -AsPlainText -Force

    $credential = New-Object -TypeName PSCredential -ArgumentList $Config.Username, $securePassword

    # Load the Switch Backup Alternate Account Configuration
    $Config = Import-Clixml -Path $ConfigPath
    $decryptedAltPassword = Decrypt-String -EncryptedString $Config.AltPassword -KeyPath $KeyPath
    $secureAltPassword = $decryptedAltPassword | ConvertTo-SecureString -AsPlainText -Force

    $altcredential = New-Object -TypeName PSCredential -ArgumentList $Config.AltUsername, $secureAltPassword

    return [PSCustomObject]@{
        Credential = $credential
        AltCredential = $altcredential
        Input      = $Config.Input
        Output     = $Config.Output
    }
}