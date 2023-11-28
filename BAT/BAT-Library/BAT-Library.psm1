####################################################################
#################################################################### 
#####        
#####        Name: Bastogne Automations Tool (BAT) Functions Library
#####        Author: Joshua R. Noll
#####        Version: 2.0
#####        Usage: help .\BAT
#####
####################################################################
####################################################################


########################################################################
############ Function for pseudo-random password generation ############
########################################################################
function New-Password
{
    param
    (
        # The length of the password to be generated
        [Parameter(Mandatory=$true)]
        [int32]$length,

        [Parameter(Mandatory=$false)]
        [switch]$NoSpecial
    )

    $specchar_array = 33..47
    $specchar_array += 58..64
    $specchar_array += 91..96
    $specchar_array += 123..126

    $password = @()

    for ($i = 0; $i -lt $length; $i++)
    {            
        $number = Get-Random -Minimum 48 -Maximum 57
        $capletter = Get-Random -Minimum 65 -Maximum 90
        $lowletter = Get-Random -Minimum 97 -Maximum 122
        $specchar = $specchar_array | Get-Random

        if ($NoSpecial)
        {
            $pw_chars = [char]$number,[char]$capletter,[char]$lowletter

            $random_char = $pw_chars | Get-Random

            [string]$password += $random_char
        }

        else
        {
            $pw_chars = [char]$number,[char]$capletter,[char]$lowletter,[char]$specchar

            $random_char = $pw_chars | Get-Random

            [string]$password += $random_char
        }
    }

    return [string]$password
}

###################################################################
############ Function to import ATCTS Compliance Data ############
###################################################################
function Import-ATCTS
{
    ############ function parameters ############
    param
    (
        #The full or relative path to the ATCTS report. By default, this value is .\report_export.csv
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo] $Path
    )
    
    ######## Import ATCTS report #############
    $header = "EDIPI","Personnel Type","HQ Alignment Subunit","Name","Rank/Grade","Profile Verified","Date SAAR/DD2875 Signed","Date Awareness Training Completed","Date Most Recent Army IT UA Doc Signed","Enterprise Email Address"
    
    if (!(Test-Path $Path))
    {
        Write-Error "The ATCTS report could not be found. Is the .csv file in your working directory?" -ErrorAction Stop
    }
    else
    {
        $global:ATCTS = Import-Csv -Path $Path -Header $header -ErrorAction SilentlyContinue
    
        $global:CAO = [datetime](Get-ItemProperty -Path $Path -Name LastWriteTime).LastWriteTime
    }
}


###################################################################
########### Function to import unit Organizational Units ##########
###################################################################
function Import-OUs
{
    ############ function parameters ############
    param
    (
        #The full or relative path to the OrganizationalUnits.csv file. By default, this value is 'C:\Program files\WindowsPowerShell\Modules\BAT\BAT-Library\OrganizationalUnits.csv'
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo] $Path = 'C:\Program files\WindowsPowerShell\Modules\BAT\BAT-Library\OrganizationalUnits.csv'
    )
    
    ######## Import ATCTS report #############
    $header = "Unit","OrganizationalUnit"
    
    if (!(Test-Path $Path))
    {
        Write-Error "The OrganizationalUnits.csv file could not be found." -ErrorAction Stop
    }
    else
    {
        $global:OUs = Import-Csv -Path $Path -Header $header -ErrorAction SilentlyContinue
    }

    ######## Define number of BNs ##########
    $number_of_bns = ($OUs.Count - 2)
    
    ########## Set global variables for visitor and BDE OUs ##########
    $global:visitor_ou = $global:OUs[1].OrganizationalUnit
    $global:bde_ou = $global:OUs[2].OrganizationalUnit

    ######### Set global variables for BN OUs #############
    for ($i = 1; $i -lt $number_of_bns; $i++)
    {
        $var_name = "bn_$i" + "_ou"

        New-Variable -Name $var_name -Scope global -Value $global:OUs[$i + 2].OrganizationalUnit -Force
    }

    for ($i = 1; $i -lt $number_of_bns; $i++)
    {
        $var_name = "bn_$i" + "_name"

        New-Variable -Name $var_name -Scope global -Value $global:OUs[$i + 2].Unit -Force
    }

}

################################################################################
#### Function to check if user is in BDE based on unit name in ATCTS report ####
################################################################################

function Test-Bde
{
    ############ function parameters ############
    param
    (
        #The input string to be tested
        [string]$inputString
    )

    ####### If string has no forward slash ('/') or if string has a single forward slash followed by 'HHC' ('/HHC') ########
    if (($inputString -notmatch '/') -or ($inputString -match '^([^/]*\/[^/]*)$' -and $inputString -match '/HHC'))
    {
        return $true
    }

    else
    {
        return $false
    }
}

########################################################################################
#### Function to check if user is in a Battalion based on unit name in ATCTS report ####
########################################################################################

function Test-Bn
{
    ############ function parameters ############
    param
    (
        #The input string to be tested
        [string]$inputString
    )

    ###### If the string has a single forward slash, NOT followed immediately by HHC -or- if the string has two forward slashes ##########
    if (($inputString -match '^([^/]*\/[^/]*)$' -and $inputString -notmatch '/HHC') -or ($inputString -match '^([^/]*\/[^/]*\/[^/]*)$'))
    {
        return $true
    }

    else
    {
        return $false
    }
}

#############################################################
#### Function to get the user's BN based on ATCTS report ####
#############################################################

function Get-Bn
{
    ############ function parameters ############
    param
    (
        #The input string to be tested
        [string]$inputString
    )
    
    ###### If the string has a single forward slash, NOT followed immediately by HHC -or- if the string has two forward slashes ##########
    if (Test-Bn -inputString $inputString)
    {
        $bn_string = ($inputString | Select-String -Pattern '^[^/]*\/(\d+-?\d+)')

        if ($bn_string -ne $null)
        {
            $bn_string = $bn_string.Matches.Groups[1].ToString()
        }
    }

    return $bn_string
}

#################################################################
#### Function to define rank abbreviations from ATCTS report ####
#################################################################

function Add-RankAbbreviations 
{
    #### Define global rank abbreviation dictionary #######
    $global:rank_abbreviations = @{

        "Private" = "PVT"
        "Private 2" = "PV2"
        "Private First Class" = "PFC"
        "Specialist" = "SPC"
        "Sergeant" = "SGT"
        "Staff Sergeant" = "SSG"
        "Sergeant First Class" = "SFC"
        "Master Sergeant" = "MSG"
        "First Sergeant" = "1SG"
        "Sergeant Major" = "SGM"
        "Command Sergeant Major" = "CSM"
        "Warrant Officer" = "WO1"
        "Chief Warrant Officer 2" = "CW2"
        "Chief Warrant Officer 3" = "CW3"
        "Chief Warrant Officer 4" = "CW4"
        "Chief Warrant Officer 5" = "CW5"
        "Second Lieutenant" = "2LT"
        "First Lieutenant" = "1LT"
        "Captain" = "CPT"
        "Major" = "MAJ"
        "Lieutenant Colonel" = "LTC"
        "Colonel" = "COL"
        "Brigadier General" = "BG"
        "Major General" = "MG"
        "Lieutenant General" = "LTG"
        "General" = "GEN"
        }
}

function Get-ATCTS
{
    ############ function parameters ############
    param
    (
        #The full or relative path to the ATCTS report. By default, this value is .\report_export.csv
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo] $Path,

        #One or more EDIPIs (DoD ID numbers) of a user or users, separated by commas
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$EDIPIs
    )

    ############ Variable to return for users with a clean ATCTS profile ########
    $good = @()

    ###### Set variables for SAAR/Cyber/UA expiration #####
    $today = Get-Date
    $expiration = $today.AddYears(-1)
    
    ############ loop through each EDIPI given by user input ############
    foreach ($EDIPI in $EDIPIs)
    {            
        foreach ($user in $ATCTS)
        {
            if ($EDIPI -eq $user.EDIPI)
            {
                ####### Define type string variables for ATCTS status ##########
                [string]$verified_status = $user."Profile Verified"
                [string]$SAAR = $user."Date SAAR/DD2875 Signed"
                [string]$cyber = $user."Date Awareness Training Completed" 
                [string]$ua = $user."Date Most Recent Army IT UA Doc Signed"

                ######### Define type datetime variables for ATCTS status ######
                $SAAR_date = try { [datetime]::parseexact($SAAR, 'dd-MMM-yyyy', $null) } catch { $null }

                if ($SAAR_date -ne $null)
                {
                    $SAAR_date = [datetime]$SAAR_date
                }
                
                $cyber_date = try { [datetime]::parseexact($cyber, 'dd-MMM-yyyy', $null) } catch { $null }
                
                if ($cyber_date -ne $null)
                {
                    $cyber_date = [datetime]$cyber_date
                }

                $ua_date = try { [datetime]::parseexact($ua, 'dd-MMM-yyyy', $null) } catch { $null }

                if ($ua_date -ne $null)
                {
                    $ua_date = [datetime]$ua_date
                }
                
                ######## Check verified status ########
                if ($verified_status -ne $null)
                {
                    switch ($verified_status)
                    {
                        {$verified_status -eq $null} {$verified_good = $false ; break}
                    
                        {$verified_status -eq "Yes"} {$verified_good = $true ; break}

                        {$verified_status -eq "No"} {$verified_good = $false ; break}

                        default {$verified_good = $false}
                    }
                }

                else
                {
                    $verified_good = $false
                }
                
                ####### Check SAAR date ######### 
                if ($SAAR_date -eq $null)
                {
                    $SAAR_good = $false
                }

                else
                {
                    $SAAR_good = $true
                }

                ######## Check CyberAwareness date #######
                if ($cyber_date -ne $null)
                {
                    switch ($cyber_date.CompareTo($expiration)) 
                    { 
                        {$_ -eq $null } {$cyber_good = $false ; break}
                    
                        {$_ -le 0} {$cyber_good = $false ; break }

                        {$_ -gt 0} {$cyber_good = $true ; break }

                        default { $cyber_good = $false ; break }
                    }  
                }

                else
                {
                    $cyber_good = $false
                }
                ####### Check IT User Agreement date #######
                
                if ($ua_date -ne $null)
                {
                    switch ($ua_date.CompareTo($expiration)) 
                    { 
                        {$_ -eq $null } {$ua_good = $false ; break}
                    
                        {$_ -le 0} {$ua_good = $false ; break }

                        {$_ -gt 0} {$ua_good = $true ; break }

                        default { $ua_good = $false ; break }
                    }
                }
                
                else
                {
                    $ua_good = $false
                }       
                
                if ($verified_good -and $cyber_good -and $ua_good -and $SAAR_good)
                {
                    $good += $user.EDIPI
                }

            }
        }
    }

    return $good

}

###################################################################
############ Function to Display ATCTS Compliance Data ############
###################################################################
function Show-ATCTS
{
    ############ function parameters ############
    param
    (
        #The full or relative path to the ATCTS report. By default, this value is .\report_export.csv
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo] $Path,

        #Specifies the path to the log file if -Log is selected.
        [Parameter(Mandatory=$false)]
        [System.IO.FileInfo] $LogPath = ".\atctscheck.txt",

        #One or more EDIPIs (DoD ID numbers) of a user or users, separated by commas
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$EDIPIs,

        #Specifies whether or not to log output to a .txt file in the working directory. Files are written to the working directory unless otherwise specified in the -LogPath parameter.
        [Parameter(Mandatory=$false)]
        [switch]$Log
    )

    ########## Print 'current as of' status to console ########
    Write-Host `n
    Write-Host "ATCTS data current as of $CAO" -BackgroundColor White -ForegroundColor Black

    ###### Set variables for SAAR/Cyber/UA expiration #####
    $today = Get-Date
    $expiration = $today.AddYears(-1) 
    
    ########### log output if selected ##############
    if ($Log)
    {
        Start-Transcript -Path $LogPath
    }

    ############ loop through each EDIPI given by user input ############
    foreach ($EDIPI in $EDIPIs)
    {       
       
        ######## Set variable to determine if match is found #####
        $matchfound = $false

        ########## Loop through EDIPIs in ATCTS report, searching for match ##########
        foreach ($user in $ATCTS)
        {           
            if ($EDIPI -eq $user.EDIPI)
            {
            
                ######## Set matchfound variable to avoid 'not found' message from being printed #####
                $matchfound = $true
                
                ######## Define variables for personal info ########
                $name = $user.Name
                $rank = $user."Rank/Grade"
                $abbreviatedrank = $rank_abbreviations[$rank] 
                $email = $user."Enterprise Email Address"
                $unit = $user."HQ Alignment Subunit"

                ####### Define type string variables for ATCTS status ##########
                [string]$verified_status = $user."Profile Verified"
                [string]$SAAR = $user."Date SAAR/DD2875 Signed"
                [string]$cyber = $user."Date Awareness Training Completed" 
                [string]$ua = $user."Date Most Recent Army IT UA Doc Signed"

                ######### Define type datetime variables for ATCTS status ######
                $SAAR_date = try { [datetime]::parseexact($SAAR, 'dd-MMM-yyyy', $null) } catch { $null }
                $cyber_date = try { [datetime]::parseexact($cyber, 'dd-MMM-yyyy', $null) } catch { $null }
                $ua_date = try { [datetime]::parseexact($ua, 'dd-MMM-yyyy', $null) } catch { $null }
                
                if ($SAAR_date -ne $null)
                {
                    $SAAR_date = [datetime]$SAAR_date
                }

                if ($cyber_date -ne $null)
                {
                    $cyber_date = [datetime]$cyber_date
                }

                if ($ua_date -ne $null)
                {
                    $ua_date = [datetime]$ua_date
                }

                ######## Check verified status ########
                
                if ($verified_status -ne $null)
                {
                    switch ($verified_status)
                    {
                        {$verified_status -eq $null} {$verified_good = $false ; break}
                    
                        {$verified_status -eq "Yes"} {$verified_good = $true ; break}

                        {$verified_status -eq "No"} {$verified_good = $false ; break}

                        default {$verified_good = $false}
                    }
                }

                else
                {
                    $verified_good = $false
                }
                
                ####### Check SAAR date ######### 
                if ($SAAR_date -ne $null)
                {
                    switch ($SAAR_date.CompareTo($expiration))
                    {
                        {$_ -eq $null } {$SAAR_good = $false ; break}
                    
                        {$_ -le 0} {$SAAR_good = $false ; break}

                        {$_ -gt 0} {$SAAR_good = $true ; break}

                        default {$SAAR_good = $false ; break}
                    }
                }

                else
                {
                    $SAAR_good = $false
                }

                ######## Check CyberAwareness date #######
                if ($cyber_date -ne $null)
                {
                    switch ($cyber_date.CompareTo($expiration)) 
                    { 
                        {$_ -eq $null } {$cyber_good = $false ; break}
                    
                        {$_ -le 0} {$cyber_good = $false ; break }

                        {$_ -gt 0} {$cyber_good = $true ; break }

                        default { $cyber_good = $false ; break }
                    }
                }
                
                else
                {
                    $cyber_good = $false
                }  

                ####### Check IT User Agreement date #######
                if ($ua_date -ne $null)
                {
                    switch ($ua_date.CompareTo($expiration)) 
                    { 
                        {$_ -eq $null } {$ua_good = $false ; break}
                    
                        {$_ -le 0} {$ua_good = $false ; break }

                        {$_ -gt 0} {$ua_good = $true ; break }

                        default { $ua_good = $false ; break }
                    }
                }
                
                else
                {
                   $ua_good = $false
                }       
                
                ######## Print user's name and unit if found ##########
                Write-Host `n
                Write-Host "ATCTS user found for EDIPI $EDIPI"
                Write-Host "/////////////////////////////////////"
                Write-Host "Name:" , $name

                if ($user."Personnel Type" -eq "Military")
                {
                    Write-Host "Rank:" , $abbreviatedrank
                }

                elseif ($user."Personnel Type" -eq "Civilian")
                {
                    Write-Host "Rank:" , "CIV"
                }

                elseif ($user."Personnel Type" -eq "Contractor")
                {
                    Write-Host "Rank:" , "CTR"
                }

                else
                {
                    Write-Host "UNKOWN PERSONNEL TYPE" -ForegroundColor Yellow
                }
                
                Write-Host "Email:" , $email
                Write-Host "Unit:" , $unit
                Write-Host "/////////////////////////////////////"
            
                #########################################################
                ############ Print user's verified status ###############
                #########################################################
            
                if ($verified_good)
                {
                    Write-Host "Profile Verified:" $verified_status
                }
                else
                {
                    Write-Host "Profile Verified: NO" -ForegroundColor Red
                }

                #########################################################
                ############   Print user's SAAR status   ###############
                #########################################################

                if($SAAR -eq "")
                {
                    Write-Host "No SAAR found." -ForegroundColor Red
                }
                elseif ($SAAR_good)
                {
                    Write-Host "SAAR Signed:" $SAAR
                }
                else
                {
                    Write-Host "SAAR OVER 365 DAYS OLD -- Last Signed:" $user."Date SAAR/DD2875 Signed" -ForegroundColor Yellow
                }

                #########################################################
                ########   Print user's CyberAwareness status    ########
                #########################################################

                if ($cyber -eq "")
                {
                    Write-Host "No CyberAwareness certificate found." -ForegroundColor Red
                }
                elseif ($cyber_good)
                {
                    Write-Host "CyberAwareness Completed:" $cyber
                }
                else
                {
                    Write-Host "CyberAwareness EXPIRED -- Completed:" $cyber -ForegroundColor Red
                }

                #########################################################
                #####   Print user's IT User Agreement status    ########
                #########################################################

                if ($ua -eq "")
                {
                    Write-Host "No IT UA found." -ForegroundColor Red
                }
                elseif ($ua_good)
                {
                    Write-Host "IT User Agreement Signed:" $ua
                }
                else
                {
                    Write-Host "IT User Agreement EXPIRED -- Signed:" $ua -ForegroundColor Red
                }

                ########## Print separator block ###########
                Write-Host "/////////////////////////////////////"

            }
        }

        if ($matchfound -eq $false)
        {
            Write-Host `n 
            Write-Host "/////////////////////////////////////"
            Write-Host "No user found with EDIPI of $EDIPI" -ForegroundColor Red
            Write-Host "/////////////////////////////////////"  
        }

    }
    try 
    {
        Stop-Transcript -ErrorAction SilentlyContinue
    } 
    catch 
    {
        Write-Host `n
        Write-Host "ATCTS results not logged."
    }
}

###################################################################
############     Function to search for user in AD     ############
###################################################################
function Find-ADUser
{
    ############ function parameters ##############
    param
    (
        #One or more EDIPIs (DoD ID numbers) of a user or users, separated by commas
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$EDIPIs,

        #Specifies the path to the log file if -Log is selected.
        [Parameter(Mandatory=$false)]
        [System.IO.FileInfo] $LogPath = ".\adcheck.txt",

        #Specifies whether or not to log output to a .txt file in the working directory. Files are written to the working directory unless otherwise specified in the -LogPath parameter.
        [Parameter(Mandatory=$false)]
        [switch]$Log
    )

    ###### variable for domain controller to make changes on ########
    $dc = Get-ADDomainController
    
    foreach ($OU in $OUs)
    {
        if ($OU.Unit -eq "Visitor")
        {
            $visitor_ou = $OU.OrganizationalUnit
        }
    }

    ########### log output if selected ##############
    if ($Log)
    {
        Start-Transcript -Path $LogPath
    }

    ############ loop through each EDIPI given by user input ############
    foreach ($EDIPI in $EDIPIs)
    {
        $exists = Get-ADUser -Filter "UserPrincipalName -like '$($EDIPI + "*")'" -Properties * -Server $dc
        #$visitor = Get-ADUser -SearchBase $visitor_ou -Filter "UserPrincipalName -like '$($EDIPI + "*")'" -Properties * -Server $dc        
        
        ######### Check in visitor OU ############
        if ((($exists | Measure-Object).count -eq 1) -and ($exists.Description -like "This account was created by ProV*"))
        {
            Write-Host `n
            Write-Host "DoD visitor account found with EDIPI of $EDIPI" -ForegroundColor Yellow
            Write-Host "/////////////////////////////////////" -ForegroundColor Yellow
            Write-Host "Name: "$exists.Name"" -ForegroundColor Yellow
            Write-Host "Description: "$exists.Description"" -ForegroundColor Yellow
            Write-Host "Enabled: "$exists.Enabled"" -ForegroundColor Yellow
            Write-Host "/////////////////////////////////////" -ForegroundColor Yellow
        }

        ########### Check for regular user ##########
        elseif ($exists)
        {
            foreach ($user in $exists)
            {
                Write-Host `n
                Write-Host "AD user found: with EDIPI of $EDIPI"
                Write-Host "/////////////////////////////////////"
                Write-Host "Name: "$user.Name""
                Write-Host "Description: "$user.Description""
                Write-Host "Enabled: "$user.Enabled""
                Write-Host "/////////////////////////////////////"
            }
        }
      
        ######### Not found ############
        else
        {
            Write-Host `n
            Write-Host "/////////////////////////////////////"
            Write-Host "No AD user found in 1BCT with EDIPI of $EDIPI" -ForegroundColor Red
            Write-Host "/////////////////////////////////////"
        }
    }

    try 
    {
        Stop-Transcript -ErrorAction SilentlyContinue
    } 
    catch 
    {
        Write-Host `n
        Write-Host "AD results not logged."
    }
}


###################################################################
############  Function to enable user if ATCTS is good  ###########
###################################################################
function Enable-ADUser
{
    ######### Function parameters #############
    param
    (
        ##One or more EDIPIs (DoD ID numbers) of a user or users, separated by commas
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$EDIPIs,

        #The full or relative path to the ATCTS report. By default, this value is .\report_export.csv
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo] $Path,

        #Specifies the path to the log file if -Log is selected.
        [Parameter(Mandatory=$false)]
        [System.IO.FileInfo] $LogPath = ".\enable.txt",

        #Specifies whether or not to log output to a .txt file in the working directory. Files are written to the working directory unless otherwise specified in the -LogPath parameter.
        [Parameter(Mandatory=$false)]
        [switch]$Log
    )

    ###### variable for domain controller to make changes on ########
    $dc = Get-ADDomainController
    
    ########## Variable for ATCTS status ############
    $good = Get-ATCTS -EDIPIs $EDIPIs -Path $Path
    
    ####### Start transcript if log switch was selected #######
    if ($Log)
    {
        Start-Transcript -Path $LogPath
    }

    ########## Loop through EDIPIs given by user input #########
    foreach ($EDIPI in $EDIPIs)
    {
        ####### Set variable for match found status #########
        $matchfound = $false

        ######### Check for a match in ATCTS variable ##########
        foreach ($user in $good)
        {
            if ($user -eq $EDIPI)
            {
                $matchfound = $true
            }
        }

        ######## If match is found, enable ############
        if ($matchfound -eq $true)
        {
            $user_info = Add-ADUser -EDIPIs $EDIPI
            $user = Get-ADUser -Filter "UserPrincipalName -like '$($EDIPI + "*")'" -Properties * -Server $dc 
            
            if ($user)
            {
                if ($user.Enabled -eq $true)
                {
                    Write-Host "User "$user.Name" is already enabled" -ForegroundColor Green
                }
                    
                elseif ($user.Enabled -eq $false)
                {
                        
                    try
                    {
                        $user | Set-ADUser -Enabled $true -Description $user_info.Description -Server $dc -ErrorAction SilentlyContinue
                    }
                        
                    catch
                    {
                        Write-Host "User could not be enabled. Check your permissions" -ForegroundColor Red
                    }

                    $user = Get-ADUser -Filter "UserPrincipalName -like '$($EDIPI + "*")'" -Properties * -Server $dc

                    if ($user.Enabled -eq $true)
                    {
                        Write-Host "User "$user.Name" was enabled" -ForegroundColor Green
                    }                   
                        
                    else
                    {
                        Write-Host "Enabling user "$user.Name"... verify with: bat $EDIPI -CheckAD" -ForegroundColor Yellow
                    }
                }
                    
                else
                {
                    Write-Host "Something went wrong. Is RSAT installed?." -ForegroundColor Red
                }
            }

            else
            {
                Write-Host "User $($user_info.Name) could not be found." -ForegroundColor Red
            }
        }  
        
        elseif ($matchfound -eq $false)
        {
            Write-Host "User could not be enabled due to ATCTS non-compliance." -ForegroundColor Red
        }
        
        else
        {
            Write-Warning "Something went wrong."
        }
    }

        ####### Stop transcript for log if necessary #########
        try 
        {
            Stop-Transcript -ErrorAction SilentlyContinue
        } 
        catch 
        {
            Write-Host `n
            Write-Host "AD results not logged."
        }
}                 


###############################################################################
###### Function to collect attributes for Active Directory user creation ######
###############################################################################

function Add-ADUser
{
    param
    (
        #One or more EDIPIs (DoD ID numbers) of a user or users, separated by commas
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$EDIPIs
    )

    $users = @()
    
    foreach ($EDIPI in $EDIPIs)
    {                  
        
        foreach ($user in $ATCTS)
        {
            
            if ($EDIPI -eq $user.EDIPI)
            {  
            
                ###### Set firstname ########
                $firstname_regex = $user.Name | Select-String -Pattern ',\s(.+)'
               
                try
                {
                    $firstname = (($firstname_regex)[0].Matches[0].Groups[1]).ToString()
                }

                catch
                {
                    $firstname = $null
                }
                
                ########### Set lastname ##########
                $lastname_regex = $user.Name | Select-String -Pattern '^(.+),'

                try
                {
                    $lastname = (($lastname_regex)[0].Matches[0].Groups[1]).ToString()
                }

                catch
                {
                    $lastname = $null
                }
                
                ######### Set middle initial ###########
                $middleinitial_regex = $user.Name | Select-String -Pattern '\w+\s(\w)$'
                
                try
                {
                    $middleinitial = (($middleinitial_regex)[0].Matches[0].Groups[1]).ToString()
                }

                catch
                {
                    $middleinitial = $null
                }

                ####### Status Specific Attrs #######
                
                if ($user."Personnel Type" -eq "Military")
                {
                    ########## Set title (Rank) #########
                    try
                    {
                        $Title = $rank_abbreviations[($user."Rank/Grade")]
                    }
                    catch
                    {
                        $Title = $null
                    }
                    ######### Set UserPrincipalName #########
                    $UserPrincipalName = $user.EDIPI + "121004@mil"

                    ########## Set SamAccountName #############
                    $sAMAccountName = [string]::Format("{0}.mil",$user.EDIPI)
                }
                elseif($user."Personnel Type" -eq "Civilian")
                {
                    ########## Set title (Rank) #########
                    $Title = "CIV"

                    ######### Set UserPrincipalName #########
                    $UserPrincipalName = $user.EDIPI + "121002@mil"

                    ########## Set SamAccountName #############
                    $sAMAccountName = [string]::Format("{0}.civ",$user.EDIPI)
                }
                elseif($user."Personnel Type" -eq "Contractor")
                {
                    ########## Set title (Rank) #########
                    $Title = "CTR"

                    ######### Set UserPrincipalName #########
                    $UserPrincipalName = $user.EDIPI + "121005@mil"

                    ########## Set SamAccountName #############
                    $sAMAccountName = [string]::Format("{0}.ctr",$user.EDIPI)
                }
                else
                {
                    Write-Warning "Unkown personnel type - user EDIPI cannot be determined"
                    $Title = $null
                    $UserPrincipalName = $null
                }

                ####### To Do - Make MACOM a variable rather than hard-coded string #########
                Try
                {
                    #$DisplayName = ($user.Name + " " + $Title + " " + "USA FORSCOM")
                    $DisplayName = [string]::Format("{0} {1} USA FORSCOM",$user.Name,$Title)
                }
                
                catch
                {
                    $DisplayName = "Last, First MI RANK USA FORSCOM"
                }

                ####### Set Account Name #########
                Try
                {
                    $Name = ($user.Name + " " + $Title) 
                }

                catch
                {
                    $Name = "Last, First MI RANK "
                }

                ######## Set user's OU #########
                Switch ($unit = $user."HQ Alignment Subunit")
                {
                        {Test-Bde -inputString $unit} { $OU = $bde_ou ; break}

                        {Test-Bn -inputString $unit} { 
                        
                        $bn_string = Get-Bn -inputString $unit

                        foreach ($Unit in $OUs)
                        {
                            $ou_string = $Unit.Unit | Select-String -Pattern '^(\d+-?\d+)'

                            if ($ou_string -ne $null)
                            {
                                $ou_string = $ou_string.Matches.Groups[1].ToString()
                            }

                            if ($bn_string -eq $ou_string) { $OU = $Unit.OrganizationalUnit }
                        }

                        }

                        Default { $OU = $bde_ou }
                }

                ######## Set Description ###########
                $Description_Regex = $OU | Select-String -Pattern '^[^,]+,[^,]+,OU=([^,]+)'

                try
                {
                    $Description = $Description_Regex.Matches.Groups[1]
                }

                catch
                {
                    $Description = "CHANGE TO USER'S OU"
                }

                ######## Set email address ########
                $Email = $user."Enterprise Email Address"

                ######## Set hard coded attributes ############
                $Company = "Army"
                $city = "Fort Campbell"
                $state = "KY"
                $postalcode = "42223" 
                $telephoneNumber = "270.798.6019"

                ######### Create Object witht the above attributes #########
                $ad_user_attr = [PSCustomObject]@{

                    Name = [string]$Name
                    FirstName = [string]$firstname
                    LastName = [string]$lastname
                    MI = [string]$middleinitial
                    Title = [string]$Title
                    DisplayName = [string]$DisplayName
                    Company = [string]$Company
                    OU = [string]$OU
                    Description = [string]$Description
                    SamAccountName = [string]$SamAccountName
                    Email = [string]$Email
                    UserPrincipalName = [string]$UserPrincipalName
                    City = [string]$city
                    State = [string]$state
                    PostalCode = [string]$postalcode
                    TelephoneNumber = [string]$telephoneNumber
                }

                ######### Add object to array to be returned by function #########
                $users += $ad_user_attr

            }
        }
        
    }

    return $users
}

######################################################
###### Function to create Active Directory user ######
######################################################

function Create-ADUser
{
    ######### Function parameters #############
    param
    (
        #One or more EDIPIs (DoD ID numbers) of a user or users, separated by commas
        [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
        [string[]]$EDIPIs,

        #The full or relative path to the ATCTS report. By default, this value is .\report_export.csv
        [Parameter(Mandatory=$true)]
        [System.IO.FileInfo] $Path,

        #Specifies the path to the log file if -Log is selected.
        [Parameter(Mandatory=$false)]
        [System.IO.FileInfo] $LogPath = ".\create.txt",

        #Specifies whether or not to log output to a .txt file in the working directory. Files are written to the working directory unless otherwise specified in the -LogPath parameter.
        [Parameter(Mandatory=$false)]
        [switch]$Log
    )

    ###### variable for domain controller to make changes on ########
    $dc = Get-ADDomainController
    
    ###### Set default PW ########
    $default_password = New-Password -length 15
    
    ########### log output if selected ##############
    if ($Log)
    {
        Start-Transcript -Path $LogPath
    }
    
    ########## Variable for ATCTS status ############
    $good = Get-ATCTS -EDIPIs $EDIPIs -Path $Path

    ########## Loop through EDIPIs given by user input #########
    foreach ($EDIPI in $EDIPIs)
    {
        
        ####### Clear new user variable and attribute hashtable for account creation #########
        $new_user = $null
        $other_attrs = @{}
        
        ####### Set variable for match found status #########
        $matchfound = $false

        ######### Check for a match in ATCTS variable ##########
        foreach ($user in $good)
        {
            if ($user -eq $EDIPI)
            {
                $matchfound = $true
            }
        }
        
        ###### Define user attributes #######
        $new_user = Add-ADUser -EDIPIs $EDIPI
        
        ########## Create user if found to have clean ATCTS report ########
        if ($matchfound -eq $true)
        {   
            if (Get-ADUser -Filter "UserPrincipalName -like '$($EDIPI + "*")'" -Properties * -Server $dc)
            {
                Write-Warning "User $($new_user.Name) already exists. Skipping..."
                Write-Host `n
            }

            else
            {

                $other_attr_keys = @("DisplayName","GivenName","sn","Initials","Department","Description","Mail","telephoneNumber","l","st","PostalCode","EmployeeID","Company","Title")

                $other_attr_values = @($new_user.DisplayName,$new_user.FirstName,$new_user.LastName,$new_user.MI,"FORSCOM",$new_user.Description,$new_user.Email,$new_user.TelephoneNumber,$new_user.city,$new_user.State,$new_user.PostalCode,[string]$EDIPI,$new_user.Company,$new_user.Title)

                for($i = 0; $i -lt $($other_attr_keys.count); $i++)
                {
                    if ($other_attr_values[$i] -ne $null -and $other_attr_values[$i] -ne "")
                    {
                        $other_attrs.Add($other_attr_keys[$i],$other_attr_values[$i])
                    }
                }

                Write-Host "User $($new_user.Name) is being created. Please wait... :" -ForegroundColor Black -BackgroundColor White
                Write-Host `n

                if ($new_user -ne $null -and $other_attrs.Count -ne 0)
                {
                    New-ADUser -Name $([string]$new_user.Name) -SmartcardLogonRequired $True -Enabled $False -SamAccountName $new_user.SamAccountName -UserPrincipalName $new_user.UserPrincipalName -AccountPassword (ConvertTo-SecureString $default_password -AsPlainText -Force) -Path $new_user.OU -Office $new_user.Description -OtherAttributes $other_attrs -Server $dc

                    Start-Sleep 3

                    if (Get-ADUser -Filter "UserPrincipalName -like '$($EDIPI + "*")'" -Server $dc)
                    {
                        Write-Host "USER $($new_user.Name) CREATED" -ForegroundColor Green
                    }

                    else
                    {
                        Write-Host "SOMETHING WENT WRONG CREATING USER $($new_user.Name) -- VERIFY WITH: bat $EDIPI -CheckAD" -ForegroundColor Yellow
                    }
                }

            }

        }

        if ($matchfound -eq $false)
        {
            Write-Warning "User $($new_user.Name) cannot be created due to ATCTS non-compliance. Run: bat $EDIPI -CheckATCTS for more info."
        }
    }

    ####### Stop transcript for log if necessary #########
    try 
    {
        Stop-Transcript -ErrorAction SilentlyContinue
    } 
    catch 
    {
        Write-Host `n
        Write-Host "Creation results not logged."
    }
}