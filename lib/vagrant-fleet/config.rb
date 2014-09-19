module VagrantPlugins
  module FleetProvisioner
    class Config < Vagrant.plugin("2", :config)
      extend Vagrant::Util::Counter

      attr_accessor :binary_path
      attr_accessor :provisioning_path
      attr_accessor :file_cache_path

      def initialize
        @__actions = Hash.new { |h, k| h[k] = Set.new }
        @__uploaded = []
        @__shared = []

        @binary_path = UNSET_VALUE
        @provisioning_path = UNSET_VALUE
        @file_cache_path = UNSET_VALUE
      end

      def actions
        @__actions
      end

      def uploaded_units
        @__uploaded
      end

      def shared_units
        @__shared
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
          @__uploaded << unit_from_spec(name, inline)
        elsif file
          @__uploaded << file
        elsif directory
          @__shared << directory
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
    end
  end
end
