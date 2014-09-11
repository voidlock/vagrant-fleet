require "pathname"

require "vagrant"
require "vagrant-fleet/plugin"

module VagrantPlugins
  module FleetProvisioner
    def self.source_root
      @source_root ||= Pathname.new(File.expand_path("../../", __FILE__))
    end
  end
end
