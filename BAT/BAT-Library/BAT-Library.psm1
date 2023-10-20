####################################################################
#################################################################### 
#####        
#####        Name: Bastogne Automations Tool (BAT) Functions Library
#####        Author: Joshua R. Noll
#####        Version: 1.3
#####        Usage: help .\BAT
#####
####################################################################
####################################################################


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

    ############ loop through each EDIPI given by user input ############
    foreach ($EDIPI in $EDIPIs)
    {            
        foreach ($user in $ATCTS)
        {
            if ($EDIPI -eq $user.EDIPI)
            {
                ####### Define variables for ATCTS status ##########
                [string]$verified_status = $user."Profile Verified"
                [string]$cyber = $user."Date Awareness Training Completed" 
                [string]$ua = $user."Date Most Recent Army IT UA Doc Signed"

                ###### Define variables for a clean ATCTS report ##########
                $verified_good = $verified_status -eq "Yes"
                $cyber_good = try { [datetime]::parseexact($cyber, 'dd-MMM-yyyy', $null) -gt $expiration } catch { $null }
                $ua_good = try { [datetime]::parseexact($ua, 'dd-MMM-yyyy', $null) -gt $expiration } catch { $null }   

                if ($verified_good -and $cyber_good -and $ua_good)
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
            
                ######## Define variables for personal info ########
                $name = $user.Name
                $rank = $user."Rank/Grade"
                $abbreviatedrank = $rank_abbreviations[$rank] 
                $email = $user."Enterprise Email Address"
                $unit = $user."HQ Alignment Subunit"
            
                ####### Define variables for ATCTS status ##########
                [string]$verified_status = $user."Profile Verified"
                [string]$SAAR = $user."Date SAAR/DD2875 Signed"
                [string]$cyber = $user."Date Awareness Training Completed" 
                [string]$ua = $user."Date Most Recent Army IT UA Doc Signed"

                ###### Define variables for a clean ATCTS report ##########
                $verified_good = $verified_status -eq "Yes"
                $SAAR_good = try { [datetime]::parseexact($SAAR, 'dd-MMM-yyyy', $null) -gt $expiration } catch { $null }
                $cyber_good = try { [datetime]::parseexact($cyber, 'dd-MMM-yyyy', $null) -gt $expiration } catch { $null }
                $ua_good = try { [datetime]::parseexact($ua, 'dd-MMM-yyyy', $null) -gt $expiration } catch { $null }   

                ######## Set matchfound variable to avoid 'not found' message from being printed #####
                $matchfound = $true
                
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
                    Write-Host "Profile Verified:" $verified_status -ForegroundColor Red
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

                if ($verified_good -and $SAAR_good -and $cyber_good -and $ua_good)
                {
                    $good += $user.EDIPI
                }
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
        $exists = Get-ADUser -Filter "UserPrincipalName -like '$($EDIPI + "*")'" -Properties *
        $visitor = Get-ADUser -SearchBase $visitor_ou -Filter "UserPrincipalName -like '$($EDIPI + "*")'" -Properties *        
        
        ######### Check in visitor OU ############
        if ($visitor)
        {
            Write-Host `n
            Write-Host "DoD visitor account found with EDIPI of $EDIPI" -ForegroundColor Yellow
            Write-Host "/////////////////////////////////////" -ForegroundColor Yellow
            Write-Host "Name: "$visitor.Name"" -ForegroundColor Yellow
            Write-Host "Description: "$visitor.Description"" -ForegroundColor Yellow
            Write-Host "Enabled: "$visitor.Enabled"" -ForegroundColor Yellow
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
            $user = Get-ADUser -Filter "UserPrincipalName -like '$($EDIPI + "*")'" -Properties *
            
            if ($user)
            {
                foreach ($account in $user)
                {   
                    if ($account.Enabled -eq $true)
                    {
                        Write-Host "User "$account.Name" is already enabled" -ForegroundColor Green
                    }
                    
                    elseif ($account.Enabled -eq $false)
                    {
                        
                        try
                        {
                            $account | Set-ADUser -Enabled $true -ErrorAction SilentlyContinue
                        }
                        
                        catch
                        {
                            Write-Host "User could not be enabled. Check your permissions" -ForegroundColor Red
                        }
                        
                        Start-Sleep 2

                        if ($account.Enabled -eq $true)
                        {
                            Write-Host "User "$account.Name" was enabled" -ForegroundColor Green
                        }                   
                        
                        else
                        {
                            Write-Host "Enabling user "$account.Name"... verify with: bat $EDIPI -CheckAD" -ForegroundColor Yellow
                        }
                    }
                    
                    else
                    {
                        Write-Host "Something went wrong. Is RSAT installed?." -ForegroundColor Red
                    }
                }
            }
            
            else
            {
                Write-Host "No user found with EDIPI of '$EDIPI'"
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
}

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
                $firstname_regex = $user.Name | Select-String -Pattern ',\s(\w+)'
               
                try
                {
                    $firstname = (($firstname_regex)[0].Matches[0].Groups[1]).ToString()
                }

                catch
                {
                    $firstname = $null
                }
                
                ########### Set lastname ##########
                $lastname_regex = $user.Name | Select-String -Pattern '^(\w+),'

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

                ########## Set title (Rank) #########
                try
                {
                    $Title = $rank_abbreviations[$user."Rank/Grade"]
                }

                catch
                {
                    $Title = $null
                }

                ####### To Do - Make MACOM a variable rather than hard-coded string #########
                Try
                {
                    $DisplayName = ($user.Name + " " + $Title + " " + "USA FORSCOM") 
                }

                catch
                {
                    $DisplayName = "Last, First MI RANK USA FORSCOM"
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
                $Description_Regex = $OU | Select-String -Pattern '^[^,]+,[^,]+,([^,]+)'

                try
                {
                    $Description = $Description_Regex.Matches.Groups[1]
                }

                catch
                {
                    $Description = "CHANGE TO USER'S OU"
                }
                
                ######### Set SamAccountName ############
                $SamAccountName_Regex = $user."Enterprise Email Address" | Select-String -Pattern '^(.+)\..+@.+'
                
                try
                {
                    $SamAccountName = $SamAccountName_Regex.Matches.Groups[1]
                }

                catch
                {
                    $SamAccountName = "first.mi.last"
                }

                $Email = $user."Enterprise Email Address"
                
                ######### Set UserPrincipalName #########
                if ($user."Personnel Type" -eq "Military")
                {
                    $UserPrincipalName = $user.EDIPI + "121004@mil"
                }
                
                elseif ($user."Personnel Type" -eq "Civilian")
                {
                    $UserPrincipalName = $user.EDIPI + "121002@mil"
                }

                elseif ($user."Personnel Type" -eq "Contractor")
                {
                    $UserPrincipalName = $user.EDIPI + "121005@mil"
                }

                else
                {
                    Write-Warning "Unkown personnel type - user EDIPI cannot be determined"
                    $UserPrincipalName = $null
                }

                ######## Set hard coded attributes ############
                $Company = "Army"
                $city = "Fort Campbell"
                $state = "KY"
                $postalcode = "42223" 
                $telephoneNumber = "270.798.6019"

                ######### Create Object witht the above attributes #########
                $ad_user_attr = [PSCustomObject]@{

                    FirstName = $firstname
                    LastName = $lastname
                    MI = $middleinitial
                    Title = $Title
                    DisplayName = $DisplayName
                    Company = $Company
                    OU = $OU
                    Description = $Description
                    SamAccountName = $SamAccountName
                    Email = $Email
                    UserPrincipalName = $UserPrincipalName
                    City = $city
                    State = $state
                    PostalCode = $postalcode
                    TelephoneNumber = $telephoneNumber
                }

                ######### Add object to array to be returned by function #########
                $users += $ad_user_attr

            }
        }
        
    }

    return $users
}

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
        [System.IO.FileInfo] $LogPath = ".\enable.txt",

        #Specifies whether or not to log output to a .txt file in the working directory. Files are written to the working directory unless otherwise specified in the -LogPath parameter.
        [Parameter(Mandatory=$false)]
        [switch]$Log
    )

    ########## Variable for ATCTS status ############
    $good = Get-ATCTS -EDIPIs $EDIPIs -Path $Path

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
        
        ########## Create user if found to have clean ATCTS report ########
        if ($matchfound -eq $true)
        {   
            if (Get-ADUser -Filter "UserPrincipalName -like '$($EDIPI + "*")'" -Properties *)
            {
                Write-Warning "User already exists. Skipping..."
            }

            else
            {
                Add-ADUser -EDIPIs $EDIPI 
            }

        }

        if ($matchfound -eq $false)
        {
            Write-Warning "User $EDIPI cannot be created due to ATCTS non-compliance"
        }
    }
}