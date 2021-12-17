# Do you have a policy that blocks RDP if you do not add your IP address to the NSG? Update your NIC and Subnet NSGs with a rule allowing 3389 (RDP), 22 (SSH), 6516 (WAC), etc. scoped to your IP address so you can remotely access your VM.
# Version 0.2

# Set the Parameters for the script
param (
    [Parameter(Mandatory = $true, HelpMessage = "The name of the VM.")]
    [Alias('v')]
    [string]
    $vmName,
    [Parameter(Mandatory = $true, HelpMessage = "The name of the Resource Group.")]
    [Alias('r')]
    [string]
    $rgName,
    [Parameter(Mandatory = $true, HelpMessage = "The port number (e.g. 3389, 22, etc.)")]
    [Alias('p')]
    [string]
    $portNumber
)

# Catch any NSG failures if there are no NSGs on the network resource
trap {
    if ($_ -like "*empty*" ) {
        Write-Host "Did not detect an NSG at the $($devices[-1]) level"
        continue 
    }
}

#Enter the VM name
if (!$vmName) {
    $vmName = Read-Host -Prompt "Paste the VM name" 
}

#Enter the resource group name
if (!$rgName) {
    $rgName = Read-Host -Prompt "Enter the resource group name"
}

#Enter the port number
if (!$portNumber) {
    $portNumber = Read-Host -Prompt "Enter the port number"
} 

# Get NSGs from NIC and Subnet (if they exist)
$devices = @()
$vmObject = Get-AzVM -Name $vmName -ResourceGroupName $rgName
# TODO: account for several NICs
# for ($a = 0; $a -lt $vmObject.NetworkProfile.NetworkInterfaces.Count; $a++) {
#     $nic += Get-AzNetworkInterface -ResourceId $vmObject.NetworkProfile.NetworkInterfaces[$a].Id     
#     $devices += "NIC #$($a + 1)"
# } 
$nic = Get-AzNetworkInterface -ResourceId $vmObject.NetworkProfile.NetworkInterfaces[0].Id 
$devices += "NIC"
$nicNSG = (Get-AzResource -ResourceId $nic.NetworkSecurityGroup.Id -ErrorAction Stop).Name
$vnet = Get-AzVirtualNetwork -ResourceGroupName $rgName
$subnet = $vnet.Subnets[0]
$devices += "Subnet"
$subnetNSG = (Get-AzResource -ResourceId $subnet.NetworkSecurityGroup.Id -ErrorAction Stop).Name 

# Get your IP Address
$myipaddress = (Invoke-WebRequest https://myexternalip.com/raw).content

# Add NSG(s) to array
$NSGArray = @()
if ($nicNSG) {
    $NSGArray += $nicNSG
}
if ($subnetNSG) {
    $NSGArray += $subnetNSG
}

# Update NSG(s)
$priority = 100
$j = 1
$ruleName = "Allow My Access"
for ($i = 0; $i -lt $NSGArray.Count; $i++) {
    while ($true) {
        try { 
            Write-Host "Creating rule $($ruleName) allowing port $($portNumber) on $($devices[$i]) at priority $($priority)"       
            Get-AzNetworkSecurityGroup -Name $NSGArray[$i] -ResourceGroupName $rgName | Add-AzNetworkSecurityRuleConfig -Name $ruleName -Description "$($ruleName) via PowerShell" -Access "Allow" -Protocol "Tcp" -Direction "Inbound" -Priority $priority -SourceAddressPrefix $myipaddress -SourcePortRange "*" -DestinationAddressPrefix "*" -DestinationPortRange $portNumber -ErrorAction Stop | Set-AzNetworkSecurityGroup -ErrorAction Stop
            break
        }
        catch {
            # If we have a rule at this priority conflicting with this issue, increase priority until we don't have a rule here            
            if ($_ -like "*conflict*" ) {                
                $priority++
            }
            # Rename if the rule already exists
            elseif ($_.Exception.Message -eq "Rule with the specified name already exists") {
                $j++
                $ruleName = "$($ruleName) $($j)"
            }
            # Otherwise display error
            else {
                $_
                break
            }
        }
    }
}
