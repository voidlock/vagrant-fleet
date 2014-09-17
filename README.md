# Vagrant Fleet Provisioner

Vagrant fleet provisioner for use with a CoreOS guest machine

## Strong Warnings - Pre-Release softare

This is very early work.

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
**Table of Contents**  *generated with [DocToc](http://doctoc.herokuapp.com/)*

- [Installation](#installation)
  - [Pre-release Versions](#pre-release-versions)
  - [Stable Versions](#stable-versions)
- [Usage](#usage)
  - [With a CoreOS vagrant box](#with-a-coreos-vagrant-box)
  - [Submitting Units to fleet](#submitting-units-to-fleet)
      - [Submitting a file](#submitting-a-file)
      - [Submitting a directory](#submitting-a-directory)
      - [Submitting an inline unit definition](#submitting-an-inline-unit-definition)
    - [Starting and Stopping Services](#starting-and-stopping-services)
    - [Loading and Unloading Services](#loading-and-unloading-services)
    - [Destroying Services](#destroying-services)
- [Contributing](#contributing)

<!-- END doctoc generated TOC please keep comment here to allow auto update -->

## Installation

Installation is handled via Vagrant's standard plugin mechanisms.

### Pre-release Versions

_NOTE: This is the only way to install the plugin at the moment._

To install the latest pre-release version use:

    $ vagrant plugin install vagrant-fleet --plugin-prerelease

### Stable Versions

To install the latest stable version:

    $ vagrant plugin install vagrant-fleet

## Usage

### With a CoreOS vagrant box

In it's present from the plugin requires that you use a CoreOS basebox and that
fleet is provisioned within that box. This limitation will be removed sometime
before v1.0 of the plugin.

For a detailed example have a look at the bundled [Vagrantfile](Vagrantfile).

In order to provision systemd style units to your CoreOS cluster. You can
specify the `:fleet` provisioner

```ruby
config.vm.provision :fleet do |ctl|
  # fleet provisioning code
end
```

### Submitting Units to fleet

The same actions as found with the `fleetctl` command. If you are familiar with
using that tool then the syntax will be familiar as well.

To start with all units must be submitted to the fleet. For the purposes of
this example it is assumed that your unit files are stored locally. This
however, is not a requirement. The units could be fetched down using other
mechanisms or already be shared via fleet in a pre-existing cluster.

The plugin supports three ways of submitting units to the fleet cluster.

##### Submitting a file

Here the specfied file is uploaded to the vagrant box and then submitted into
the fleet cluster.

```ruby
config.vm.provision :fleet do |fleet|
  fleet.submit file: "my_unit.service"
end
```

##### Submitting a directory

Here the entire directory is shared using vagrant's synced folders to the
vagrant box. Each unit found within that directory is then submitted to the
fleet cluster.

```ruby
config.vm.provision :fleet do |fleet|
  fleet.submit directory: "./path/to/dir"
end
```

##### Submitting an inline unit definition

Here the unit is defined inline using ruby's HEREDOC syntax. The unit is
uploaded to the vagrant box and then submitted to the fleet cluster.

```ruby
config.vm.provision :fleet do |fleet|
  fleet.submit "redis.service",
    inline: <<-UNIT
      [Unit]
      Description=Redis

      [Service]
      TimeoutStartSec=10m
      Environment=IMG=dockerfile/redis CNAME=redis
      ExecStartPre=/bin/bash -c "/usr/bin/docker inspect $IMG &> /dev/null || /usr/bin/docker pull $IMG"
      ExecStartPre=-/bin/bash -c "/usr/bin/docker rm $CNAME &> /dev/null"
      ExecStart=/usr/bin/docker run --name $CNAME --rm $IMG
      ExecStop=/usr/bin/docker stop $CNAME
  UNIT
end
```

#### Starting and Stopping Services

Once a unit has been submitted it can be started using the `start` method and
stopped using the `stop` method.

```ruby
config.vm.provision :fleet do |fleet|
  # starts the unit
  fleet.start "redis.service"

  # stops the unit
  fleet.stop "my_unit.service"
end
```

#### Loading and Unloading Services

Units can be scheduled onto machines withing starting them using the `load`
command. Likewise they can also be unscheduled from a machine, but remain in
the cluster, using the `unload` command.

```ruby
config.vm.provision :fleet do |fleet|
  # loads the unit
  fleet.load "redis.service"

  # unloads the unit
  fleet.unload "my_unit.service"
end
```

#### Destroying Services

Finally units can be destroyed, causing the unit to first be stopped and them
removed from the cluster. This is accomplished using the `destroy` command.

```ruby
config.vm.provision :fleet do |fleet|
  # destroys the unit
  fleet.destroy "redis.service"
end
```

## Contributing

1. Fork it ( https://github.com/voidlock/vagrant-fleet/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
