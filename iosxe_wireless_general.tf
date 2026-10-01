resource "iosxe_wireless_management_interface" "wireless_management_interface" {
  for_each = { for device in local.devices : device.name => device if try(local.device_config[device.name].wireless.management_interface_type, local.defaults.iosxe.configuration.wireless.management_interface_type, null) != null }
  device   = each.value.name

  interface_name = format("%s%s",
    try(local.device_config[each.value.name].wireless.management_interface_type, local.defaults.iosxe.configuration.wireless.management_interface_type),
    try(local.device_config[each.value.name].wireless.management_interface_id, local.defaults.iosxe.configuration.wireless.management_interface_id)
  )

  depends_on = [iosxe_interface_vlan.vlan]
}
