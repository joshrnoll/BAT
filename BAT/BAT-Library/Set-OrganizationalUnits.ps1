$header = "`"Unit`", `"OrganizationalUnit`""

$default_password = Read-Host "Enter the default password for newly created users" -AsSecureString

$visitor_name = "Visitor"
$visitor_ou = Read-Host -Prompt "Enter the distinguished name of the Visitor OU (ex. OU=Distinguished,OU=Name,OU=Of,DC=The,DC=Visitor,DC=Organizational,DC=Unit)"

$bde_name = "HHC BDE"
$bde_ou = Read-Host -Prompt "Enter the distinguished name of the BDE OU (ex. OU=Distinguished,OU=Name,OU=Of,DC=The,DC=BDE,DC=Organizational,DC=Unit)"

[int32]$number_of_bns = Read-Host -Prompt "How many BNs?"

for (($i = 1); ($i -le $number_of_bns); $i++)
{
    $var_name = [string]::Format("bn_{0}_name",$i)

    $name = Read-Host -Prompt "Enter the name of BN $i (ex. 1-10 IN)"

    New-Variable -Name $var_name -Scope script -Value $name -Force
}

for (($i = 1); ($i -le $number_of_bns); $i++)
{
    $var_name = [string]::Format("bn_{0}_ou",$i)

    $dn = Read-Host -Prompt "Enter the distinguished name for BN $i (ex. OU=Distinguished,OU=Name,OU=Of,DC=The,DC=1-10IN,DC=Organizational,DC=Unit)"

    New-Variable -Name $var_name -Scope script -Value $dn -Force
}

$org_units_filename = '.\test.csv'
$def_passwd_filename = '.\defpass.txt'

$default_password | ConvertFrom-SecureString | Out-File $def_passwd_filename

$header | Out-File $org_units_filename
[string]::Format("`"{0}`",`"{1}`"",$visitor_name,$visitor_ou) | Add-Content $org_units_filename
[string]::Format("`"{0}`",`"{1}`"",$bde_name,$bde_ou) | Add-Content $org_units_filename

for (($i = 1); ($i -le $number_of_bns); $i++)
{
    $bn_name_var = [string]::Format("bn_{0}_name",$i)

    $bn_ou_var = [string]::Format("bn_{0}_ou",$i)

    $bn_name = Get-Variable -Name $bn_name_var

    $bn_ou = Get-Variable -Name $bn_ou_var

    [string]::Format("`"{0}`",`"{1}`"",$bn_name.Value,$bn_ou.Value) | Add-Content $org_units_filename
}



