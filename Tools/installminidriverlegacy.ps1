$CheckYubikeydriver=(Get-WindowsDriver -Online | where {($_.ProviderName -like "Yubico") `
                              -and ($_.ClassName -like "SmartCard") `
                              -and ($_.Version -like "*")} `
                          | select ProviderName,ClassName,Version)

if ($null -eq $CheckYubikeydriver){

    $CopyItem = Copy-Item -Path .\YubiKey-Minidriver-latest-x64.msi -Destination C:\    
    Start-Process C:\Windows\System32\msiexec.exe -ArgumentList "/i C:\YubiKey-Minidriver-latest-x64.msi INSTALL_LEGACY_NODE=1 /quiet" -wait -NoNewWindow
    $DeletItem = Remove-Item -Path C:\YubiKey-Minidriver-latest-x64.msi -Confirm:$false
        
}else
    {Write-Warning "Yubikey Minidriver already installed"}