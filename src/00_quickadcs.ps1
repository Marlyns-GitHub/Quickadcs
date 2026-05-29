function Set-RootCertificateAuthority ()
   {
        $Node = (Get-ADDomain).NetBIOSName
        $CheckAuthority = (Get-WindowsFeature -Name ADCS* | Where Name -eq "ADCS-Cert-Authority").InstallState
        Write-Progress -Activity "Quickadcs" -Status "Gathering domain information" -PercentComplete 50
        
        if (-not ($CheckAuthority -eq 'Installed'))
            {
                #Check and Install adcs
                $Install = Install-WindowsFeature AD-Certificate
                $Install = Add-WindowsFeature Adcs-Cert-Authority -IncludeManagementTools
            }
        # Install a new Enterprise Root CA using a specific provider and a validity period :

        $searchBase = ([ADSI]"LDAP://RootDSE").configurationNamingContext
        $caPath = "CN=Enrollment Services,CN=Public Key Services,CN=Services,$searchBase"
        $CAName = (Get-ADObject -Filter 'objectClass -eq "pKIEnrollmentService"' -SearchBase $caPath -Properties Name).Name

        if ($null -eq $CAName)
            {
                $params = @{
                    CAType                    = 'EnterpriseRootCa'
                    CACommonName              = "$Node-ROOT-CA"
                    ValidityPeriod            = 'Years'
                    ValidityPeriodUnits       = 5
                    CryptoProviderName        = "RSA#Microsoft Software Key Storage Provider"
                    HashAlgorithmName         = 'SHA256'
                    KeyLength                 = 4096
                }
                
                # Configure
                Install-AdcsCertificationAuthority @params -Force 
            }
        else
            {
                Write-Warning "Root Certificate Authority already configured"
                Break;
            }
   }

function Set-InstallCertificateAuthority ()
   {
        try {
                $CheckSrv = (Get-CimInstance Win32_OperatingSystem).ProductType
                if ($CheckSrv -eq "2")
                    {
                        $IsReadOnly = (Get-ADDomainController).IsReadOnly
                        if ($IsReadOnly -eq $false)
                            {
                                Set-RootCertificateAuthority
                                Write-Progress -Activity "Quickadcs" -Status "Configuring Root Certificate Authority" -PercentComplete 90
                                Start-Sleep -Seconds 2
                            }
                    }
                else
                    {
                        Write-Warning "Quickadcs can be performed on a domain controller"
                        Write-Progress -Activity "Quickadcs" -Status "Completed" -Completed
                        Start-Sleep -Seconds 2
                        Break;
                    }
            }
        catch
            {
                Write-Warning "$_"
            }
   }   

Set-InstallCertificateAuthority
Write-Progress -Activity "Quickadcs" -Status "Completed" -Completed
Start-Sleep -Seconds 2