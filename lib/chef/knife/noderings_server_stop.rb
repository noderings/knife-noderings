# frozen_string_literal: true

#
# Copyright:: NodeRings
# License:: Apache-2.0
#

require "chef/knife"
require_relative "helpers/noderings_base"

class Chef
  class Knife
    # Stops NodeRings virtual machines and waits until they are done.
    class NoderingsServerStop < Knife
      include Knife::NoderingsBase

      banner "knife noderings server stop HOSTNAME|ID [HOSTNAME|ID...] (options)"

      def run
        if name_args.empty?
          show_usage
          ui.fatal("Name at least one server")
          exit 1
        end

        name_args.each do |name|
          vm = find_vm!(name)
          vm = noderings_call("stoping #{vm["hostname"]}") { compute.set_power(noderings_client, vm["id"], "stopped") }
          state = compute.power_state(vm)
          ui.msg("#{vm["hostname"]}: #{ui.color(state, power_color(state))}")
        end
      end
    end
  end
end
