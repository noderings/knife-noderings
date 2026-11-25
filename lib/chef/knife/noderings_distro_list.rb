# frozen_string_literal: true

#
# Copyright:: NodeRings
# License:: Apache-2.0
#

require "chef/knife"
require_relative "helpers/noderings_base"

class Chef
  class Knife
    # Lists the operating systems a server can be ordered with.
    class NoderingsDistroList < Knife
      include Knife::NoderingsBase

      banner "knife noderings distro list (options)"

      def run
        distros = noderings_call("listing distros") { noderings_client.list_distros }
          .map { |d| KnifeNoderings.trim_enum(d["distro"], "DISTRO_") }.reject(&:empty?)
        if config[:format] && config[:format] != "summary"
          output(distros)
          return
        end

        ui.msg(distros.join("\n"))
      end
    end
  end
end
