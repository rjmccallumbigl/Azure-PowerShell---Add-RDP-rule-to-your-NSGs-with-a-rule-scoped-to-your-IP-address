# Do you have a policy that blocks RDP if you do not add your IP address to the NSG? Update your NIC and Subnet NSGs with a rule allowing 3389 or 22 scoped to your IP address so you can remotely access your VM.

#Enter the VM name
$vm = Read-Host -Prompt "Paste the VM name";

#Enter the resource group name
$rgname = Read-Host -Prompt "Enter the resource group name";

#Enter the port number
$portnumber = Read-Host -Prompt "Enter the port number";

# Get NSGs from NIC and Subnet
$vmObject = Get-AzVM -Name $vm -ResourceGroupName $rgname;
$nic = Get-AzNetworkInterface -ResourceId $vmObject.NetworkProfile.NetworkInterfaces[0].Id;
$nicNSG = (Get-AzResource -ResourceId $nic.NetworkSecurityGroup.Id).Name;
$vnet = Get-AzVirtualNetwork -ResourceGroupName $rgname;
$subnet = $vnet.Subnets[0];
$subnetNSG = (Get-AzResource -ResourceId $subnet.NetworkSecurityGroup.Id).Name;
  
# Get your IP Address
$myipaddress = (Invoke-WebRequest https://myexternalip.com/raw).content;

# Add NSGs to array
$NSGArray = $nicNSG, $subnetNSG;

# Update NSGs
for ($i = 0; $i -lt $NSGArray.Count; $i++) {
    Get-AzNetworkSecurityGroup -Name $NSGArray[$i] -ResourceGroupName $rgname | Add-AzNetworkSecurityRuleConfig -Name $portnumber -Description "Allow My Access" -Access "Allow" -Protocol "Tcp" -Direction "Inbound" -Priority 100 -SourceAddressPrefix $myipaddress -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange $portnumber | Set-AzNetworkSecurityGroup
}
 
