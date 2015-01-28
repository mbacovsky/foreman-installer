if app_value(:provisioning_wizard) != 'none'
  require File.join(KafoConfigure.root_dir, 'hooks', 'lib', 'authentication_wizard.rb')
  require File.join(KafoConfigure.root_dir, 'hooks', 'lib', 'provisioning_wizard.rb')

  provisioning_wizard = ProvisioningWizard.setup_wizard(kafo)
  provisioning_wizard_result = provisioning_wizard.run
  provisioning_wizard_values = provisioning_wizard.values

  authentication_wizard = AuthenticationWizard.setup_wizard(kafo)
  authentication_wizard_result = authentication_wizard.run
  authentication_wizard_values = authentication_wizard.values

  if provisioning_wizard_values[:configure_networking] || provisioning_wizard_values[:configure_firewall]
    command = PuppetCommand.new(%Q(class {"foreman::plugin::staypuft_network":
      interface            => "#{provisioning_wizard_values[:interface]}",
      ip                   => "#{provisioning_wizard_values[:ip]}",
      netmask              => "#{provisioning_wizard_values[:netmask]}",
      gateway              => "#{provisioning_wizard_values[:own_gateway]}",
      dns                  => "#{provisioning_wizard_values[:dns]}",
      configure_networking => #{provisioning_wizard_values[:configure_networking]},
      configure_firewall   => #{provisioning_wizard_values[:configure_firewall]},
    }))
    command.append '2>&1'
    command = command.command

    say 'Starting networking setup'
    logger.debug "running command to set networking"
    logger.debug `#{command}`

    if $?.success?
      say 'Networking setup has finished'
    else
      say "<%= color('Networking setup failed', :bad) %>"
      kafo.class.exit(101)
    end
  end

  param('foreman_proxy', 'tftp_servername').value = provisioning_wizard_values[:ip]
  param('foreman_proxy', 'dhcp_interface').value = provisioning_wizard_values[:interface]
  param('foreman_proxy', 'dhcp_gateway').value = provisioning_wizard_values[:gateway]
  param('foreman_proxy', 'dhcp_range').value = "#{provisioning_wizard_values[:from]} #{provisioning_wizard_values[:to]}"
  param('foreman_proxy', 'dhcp_nameservers').value = provisioning_wizard_values[:ip]
  param('foreman_proxy', 'dns_interface').value = provisioning_wizard_values[:interface]
  param('foreman_proxy', 'dns_zone').value = provisioning_wizard_values[:domain]
  param('foreman_proxy', 'dns_reverse').value = provisioning_wizard_values[:ip].split('.')[0..2].reverse.join('.') + '.in-addr.arpa'
  param('foreman_proxy', 'dns_forwarders').value = provisioning_wizard_values[:dns]
  param('foreman_proxy', 'foreman_base_url').value = provisioning_wizard_values[:base_url]

  param('foreman_plugin_staypuft', 'configure_networking').value = provisioning_wizard_values[:configure_networking]
  param('foreman_plugin_staypuft', 'configure_firewall').value = provisioning_wizard_values[:configure_firewall]
  param('foreman_plugin_staypuft', 'interface').value = provisioning_wizard_values[:interface]
  param('foreman_plugin_staypuft', 'ip').value = provisioning_wizard_values[:ip]
  param('foreman_plugin_staypuft', 'netmask').value = provisioning_wizard_values[:netmask]
  param('foreman_plugin_staypuft', 'own_gateway').value = provisioning_wizard_values[:own_gateway]
  param('foreman_plugin_staypuft', 'gateway').value = provisioning_wizard_values[:gateway]
  param('foreman_plugin_staypuft', 'dns').value = provisioning_wizard_values[:dns]
  param('foreman_plugin_staypuft', 'network').value = provisioning_wizard_values[:network]
  param('foreman_plugin_staypuft', 'from').value = provisioning_wizard_values[:from]
  param('foreman_plugin_staypuft', 'to').value = provisioning_wizard_values[:to]
  param('foreman_plugin_staypuft', 'domain').value = provisioning_wizard_values[:domain]
  param('foreman_plugin_staypuft', 'base_url').value = provisioning_wizard_values[:base_url]
  param('foreman_plugin_staypuft', 'ntp_host').value = provisioning_wizard_values[:ntp_host]
  param('foreman_plugin_staypuft', 'timezone').value = provisioning_wizard_values[:timezone]
  param('foreman_plugin_staypuft', 'root_password').value = authentication_wizard_values[:root_password]
  param('foreman_plugin_staypuft', 'ssh_public_key').value = authentication_wizard_values[:ssh_public_key]

  # some enforced values for foreman-installer
  param('foreman_proxy', 'tftp').value = true
  param('foreman_proxy', 'dhcp').value = true
  param('foreman_proxy', 'dns').value = true
  param('foreman_proxy', 'repo').value = 'nightly'
  param('foreman', 'repo').value = 'nightly'

  param('puppet', 'server').value = true
end
