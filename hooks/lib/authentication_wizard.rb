require 'kafo_wizards'

module AuthenticationWizard

  def self.setup_wizard(kafo)
    wizard = KafoWizards.wizard(:cli, 'Configure client authentication',
      :description => "Please set a default root password for newly provisioned machines. \n" \
          "If you choose not to set a password, it will be generated randomly. \n" \
          "The password must be a minimum of 8 characters. \n" \
          "You can also set a public ssh key which will be deployed to newly provisioned machines.")

    f = wizard.factory
    ssh_key_validator = lambda do |value|
      return value if value =~ /\Assh-.* .*( .*)?\Z/
      raise KafoWizards::ValidationError.new("the SSH key seems invalid, make sure the it starts with ssh- and it has no new line characters")
    end

    wizard.entries = [
      f.string_or_file(:ssh_public_key, :label => 'SSH public key',
        :description => 'You may either use a path to your public key file or enter the whole key (including type and comment)',
        :validators => [ssh_key_validator]),
      f.password(:root_password, :label => 'Root password', :default_value => 'redhat', :confirmation_required => true),
      f.boolean(:show_password, :label => 'Show password', :default_value => true),
      f.button(:ok, :label => 'Proceed with the above values', :default => true),
      f.button(:cancel, :label => 'Cancel Installation', :default => false)
    ]

    # set defaults given on CLI
    attrs = wizard.values.keys
    cli_defaults = attrs.inject({}) do |defaults, a|
      par = kafo.param('foreman_plugin_staypuft', a.to_s)
      if par.is_a?(Kafo::Params::Password) # for password we need decrypted but hidden value
        par.value = par.default if par.value.nil?
        par.send(:decrypt) if par.send(:encrypted?)
      end
      defaults[a] = par.value unless par.value.is_nil?
      defaults
    end
    wizard.update(cli_defaults)
  end

end
