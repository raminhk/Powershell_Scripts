<##############################################################################
This script creates a report of all Users in list of OUs.


By: Ramin Heidari Khabbaz

Versions:
    1.0: List of users in a single OU
    1.1: List of users in a list of OUs
    1.2: Enhanced Script Error Handling 
    1.3: Add UserAccountControl Property Flag
################################################################################>

Start-Transcript -Path ".\Logs\Log-$(Get-Date -format "dd-MM-yyyy").txt"

$Domain =  @(Get-ADDomain).DNSRoot

$OUsPath = Get-Content .\Input\ListofOUs.txt
$Output_Path = ".\Output\$Domain-Allusers-in-OUs-$(Get-Date -format "dd-MM-yyyy").csv"

$Results = @()
$Count_OUs = $OUsPath.Count
$i=1 ## Counter for OUs

Write-Host "$Count_OUs OUs found in the list.`n" -ForegroundColor Green

function UserAccountControl_decode{

Param ($userAccountControl)
if ($userAccountControl -eq 1) {$userflag = "SCRIPT"}
elseif ($userAccountControl -eq 2) {$userflag = "ACCOUNTDISABLE"}
elseif ($userAccountControl -eq 8) {$userflag = "HOMEDIR_REQUIRED"}
elseif ($userAccountControl -eq 16) {$userflag = "LOCKOUT"}
elseif ($userAccountControl -eq 32) {$userflag = "PASSWD_NOTREQD"}
elseif ($userAccountControl -eq 64) {$userflag = "PASSWD_CANT_CHANGE"}
elseif ($userAccountControl -eq 128) {$userflag = "ENCRYPTED_TEXT_PWD_ALLOWED"}
elseif ($userAccountControl -eq 256) {$userflag = "TEMP_DUPLICATE_ACCOUNT"}
elseif ($userAccountControl -eq 512) {$userflag = "NORMAL_ACCOUNT"}
elseif ($userAccountControl -eq 514) {$userflag = "Disabled Account"}
elseif ($userAccountControl -eq 544) {$userflag = "Enabled, Password Not Required"}
elseif ($userAccountControl -eq 546) {$userflag = "Disabled, Password Not Required"}
elseif ($userAccountControl -eq 2048) {$userflag = "INTERDOMAIN_TRUST_ACCOUNT"}
elseif ($userAccountControl -eq 4096) {$userflag = "WORKSTATION_TRUST_ACCOUNT"}
elseif ($userAccountControl -eq 8192) {$userflag = "SERVER_TRUST_ACCOUNT"}
elseif ($userAccountControl -eq 65536) {$userflag = "DONT_EXPIRE_PASSWORD"}
elseif ($userAccountControl -eq 66048) {$userflag = "Enabled, Password Doesn't Expire"}
elseif ($userAccountControl -eq 66050) {$userflag = "Disabled, Password Doesn't Expire"}
elseif ($userAccountControl -eq 66082) {$userflag = "Disabled, Password Doesn't Expire & Not Required"}
elseif ($userAccountControl -eq 131072) {$userflag = "MNS_LOGON_ACCOUNT"}
elseif ($userAccountControl -eq 262144) {$userflag = "SMARTCARD_REQUIRED"}
elseif ($userAccountControl -eq 262656) {$userflag = "Enabled, Smartcard Required"}
elseif ($userAccountControl -eq 262658) {$userflag = "Disabled, Smartcard Required"}
elseif ($userAccountControl -eq 262690) {$userflag = "Disabled, Smartcard Required, Password Not Required"}
elseif ($userAccountControl -eq 328194) {$userflag = "Disabled, Smartcard Required, Password Doesn't Expire"}
elseif ($userAccountControl -eq 328226) {$userflag = "Disabled, Smartcard Required, Password Doesn't Expire & Not Required"}
elseif ($userAccountControl -eq 524288) {$userflag = "TRUSTED_FOR_DELEGATION"}
elseif ($userAccountControl -eq 532480) {$userflag = "Domain controller"}
elseif ($userAccountControl -eq 1048576) {$userflag = "NOT_DELEGATED"}
elseif ($userAccountControl -eq 2097152) {$userflag = "USE_DES_KEY_ONLY"}
elseif ($userAccountControl -eq 4194304) {$userflag = "DONT_REQ_PREAUTH"}
elseif ($userAccountControl -eq 8388608) {$userflag = "PASSWORD_EXPIRED"}
elseif ($userAccountControl -eq 16777216) {$userflag = "TRUSTED_TO_AUTH_FOR_DELEGATION"}
elseif ($userAccountControl -eq 67108864) {$userflag = "PARTIAL_SECRETS_ACCOUNT"}
else {$userflag = "N/A"}


Return $userflag

}



foreach ($OUPath in $OUsPath) {
  try{  

    $Users = Get-ADUser -Filter * -SearchBase $OUPath -Server $Domain | select SamAccountName
    $Count_Users = $Users.Count
    $j=1 ## Counter for Users

    Write-Host "`n$i/$Count_OUs-- $OUPath" -ForegroundColor Cyan
    Write-Host "---------------------------------------------------" -ForegroundColor Cyan
    Write-Host "++++++ $Count_Users Users have been found.`n" -ForegroundColor Yellow

         foreach ($User in $Users){
    
            try{
            
            $Users_Attribute = Get-ADUser -Identity $User.SamAccountName -Properties *
            $flag = UserAccountControl_decode ($Users_Attribute.userAccountControl)

            $Att = New-Object -TypeName PsObject
                $Att | Add-Member -MemberType NoteProperty -Name Domain -Value $Domain
                $Att | Add-Member -MemberType NoteProperty -Name OU -Value $OUPath
                $Att | Add-Member -MemberType NoteProperty -Name SamAccountName -Value $Users_Attribute.SamAccountName
                $Att | Add-Member -MemberType NoteProperty -Name Enabled -Value $Users_Attribute.Enabled
                $Att | Add-Member -MemberType NoteProperty -Name Name -Value $Users_Attribute.Name
                $Att | Add-Member -MemberType NoteProperty -Name Description -Value $Users_Attribute.Description
                $Att | Add-Member -MemberType NoteProperty -Name DistinguishedName -Value $Users_Attribute.DistinguishedName
                $Att | Add-Member -MemberType NoteProperty -Name AccountExpirationDate -Value $Users_Attribute.AccountExpirationDate
                $Att | Add-Member -MemberType NoteProperty -Name LastLogonDate -Value $Users_Attribute.LastLogonDate
                $Att | Add-Member -MemberType NoteProperty -Name PasswordLastSet -Value $Users_Attribute.PasswordLastSet
                $Att | Add-Member -MemberType NoteProperty -Name userAccountControl -Value $Users_Attribute.userAccountControl
                $Att | Add-Member -MemberType NoteProperty -Name PropertyFlag -Value $flag
                
                $Results += $Att
                
                $Username = $Users_Attribute.SamAccountName
                Write-Host "+++++++++++ $j/$Count_Users- $Username" -ForegroundColor Magenta
                
                $j+=1

            }
            catch{
                
                $error_msg = $Error[0].Exception.Message
                "Error!! $User in $OUPath under $Domain : $error_msg" | Out-File -Encoding Ascii -append  ".\Errors\$Domain-Errors-$(Get-Date -format "dd-MM-yyyy").txt"
                                    
            }
            
            
            
            
            } ## End of Users foreach
            

    $i+=1

} ## End of Try for OUs

catch {
    $error_msg = $Error[0].Exception.Message
    "Cannot find $OUPath under $Domain : $error_msg" | Out-File -Encoding Ascii -append  ".\Errors\$Domain-Errors-$(Get-Date -format "dd-MM-yyyy").txt"
    

}


} ## End of OUs foreach


$Results | Format-Table
$Results | Export-Csv -Path $Output_Path -NoTypeInformation

Stop-Transcript
