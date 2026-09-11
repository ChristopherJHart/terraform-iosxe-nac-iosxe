locals {
  interfaces_vrrp = flatten([
    for device in local.devices : concat(
      [
        for int in try(local.device_config[device.name].interfaces.ethernets, []) : [
          for vrrp in try(int.vrrp_groups, []) : {
            key                     = format("%s/%s%s/vrrp/%s", device.name, try(int.type, "GigabitEthernet"), trimprefix(int.id, "$string "), vrrp.group_id)
            device                  = device.name
            type                    = try(int.type, "GigabitEthernet")
            name                    = trimprefix(int.id, "$string ")
            managed                 = try(int.managed, true)
            group_id                = vrrp.group_id
            address_primary_address = try(vrrp.address_primary_address, null)
            secondary_addresses     = try(length(vrrp.secondary_addresses) == 0, true) ? null : [for addr in vrrp.secondary_addresses : { address = addr }]
            priority                = try(vrrp.priority, null)
            preempt_delay_minimum   = try(vrrp.preempt_delay_minimum, null)
            timers_advertise        = try(vrrp.timers_advertise, null)
            description             = try(vrrp.description, null)
            tracks = try(length(vrrp.tracks) == 0, true) ? null : [for track in vrrp.tracks : {
              object_id = track.object_id
              decrement = try(track.decrement, null)
              shutdown  = try(track.shutdown, null)
            }]
            shutdown = try(vrrp.shutdown, null)
          }
        ]
      ],
      [
        for int in try(local.device_config[device.name].interfaces.vlans, []) : [
          for vrrp in try(int.vrrp_groups, []) : {
            key                     = format("%s/Vlan%s/vrrp/%s", device.name, int.id, vrrp.group_id)
            device                  = device.name
            type                    = "Vlan"
            name                    = tostring(int.id)
            managed                 = true
            group_id                = vrrp.group_id
            address_primary_address = try(vrrp.address_primary_address, null)
            secondary_addresses     = try(length(vrrp.secondary_addresses) == 0, true) ? null : [for addr in vrrp.secondary_addresses : { address = addr }]
            priority                = try(vrrp.priority, null)
            preempt_delay_minimum   = try(vrrp.preempt_delay_minimum, null)
            timers_advertise        = try(vrrp.timers_advertise, null)
            description             = try(vrrp.description, null)
            tracks = try(length(vrrp.tracks) == 0, true) ? null : [for track in vrrp.tracks : {
              object_id = track.object_id
              decrement = try(track.decrement, null)
              shutdown  = try(track.shutdown, null)
            }]
            shutdown = try(vrrp.shutdown, null)
          }
        ]
      ],
      [
        for int in try(local.device_config[device.name].interfaces.port_channels, []) : [
          for vrrp in try(int.vrrp_groups, []) : {
            key                     = format("%s/Port-channel%s/vrrp/%s", device.name, trimprefix(tostring(int.id), "$string "), vrrp.group_id)
            device                  = device.name
            type                    = "Port-channel"
            name                    = trimprefix(tostring(int.id), "$string ")
            managed                 = true
            group_id                = vrrp.group_id
            address_primary_address = try(vrrp.address_primary_address, null)
            secondary_addresses     = try(length(vrrp.secondary_addresses) == 0, true) ? null : [for addr in vrrp.secondary_addresses : { address = addr }]
            priority                = try(vrrp.priority, null)
            preempt_delay_minimum   = try(vrrp.preempt_delay_minimum, null)
            timers_advertise        = try(vrrp.timers_advertise, null)
            description             = try(vrrp.description, null)
            tracks = try(length(vrrp.tracks) == 0, true) ? null : [for track in vrrp.tracks : {
              object_id = track.object_id
              decrement = try(track.decrement, null)
              shutdown  = try(track.shutdown, null)
            }]
            shutdown = try(vrrp.shutdown, null)
          }
        ]
      ],
      [
        for int in try(local.device_config[device.name].interfaces.port_channels, []) : [
          for sub in try(int.subinterfaces, []) : [
            for vrrp in try(sub.vrrp_groups, []) : {
              key                     = format("%s/Port-channel%s/vrrp/%s", device.name, trimprefix(sub.id, "$string "), vrrp.group_id)
              device                  = device.name
              type                    = "Port-channel-subinterface/Port-channel"
              name                    = trimprefix(sub.id, "$string ")
              managed                 = true
              group_id                = vrrp.group_id
              address_primary_address = try(vrrp.address_primary_address, null)
              secondary_addresses     = try(length(vrrp.secondary_addresses) == 0, true) ? null : [for addr in vrrp.secondary_addresses : { address = addr }]
              priority                = try(vrrp.priority, null)
              preempt_delay_minimum   = try(vrrp.preempt_delay_minimum, null)
              timers_advertise        = try(vrrp.timers_advertise, null)
              description             = try(vrrp.description, null)
              tracks = try(length(vrrp.tracks) == 0, true) ? null : [for track in vrrp.tracks : {
                object_id = track.object_id
                decrement = try(track.decrement, null)
                shutdown  = try(track.shutdown, null)
              }]
              shutdown = try(vrrp.shutdown, null)
            }
          ]
        ]
      ]
    )
  ])
}

resource "iosxe_vrrp" "vrrp" {
  for_each = { for v in local.interfaces_vrrp : v.key => v if v.managed }

  device                  = each.value.device
  type                    = each.value.type
  name                    = each.value.name
  group_id                = each.value.group_id
  address_primary_address = each.value.address_primary_address
  secondary_addresses     = each.value.secondary_addresses
  priority                = each.value.priority
  preempt_delay_minimum   = each.value.preempt_delay_minimum
  timers_advertise        = each.value.timers_advertise
  description             = each.value.description
  tracks                  = each.value.tracks
  shutdown                = each.value.shutdown

  depends_on = [
    iosxe_fhrp.fhrp,
    iosxe_interface_ethernet.ethernet,
    iosxe_interface_ethernet.ethernet_sub,
    iosxe_interface_vlan.vlan,
    iosxe_interface_port_channel.port_channel,
    iosxe_interface_port_channel_subinterface.port_channel_subinterface
  ]
}

resource "iosxe_vrrp" "vrrp_unmanaged" {
  for_each = { for v in local.interfaces_vrrp : v.key => v if !v.managed }

  device                  = each.value.device
  type                    = each.value.type
  name                    = each.value.name
  group_id                = each.value.group_id
  address_primary_address = each.value.address_primary_address
  secondary_addresses     = each.value.secondary_addresses
  priority                = each.value.priority
  preempt_delay_minimum   = each.value.preempt_delay_minimum
  timers_advertise        = each.value.timers_advertise
  description             = each.value.description
  tracks                  = each.value.tracks
  shutdown                = each.value.shutdown

  depends_on = [
    iosxe_fhrp.fhrp,
    iosxe_interface_ethernet.ethernet_unmanaged
  ]

  lifecycle {
    ignore_changes = all
  }
}
