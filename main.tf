terraform {
  backend "remote" {
    hostname = "app.terraform.io"
    organization = "mel-ciscolabs-com"
    workspaces {
      name = "ndfc-demo-1"
    }
  }
  required_providers {
    dcnm = {
      source = "CiscoDevNet/dcnm"
      # version = "0.0.5"
    }
  }
}

## If using DCNM to assign VNIs use -parallelism=1

provider "dcnm" {
  username = var.dcnm_user
  password = var.dcnm_password
  url      = var.dcnm_url
  insecure = true
  platform = "nd"
}

## Read Switch Inventory ##
data "dcnm_inventory" "switches" {
  for_each = var.switches

  fabric_name = each.value.fabric
  switch_name = each.value.name
}

## Build Local Dictionaries
# - serial_numbers: Switch Name -> Serial Number

locals {
  serial_numbers = {
      for switch in data.dcnm_inventory.switches :
          switch.switch_name => switch.serial_number
  }
}

output "serial_numbers" {
  value = local.serial_numbers
}

## Build New VRFs ###
resource "dcnm_vrf" "vrfs" {
  for_each = var.vrfs

  fabric_name             = var.dcnm_fabric
  name                    = each.value.name
  vlan_id                 = each.value.vlan_id
  segment_id              = each.value.vni_id
  vlan_name               = each.value.name
  description             = each.value.description
  intf_description        = each.value.name
  // tag                     = "12345"
  max_bgp_path            = 2
  max_ibgp_path           = 2
  // trm_enable              = false
  // rp_external_flag        = true
  // rp_address              = "1.2.3.4"
  // loopback_id             = 15
  // mutlicast_address       = "10.0.0.2"
  // mutlicast_group         = "224.0.0.1/4"
  // ipv6_link_local_flag    = "true"
  // trm_bgw_msite_flag      = true
  advertise_host_route    = true
  // advertise_default_route = true
  // static_default_route    = false
  deploy                  = each.value.deploy

  dynamic "attachments" {
    for_each = toset(each.value.attached_switches)
    content {
      serial_number = lookup(local.serial_numbers, attachments.key)
      vlan_id = each.value.vlan_id
      attach = true
      // loopback_id   = 70
      // loopback_ipv4 = "1.2.3.4"
    }
  }
}


## Build New VPC Interfaces ##
resource "dcnm_interface" "vpc" {
  for_each = var.vpc_interfaces

  policy                  = "int_vpc_trunk_host_11_1"
  type                    = "vpc"
  name                    = each.value.name
  fabric_name             = var.dcnm_fabric
  switch_name_1           = each.value.switch1.name
  switch_name_2           = each.value.switch2.name
  vpc_peer1_id            = each.value.vpc_id
  vpc_peer2_id            = each.value.vpc_id
  mode                    = "active"
  bpdu_guard_flag         = "true"
  mtu                     = "default"
  vpc_peer1_allowed_vlans = "none"
  vpc_peer2_allowed_vlans = "none"
  // vpc_peer1_access_vlans  = "10"
  // vpc_peer2_access_vlans  = "20"
  vpc_peer1_interface     = each.value.switch1.ports
  vpc_peer2_interface     = each.value.switch1.ports
}


## Build New L3 Networks ##

resource "dcnm_network" "networks" {
  for_each = var.networks

  fabric_name     = var.dcnm_fabric
  name            = each.value.name
  network_id      = each.value.vni_id
  display_name    = each.value.name
  description     = each.value.description
  vrf_name        = each.value.vrf_name
  vlan_id         = each.value.vlan_id
  vlan_name       = each.value.name
  ipv4_gateway    = each.value.ip_subnet
  # ipv6_gateway    = "2001:db8::1/64"
  # mtu             = 1500
  # secondary_gw_1  = "192.0.3.1/24"
  # secondary_gw_2  = "192.0.3.1/24"
  # arp_supp_flag   = true
  ir_enable_flag  = true #???
  # mcast_group     = "239.1.2.2"
  # dhcp_1          = "1.2.3.4"
  # dhcp_2          = "1.2.3.5"
  # dhcp_vrf        = "VRF1012"
  # loopback_id     = 100
  tag             = 12345
  # rt_both_flag    = true
  # trm_enable_flag = true
  l3_gateway_flag = true
  # template        = "MODIFIED_Network_Universal"
  deploy          = each.value.deploy

  dynamic "attachments" {
    # for_each = each.value.attachments
    // for_each = toset(each.value.attached_switches)
    for_each = each.value.attached_switches
    content {
      serial_number = lookup(local.serial_numbers, attachments.key)
      vlan_id       = each.value.vlan_id
      attach        = true
      switch_ports  = attachments.value["switch_ports"]
    }
  }

  depends_on = [dcnm_vrf.vrfs, dcnm_interface.vpc]
}
