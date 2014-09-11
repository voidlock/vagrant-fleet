module VagrantPlugins
  module FleetProvisioner
    class RemoteClient
      def initialize(machine)
        @machine = machine
      end

      def start_units(units)
        @machine.communicate.tap do |comm|
          units.each do |unit, opts|
            @machine.ui.info(I18n.t("vagrant.fleet_provisioner.fleet_start_unit", unit: unit))
            comm.sudo("fleetctl start #{unit}") do |type, data|
              handle_comm(type, data)
            end
          end
        end
      end

protected

      # This handles outputting the communication data back to the UI
      def handle_comm(type, data)
        if [:stderr, :stdout].include?(type)
          # Output the data with the proper color based on the stream.
          # color = type == :stdout ? :green : :red

          # Clear out the newline since we add one
          data = data.chomp
          return if data.empty?

          options = {}
          #options[:color] = color if !config.keep_color

          @machine.ui.info(data.chomp, options)
        end
      end
    end
  end
end
