require_relative "client"

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
        @unit_folders = expanded_folders(config.shared_units)

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
        copy_file_units()
        verify_shared_folders(check)
        verify_binary(binary_path("fleetctl"))

        @client.submit_units(expand_file_cache_path(config.uploaded_units))
        @client.submit_units(expand_unit_folders(@unit_folders))
        config.actions.each do |action, units|
          @client.send(:"#{action}_units", units)
        end
      end

      def chown_provisioning_folder
        paths = [config.provisioning_path,
                 config.file_cache_path]

        @machine.communicate.tap do |comm|
          paths.each do |path|
            comm.sudo("mkdir -p #{path}")
            comm.sudo("chown -h #{@machine.ssh_info[:username]} #{path}")
          end
        end
      end

      def copy_file_units
        with_file_units do |local_path, remote_path|
          @machine.communicate.tap do |comm|
            @logger.debug("Upload: #{local_path} to #{remote_path}")
            comm.upload(local_path.to_s, remote_path)
          end
        end
      end

      def with_file_units
        config.uploaded_units.each do |unit|
          name = nil
          spec = nil

          case unit
          when String
            root_path = @machine.env.root_path
            name = File.basename(unit)
            spec = Pathname.new(unit).expand_path(root_path).read
          when Hash
            name = unit[:name]
            spec = unit[:spec]
          end

          ext = File.extname(name)
          remote_path = "#{config.file_cache_path}/#{name}"


          # Replace Windows line endings with Unix ones unless binary file
          # or we're running on Windows.
          if !config.binary && @machine.config.vm.communicator != :winrm
            spec.gsub!(/\r\n?$/, "\n")
          end

          # Otherwise we have an inline unit, we need to Tempfile it,
          # and handle it specially...
          file = Tempfile.new(['vagrant-shell', ext])

          # Unless you set binmode, on a Windows host the unit
          # will have CRLF line endings instead of LF line
          # endings, causing havoc when the guest executes it.
          # This fixes [GH-1181].
          file.binmode

          begin
            file.write(spec)
            file.fsync
            file.close
            yield file.path, remote_path
          ensure
            file.close
            file.unlink
          end
        end
      end

      def binary_path(binary)
        return binary if !config.binary_path
        return File.join(config.binary_path, binary)
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
          case unit
          when String
            results << "#{config.file_cache_path}/#{File.basename(unit)}"
          when Hash
            results << "#{config.file_cache_path}/#{unit[:name]}"
          end
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
            remote_path = "#{config.provisioning_path}/shared-units-#{get_and_update_counter(:units_path)}"
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
          opts[:type] = config.synced_folder_type if config.synced_folder_type

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
