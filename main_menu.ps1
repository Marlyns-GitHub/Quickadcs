<#
      Date : May 2026
      Program Language : PowerShell
      Author : Marlyns NKUNGA
      Email : marlinnkunga348@gmail.com 
      Title : Main Menu for Quickadcs 
#>
Clear-Host

function Print_Menu
{
   Write-Host ""
   Get-Content .\banner.md
   Write-Host ""
   Write-Host "Main Menu"
   Write-Host ""
   Write-Host "     [1] Install & Configure adcs"
   Write-Host "     [2] Provisioning Smardcard certificate"
   Write-Host "     [0] Exit"
}
do {

      Print_Menu

      Write-Host ""
      Write-Host "Select Menu Number [0-8]: " -NoNewline

      switch ($choise = Read-Host)
      {  
	
       "1" { 
              .\src\00_quickadcs.ps1
           }
        
        "2"{
              # Run function
              .\src\01_gpo_smartcard.ps1
              .\src\02_certtmpl.ps1
           }

        "0"{
              Exit
           }

       default {

            Write-Warning " This choise is not valid"
       }
    }
      pause
      Clear-Host
}while($true)