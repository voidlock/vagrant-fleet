module VagrantPlugins
  module FleetProvisioner
    module Command
      class Shell < Vagrant.plugin(2, :command)
        def self.synopsis
          "creates a sub-shell preconfigured to run a local fleetctl tunnel"
        end

        def execute
          opts = OptionParser.new do |o|
            o.banner = "Usage: vagrant fleetctl-shell [vm-name]"
            o.separator ""
          end

          argv = parse_options(opts)
          return if !argv

          with_target_vms(argv, reverse: true) do |machine|
            ssh_info = machine.ssh_info
            raise Vagrant::Errors::SSHNotReady if ssh_info.nil?

            fleetctl_tunnell = "#{ssh_info[:host]}:#{ssh_info[:port]}"
            puts "FLEETCTL_TUNNEL => #{fleetctl_tunnell}"
            ENV['FLEETCTL_TUNNEL'] = fleetctl_tunnell

            present_keys = `ssh-add -L`
            ssh_info[:private_key_path].each do |private_key_path|
              public_key = `ssh-keygen -y -f #{private_key_path}`.chomp
              `ssh-add "#{private_key_path}"` unless present_keys.include?(public_key)
            end
            exec "#{ENV['SHELL']}"
          end
        end
      end
    end
  end
end
