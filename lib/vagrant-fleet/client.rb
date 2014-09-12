module VagrantPlugins
  module FleetProvisioner
    class Client
      def initialize(machine)
        @machine = machine
      end

      def submit_units(units)
        exec(:submit, units)
      end

      def start_units(units)
        exec(:start, units)
      end

      def stop_units(units)
        exec(:stop, units)
      end

      def load_units(units)
        exec(:load, units)
      end

      def unload_units(units)
        exec(:unload, units)
      end

      def destroy_units(units)
        exec(:destroy, units)
      end

      protected


      def exec(command, units)
        @machine.communicate.tap do |comm|
          units.each do |unit, opts|
            @machine.ui.info(I18n.t("vagrant.provisioners.fleet.start_unit", unit: unit))
            comm.execute("fleetctl #{command} #{unit}") do |type, data|
              handle_comm(type, data)
            end
          end
        end
      end

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
