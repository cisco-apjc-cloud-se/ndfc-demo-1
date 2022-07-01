dcnm_fabric = "MSD_Fabric_DCI"

### FABRIC INVENTORY ###
switches = {
  s2-bgw1 = {
    name    = "S2-BGW1"
    fabric  = "Geelong"
  }
  s2-bgw2 = {
    name    = "S2-BGW2"
    fabric  = "Geelong"
  }
  s1-bgw1 = {
    name    = "S1-BGW1"
    fabric  = "Richmond"
  }
  s1-bgw2 = {
    name    = "S1-BGW2"
    fabric  = "Richmond"
  }
  spine = {
    name    = "SPINE"
    fabric  = "Richmond"
  }
}

### VRFS ###
vrfs = {
  TFCB-VRF-1 = {
    name = "TFCB-VRF-1"
    description = "VRF-1 Created by Terraform Plan"
    vni_id = 33001
    vlan_id = 3001
    deploy = true
    attached_switches = [
      "S1-BGW1",
      "S1-BGW2",
      "S2-BGW1",
      "S2-BGW2"
    ]
  }
  # TFCB-VRF-2 = {
  #   name = "TFCB-VRF-2"
  #   description = "VRF Created by Terraform Plan #2"
  #   vni_id = 33002
  #   vlan_id = 3002
  #   deploy = true
  #   attached_switches = [
  #     "DC3-LEAF-1",
  #     "DC3-LEAF-2",
  #     "DC3-BORDER-1",
  #     "DC3-BORDER-2"
  #   ]
  # },
  # TFCB-VRF-3 = {
  #   name = "TFCB-VRF-3"
  #   description = "VRF Created by Terraform Plan #3"
  #   vni_id = 33003
  #   vlan_id = 3003
  #   deploy = false
  #   attached_switches = []
  # }
}

### INTERFACES ###
vpc_interfaces = {
  s1-vpc10 = {
    name = "vPC10"
    vpc_id = 10
    switch1 = {
      name = "S1-BGW1"
      ports = ["Eth1/10"]
      }
    switch2 = {
      name = "S1-BGW12"
      ports = ["Eth1/10"]
      }
  }
  s2-vpc10 = {
    name = "vPC10"
    vpc_id = 10
    switch1 = {
      name = "S2-BGW1"
      ports = ["Eth1/10"]
      }
    switch2 = {
      name = "S2-BGW12"
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
      S1-BGW1 = {
        name = "S1-BGW1"
        switch_ports = [
          "Port-channel10"
        ]
      }
      S1-BGW2 = {
        name = "S1-BGW2"
        switch_ports = [
          "Port-channel10"
        ]
      }
      S2-BGW1 = {
        name = "S2-BGW1"
        switch_ports = [
          "Port-channel10"
        ]
      }
      S2-BGW2 = {
        name = "S2-BGW2"
        switch_ports = [
          "Port-channel10"
        ]
      }
    }
  }
  # TFCB-NET-2 = {
  #   name = "TFCB-NET-2"
  #   description = "Terraform Intersight Demo Network #2"
  #   vrf_name = "TFCB-VRF-1"
  #   ip_subnet = "192.168.102.1/24"
  #   vni_id = 33102
  #   vlan_id = 3102
  #   deploy = true
  #   attached_switches = {
  #     DC3-LEAF-1 = {
  #       name = "DC3-LEAF-1"
  #       switch_ports = [
  #         "Port-channel10"
  #       ]
  #     }
  #     DC3-LEAF-2 = {
  #       name = "DC3-LEAF-2"
  #       switch_ports = [
  #         "Port-channel10"
  #       ]
  #     }
  #   }
  # }
  # TFCB-NET-3 = {
  #   name = "TFCB-NET-3"
  #   description = "Terraform Intersight Demo Network #3"
  #   vrf_name = "TFCB-VRF-1"
  #   ip_subnet = "192.168.103.1/24"
  #   vni_id = 33103
  #   vlan_id = 3103
  #   deploy = true
  #   attached_switches = {
  #     DC3-LEAF-1 = {
  #       name = "DC3-LEAF-1"
  #       switch_ports = [
  #         "Port-channel10"
  #       ]
  #     }
  #     DC3-LEAF-2 = {
  #       name = "DC3-LEAF-2"
  #       switch_ports = [
  #         "Port-channel10"
  #       ]
  #     }
  #   }
  # }
}
