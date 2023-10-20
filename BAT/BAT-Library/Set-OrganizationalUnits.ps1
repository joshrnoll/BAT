$header = "Unit, OrganizationalUnit"

$visitor_name = "Visitor"
$visitor_ou = Read-Host -Prompt "Enter the distinguished name of the Visitor OU"

$bde_name = "HHC BDE"
$bde_ou = Read-Host -Prompt "Enter the distinguished name of the BDE OU"

[int32]$number_of_bns = Read-Host -Prompt "How many BNs?"

for (($i = 1); ($i -le $number_of_bns); $i++)
{
    $var_name = "bn_$i" + "_name"

    $name = Read-Host -Prompt "Enter the name of BN $i (ex. 1-10 IN)"

    New-Variable -Name $var_name -Scope global -Value $name -Force
}

for (($i = 1); ($i -le $number_of_bns); $i++)
{
    $var_name = "bn_$i" + "_ou"

    $dn = Read-Host -Prompt "Enter the distinguished name for BN $i (ex. OU=Distinguished,OU=Name,OU=Of,DC=The,DC=1-10IN,DC=Organizational,DC=Unit)"

    New-Variable -Name $var_name -Scope global -Value $dn -Force
}

$header | Out-File .\test.csv
$visitor_ou | Add-Content .\test.csv
$bde_ou | Add-Content .\test.csv

for (($i = 1); ($i -le $number_of_bns); $i++)
{
    $bn_name = "bn_$i" + "_name"

    $bn = Get-Variable -Name $bn_name

    $bn.Value | Add-Content .\test.csv
}

for (($i = 1); ($i -le $number_of_bns); $i++)
{
    $bn_ou = "bn_$i" + "_ou"
    
    $bn = Get-Variable -Name $bn_ou

    $bn.Value | Add-Content .\test.csv
}



