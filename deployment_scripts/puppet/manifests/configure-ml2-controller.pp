$plugin_name            = "fuel-plugin-ext-net-vlan"
notice("MODULAR: ${plugin_name}/configure-ml2-controller.pp")

$plugin_metadata = hiera($plugin_name, false)

if $plugin_metadata {
  include neutron::params

#  file { '/etc/neutron/policy.json':
#    ensure => file,
#    owner => 'root',
#    group => 'neutron',
#    mode   => 0644,
#    content => template("${plugin_name}/policy.json.erb")
#  }

  neutron_plugin_ml2 {
    'ml2_type_vlan/network_vlan_ranges': value => 'provider:2:4094';
    'ovs/bridge_mappings':               value => 'provider:br-floating';
  }

  service { 'neutron-server':
    ensure  => running,
    enable  => true,
  } ->
  service { 'neutron-ovs-agent-service':
    name       => $::neutron::params::ovs_agent_service,
    enable     => true,
    ensure     => running,
    hasstatus  => true,
    hasrestart => false,
    provider   => 'pacemaker',
  }

###File['/etc/neutron/policy.json'] -> Neutron_plugin_ml2<||> ~> Service['neutron-server', 'neutron-ovs-agent-service']
  Neutron_plugin_ml2<||> ~> Service['neutron-server', 'neutron-ovs-agent-service']

}
