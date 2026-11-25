# frozen_string_literal: true

#
# Copyright:: NodeRings
# License:: Apache-2.0
#

require "chef/knife"
require_relative "helpers/noderings_base"

class Chef
  class Knife
    # Starts NodeRings virtual machines and waits until they are done.
    class NoderingsServerStart < Knife
      include Knife::NoderingsBase

      banner "knife noderings server start HOSTNAME|ID [HOSTNAME|ID...] (options)"

      def run
        if name_args.empty?
          show_usage
          ui.fatal("Name at least one server")
          exit 1
        end

        name_args.each do |name|
          vm = find_vm!(name)
          vm = noderings_call("starting #{vm["hostname"]}") { compute.set_power(noderings_client, vm["id"], "running") }
          state = compute.power_state(vm)
          ui.msg("#{vm["hostname"]}: #{ui.color(state, power_color(state))}")
        end
      end
    end
  end
end
