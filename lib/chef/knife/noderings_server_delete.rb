# frozen_string_literal: true

#
# Copyright:: NodeRings
# License:: Apache-2.0
#

require "chef/knife"
require_relative "helpers/noderings_base"

class Chef
  class Knife
    # Deletes NodeRings virtual machines, and optionally their Chef node and client.
    class NoderingsServerDelete < Knife
      include Knife::NoderingsBase

      deps do
        require "chef/node"
        require "chef/api_client"
      end

      banner "knife noderings server delete HOSTNAME|ID [HOSTNAME|ID...] (options)"

      option :purge,
        short: "-P",
        long: "--purge",
        boolean: true,
        default: false,
        description: "Also delete the Chef node and client named like the server (or --node-name)."

      option :chef_node_name,
        short: "-N NAME",
        long: "--node-name NAME",
        description: "Name of the Chef node and client to purge, when it differs from the server hostname."

      def run
        if name_args.empty?
          show_usage
          ui.fatal("Name at least one server")
          exit 1
        end

        name_args.each do |name|
          vm = find_vm!(name)
          msg_pair("Server ID", vm["id"])
          msg_pair("Hostname", vm["hostname"])
          msg_pair("IPv4 address", vm["ipv4"])
          ui.confirm("Delete #{vm["hostname"]}? Hourly billing stops; a monthly subscription is cancelled without a refund")
          noderings_call("deleting #{vm["hostname"]}") do
            noderings_client.delete_virtual_machine(vm["id"])
          rescue KnifeNoderings::APIError => e
            raise unless e.not_found?
          end
          ui.warn("Deleted NodeRings server #{vm["hostname"]} (#{vm["id"]})")
          purge(config[:chef_node_name] || vm["hostname"]) if config[:purge]
        end
      end

      private

      def purge(node_name)
        [[Chef::Node, "node"], [Chef::ApiClient, "client"]].each do |klass, type|
          klass.load(node_name).destroy
          ui.warn("Deleted #{type} #{node_name}")
        rescue Net::HTTPClientException
          ui.warn("Could not find a #{type} named #{node_name} to delete")
        end
      end
    end
  end
end
