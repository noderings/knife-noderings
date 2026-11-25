# frozen_string_literal: true

#
# Copyright:: NodeRings
# License:: Apache-2.0
#

require "chef/knife"
require_relative "helpers/noderings_base"

class Chef
  class Knife
    # Shows one NodeRings virtual machine.
    class NoderingsServerShow < Knife
      include Knife::NoderingsBase

      banner "knife noderings server show HOSTNAME|ID (options)"

      def run
        if name_args.length != 1
          show_usage
          ui.fatal("Name one server")
          exit 1
        end
        output(compute.view(find_vm!(name_args.first)))
      end
    end
  end
end
