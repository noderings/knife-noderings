# frozen_string_literal: true

#
# Copyright:: NodeRings
# License:: Apache-2.0
#

require "chef/knife"
require_relative "helpers/noderings_base"

class Chef
  class Knife
    # Lists the SSH keys stored in the organization, for --noderings-ssh-key.
    class NoderingsSshKeyList < Knife
      include Knife::NoderingsBase

      banner "knife noderings ssh key list (options)"

      def run
        keys = noderings_call("listing SSH keys") { noderings_client.list_ssh_keys }
        if config[:format] && config[:format] != "summary"
          output(keys.map { |k| k.slice("id", "name", "keyType", "fingerprint") })
          return
        end

        rows = %w{ID Name Type Fingerprint}.map { |h| ui.color(h, :bold) }
        keys.sort_by { |k| k["name"].to_s }.each { |k| rows.push(k["id"].to_s, k["name"].to_s, k["keyType"].to_s, k["fingerprint"].to_s) }
        ui.msg(ui.list(rows, :uneven_columns_across, 4))
      end
    end
  end
end
