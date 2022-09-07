$FilePath = "C:\code\Vmware-Inventory"

# transcripting
Stop-Transcript | out-null
$logspath = $FilePath + "\" + ("{0:yyyyMMdd}_VCenter-VMInventory.log" -f (get-date))  
Start-Transcript -path $logspath -append

$outpath = $FilePath + "\" + ("{0:MM_dd_yyyy}_VCenter-VMInventory.csv" -f (get-date)) 

# Check for PowerCLI
Write-host "Detecting if PowerCLI is available"
$PowerCLI = Get-Module -ListAvailable VMware.PowerCLI
if (!$PowerCLI) {
    Throw 'The PowerCLI module must be installed to continue'
}

# Disconnect any existing VCenter connections
if($global:DefaultVIServers){
    Disconnect-VIServer -Server $global:DefaultVIServers -confirm:$False -Force | out-null
}

# Define Credentials for connecting to vCenters
$Credential = Get-Credential

# Define Vcenters to inventory
$Vcenters = @(
    "vcenter1.test.com",
    "vcenter2.test.com",
    "vcenter3.test.com",
    "vcenter4.test.com",
    "vcenter5.test.com",
    "vcenter6.test.com",
    "vcenter7.test.com"
)

# SciptBlock used in the threads
$ScriptBlock = {
    Param (
        [string]$VCenterName,
        [System.Management.Automation.PSCredential]$Credential
    )

    # Create random sleep timer to avoid accessing vcenter file at the same time.
    $RandomOffset = Get-Random -Maximum 120
    Start-Sleep -Seconds $RandomOffset
    
    # Connect to vCenter 
    try{
        connect-viserver -server $VCenterName -Credential $Credential -force -erroraction stop 
        $connectedtoVcenter = $true
    }Catch{
        $connectedtoVcenter = $False
    }
    
    if($connectedtoVcenter -eq $true){
        # Empty VcenterData
        $VCenterData = @()
        
        # Get list of VMs for vCenter
        $VMs = get-vm -server $VCenterName | sort Name
        $VMs_NICs = Get-NetworkAdapter -VM *
        $VMs_Disks = Get-HardDisk -VM *

        foreach ($VM in $VMs){
            
            # VM_Disks
            $VM_Disks = @()
            $VM_Disks = $VMs_Disks | where {$_.Parent.name -eq $vm.name}

            # VMs_NICs
            $VM_NICs = @()
            $VM_NICs = $VMs_NICs | where {$_.Parent.name -eq $vm.name}
            
            # Get Annotations
            $Annotations = @()
            $Annotations = $VM | Get-Annotation
            
            # Add Data to Row
            $Row = [PSCustomObject]@{
                Name                	= $VM.Name
                PowerState          	= $VM.PowerState
                DNS_Name				= $VM.Guest.HostName
                HardwareVersion     	= $VM.HardwareVersion
                PortGroupName			= $VM_NICs.NetworkName -join ','
                vCenter             	= $VCenterName
                Host                	= $VM.VMHost.Name
                Cluster             	= $VM.VMHost.Parent.name
                GuestOS             	= $VM.Guest.OSFullName
                Folder					= $vm.Folder.Name
                NumCPU              	= $VM.NumCpu
                MemGB               	= $VM.MemoryGB
                NumDisks            	= $VM_Disks.Count
                VMDK_GB					= $VM_Disks | Measure-Object -Property CapacityGB -Sum | Select -ExpandProperty Sum
                NIC0_IP             	= $VM.Guest.IPAddress[0]
                NIC0_Mac            	= $VM_NICs.MacAddress[0]
                Application_Name    	= ($annotations | where {$_.name -eq "Application_Name"}).value
                Business_Unit       	= ($annotations | where {$_.name -eq "Business_Unit"}).value
                Channel             	= ($annotations | where {$_.name -eq "Channel"}).value
                Domain					= ($annotations | where {$_.name -eq "Domain"}).value
                Environment				= ($annotations | where {$_.name -eq "Environment"}).value
                Notes					= ($annotations | where {$_.name -eq "Notes"}).value
                Project_Name			= ($annotations | where {$_.name -eq "Project_Name"}).value
                Project_Sponsor			= ($annotations | where {$_.name -eq "Project_Sponsor"}).value
                Requestor				= ($annotations | where {$_.name -eq "Requestor"}).value
                Server_Description		= ($annotations | where {$_.name -eq "Server_Description"}).value
                Server_Role				= ($annotations | where {$_.name -eq "Server_Role"}).value
                Service_Line			= ($annotations | where {$_.name -eq "Service_Line"}).value
                Service_Request_Number	= ($annotations | where {$_.name -eq "Service_Request_Number"}).value
                Technical_Contact		= ($annotations | where {$_.name -eq "Technical_Contact"}).value
                VM_Created_Date			= $VM.ExtensionData.Config.createDate
                VMID					= $VM.Extensiondata.config.Uuid
            }
            # Add Row to VcenterData
            $VCenterdata += $Row
        }
    }else{
        # Empty VcenterData
        $VCenterData = @()

        # Add Data to Row
        $Row = [PSCustomObject]@{
            Name                	= "Couldn't Connect to $VCentername"
            PowerState          	= "Couldn't Connect to $VCentername"
            DNS_Name				= "Couldn't Connect to $VCentername"
            HardwareVersion     	= "Couldn't Connect to $VCentername"
            PortGroupName			= "Couldn't Connect to $VCentername"
            vCenter             	= $VCenterName
            Host                	= "Couldn't Connect to $VCentername"
            Cluster             	= "Couldn't Connect to $VCentername"
            GuestOS             	= "Couldn't Connect to $VCentername"
            Folder					= "Couldn't Connect to $VCentername"
            NumCPU              	= "Couldn't Connect to $VCentername"
            MemGB               	= "Couldn't Connect to $VCentername"
            NumDisks            	= "Couldn't Connect to $VCentername"
            VMDK_GB					= "Couldn't Connect to $VCentername"
            NIC0_IP             	= "Couldn't Connect to $VCentername"
            NIC0_Mac            	= "Couldn't Connect to $VCentername"
            Application_Name    	= "Couldn't Connect to $VCentername"
            Business_Unit       	= "Couldn't Connect to $VCentername"
            Channel             	= "Couldn't Connect to $VCentername"
            Domain					= "Couldn't Connect to $VCentername"
            Environment				= "Couldn't Connect to $VCentername"
            Notes					= "Couldn't Connect to $VCentername"
            Project_Name			= "Couldn't Connect to $VCentername"
            Project_Sponsor			= "Couldn't Connect to $VCentername"
            Requestor				= "Couldn't Connect to $VCentername"
            Server_Description		= "Couldn't Connect to $VCentername"
            Server_Role				= "Couldn't Connect to $VCentername"
            Service_Line			= "Couldn't Connect to $VCentername"
            Service_Request_Number	= "Couldn't Connect to $VCentername"
            Technical_Contact		= "Couldn't Connect to $VCentername"
            VM_Created_Date			= "Couldn't Connect to $VCentername"
            VMID					= "Couldn't Connect to $VCentername"
        }
        # Add Row to VcenterData
        $VCenterdata += $Row
    }
    # Add Vcenter Data to Data Hash
    $Data[$VCenterName] = $VCenterData
}

# Build Runspaces
$numThreads = 10
$vcentercount = $vcenters.count
Write-Host "Running $numthreads threds at a time for $vcentercount vCenters"

# To return data, use a synchronized hashtable and add the data to it in the scriptblock
$data = [HashTable]::Synchronized(@{})

# Add the synchronized hashtable to the "initial state".
$InitialSessionState = [System.Management.Automation.Runspaces.InitialSessionState]::CreateDefault() 
$InitialSessionState.Variables.Add((New-Object -TypeName System.Management.Automation.Runspaces.SessionStateVariableEntry -ArgumentList 'Data', $Data, ''))

# Create runspace pool consisting of $numThreads runspaces
$RunspacePool = [RunspaceFactory]::CreateRunspacePool(1, $numThreads, $InitialSessionState, $Host)
$RunspacePool.Open()

$startTime = Get-Date
$a = 1
$Jobs = @()

foreach ($vcenter in $vcenters) {

    $Job = [powershell]::Create().AddScript($ScriptBlock).AddParameter("VCenterName", $vcenter).AddParameter("Credential", $Credential)
    $Job.RunspacePool = $RunspacePool
    # Create Runspace collection
	# When we create the collection, we also define that each Runspace should begin running
    $Jobs += New-Object PSObject -Property @{
      RunNum = $a
      Job = $Job
      Result = $Job.BeginInvoke()
   }
   $a++
}
 
Write-Host "Running Inventory Jobs" 
Do {
    # Creating counters for progress bar
    $I = ($jobs | where {$_.result.iscompleted -eq $true}).count
    if(!$I){$I = 0}
    $total = $jobs.Count
    
    # Progress Bar
    Write-Progress -id 0 -activity "Running Inventory Jobs" "Completed: $i vCenters of $total" -PercentComplete (($i / $total) * 100)
    
    # Sleep interval before checking status again
    Start-Sleep -Seconds 1   

} While ( $Jobs.Result.IsCompleted -contains $false) 

# Cleanup Progress Bar - Can just close it with the last line but this will show the final state as well. 
$I = ($jobs | where {$_.result.iscompleted -eq $true}).count
Write-Progress -id 0 -activity "Running Inventory Jobs" "Completed: $i vCenters of $total" -PercentComplete (($i / $total) * 100)
Start-Sleep -seconds 2
Write-Progress -id 0 -activity "Running Inventory Jobs" -Completed

# Cleanup RunspacePool
foreach ($job in $jobs){
    $job.job.EndInvoke($job.result)
    $job.job.Dispose()
}
$RunspacePool.Close()

$endTime = Get-Date
$totaltime = ($endTime-$startTime) -f "HHmmss"
Write-Host "All VCenters Ran in $totaltime "

# Add Data from synchronized hash table to the export data report
write-host "Building Data Export file" -ForegroundColor Yellow
$exportdata = @()

foreach ($item in $data){
    foreach ($value in $item.values){
        $exportdata += $value
    } 
}

Write-host "Exporting Data to: $outpath"
$exportdata | sort name | export-csv -NoTypeInformation $outpath

Stop-Transcript | out-null

