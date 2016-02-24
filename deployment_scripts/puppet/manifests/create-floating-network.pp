$plugin_name            = "fuel-plugin-ext-net-vlan"
notice("MODULAR: ${plugin_name}/create-floating-network.pp")

$plugin_metadata = hiera($plugin_name, false)

if $plugin_metadata {
    $access_hash             = hiera('access', {})
    $keystone_admin_tenant   = $access_hash['tenant']
    $primary_controller_role = 'primary-controller'
    $roles                   = hiera('roles')
    $neutron_settings        = hiera_hash('quantum_settings')
    $alloc_net1              = split($neutron_settings['predefined_networks']['net04_ext']['L3']['floating'], ':')
    $allocation_pools_net1   = "start=${alloc_net1[0]},end=${alloc_net1[1]}"
    $alloc_net2              = split($plugin_metadata['floating_range_net2'], ':')
    $allocation_pools_net2   = "start=${alloc_net2[0]},end=${alloc_net2[1]}"
    if $primary_controller_role in $roles {
      neutron_network { 'net04_ext':
        ensure                    => present,
        provider_physical_network => 'provider',
        provider_network_type     => 'vlan',
        provider_segmentation_id  => $plugin_metadata['segment_id_net1'],
        router_external           => true,
        tenant_name               => $keystone_admin_tenant,
        shared                    => true,
      } ->
      neutron_network { 'net05_ext':
        ensure                    => present,
        provider_physical_network => 'provider',
        provider_network_type     => 'vlan',
        provider_segmentation_id  => $plugin_metadata['segment_id_net2'],
        router_external           => true,
        tenant_name               => $keystone_admin_tenant,
        shared                    => true,
      } ->
      neutron_subnet { "net04_ext__subnet":
        ensure          => present,
        cidr            => $neutron_settings['predefined_networks']['net04_ext']['L3']['subnet'],
        network_name    => 'net04_ext',
        tenant_name     => $keystone_admin_tenant,
        gateway_ip      => $neutron_settings['predefined_networks']['net04_ext']['L3']['gateway'],
        enable_dhcp     => false,
        dns_nameservers => [],
        allocation_pools=> $allocation_pools_net1,
      } ->
      neutron_subnet { "net05_ext__subnet":
        ensure          => present,
        cidr            => $plugin_metadata['floating_subnet_net2'],
        network_name    => 'net05_ext',
        tenant_name     => $keystone_admin_tenant,
        gateway_ip      => $plugin_metadata['floating_gateway_net2'],
        enable_dhcp     => false,
        dns_nameservers => [],
        allocation_pools=> $allocation_pools_net2,
      } ->
      neutron_router { 'router04':
        ensure               => present,
        tenant_name          => $keystone_admin_tenant,
        gateway_network_name => 'net04_ext',
      } ->
      neutron_router_interface { "router04:net04__subnet":
        ensure => present,
      } ->
      neutron_router_interface { "router04:net05_ext__subnet":
        ensure => present,
      }
    }
}
