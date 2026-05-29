# Date : May 20266
# Program Language : PowerShell
# Author : Marlyns NKUNGA
# Email : marlinnkunga348@gmail.com
# Title : My Variables to gathering domain informations

# Variable Level 0

$DC = (Get-ADDomainController)
$MyDomain = (Get-ADDomain)
$DomainName = (Get-ADRootDSE).defaultNamingContext

# Variable Level 1
# Domain Informations
$Hostname = $DC.Name
$Domain = $DC.Domain
$Server = $DC.HostName
$DNSRoot = $MyDomain.DNSRoot
$FQDNDomainName = $MyDomain.DnsRoot
$NetBIOSName = $MyDomain.NetBIOSName
$DomainSid = $MyDomain.DomainSid.Value
$DomainDistinguishedName = $MyDomain.DistinguishedName
$DomainControllersContainer = $MyDomain.DomainControllersContainer

# Templates Files
$ExportGPO = "C:\GPOList.csv"
$CheckGPO = (Get-GPO -all | Select-Object -ExpandProperty DisplayName) | Out-File $ExportGPO

$TmplPath = ".\Templates"
$TmplPathXml = "$TmplPath\Xml"
$TmplPathSecEdit = "$TmplPath\SecEdit"

$CMTXPath = "comment.cmtx"
$GptTmplPath = "GptTmpl.inf"
$Pattern = "CISTemplate"

# Disabled critical protocols and Services

$NewItem = "\\$Domain\Sysvol\$Domain\Policies"


