# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing!
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.box = "yungsang/coreos-alpha"

  # config.vm.network "forwarded_port", guest: 80, host: 8080
  config.vm.provision :file, source: "./user-data", destination: "/tmp/vagrantfile-user-data"

  config.vm.provision :shell do |sh|
    sh.privileged = true
    sh.inline = <<-EOT
        mv /tmp/vagrantfile-user-data /var/lib/coreos-vagrant/
    EOT
  end
  config.vm.provision :fleet do |fleet|

    # Starts the service assuming service exists in local directory with given
    # name
    fleet.submit "redis.service"
    fleet.start "redis.service"

    # fleet.start "path/to/service/file.service"

    # Stops the service
    # fleet.stop "stop-some.service"

    # To schedule a unit into the cluster (i.e. load it on a machine) without
    # starting it.
    #
    # This will not call the equivalent of systemctl start, so the loaded unit
    # will be in an inactive state.
    # fleet.load "load-some.service"

    # Units can also be unscheduled, but remain in the cluster with fleetctl
    # unload. The unit will still be visible in fleetctl list-unit-files, but
    # will have no state reported in fleetctl list-units
    # fleet.unload "unload-some.service"

    # Submission of units to a fleet cluster does not cause them to be
    # scheduled. The unit will be visible in a fleetctl list-unit-files
    # command, but have no reported state in fleetctl list-units.
    # fleet.submit "submit-some.service"

    # The destroy command does two things:
    #
    # 1) Instruct systemd on the host machine to stop the unit, deferring to
    # systemd completely for any custom stop directives (i.e. ExecStop option
    # in the unit file).
    # 2) Remove the unit file from the cluster, making it
    # impossible to start again until it has been re-submitted.
    #
    # Once a unit is destroyed, state will continue to be reported for it in
    # fleetctl list-units. Only once the unit has stopped will its state be
    # removed.
    # fleet.destroy "destroy-some.service"
  end
end
