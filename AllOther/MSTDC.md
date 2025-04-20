Create 2 VMs in 1 subnet
Add an Elastic SAN with a Volume Group and then Volumes for Data, Log, MSDTC, witness

Go into each VM and do the following
* Start | Run | dcomcnfg | Enter
* Expand My Computer
* Right click on Local DTC and choose Properties
* Click on the configure tab
*   Click allow Network access
*   Click allow inbound and outbound
*   Click allow remote connections
*   Click Enable XA transactions
*   Click OK

Open Administrative Tools
Open ISCSI
It will ask if you want ISCSI to start up automatically, Choose Yes
Close ISCSI

Add role MultiPath-IO and FailoverClustering to the VMs
Restart the VMs

There is a link on the <a href='https://learn.microsoft.com/en-us/azure/storage/elastic-san/elastic-san-connect-windows'>Connect to ESAN</a> doc page 

The link to <a href='https://github.com/Azure-Samples/azure-elastic-san/blob/main/PSH%20(Windows)%20Multi-Session%20Connect%20Scripts/ElasticSanDocScripts0523/connect.ps1'>Connect.ps1</a>

Install the following PowerShell modules
AZ.Account
AZ.ElasticSAN

Create an Empty role in the Cluster
Name it appropriately, something like MSDTC01
Add client access point and add the name and IP (must be in the subnet)
Add a volume that was created on the ElasticSAN to that Role

Create an internal load balancer
Probe Port 59999
add that port to the NSG inbound related to the VMs that are in the Availability Group
Add the 2 VMs to the backend
Frontend should be the IP address used in the MSDTC role Client Access Point

Go into each VM and run dcomcnfg
Expand My Computer
Expand MSDTC
Right click on the local MSDTC and choose Properties
Configure Netowk Access
Allow inbound and outbound
No Authentication needed
Enable XA Transactions
