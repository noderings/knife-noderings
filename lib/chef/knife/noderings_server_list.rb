# frozen_string_literal: true

#
# Copyright:: NodeRings
# License:: Apache-2.0
#

require "chef/knife"
require_relative "helpers/noderings_base"

class Chef
  class Knife
    # Lists the organization's NodeRings virtual machines.
    class NoderingsServerList < Knife
      include Knife::NoderingsBase

      banner "knife noderings server list (options)"

      def run
        vms = noderings_call("listing servers") { noderings_client.list_virtual_machines }.map { |vm| compute.view(vm) }
        if config[:format] && config[:format] != "summary"
          output(vms)
          return
        end

        rows = %w{ID Hostname IPv4 Plan Distro State}.map { |h| ui.color(h, :bold) }
        vms.sort_by { |v| v["hostname"].to_s }.each do |v|
          rows.push(v["id"].to_s, v["hostname"].to_s, v["ipv4"].to_s, v["plan_code"].to_s, v["distro"].to_s,
            ui.color(v["power_state"], power_color(v["power_state"])))
        end
        ui.msg(ui.list(rows, :uneven_columns_across, 6))
      end
    end
  end
end
