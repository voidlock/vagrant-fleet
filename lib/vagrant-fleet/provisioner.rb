require_relative "local_client"

module VagrantPlugins
  module FleetProvisioner
    class Provisioner < Vagrant.plugin(2, :provisioner)
      extend Vagrant::Util::Counter
      include Vagrant::Util::Counter

      class FleetError < Vagrant::Errors::VagrantError
        error_namespace("vagrant.provisioners.fleet")
      end

      def initialize(machine, config, client = nil)
        super(machine, config)

        @client = client || Client.new(@machine)
        @logger = Log4r::Logger.new("vagrant::provisioners::fleet")
      end

      def configure(root_config)
        @unit_folders = expanded_folders(@config.units[:shared])

        share_folders(root_config, "fsu", @unit_folders)
      end

      def provision
        # Verify that the proper shared folders exist.
        check = []
        @unit_folders.each do |local_path, remote_path|
          # We only care about checking folders that have a local path, meaning
          # they were shared from the local machine, rather than assumed to
          # exist on the VM.
          check << remote_path if local_path
        end

        chown_provisioning_folder()
        copy_inline_units()
        verify_shared_folders(check)
        verify_binary(binary_path("fleetctl"))

        @client.submit_units(expand_file_cache_path(@config.copied_units))
        @client.submit_units(expand_unit_folders(@unit_folders))
        @config.actions.each do |action, units|
          @client.send(:"#{action}_units", units)
        end
      end

      def chown_provisioning_folder
        paths = [@config.provisioning_path,
                 @config.file_cache_path]

        @machine.communicate.tap do |comm|
          paths.each do |path|
            comm.sudo("mkdir -p #{path}")
            comm.sudo("chown -h #{@machine.ssh_info[:username]} #{path}")
          end
        end
      end

      def copy_inline_units()
        @machine.communicate.tap do |comm|
          @config.copied_units.each do |unit|
            comm.execute("echo '#{unit[:unit]}' > #{@config.file_cache_path}/#{unit[:name]}")
          end
        end
      end

      def binary_path(binary)
        return binary if !@config.binary_path
        return File.join(@config.binary_path, binary)
      end

      def verify_binary(binary)
        # Checks for the existence of fleetctl binary and error if it
        # doesn't exist.
        @machine.communicate.sudo(
          "which #{binary}",
          error_class: FleetError,
          error_key: :fleet_not_detected,
          binary: binary)
      end

      def expand_file_cache_path(units)
        results = []
        units.each do |unit|
          results << "#{@config.file_cache_path}/#{unit[:name]}"
        end
        results
      end

      def expand_unit_folders(folders)
        results = []
        folders.each do |local_path, remote_path|
          results += Dir.glob(File.join(local_path, "*")).map do |local_file|
            local_file.gsub(local_path, remote_path)
          end
        end
        results
      end

      def expanded_folders(paths, appended_folder=nil)
        # Convert the path to an array if it is a string or just a single
        # path element which contains the folder location (:host or :vm)
        paths = [paths] if paths.is_a?(String) || paths.first.is_a?(Symbol)

        results = []

        paths.each do |path|
          # Create the local/remote path based on whether this is a host
          # or VM path.
          local_path = nil
          remote_path = nil

          # Get the expanded path that the host path points to
          local_path = File.expand_path(path, @machine.env.root_path)

          if File.exist?(local_path)
            # Path exists on the host, setup the remote path
            remote_path = "#{@config.provisioning_path}/shared-units-#{get_and_update_counter(:units_path)}"
          else
            @machine.ui.warn(I18n.t("vagrant.provisioners.fleet.unit_folder_not_found_warning",
                                    path: local_path.to_s))
            next
          end

          # If we have specified a folder name to append then append it
          remote_path += "/#{appended_folder}" if appended_folder

          # Append the result
          results << [local_path, remote_path]
        end

        results
      end

      def share_folders(root_config, prefix, folders)
        folders.each do |local_path, remote_path|
          opts = {}
          opts[:id] = "v-#{prefix}-#{self.class.get_and_update_counter(:shared_folder)}"
          opts[:type] = @config.synced_folder_type if @config.synced_folder_type

          root_config.vm.synced_folder(local_path, remote_path, opts)
        end
      end

      def verify_shared_folders(folders)
        folders.each do |folder|
          @logger.debug("Checking for shared folder: #{folder}")
          if !@machine.communicate.test("test -d #{folder}", sudo: true)
            raise FleetError, :missing_shared_folders
          end
        end
      end
    end
  end
end
