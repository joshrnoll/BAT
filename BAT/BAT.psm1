####################################################################
#################################################################### 
#####        
#####        Name: Bastogne Automations Tool (BAT) 
#####        Author: Joshua R. Noll
#####        Version: 1.2
#####        Usage: help .\BAT
#####
####################################################################
####################################################################

###################################################################
##################       Main function for BAT     ################
###################################################################

function BAT
{

<#

.SYNOPSIS
This module is an automation tool for helpdesk operations on an Army network.

.DESCRIPTION
This module is dependent upon an ATCTS report being present in the working directory with the following fields:

    - EDIPI
    - HQ Alignment Subunit
    - Name
    - Rank
    - Profile Verified
    - Date SAAR/DD2875 Signed
    - Date Awareness Training Completed
    - Date Most Recent Army IT UA Doc Signed
    - Enterprise Email Address

Alternatively to being present in the working directory, you can specify the path to the report with the -Path parameter.

.LINK
https://github.com/joshrnoll/BAT
https://atcts.army.mil

#>

    ######## BAT parameters #########  
    param
    (
        #One or more EDIPIs (DoD ID numbers) of a user or users, separated by commas
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$EDIPIs,

        #The full or relative path to the ATCTS report. By default, this value is .\report_export.csv
        [Parameter(Mandatory=$false)]
        [System.IO.FileInfo]$Path = ".\report_export.csv",

        #Specifies to check for an account in Active Directory
        [Parameter(Mandatory=$false)]
        [switch]$CheckAD,

        #Specifies to display ATCTS compliance information
        [Parameter(Mandatory=$false)]
        [switch]$CheckATCTS,
        
        #Specifies to enable the users
        [Parameter(Mandatory=$false)]
        [switch]$Enable,

        #Specifies whether or not to log output to a .txt file in the working directory. Files are written to the working directory.
        [Parameter(Mandatory=$false)]
        [switch]$Log
    )
    
    if (!($CheckAD) -and !($CheckATCTS) -and !($Enable))
    {
        Write-Warning "You have not provided any parameters. Run help BAT -full for help."
    }
    
    if ($CheckATCTS)
    {
        if ($Log)
        {
            Get-ATCTS -Path $Path -EDIPIs $EDIPIs -Log
        }
        else
        {
            Get-ATCTS -Path $Path -EDIPIs $EDIPIs
        }
    }
    
    if ($CheckAD)
    {
        if($Log)
        {
           Find-ADUser -EDIPIs $EDIPIs -Log 
        }
        else
        {
           Find-ADUser -EDIPIs $EDIPIs
        }
    }
    
    if ($Enable)
    {
        if ($Log)
        {
            Enable-ADUser -Path $Path -EDIPIs $EDIPIs -Log
        }

        else
        {
            Enable-ADUser -Path $Path -EDIPIs $EDIPIs
        }
    } 
}