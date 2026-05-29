# Date : May 2026
# Program Language : PowerShell
# Author : Marlyns NKUNGA
# Email : marlinnkunga348@gmail.com
# Title : Configure Smartcard

# Importing Variables
$CheckSrv = (Get-CimInstance Win32_OperatingSystem).ProductType
    if (-not ($CheckSrv -eq "2"))
        {
            Write-Warning "Quickadcs can be performed on a domain controller"
            Break;
        }

. ./vars/myvars.ps1
Write-Progress -Activity "Quickadcs" -Status "Gathering domain information" -PercentComplete 15
Start-Sleep -Seconds 2

# Script body
$ExportGPO = "C:\GPOList.csv"

# Script body
$GPOLists = "SmartcardConfiguration",
            "SmartcardInteractiveLogonBehavior",
            "SmartcardRemoteLogonBehavior",
            "SmartcardRemovalPolicyService"

if ((Get-Content $ExportGPO | Select-String -Pattern "SmartcardConfiguration") -and
    (Get-Content $ExportGPO | Select-String -Pattern "SmartcardInteractiveLogonBehavior") -and
    (Get-Content $ExportGPO | Select-String -Pattern "SmartcardRemoteLogonBehavior") -and
    (Get-Content $ExportGPO | Select-String -Pattern "SmartcardRemovalPolicyService")
   ) 
    {
        Write-Progress -Activity "Quickadcs" -Status "Checking GPO already exist" -PercentComplete 25
        Start-Sleep -Seconds 2
    }
else
    {
        # Creating Group Policies
        foreach ($GPOList in $GPOLists)
            {
                try {
                        $CreateGPOs = New-GPO -Name $GPOList -ErrorAction SilentlyContinue
                        $Linkgpo = New-GPLink -Name $GPOList -Target $DomainDistinguishedName
                        Write-Progress -Activity "Quickadcs" -Status "Creating GPO $GPOList" -PercentComplete 25
                        Start-Sleep -Seconds 2
                    }
                Catch 
                    {
                        Write-Warning $_
                    }
            }

        $000Id = (Get-GPO -Name $GPOLists[0]).Id.ToString()
        $001Id = (Get-GPO -Name $GPOLists[1]).Id.ToString()
        $002Id = (Get-GPO -Name $GPOLists[2]).Id.ToString()
        $003Id = (Get-GPO -Name $GPOLists[3]).Id.ToString()

        try {
                $RegistryPolPath0 = "$NewItem\{$($000Id)}\Machine"
                $SecEdit1 = New-Item "$NewItem\{$($001Id)}\Machine\Microsoft\Windows NT\SecEdit" -ItemType Directory -ErrorAction SilentlyContinue
                $SecEdit2 = New-Item "$NewItem\{$($002Id)}\Machine\Microsoft\Windows NT\SecEdit" -ItemType Directory -ErrorAction SilentlyContinue
                $Preferences = New-Item "$NewItem\{$($003Id)}\Machine\Preferences\Services" -ItemType Directory -ErrorAction SilentlyContinue
                
                $Template = Copy-Item -Path "$TmplPathSecEdit\$GptTmplPath" -Destination $SecEdit1
                $Template = Copy-Item -Path "$TmplPathSecEdit\$GptTmplPath" -Destination $SecEdit2
                $Template = Copy-Item -Path "$TmplPathXml\comment.cmtx" -Destination $RegistryPolPath0
                $Template = Copy-Item -Path "$TmplPathXml\Services.xml" -Destination $Preferences
            }
        catch
            {
                Write-Warning $_ 
            }
    }

try {
        $000Id = (Get-GPO -Name $GPOLists[0]).Id.ToString()
        $001Id = (Get-GPO -Name $GPOLists[1]).Id.ToString()
        $002Id = (Get-GPO -Name $GPOLists[2]).Id.ToString()
        $003Id = (Get-GPO -Name $GPOLists[3]).Id.ToString()

        $RegistryPolPath0 = Get-Item "$NewItem\{$($000Id)}\Machine"
        $SecEdit1 = Get-Item "$NewItem\{$($001Id)}\Machine\Microsoft\Windows NT\SecEdit"
        $SecEdit2 = Get-Item "$NewItem\{$($002Id)}\Machine\Microsoft\Windows NT\SecEdit"
        $Preferences = Get-Item "$NewItem\{$($003Id)}\Machine\Preferences\Services"

        $Cmtxfile0 = "$RegistryPolPath0\comment.cmtx"
        $Services = "$Preferences\Services.xml"
        $gptFile1 = "$SecEdit1\GptTmpl.inf"
        $gptFile2 = "$SecEdit2\GptTmpl.inf"

        $GptIni1 = "$NewItem\{$($001Id)}\GPT.INI"
        $GptIni2 = "$NewItem\{$($002Id)}\GPT.INI"
        $GptIni3 = "$NewItem\{$($003Id)}\GPT.INI"

    }
Catch
    {
        Write-Warning $_
    }

$PathPolicy = (Get-ADObject -Filter 'Name -eq "Policies"' -Properties * | Where-Object ObjectClass -eq container | Select-Object Name, distinguishedName).DistinguishedName    
$pPCMachineExtensionNames = "{827D319E-6EAC-11D2-A4EA-00C04F79F83A}{803E14A0-B4FB-11D0-A0D0-00A0C90F574B}"
$gPCMachineExtensionNameSRV = "{00000000-0000-0000-0000-000000000000}{CC5746A9-9B74-4BE5-AE2E-64379C86E0E4}][{91FBB303-0CD5-4055-BF42-E512A681B325}{CC5746A9-9B74-4BE5-AE2E-64379C86E0E4}"
Write-Progress -Activity "Quickadcs" -Status "Importing GPO Informations" -PercentComplete 60
Start-Sleep -Seconds 2

function Set-SmardcardConfig (){

    function 00_SmartcardConf (){

        $VersionNumber = (Get-ADObject "CN={$($000Id)},$PathPolicy" -Properties *)
        $VersionNumber.versionNumber | ForEach {

            if ( $VersionNumber.versionNumber -eq "4" )
                {
                    Write-Host "This GPO already configured" -ForegroundColor DarkGray
                }
            else
                {
                    # Parameters
                    $PatternReplace = "Microsoft.Policies.Smartcard"

                    # Update Comment.cmtx file
                    $Content = Get-Content $Cmtxfile0
                    $Content = $Content -replace $Pattern, $PatternReplace
                    Set-Content $Cmtxfile0 $Content

                    $Params = @{
                        Key = 'SOFTWARE\Policies\Microsoft\Windows'
                        ValueName0 = "CertPropEnabled"
                        ValueName1 = "EnableScPnP"
                        ValueName2 = "EnumerateECCCerts"
                        ValueName3 = "AllowCertificatesWithNoEKU"
                        Type = 'DWORD'
                        Value = 00000001
                    }

                    $Smartcard = Set-GPRegistryValue -Name $GPOLists[0] -Key "HKLM\$($Params.Key)\CertProp" -ValueName $Params.ValueName0 -Type $Params.Type -Value $Params.Value
                    $Smartcard = Set-GPRegistryValue -Name $GPOLists[0] -Key "HKLM\$($Params.Key)\ScPnP" -ValueName $Params.ValueName1 -Type $Params.Type -Value $Params.Value
                    $Smartcard = Set-GPRegistryValue -Name $GPOLists[0] -Key "HKLM\$($Params.Key)\SmartCardCredentialProvider" -ValueName $Params.ValueName2 -Type $Params.Type -Value $Params.Value
                    $Smartcard = Set-GPRegistryValue -Name $GPOLists[0] -Key "HKLM\$($Params.Key)\SmartCardCredentialProvider" -ValueName $Params.ValueName3 -Type $Params.Type -Value $Params.Value
                
                }
        }
    }

    function 01_SmartcardInteractive (){

        $VersionNumber = (Get-ADObject "CN={$($001Id)},$PathPolicy" -Properties *)
        $VersionNumber.versionNumber | ForEach {

            if ( $VersionNumber.versionNumber -eq "4" )
                {
                    Write-Host "This GPO already configured" -ForegroundColor DarkGray
                }
            else
                {
                    #Parameters
                    $smartcard = 'MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\ScRemoveOption=1,"1"'
                    $smartcard1 = 'MACHINE\Software\Microsoft\Windows\CurrentVersion\Policies\System\ScForceOption=4,0'

                    Add-Content -Path $gptFile1 -Value '[Registry Values]'
                    Add-Content -Path $gptFile1 -Value $smartcard
                    Add-Content -Path $gptFile1 -Value $smartcard1
                
                    # set the gPCMachineExtension to Apply the GPO
                    $getGPO = (Get-ADObject "CN={$($001Id)},$PathPolicy").DistinguishedName
                    Set-ADObject -Identity $getGPO -Replace @{gPCMachineExtensionNames="[$pPCMachineExtensionNames]"} 

                    # Edit GPT.INI and update Sysvol versionNumber

                    $GptContent = Get-Content $GptIni1
                    $GptContent = $GptContent -replace "Version=0", "Version=4"
                    Set-Content $GptIni1 $GptContent

                    # Update AD versionNumber

                    $VersionNumberAudit = (Get-ADObject "CN={$($001Id)},$PathPolicy" -Properties *)
                    Set-ADObject -Identity $VersionNumberAudit -Replace @{versionNumber="4"}
                }
        }
    }

    function 02_SmartcardRemote (){

        $VersionNumber = (Get-ADObject "CN={$($002Id)},$PathPolicy" -Properties *)
        $VersionNumber.versionNumber | ForEach {

            if ( $VersionNumber.versionNumber -eq "2" )
                {
                    Write-Host "This GPO already configured" -ForegroundColor DarkGray
                }
            else
                {
                    #Parameters
                    $smartcard = 'MACHINE\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\ScRemoveOption=1,"3"'

                    Add-Content -Path $gptFile2 -Value '[Registry Values]'
                    Add-Content -Path $gptFile2 -Value $smartcard
                
                    # set the gPCMachineExtension to Apply the GPO
                    $getGPO = (Get-ADObject "CN={$($002Id)},$PathPolicy").DistinguishedName
                    Set-ADObject -Identity $getGPO -Replace @{gPCMachineExtensionNames="[$pPCMachineExtensionNames]"} 

                    # Edit GPT.INI and update Sysvol versionNumber

                    $GptContent = Get-Content $GptIni2
                    $GptContent = $GptContent -replace "Version=0", "Version=2"
                    Set-Content $GptIni2 $GptContent

                    # Update AD versionNumber

                    $VersionNumberAudit = (Get-ADObject "CN={$($002Id)},$PathPolicy" -Properties *)
                    Set-ADObject -Identity $VersionNumberAudit -Replace @{versionNumber="2"}
                }
        }
    }
    
    function 03_SmartcardRemovePolicy (){

        $VersionNumber = (Get-ADObject "CN={$($003Id)},$PathPolicy" -Properties *)
        $ChgdDate = Date -Format "yyyy-MM-dd HH:mm:ss"
        $NewUid = "{"+ (New-Guid).ToString().ToUpper() +"}"
        $UIDTmpl = "{00000000-0000-0000-0000-000000000000}"
        $ChangedTmpl = "2000-01-01 00:00:00"

        $VersionNumber.versionNumber | ForEach {

            if ( $VersionNumber.versionNumber -eq "8" )
                {
                    Write-Host "This GPO already configured" -ForegroundColor DarkGray
                }
            else
                {
                    # Edit and update xml file
                    $xmlPath = Join-Path -Path $Preferences -ChildPath "Services.xml"
                    $xmlEdit = [xml](Get-Content -Path $xmlPath )

                    $xmlUpdate = $xmlEdit.NTServices.NTService | 
                    where {$_.changed -eq $ChangedTmpl -and $_.uid -eq $UIDTmpl}
                    $xmlUpdate.changed = "$ChgdDate"
                    $xmlUpdate.uid = "$NewUid"
                    
                    $xmlEdit.Save($xmlPath)
                
                    # set the gPCMachineExtension to Apply the GPO
                    $getGPO = (Get-ADObject "CN={$($003Id)},$PathPolicy").DistinguishedName
                    Set-ADObject -Identity $getGPO -Replace @{gPCMachineExtensionNames="[$gPCMachineExtensionNameSRV]"} 

                    # Edit GPT.INI and update Sysvol versionNumber

                    $GptContent = Get-Content $GptIni3
                    $GptContent = $GptContent -replace "Version=0", "Version=8"
                    Set-Content $GptIni3 $GptContent

                    # Update AD versionNumber

                    $VersionNumberAudit = (Get-ADObject "CN={$($003Id)},$PathPolicy" -Properties *)
                    Set-ADObject -Identity $VersionNumberAudit -Replace @{versionNumber="8"}
                }
        }
    }

    Write-Progress -Activity "Quickadcs" -Status "Configuring Smartcard Behaviors" -PercentComplete 90
    Start-Sleep -Seconds 2
    
    # Run Fuctios
    00_SmartcardConf
    01_SmartcardInteractive
    02_SmartcardRemote
    03_SmartcardRemovePolicy
}

# Run function
Set-SmardcardConfig
Write-Progress -Activity "Quickadcs" -Status "Completed" -Completed
Start-Sleep -Seconds 5