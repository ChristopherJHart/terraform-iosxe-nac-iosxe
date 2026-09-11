locals {
  interfaces_vrrp_ipv6 = flatten([
    for device in local.devices : concat(
      [
        for int in try(local.device_config[device.name].interfaces.ethernets, []) : [
          for vrrp in try(int.vrrp_ipv6_groups, []) : {
            key                   = format("%s/%s%s/vrrp-ipv6/%s", device.name, try(int.type, "GigabitEthernet"), trimprefix(int.id, "$string "), vrrp.group_id)
            device                = device.name
            type                  = try(int.type, "GigabitEthernet")
            name                  = trimprefix(int.id, "$string ")
            managed               = try(int.managed, true)
            group_id              = vrrp.group_id
            ipv6_link_local       = try(vrrp.ipv6_link_local, null)
            ipv6_prefixes         = try(length(vrrp.ipv6_prefixes) == 0, true) ? null : [for prefix in vrrp.ipv6_prefixes : { prefix = prefix }]
            priority              = try(vrrp.priority, null)
            preempt_delay_minimum = try(vrrp.preempt_delay_minimum, null)
            timers_advertise      = try(vrrp.timers_advertise, null)
            description           = try(vrrp.description, null)
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
          for vrrp in try(int.vrrp_ipv6_groups, []) : {
            key                   = format("%s/Vlan%s/vrrp-ipv6/%s", device.name, int.id, vrrp.group_id)
            device                = device.name
            type                  = "Vlan"
            name                  = tostring(int.id)
            managed               = true
            group_id              = vrrp.group_id
            ipv6_link_local       = try(vrrp.ipv6_link_local, null)
            ipv6_prefixes         = try(length(vrrp.ipv6_prefixes) == 0, true) ? null : [for prefix in vrrp.ipv6_prefixes : { prefix = prefix }]
            priority              = try(vrrp.priority, null)
            preempt_delay_minimum = try(vrrp.preempt_delay_minimum, null)
            timers_advertise      = try(vrrp.timers_advertise, null)
            description           = try(vrrp.description, null)
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
          for vrrp in try(int.vrrp_ipv6_groups, []) : {
            key                   = format("%s/Port-channel%s/vrrp-ipv6/%s", device.name, trimprefix(tostring(int.id), "$string "), vrrp.group_id)
            device                = device.name
            type                  = "Port-channel"
            name                  = trimprefix(tostring(int.id), "$string ")
            managed               = true
            group_id              = vrrp.group_id
            ipv6_link_local       = try(vrrp.ipv6_link_local, null)
            ipv6_prefixes         = try(length(vrrp.ipv6_prefixes) == 0, true) ? null : [for prefix in vrrp.ipv6_prefixes : { prefix = prefix }]
            priority              = try(vrrp.priority, null)
            preempt_delay_minimum = try(vrrp.preempt_delay_minimum, null)
            timers_advertise      = try(vrrp.timers_advertise, null)
            description           = try(vrrp.description, null)
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
            for vrrp in try(sub.vrrp_ipv6_groups, []) : {
              key                   = format("%s/Port-channel%s/vrrp-ipv6/%s", device.name, trimprefix(sub.id, "$string "), vrrp.group_id)
              device                = device.name
              type                  = "Port-channel-subinterface/Port-channel"
              name                  = trimprefix(sub.id, "$string ")
              managed               = true
              group_id              = vrrp.group_id
              ipv6_link_local       = try(vrrp.ipv6_link_local, null)
              ipv6_prefixes         = try(length(vrrp.ipv6_prefixes) == 0, true) ? null : [for prefix in vrrp.ipv6_prefixes : { prefix = prefix }]
              priority              = try(vrrp.priority, null)
              preempt_delay_minimum = try(vrrp.preempt_delay_minimum, null)
              timers_advertise      = try(vrrp.timers_advertise, null)
              description           = try(vrrp.description, null)
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

resource "iosxe_vrrp_ipv6" "vrrp_ipv6" {
  for_each = { for v in local.interfaces_vrrp_ipv6 : v.key => v if v.managed }

  device                = each.value.device
  type                  = each.value.type
  name                  = each.value.name
  group_id              = each.value.group_id
  ipv6_link_local       = each.value.ipv6_link_local
  ipv6_prefixes         = each.value.ipv6_prefixes
  priority              = each.value.priority
  preempt_delay_minimum = each.value.preempt_delay_minimum
  timers_advertise      = each.value.timers_advertise
  description           = each.value.description
  tracks                = each.value.tracks
  shutdown              = each.value.shutdown

  depends_on = [
    iosxe_fhrp.fhrp,
    iosxe_interface_ethernet.ethernet,
    iosxe_interface_ethernet.ethernet_sub,
    iosxe_interface_vlan.vlan,
    iosxe_interface_port_channel.port_channel,
    iosxe_interface_port_channel_subinterface.port_channel_subinterface
  ]
}

resource "iosxe_vrrp_ipv6" "vrrp_ipv6_unmanaged" {
  for_each = { for v in local.interfaces_vrrp_ipv6 : v.key => v if !v.managed }

  device                = each.value.device
  type                  = each.value.type
  name                  = each.value.name
  group_id              = each.value.group_id
  ipv6_link_local       = each.value.ipv6_link_local
  ipv6_prefixes         = each.value.ipv6_prefixes
  priority              = each.value.priority
  preempt_delay_minimum = each.value.preempt_delay_minimum
  timers_advertise      = each.value.timers_advertise
  description           = each.value.description
  tracks                = each.value.tracks
  shutdown              = each.value.shutdown

  depends_on = [
    iosxe_fhrp.fhrp,
    iosxe_interface_ethernet.ethernet_unmanaged
  ]

  lifecycle {
    ignore_changes = all
  }
}
