module VagrantPlugins
  module FleetProvisioner
    class Config < Vagrant.plugin("2", :config)
      extend Vagrant::Util::Counter
      attr_accessor :binary_path
      attr_accessor :provisioning_path
      attr_accessor :file_cache_path

      def initialize
        @__actions = Hash.new { |h, k| h[k] = Set.new }
        @__units = Hash.new { |h, k| h[k] = [] }

        @binary_path = UNSET_VALUE
        @provisioning_path = UNSET_VALUE
        @file_cache_path = UNSET_VALUE
      end

      def units
        @__units
      end

      def actions
        @__actions
      end

      def copied_units
        @__units[:copied]
      end

      def shared_units
        @__units[:shared]
      end

      def start(unit)
        @__actions[:start] << unit.to_s
      end

      def stop(unit)
        @__actions[:stop] << unit.to_s
      end

      def load(unit)
        @__actions[:load] << unit.to_s
      end

      def unload(unit)
        @__actions[:unload] << unit.to_s
      end

      def submit(name = nil, file: nil, inline: nil, directory: nil)
        if name && inline
          @__units[:copied] << unit_from_spec(name, inline)
        elsif file
          @__units[:copied] << unit_from_file(file)
        elsif directory
          @__units[:shared] << directory
        end
      end

      def destroy(unit)
        @__actions[:destroy] << unit.to_s
      end


      def finalize!
        @binary_path = nil if @provisioning_path == UNSET_VALUE
        @provisioning_path = nil if @provisioning_path == UNSET_VALUE
        @file_cache_path = nil if @file_cache_path == UNSET_VALUE

        # Set the default provisioning path to be a unique path in /tmp
        if !@provisioning_path
          counter = self.class.get_and_update_counter(:fleet_config)
          @provisioning_path = "/tmp/vagrant-fleet-#{counter}"
        end

        if !@file_cache_path
          @file_cache_path = "#{@provisioning_path}/uploaded_units"
        end
      end
      private

      def unit_from_spec(name, spec)
        { name: name.to_s, unit: spec }
      end

      def unit_from_file(file)
        unit_from_spec(File.basename(file), File.read(file))
      end
    end
  end
end
