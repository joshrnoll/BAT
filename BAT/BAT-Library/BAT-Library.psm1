####################################################################
#################################################################### 
#####        
#####        Name: Bastogne Automations Tool (BAT) Functions Library
#####        Author: Joshua R. Noll
#####        Version: 1.2
#####        Usage: help .\BAT
#####
####################################################################
####################################################################


###################################################################
############ Function to Display ATCTS Compliance Data ############
###################################################################
function Get-ATCTS
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
    
    ######## Import ATCTS report #############
    $header = "EDIPI","Personnel Type","HQ Alignment Subunit","Name","Rank/Grade","Profile Verified","Date SAAR/DD2875 Signed","Date Awareness Training Completed","Date Most Recent Army IT UA Doc Signed","Enterprise Email Address"
    
    if (!(Test-Path $Path))
    {
        Write-Error "The ATCTS report could not be found. Is the .csv file in your working directory?" -ErrorAction Stop
    }
    else
    {
        $ATCTS = Import-Csv -Path $Path -Header $header -ErrorAction SilentlyContinue
    
        $CAO = [datetime](Get-ItemProperty -Path $Path -Name LastWriteTime).LastWriteTime

        Write-Host `n
        Write-Host "ATCTS data current as of $CAO" -BackgroundColor White -ForegroundColor Black
    }

    ###### Set variables for SAAR/Cyber/UA expiration #####
    $today = Get-Date
    $expiration = $today.AddYears(-1)

    ############ Variable to return for users with a clean ATCTS profile ########
    $good = @()

    #Define rank abbreviation dictionary
    $rank_abbreviations = @{

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
                
                #Print user's name and unit if found
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
                    Write-Host "SAAR EXPIRED -- Last Signed:" $user."Date SAAR/DD2875 Signed" -ForegroundColor Red
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

    Write-Host `n
    Write-Host "EDIPIs with a clean ATCTS report:"
    return $good
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
    
    ######### Store visitor OU DN in variable #############
    $OUs = Import-Csv -Path .\OrganizationalUnits.csv

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
                            Write-Host "Unable to verify enabling of user "$account.Name" -- verify with: bat $EDIPI -CheckAD" -ForegroundColor Yellow
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
