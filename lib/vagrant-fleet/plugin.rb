require "vagrant"

module VagrantPlugins
  module FleetProvisioner
    class Plugin < Vagrant.plugin("2")
      name "vagrant-fleet"
      description <<-DESC
        A vagrant CoreOS Fleet provisioner plugin
      DESC

      config(:fleet, :provisioner) do
        require_relative "config"
        Config
      end

      provisioner "fleet" do
        setup_i18n

        require_relative "provisioner"
        Provisioner
      end

      def self.setup_i18n
        I18n.load_path << File.expand_path("locales/en.yml", FleetProvisioner.source_root)
        I18n.reload!
      end
    end
  end
end
