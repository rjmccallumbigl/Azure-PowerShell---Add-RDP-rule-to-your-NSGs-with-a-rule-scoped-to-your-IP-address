# Azure-PowerShell---Add-RDP-rule-to-your-NSGs-with-a-rule-scoped-to-your-IP-address
Do you have a policy that blocks RDP if you do not add your IP address to the NSG? Update your NIC and Subnet NSGs with a rule allowing 3389 scoped to your IP address so you can remotely access your VM.

Requires VM Name and Resource Group name.

Initial script from Todd Hammer (requires NSG name, Resource Group name, and Port):

```PowerShell
#If running from your PC and you have the azure module loaded in powershell
#Enter the nsg name
$nsgname=Read-Host -Prompt "Enter the NSG name" 
 
#Enter the resource group name
$rgname=Read-Host -Prompt "Enter the resource group name"
 
#Enter the port number
$portnumber=Read-Host -Prompt "What port do you want opened?"
 
$myipaddress=(Invoke-WebRequest https://myexternalip.com/raw).content
 
Get-AzNetworkSecurityGroup -Name $nsgname -ResourceGroupName $rgname | Add-AzNetworkSecurityRuleConfig -Name $portnumber -Description "Allow My Access" -Access "Allow" -Protocol "Tcp" -Direction "Inbound" -Priority 100 -SourceAddressPrefix $myipaddress -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange $portnumber | Set-AzNetworkSecurityGroup
```

Additional script (thanks Dean Weis!):

```PowerShell
$myipaddress=(Invoke-WebRequest https://myexternalip.com/raw).content
$mynsg = Get-AzNetworkSecurityGroup | Select-Object name,resourceGroupName,id | ogv -OutputMode Single -Title "Select the NSG you would like to update"
Get-AzNetworkSecurityGroup -Name $mynsg.name -ResourceGroupName $mynsg.resourcegroup | Add-AzNetworkSecurityRuleConfig -Name MyIPaddress -Description "Allow My Access" -Access "Allow" -Protocol "Tcp" -Direction "Inbound" -Priority 100 -SourceAddressPrefix $myipaddress -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange 22,3389 | Set-AzNetworkSecurityGroup
```
