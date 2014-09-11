module VagrantPlugins
  module FleetProvisioner
    class LocalClient
      def initialize(machine)
        @machine = machine
      end

      def submit_units(units)
        @machine.communicate.tap do |comm|
          remote_temp_dir = Pathname.new "/tmp/fleet_#{Time.now.to_i}_#{rand(100000)}"
          comm.execute("mkdir #{remote_temp_dir}") do |type, data|
            handle_comm(type, data)
          end

          units.each do |unit, opts|
            # Upload the temp file to the remote machine
            remote_temp = remote_temp_dir.join(unit)
            @machine.communicate.upload(unit, remote_temp)

            @machine.ui.info(I18n.t("vagrant.fleet_provisioner.fleet_start_unit", unit: unit))
            comm.execute("fleetctl submit #{remote_temp}") do |type, data|
              handle_comm(type, data)
            end
          end
        end
      end
      def start_units(units)
        @machine.communicate.tap do |comm|
          units.each do |unit, opts|
            @machine.ui.info(I18n.t("vagrant.fleet_provisioner.fleet_start_unit", unit: unit))
            comm.execute("fleetctl start #{unit}") do |type, data|
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
