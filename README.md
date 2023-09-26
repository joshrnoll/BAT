<img src="./Bastogne Logo.png" width="300" height="300">

# BAT
Bastogne Automation Tool

# Description
BAT is a PowerShell module used for streamlining helpdesk operations for an Army network. This tool helps to automate the process of checking user's compliance in ATCTS alongside account creation/modification in Active Directory.

# Features
<ul>
  <li> Check ATCTS compliance </li>
  <li> Check if user has an AD account (including visitors accounts) </li>
  <li> Enable users in AD </li>
  <li> Log output for later reference </li>
</ul>

# Installation
<ol>
  <li> Click the 'code' dropdown menu and download the .zip file. </li>
  <li> Extract the contents and find the BAT folder. </li>
  <li> The BAT folder should have the following contents/structure: </li> <br>
  <ul> 
    <li> BAT-Library </li>
    <ul>
      <li> BAT-Library.psm1 </li>
    </ul>
    <li> BAT.psd1 </li>
    <li> BAT.psm1 </li> <br>
  </ul>
  <li> Copy the BAT folder and all of its contents to <code>C:\Program Files\WindowsPowerShell\Modules</code> </li>
  <li> Open a PowerShell window and run: <code>Import-Module BAT</code> </li>
  <li> For usage instructions run: <code>Get-Help BAT</code> </li>
</ol>

# Usage
<ul>
  <li> Basic syntax: </li> 
  
`bat [EDIPIs] [Options]`

  <li> Options: </li>
  
  <ul>
    <li> <strong>CheckATCTS:</strong> This will check the user(s) ATCTS report and provide feedback on delinquent items. </li>
    <li> <strong>CheckAD:</strong> This will report whether or not the user is found in Active Directory. It will also identify if the user has a DoD visitor account on Ft. Campbell. </li>
    <li> <strong>Enable:</strong> This will enable the user, only if their ATCTS report is clean. <em>(requires admin credentials)</em></li>
    <li> <strong>Log:</strong> This will log the output to a .txt file in the working directory. </li>
    <li> <strong>Path:</strong> This will specify the path to your ATCTS report (.csv file) -- default value is <strong>.\report_export</strong> if not specified</li>
  </ul> <br>

  <li> Simple Examples: </li>

`bat 1234567890 -CheckATCTS` -- This will check a single user's ATCTS report <br>
`bat 1234567890 -CheckAD` -- This will check if the user exists in Active Directory <br>
`bat 1234567890 -Enable` -- This will enable the user, but only if their ATCTS report is clean <br>
  
  <li> Dynamic Examples: </li>

`bat 1234567890,3216549870,4560123987 -CheckATCTS` -- Check multiple user's ATCTS <br>
`bat 1234567890,3216549870,4560123987 -CheckATCTS -CheckAD` -- Check multiple user's ATCTS reports and check for accounts in Active Directory <br>
`bat 1234567890,3216549870,4560123987 -CheckATCTS -Log` -- Check multiple user's ATCTS and log the output <br>

</ul>

