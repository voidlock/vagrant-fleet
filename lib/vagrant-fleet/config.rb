module VagrantPlugins
  module FleetProvisioner
    class Config < Vagrant.plugin("2", :config)
      def initialize
        @__submit = Hash.new { |h, k| h[k] = {} }
        @__units = Hash.new { |h, k| h[k] = {} }
      end

      def submit_units
        @__submit
      end

      def units
        @__units
      end

      def start(unit, **options)
        @__units[unit.to_s] = options.dup
      end

      def stop(unit)
      end

      def load(unit)
      end

      def unload(unit)
      end

      def submit(unit, **options)
        @__submit[unit.to_s] = options.dup
      end

      def destroy(unit)
      end
    end
  end
end
