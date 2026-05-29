
function Invoke-Certtmpl ()
    {
        # 1. Define the source and new template names
        $SrcTemplateName = "SmartcardLogon"
        $NewTemplateName = "YubikeySmartcardLogon"
        $DisplayName = "Yubikey Smartcard Logon"
        $RAAppPolicies = 'msPKI-Asymmetric-Algorithm`PZPWSTR`ECDH_P384`msPKI-Hash-Algorithm`PZPWSTR`SHA256`msPKI-Key-Usage`DWORD`16777215`msPKI-Symmetric-Algorithm`PZPWSTR`3DES`msPKI-Symmetric-Key-Length`DWORD`168`'

        # 2. Get the Configuration Naming Context path
        $ConfigNC = (Get-ADRootDSE).configurationNamingContext
        $CertTmplContainer = "CN=Certificate Templates,CN=Public Key Services,CN=Services,$ConfigNC"
        $Server = (Get-ADDomainController -Discover -ForceDiscover -Writable).HostName[0]

        # 3. Get the Source Template object and Generate new OID
        $SourceTemplate = Get-ADObject -Filter "name -eq '$SrcTemplateName'" -SearchBase $CertTmplContainer -Properties *
        $NewTemplate = Get-ADObject -Filter "name -eq '$NewTemplateName'" -SearchBase $CertTmplContainer -Properties *
        Write-Progress -Activity "Quickadcs" -Status "Gethering certificate template informations" -PercentComplete 35
        Start-Sleep -Seconds 2

        if ($null -eq $NewTemplate.Name)
            {
                $OID_Part_1 = Get-Random -Minimum 1000000 -Maximum 9999999
                $OID_Part_2 = Get-Random -Minimum 10000000 -Maximum 99999999
                $OID_Forest = Get-ADObject -Server $Server `
                                -Identity "CN=OID,CN=Public Key Services,CN=Services,$ConfigNC" `
                                -Properties msPKI-Cert-Template-OID |
                                Select-Object -ExpandProperty msPKI-Cert-Template-OID
                $OIDTemplate = "$OID_Forest.$OID_Part_1.$OID_Part_2"
                [byte[]]$KeyUsageValue = 0x88

                Write-Progress -Activity "Quickadcs" -Status "Creating New OID" -PercentComplete 45
                Start-Sleep -Seconds 2
                # 4. Create the new Template object based on the source attributes
                $ObjectAttributes = @{
                    distinguishedName     = "CN=$NewTemplateName,$CertTmplContainer"
                    displayName           = $DisplayName
                    flags                 = 131584
                    revision              = 100
                    pKIExtendedKeyUsage   = $SourceTemplate.pKIExtendedKeyUsage
                    pKIDefaultKeySpec     = $SourceTemplate.pKIDefaultKeySpec
                    pKIMaxIssuingDepth    = $SourceTemplate.pKIMaxIssuingDepth
                    pKIDefaultCSPs        = "1,Microsoft Smart Card Key Storage Provider"
                    pKICriticalExtensions = $SourceTemplate.pKICriticalExtensions
                    pKIOverlapPeriod      = $SourceTemplate.pKIOverlapPeriod
                    pKIExpirationPeriod   = $SourceTemplate.pKIExpirationPeriod
                    pKIKeyUsage           = $KeyUsageValue
                    "msPKI-Certificate-Application-Policy" = $SourceTemplate.pKIExtendedKeyUsage
                    "msPKI-Certificate-Name-Flag" = $SourceTemplate.'msPKI-Certificate-Name-Flag'
                    "msPKI-Enrollment-Flag" = 313
                    "msPKI-Minimal-Key-Size" = 384
                    "msPKI-Private-Key-Flag" = 101056640
                    "msPKI-Cert-Template-OID" = $OIDTemplate
                    "msPKI-RA-Application-Policies" = $RAAppPolicies
                    "msPKI-Template-Schema-Version" = 4
                    "msPKI-Template-Minor-Revision" = 3
                    "msPKI-RA-Signature" = $SourceTemplate."msPKI-RA-Signature"
                }

                Write-Progress -Activity "Quickadcs" -Status "Duplicating Smartcard Login certificate template" -PercentComplete 75
                Start-Sleep -Seconds 2
                New-ADObject -Name $NewTemplateName -Type "pkicertificatetemplate" -Path $CertTmplContainer -OtherAttributes $ObjectAttributes

                # Assign Read, Enroll and Autoenroll permissions
                $GroupName = "Yubikey Authentication"
                $CheckGroup = (Get-ADGroup -Filter {Name -eq $GroupName} -Properties * | Select-Object Name -ErrorAction SilentlyContinue )

                if ($null -eq $CheckGroup){
                    New-ADGroup -Name $GroupName -GroupCategory Security -GroupScope Global -Description "This Group is dedicated for Passwordless Auth"
                }

                $Identity = "$((Get-ADDomain).NetBIOSName)\$GroupName"
                $TemplateDN = (Get-ADObject -SearchBase $CertTmplContainer -Filter * -Properties * | Where-Object Name -eq $NewTemplateName).DistinguishedName

                $Acl = Get-Acl -Path "AD:\$TemplateDN"

                ForEach ($Group in $Identity) 
                    {
                        $account = New-Object System.Security.Principal.NTAccount($Group)
                        $sid     = $account.Translate([System.Security.Principal.SecurityIdentifier])
                        $Type = [System.Security.AccessControl.AccessControlType] "Allow"
                        $Read = [System.DirectoryServices.ActiveDirectoryRights] "GenericRead"
                        $ExtendedRight = [System.DirectoryServices.ActiveDirectoryRights] "ExtendedRight"
                        $InheritanceType = [System.DirectoryServices.ActiveDirectorySecurityInheritance] "None"
                        $Enroll = [GUID]'0e10c968-78fb-11d2-90d4-00c04f79dc55'
                        $AutoEnroll = [GUID]'a05b8cc2-17bc-4802-a710-e7c15ab866a2'
                        $InheritedObjectType = [GUID]'00000000-0000-0000-0000-000000000000'
                    
                        If ($Type -ne 'Deny') 
                            {
                                # Read, but only if Allow
                                $ObjectType = [GUID]'00000000-0000-0000-0000-000000000000'
                                $ReadRule   = New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
                                            $sid, $Read, $Type, $ObjectType, $InheritanceType, $InheritedObjectType
                                $Acl.AddAccessRule($ReadRule)
                            }
                        If ($Enroll) 
                            {
                                $ObjectType = [GUID]'0e10c968-78fb-11d2-90d4-00c04f79dc55'
                                $EnrollRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
                                            $sid, $ExtendedRight, $Type, $ObjectType, $InheritanceType, $InheritedObjectType
                                $Acl.AddAccessRule($EnrollRule)
                            }
                        If ($AutoEnroll)
                            {
                                $ObjectType = [GUID]'a05b8cc2-17bc-4802-a710-e7c15ab866a2'
                                $AutoEnrollRule = New-Object System.DirectoryServices.ActiveDirectoryAccessRule `
                                                $sid, $ExtendedRight, $Type, $ObjectType, $InheritanceType, $InheritedObjectType
                                $Acl.AddAccessRule($AutoEnrollRule)
                            }
                    }
                Write-Progress -Activity "Quickadcs" -Status "Granting Read, Enroll and Autoenroll in the new certicate template" -PercentComplete 80
                Start-Sleep -Seconds 2
                Set-Acl -Path "AD:\$TemplateDN" -AclObject $Acl

                # Publish the Certificate
                $Refress = certtmpl.msc
                Start-Sleep -Seconds 2
                $CheckCertName = (Get-CATemplate | where Name -eq $NewTemplateName).Name
                if (-not ($CheckCertName))
                    {
                        Add-CATemplate -Name $NewTemplateName -Force
                        Write-Progress -Activity "Quickadcs" -Status "Publishing $NewTemplateName certificate" -PercentComplete 95
                        Start-Sleep -Seconds 2
                    }
                Write-Progress -Activity "Quickadcs" -Status "Completed" -Completed
                Start-Sleep -Seconds 2
            }
        else
            {
                Write-Warning "This certificate template $NewTemplateName already exist"
                Break;  
            }
    }

$CheckSrv = (Get-CimInstance Win32_OperatingSystem).ProductType
if ($CheckSrv -eq "2")
    {
        $CheckAuthority = (Get-WindowsFeature -Name ADCS* | Where Name -eq "ADCS-Cert-Authority").InstallState
        if ($CheckAuthority -eq 'Installed')
            {
                Invoke-Certtmpl
            }
        else
            {
                Write-Warning "Configure ADCS first before to perfom this task"
                Break;
            }
    }
else
    {
        Write-Warning "Quickadcs can be performed on a domain controller"
        Break;
    }