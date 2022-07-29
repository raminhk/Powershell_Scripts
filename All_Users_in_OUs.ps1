$Domain =  @(Get-ADDomain).DNSRoot

$OUsPath = Get-Content .\Input\ListofOUs.txt
$Output_Path = ".\Output\$Domain-Allusers-in-OUs-$(Get-Date -format "dd-MM-yyyy").csv"

$Results = @()
$Count_OUs = $OUsPath.Count
$i=1 ## Counter for OUs

Write-Host "$Count_OUs OUs found in the list.`n" -ForegroundColor Green
foreach ($OUPath in $OUsPath) {
    
    $Users = Get-ADUser -Filter * -SearchBase $OUPath -Server $Domain | select SamAccountName
    $Count_Users = $Users.Count
    $j=1 ## Counter for Users

    Write-Host "`n$i/$Count_OUs-- $OUPath" -ForegroundColor Cyan
    Write-Host "---------------------------------------------------" -ForegroundColor Cyan
    Write-Host "++++++ $Count_Users Users have been found.`n" -ForegroundColor Yellow

         foreach ($User in $Users){
    
            $Users_Attribute = Get-ADUser -Identity $User.SamAccountName -Properties *

            $Att = New-Object -TypeName PsObject
                $Att | Add-Member -MemberType NoteProperty -Name Domain -Value $Domain
                $Att | Add-Member -MemberType NoteProperty -Name OU -Value $OUPath
                $Att | Add-Member -MemberType NoteProperty -Name SamAccountName -Value $Users_Attribute.SamAccountName
                $Att | Add-Member -MemberType NoteProperty -Name Name -Value $Users_Attribute.Name
                $Att | Add-Member -MemberType NoteProperty -Name GivenName -Value $Users_Attribute.GivenName
                $Att | Add-Member -MemberType NoteProperty -Name EmailAddress -Value $Users_Attribute.EmailAddress
                $Att | Add-Member -MemberType NoteProperty -Name DistinguishedName -Value $Users_Attribute.DistinguishedName

                $Results += $Att
                
                $Username = $Users_Attribute.SamAccountName
                Write-Host "+++++++++++ $j/$Count_Users- $Username" -ForegroundColor Magenta
                
                $j+=1

            }

    $i+=1

}


$Results | Format-Table
$Results | Export-Csv -Path $Output_Path -NoTypeInformation