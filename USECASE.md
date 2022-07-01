# Intersight Service for Terraform Demo with Nexus Dashboard Fabric Controller (a.k.a DCNM)- Common Overlay Configuration

## Overview
This use focuses on the basic overlay configuration for common Day 2 DC networking tasks.

This use case includes configuring:
- VRFs
- Networks
- vPC Interfaces

## Requirements
The Infrastructure-as-Code environment will require the following:
* GitHub Repository for Terraform plans, modules and variables as HCL or JSON files
* Terraform Cloud for Business account with a workspace associated to the GitHub repository above
* Cisco Intersight (SaaS) platform account with sufficient Advantage licensing
* An Intersight Assist appliance VM connected to the Intersight account above
* A Cisco Nexus Dashboard Fabric Controller (NDFC), formerly known as Data Center Network Manager (DCNM) instance and existng DC fabric to automate.

## Assumptions
Thise use case makes the following assumptions:
* An existing Nexus 9000 switch based VXLAN fabric has already been deployed and that it is actively managed through a DCNM instance.
* The DCNM server is accessible by HTTPS from the Intersight Assist VM.
* Suitable IP subnets (at least /29) are available to be assigned to each new L3 network.
* Suitable VLAN IDs are available to be assigned to each new L3 network.
* The following variables are defined within the Terraform Workspace.  These variables should not be configured within the public GitHub repository files.
  * DCNM account username (dcnm_user)
  * DCNM account password (dcnm_password)
  *	DCNM URL (dcnm_url)

## Link to Github Repositories
https://github.com/cisco-apjc-cloud-se/ist-dcnm-workspace

## Steps to Deploy Use Case
1.	In GitHub, create a new, or clone the example GitHub repository(s)
2.	Customize the examples Terraform files & input variables as required
3.	In Intersight, configure a Terraform Cloud target with suitable user account and token
4.	In Intersight, configure a Terraform Agent target with suitable managed host URLs/IPs.  This list of managed hosts must include the IP addresses for the DCNM server as well as access to common GitHub domains in order to download hosted Terraform providers.  This will create a Terraform Cloud Agent pool and register this to Terraform Cloud.
5.	In Terraform Cloud for Business, create a new Terraform Workspace and associate to the GitHub repository.
6.	In Terraform Cloud for Business, configure the workspace to the use the Terraform Agent pool configured from Intersight.
7.	In Terraform Cloud for Business, configure the necessary user account variables for the DCNM servers.

## Workarounds ##

*October 2021*
In this example, both VLAN IDs and VXLAN IDs have been explicity set.  These are optional parameters and can be removed and left to DCNM to inject these dynamically from the fabrics' resource pools.  However if you chose to use DCNM to do this, Terraform MUST be configured to use a "parallelism" value of 1.  This ensures Terraform will only attempt to configure one resource at a time allowing DCNM to allocate IDs from the pool sequentially.  

Typically the parallelism would be set in the Terraform cloud workspace environment variables section using the variable name "TFE_PARALLELISM" and value of "1", however this variable is NOT used by Terraform Cloud Agents.  Instead the variables "TF_CLI_ARGS_plan" and "TF_CLI_ARGS_apply" must be used with a value of "-parallelism=1"


*October 2021* Due to an issue with the Terraform Provider (version 1.0.0) and DCNM API (11.5(3)) the "dcnm_network" resource will not deploy Layer 3 SVIs.   This does NOT apply to NDFC 12.x deployments. This is due to a defaul parameter not being correctly set in the API call.  Instead, the Network will be deployed as if the template has the "Layer 2 Only" checkbox set.

There are two workarouds for this
1. After deploying the network(s), edit the network from the DCNM GUI then immediately save.  This will set the correct default parameters and these networks can be re-deployed.
2. Instead of the using the "Default_Network_Universal" template, clone and modify it as below.  Make sure to set the correct template name in the terraform plan under the dcnm_network resource.   Please note that the tag value of 12345 must also be explicity set.

    Original Lines #119-#123
    ```
    if ($$isLayer2Only$$ != "true") {
      interface Vlan$$vlanId$$
       if ($$intfDescription$$ != "") {
        description $$intfDescription$$
       }
    ```
    Modified Lines #119-#125
    ```
    if ($$isLayer2Only$$ == "true"){
     }
    else {
    interface Vlan$$vlanId$$
     if ($$intfDescription$$ != "") {
      description $$intfDescription$$
     }
    ```

## Example Input Variables ###
```hcl
dcnm_fabric = "DC3"

### FABRIC INVENTORY ###
switches = {
  dc3-leaf-1 = {
    name    = "DC3-LEAF-1"
    fabric  = "DC3"
  }
  dc3-leaf-2 = {
    name    = "DC3-LEAF-2"
    fabric  = "DC3"
  }
  dc3-border-1 = {
    name    = "DC3-BORDER-1"
    fabric  = "DC3"
  }
  dc3-border-2 = {
    name    = "DC3-BORDER-2"
    fabric  = "DC3"
  }
}

### VRFS ###
vrfs = {
  TFCB-VRF-1 = {
    name = "TFCB-VRF-1"
    description = "VRF Created by Terraform Plan #1"
    vni_id = 33001
    vlan_id = 3001
    deploy = true
    attached_switches = [
      "DC3-LEAF-1",
      "DC3-LEAF-2",
      "DC3-BORDER-1",
      "DC3-BORDER-2"
    ]
  }
  TFCB-VRF-2 = {
    name = "TFCB-VRF-2"
    description = "VRF Created by Terraform Plan #2"
    vni_id = 33002
    vlan_id = 3002
    deploy = true
    attached_switches = [
      "DC3-LEAF-1",
      "DC3-LEAF-2",
      "DC3-BORDER-1",
      "DC3-BORDER-2"
    ]
  },
  TFCB-VRF-3 = {
    name = "TFCB-VRF-3"
    description = "VRF Created by Terraform Plan #3"
    vni_id = 33003
    vlan_id = 3003
    deploy = false
    attached_switches = []
  }
}

### INTERFACES ###
vpc_interfaces = {
  vpc10 = {
    name = "vPC10"
    vpc_id = 10
    switch1 = {
      name = "DC3-LEAF-1"
      ports = ["Eth1/10"]
      }
    switch2 = {
      name = "DC3-LEAF-2"
      ports = ["Eth1/10"]
      }
  }
}

### NETWORKS ###
networks = {
  TFCB-NET-1 = {
    name = "TFCB-NET-1"
    description = "Terraform Intersight Demo Network #1"
    vrf_name = "TFCB-VRF-1"
    ip_subnet = "192.168.101.1/24"
    vni_id = 33101
    vlan_id = 3101
    deploy = true
    attached_switches = {
      DC3-LEAF-1 = {
        name = "DC3-LEAF-1"
        switch_ports = [
          "Port-channel10"
        ]
      }
      DC3-LEAF-2 = {
        name = "DC3-LEAF-2"
        switch_ports = [
          "Port-channel10"
        ]
      }
    }
  }
  TFCB-NET-2 = {
    name = "TFCB-NET-2"
    description = "Terraform Intersight Demo Network #2"
    vrf_name = "TFCB-VRF-1"
    ip_subnet = "192.168.102.1/24"
    vni_id = 33102
    vlan_id = 3102
    deploy = true
    attached_switches = {
      DC3-LEAF-1 = {
        name = "DC3-LEAF-1"
        switch_ports = [
          "Port-channel10"
        ]
      }
      DC3-LEAF-2 = {
        name = "DC3-LEAF-2"
        switch_ports = [
          "Port-channel10"
        ]
      }
    }
  }
  TFCB-NET-3 = {
    name = "TFCB-NET-3"
    description = "Terraform Intersight Demo Network #3"
    vrf_name = "TFCB-VRF-1"
    ip_subnet = "192.168.103.1/24"
    vni_id = 33103
    vlan_id = 3103
    deploy = true
    attached_switches = {
      DC3-LEAF-1 = {
        name = "DC3-LEAF-1"
        switch_ports = [
          "Port-channel10"
        ]
      }
      DC3-LEAF-2 = {
        name = "DC3-LEAF-2"
        switch_ports = [
          "Port-channel10"
        ]
      }
    }
  }
}
```

## Execute Deployment
In Terraform Cloud for Business, queue a new plan to trigger the initial deployment.  Any future changes to pushed to the GitHub repository will automatically trigger a new plan deployment.

## Results
If successfully executed, the Terraform plan will result in the following configuration:

* New VRF(s) each with the following configuration:
  * Name
  * VXLAN VNI ID
  * VLAN ID (for Symmetric IRB)
* New Layer 3 VXLAN network(s) each with the following configuration:
  * Name
  * Anycast Gateway IPv4 Address/Mask
  * VXLAN VNI ID
  * VLAN ID
* New vPC interfaces(s) each with the following configuration:
  * vPC ID
  * Member Switches & Ports


## Expected Day 2 Changes
Changes to the variables defined in the input variable files will result in dynamic, stateful update to DCNM. For example,

* Adding a new VRF entry will create a new DCNM VRF template instance and deploy this VRF to the associated switches.
* Adding a new vPC interface will create a new vPC interface template instace and local port-channel logical interfaces to each switch.
* Adding a Network entry will create a new DCNM Network template instance and deploy this network to the associated switches, as well as trunk to the associated switch interfaces.

## Related Sandbox
[Open NXOS Sandbox](https://devnetsandbox.cisco.com/RM/Diagram/Index/0e22761d-f813-415d-a557-24fa0e17ab50?diagramType=Topology)
