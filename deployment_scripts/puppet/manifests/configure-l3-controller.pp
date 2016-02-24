$plugin_name            = "fuel-plugin-ext-net-vlan"
notice("MODULAR: ${plugin_name}/configure-l3-controller.pp")

$plugin_metadata = hiera($plugin_name, false)

if $plugin_metadata {
    neutron_l3_agent_config {
      'DEFAULT/external_network_bridge': value => ''
    }

    include neutron::params
    service { 'neutron-l3':
      name       => $::neutron::params::l3_agent_service,
      enable     => true,
      ensure     => running,
      hasstatus  => true,
      hasrestart => false,
      provider   => 'pacemaker',
    }

    Neutron_l3_agent_config<||> ~> Service['neutron-l3']
}
