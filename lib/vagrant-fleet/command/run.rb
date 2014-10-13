module VagrantPlugins
  module FleetProvisioner
    module Command
      class Run < Vagrant.plugin(2, :command)
        def self.synopsis
          "run a one-off command in the context of a container"
        end

        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant fleetctl-run [vm-name]"
            o.separator ""
          end

          # Parse out the extra args to send to SSH, which is everything
          # after the "--"
          command     = nil
          split_index = @argv.index("--")
          if split_index
            command = @argv.drop(split_index + 1)
            @argv   = @argv.take(split_index)
          end

          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv, reverse: true) do |machine|
            # Run it!
            machine.action(
              :ssh_run,
              ssh_run_command: (["fleetctl"] + command).join(" ")
            )
          end
        end
      end
    end
  end
end
