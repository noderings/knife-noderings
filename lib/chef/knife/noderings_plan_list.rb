# frozen_string_literal: true

#
# Copyright:: NodeRings
# License:: Apache-2.0
#

require "chef/knife"
require_relative "helpers/noderings_base"

class Chef
  class Knife
    # Lists the plans sold, optionally in one country and city.
    class NoderingsPlanList < Knife
      include Knife::NoderingsBase

      banner "knife noderings plan list (options)"

      option :country, long: "--country COUNTRY", description: "Only plans sold in this country."
      option :city, long: "--city CITY", description: "Only plans sold in this city."
      option :billing_type,
        long: "--billing-type TYPE",
        description: "usage, subscription or free.",
        in: %w{usage subscription free}

      def run
        plans = noderings_call("listing plans") do
          noderings_client.list_available_plans(country: config[:country], city: config[:city],
            billing_type: KnifeNoderings::BILLING_TYPES[config[:billing_type].to_s],
            asset_type: "ASSET_TYPE_VM")
        end
        if config[:format] && config[:format] != "summary"
          output(plans)
          return
        end

        rows = ["Plan code", "Billing", "Compute", "Category"].map { |h| ui.color(h, :bold) }
        plans.sort_by { |p| p["planCode"].to_s }.each do |p|
          rows.push(p["planCode"].to_s, KnifeNoderings.trim_enum(p["billingType"], "BILLING_TYPE_"),
            KnifeNoderings.trim_enum(p["computeType"], "COMPUTE_TYPE_"),
            KnifeNoderings.trim_enum(p["computeCategory"], "COMPUTE_CATEGORY_"))
        end
        ui.msg(ui.list(rows, :uneven_columns_across, 4))
      end
    end
  end
end
