Param
(
  [Parameter(Mandatory=$true)]
  [string] $ProjectName = 'LucientMigration',
  [Parameter(Mandatory=$true)]
  [string] $SQLInstanceListLocation,
  [Parameter(Mandatory=$true)]
  [string] $ResultOutputPath,
  [Parameter(Mandatory=$true)]
  [ValidateSet("JSON")]
  [string] $OutputFormat,
  [Parameter(Mandatory=$true)]
  [ValidateSet("SqlServer2016","SqlServerWindows2017","SqlServerWindows2019","AzureSqlDatabase","ManagedSqlServer","All_5")]
  [string] $Target,
  [Parameter(Mandatory=$true)]
  [int] $MaxTreads = 4
)

<#
  .SYNOPSIS
      A powershell script to run Microsoft Data Migration tool in command mode (DmaCmd)

  .REQUIREMENTS
     MS Data Migration Assistant installed
       - https://www.microsoft.com/en-us/download/confirmation.aspx?id=53595
       - https://blogs.msdn.microsoft.com/datamigration/2016/10/25/data-migration-assistant-configuration-settings/

     Powershell module SQLSERVER or SQLPS 
      

  .DESCRIPTION
     Script take 6 mandatory parameters, 
       - Projectname
       - SQLInstanceListLocation
       - ResultOutputPath         Full path
       - OutputFormat             Save result as JSON
       - Target                   Validate against SQL Server 2016/2017/2019 on windows, Azure SQL Database managed instance or SQL Azure Database
       - MaxTreads                Number of simultaneous analyzing SQL Instances 

  .NOTES
      Auther: Lucient Denmark
              
              Torben Schou (tschou@lucient.com)
              

  .SAMPLE
    .\RunMigration.ps1 -ProjectName "LucientQMigration" -SQLInstanceListLocation "C:\temp\myServers.csv" -ResultOutputPath "C:\result\" -OutputFormat "JSON" -Target "Choose from List" -MaxTreads 1

    .\RunMigration.ps1 -ProjectName "LucientMigration" -SQLInstanceListLocation "C:\temp\myservers.csv" -ResultOutputPath "C:\temp\" -OutputFormat "JSON" -Target "SqlServer2016" -MaxTreads 1


#>

Clear-Host

#Build process file
$runTime = Get-Date -Format "yyyyMMdd-HHmm"
$Global:file = $ResultOutputPath + "ScriptStatus_"+ $runTime +".txt"
New-Item $Global:file -ItemType file -Force

If ($PSVersionTable.PSVersion.Major -lt 5) 
{
   Write-Host "Please ensure that PowerShell version are 5+" -ForegroundColor Red -BackgroundColor Yellow

   $message = "PowerShell version is "+ $PSVersionTable.PSVersion.Major +" upgrade to version 5+"
   Add-Content $Global:file $message
   break;
}

if (!(Get-Module -ListAvailable -Name SQLSERVER))
{

   Write-Host "Please ensure that PowerShell module SqlServer are installed" -ForegroundColor Red -BackgroundColor Yellow
   Write-Host "Try running command >> Install-Module -Name SQLSERVER -Force <<" -ForegroundColor Red -BackgroundColor Yellow

   $message = "PowerShell module SqlServer is not installed"
   Add-Content $Global:file $message
   break;
  
}

$MyDir = Get-Location
$no = 0

Function CallDWM ($Target, $SQLInstanceListLocation, $ProjectName, $ResultOutputPath, $OutputFormat, $MaxTreads)
{
 
    if (Import-Csv $SQLInstanceListLocation)
    {
         Import-Csv $SQLInstanceListLocation | ForEach-Object{

                   $SQLInstance = $_.Server
                   $cmd = ".\DataMigration.ps1 -ProjectName '$ProjectName' -SQLInstance '$SQLInstance' -ResultOutputPath '$ResultOutputPath' -Target '$Target' -Output '$OutputFormat' -ErrorReport '$Global:file' -ErrorAction SilentlyContinue"
               
                   Invoke-Expression $cmd -ErrorAction Stop

                   Write-Host "Processing SQL Instance $SQLInstance Migration target are $Target" -BackgroundColor Yellow -ForegroundColor Blue
               
                   While($(gps | ? {$_.mainwindowtitle.length -ne 0} | Where-object {$_.name -eq 'DmaCmd'}).Count -ge $MaxTreads) 
                   {
                     Start-Sleep -s 30
                   }
               
                }
    } else {

        Write-Host "The SQL Server instance list file - $SQLInstanceListLocation isn't correct!" -ForegroundColor Red
        Write-Host "Correct format is" -ForegroundColor Yellow
        Write-Host "-----------------" -ForegroundColor Yellow
        Write-Host "Server " -ForegroundColor Green
        Write-Host "tsc\maps " -ForegroundColor Green
        Write-Host "tsc\my2017 " -ForegroundColor Green
        
        Start-Process Notepad.exe $SQLInstanceListLocation
                
        break;

    }

}

switch ($Target)
{

    "SqlServer2016" 
    {      

      CallDWM "SqlServer2016" $SQLInstanceListLocation $ProjectName $ResultOutputPath $OutputFormat $MaxTreads 

    }
		
    "SqlServerWindows2017" 
    {      

      CallDWM "SqlServerWindows2017" $SQLInstanceListLocation $ProjectName $ResultOutputPath $OutputFormat $MaxTreads 

    }

    "SqlServerWindows2019" 
    {      

      CallDWM "SqlServerWindows2019" $SQLInstanceListLocation $ProjectName $ResultOutputPath $OutputFormat $MaxTreads 

    }

    "AzureSqlDatabase"
    {

      CallDWM "AzureSqlDatabase" $SQLInstanceListLocation $ProjectName $ResultOutputPath $OutputFormat $MaxTreads
    }

    "ManagedSqlServer"
    {

      CallDWM "ManagedSqlServer" $SQLInstanceListLocation $ProjectName $ResultOutputPath $OutputFormat $MaxTreads
    }

    "All_5"
    {

      CallDWM "SqlServer2016" $SQLInstanceListLocation $ProjectName $ResultOutputPath $OutputFormat $MaxTreads
	  
      Start-Sleep -Seconds 15

      CallDWM "SqlServerWindows2017" $SQLInstanceListLocation $ProjectName $ResultOutputPath $OutputFormat $MaxTreads

      Start-Sleep -Seconds 15

      CallDWM "SqlServerWindows2019" $SQLInstanceListLocation $ProjectName $ResultOutputPath $OutputFormat $MaxTreads

      Start-Sleep -Seconds 15

      CallDWM "AzureSqlDatabase" $SQLInstanceListLocation $ProjectName $ResultOutputPath $OutputFormat $MaxTreads
	  
	  Start-Sleep -Seconds 15
	  
	  CallDWM "ManagedSqlServer" $SQLInstanceListLocation $ProjectName $ResultOutputPath $OutputFormat $MaxTreads

    }

}


