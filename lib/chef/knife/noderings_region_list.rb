# frozen_string_literal: true

#
# Copyright:: NodeRings
# License:: Apache-2.0
#

require "chef/knife"
require_relative "helpers/noderings_base"

class Chef
  class Knife
    # Lists the countries and cities where virtual machines are sold.
    class NoderingsRegionList < Knife
      include Knife::NoderingsBase

      banner "knife noderings region list (options)"

      def run
        regions = noderings_call("listing regions") { noderings_client.list_marketplace_regions("ASSET_TYPE_VM") }
        if config[:format] && config[:format] != "summary"
          output(regions)
          return
        end

        rows = %w{Country City}.map { |h| ui.color(h, :bold) }
        regions.sort_by { |r| [r["country"].to_s, r["city"].to_s] }.each { |r| rows.push(r["country"].to_s, r["city"].to_s) }
        ui.msg(ui.list(rows, :uneven_columns_across, 2))
      end
    end
  end
end
