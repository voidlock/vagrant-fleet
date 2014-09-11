require_relative "local_client"

module VagrantPlugins
  module FleetProvisioner
    class Provisioner < Vagrant.plugin(2, :provisioner)
      def initialize(machine, config, client = nil)
        super(machine, config)

        @client = client || LocalClient.new(@machine)
      end

      def configure(root_config)
      end

      def provision
        @client.submit_units(@config.submit_units)
        @client.start_units(@config.units)
      end
    end
  end
end
