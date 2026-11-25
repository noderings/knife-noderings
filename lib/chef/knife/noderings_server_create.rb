# frozen_string_literal: true

#
# Copyright:: NodeRings
# License:: Apache-2.0
#

require "chef/knife/bootstrap"
require_relative "helpers/noderings_base"

class Chef
  class Knife
    # Orders a NodeRings virtual machine and bootstraps Chef Infra (or Cinc) on it.
    class NoderingsServerCreate < Chef::Knife::Bootstrap
      include Knife::NoderingsBase

      deps do
        require "socket" unless defined?(Socket)
        require "timeout" unless defined?(Timeout)
        Chef::Knife::Bootstrap.load_deps
      end

      banner "knife noderings server create (options)"

      attr_reader :server

      option :hostname,
        long: "--hostname NAME",
        description: "Hostname of the new server. It also becomes the node name unless -N is given."

      option :plan,
        long: "--plan CODE",
        description: "Plan code to order, such as SC-GC-1C-1G-20. See knife noderings plan list."

      option :country,
        long: "--country COUNTRY",
        description: "Country of the offer, such as \"United States\"."

      option :city,
        long: "--city CITY",
        description: "City of the offer, such as Ashburn. See knife noderings region list."

      option :billing_type,
        long: "--billing-type TYPE",
        description: "usage (hourly, the default), subscription or free.",
        in: %w{usage subscription free},
        default: "usage"

      option :provider_id,
        long: "--provider-id ID",
        description: "Only consider offers from this provider."

      option :sort,
        long: "--sort ORDER",
        description: "Order the cheapest matching offer (price, the default) or the best rated (rating).",
        in: %w{price rating},
        default: "price"

      option :plan_id,
        long: "--plan-id ID",
        description: "Exact plan ID to order, instead of --plan, --country and --city."

      option :region_id,
        long: "--region-id ID",
        description: "Exact region ID to order, with --plan-id."

      option :distro,
        long: "--distro DISTRO",
        description: "Operating system, such as ubuntu_24_04 (the default) or debian-13. See knife noderings distro list.",
        default: "ubuntu_24_04"

      option :noderings_ssh_keys,
        long: "--noderings-ssh-key NAME",
        description: "Name or ID of a NodeRings SSH key to install. Repeat for more keys.",
        proc: proc { |key, acc| (acc || []) + [key] }

      option :noderings_tags,
        long: "--noderings-tags TAG[,TAG]",
        description: "Comma separated NodeRings tags for the server.",
        proc: proc { |tags| tags.split(",").map(&:strip).reject(&:empty?) }

      option :firewall_ruleset,
        long: "--firewall-ruleset NAME",
        description: "Name or ID of a NodeRings firewall ruleset to attach. It must allow SSH from this workstation."

      option :server_create_timeout,
        long: "--server-create-timeout SECONDS",
        description: "Seconds to wait for the server to be ready (default 900).",
        proc: proc { |t| Integer(t) },
        default: 900

      # bootstrap overrides: connect over SSH as root, which every NodeRings image allows.
      def plugin_setup!
        config[:connection_protocol] ||= "ssh"
        config[:connection_user] ||= "root"
        config[:connection_port] ||= 22
        config[:ssh_verify_host_key] ||= :accept_new
      end

      # The host comes from the new server, not the command line.
      def validate_name_args!; end

      def plugin_validate_options!
        config[:hostname] ||= config[:chef_node_name]
        errors = []
        errors << "--hostname is required" if config[:hostname].to_s.empty?
        unless config[:plan_id] && config[:region_id]
          errors << "give --plan, --country and --city, or --plan-id and --region-id" unless config[:plan] && config[:country] && config[:city]
        end
        if Array(config[:noderings_ssh_keys]).empty?
          errors << "--noderings-ssh-key is required: bootstrap logs in with SSH keys, and the matching private key goes in --ssh-identity-file"
        end
        errors << "--ssh-identity-file is required to log in to the new server" if config[:ssh_identity_file].to_s.empty?
        unless errors.empty?
          errors.each { |e| ui.error(e) }
          exit 1
        end
        config[:chef_node_name] ||= config[:hostname]
      end

      def plugin_create_instance!
        client = noderings_client
        if noderings_call("looking up #{config[:hostname]}") { compute.find_vm(client, config[:hostname]) }
          ui.fatal("A NodeRings virtual machine named #{config[:hostname]} already exists. Bootstrap it with knife bootstrap, or choose another --hostname.")
          exit 1
        end

        plan_id, region_id, offer = select_offer(client)
        keys = noderings_call("resolving SSH keys") { compute.resolve_ssh_keys(client, config[:noderings_ssh_keys]) }
        ruleset_id = config[:firewall_ruleset] ? noderings_call("resolving the firewall ruleset") { compute.resolve_ruleset(client, config[:firewall_ruleset]) } : nil

        ui.info("Ordering #{ui.color(config[:hostname], :bold)} (#{offer}, #{compute.normalize_distro(config[:distro])})")
        timeout = config[:server_create_timeout]
        @server = noderings_call("ordering #{config[:hostname]}") do
          vm = compute.order_vm(client, config[:hostname], plan_id, region_id,
            distro: config[:distro], ssh_key_ids: keys, tags: Array(config[:noderings_tags]),
            wait: false, timeout: timeout)
          ui.info("Waiting for #{config[:hostname]} to be provisioned")
          vm = compute.wait_address(client, vm["id"], timeout)
          vm = compute.attach_firewall(client, vm["id"], ruleset_id, timeout: timeout) if ruleset_id
          vm
        end
        msg_pair("Server ID", server["id"])
        msg_pair("IPv4 address", server["ipv4"])
        msg_pair("IPv6 address", server["ipv6"])

        address = server["ipv4"].to_s.empty? ? server["ipv6"] : server["ipv4"]
        if address.to_s.empty?
          ui.fatal("#{config[:hostname]} was created but has no IP address yet; delete it with knife noderings server delete and try again")
          exit 1
        end
        @name_args = [address]
        # An Ohai hint, so recipes can tell the node runs on NodeRings: hint?("noderings").
        config[:hints] ||= {}
        config[:hints]["noderings"] ||= { "id" => server["id"], "hostname" => server["hostname"] }
        wait_for_sshd(address)
      end

      def plugin_finalize
        ui.info("")
        msg_pair("Server ID", server["id"])
        msg_pair("Hostname", server["hostname"])
        msg_pair("IPv4 address", server["ipv4"])
        msg_pair("IPv6 address", server["ipv6"])
        msg_pair("Distro", KnifeNoderings.trim_enum(server["distro"], "DISTRO_"))
        msg_pair("Plan", server["planCode"])
        msg_pair("Node name", config[:chef_node_name])
        msg_pair("Run list", (config[:run_list] || []).join(", "))
        msg_pair("Policy", [config[:policy_group], config[:policy_name]].compact.join("/"))
      end

      private

      def select_offer(client)
        if config[:plan_id] && config[:region_id]
          return [config[:plan_id], config[:region_id], "plan #{config[:plan_id]}"]
        end

        plan_id, region_id, offer = noderings_call("finding an offer") do
          compute.choose_offer(client, config[:plan], config[:country], config[:city],
            billing_type: config[:billing_type], provider_id: config[:provider_id], sort: config[:sort])
        end
        [plan_id, region_id, "#{config[:plan]} from #{offer["provider_name"]} in #{config[:city]}, #{config[:country]}"]
      end

      # A fresh server opens port 22 before cloud-init has installed the keys,
      # so wait for the port, then a little longer.
      def wait_for_sshd(address)
        ui.info("Waiting for SSH on #{address}")
        deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + config[:server_create_timeout]
        until tcp_open?(address, config[:connection_port])
          if Process.clock_gettime(Process::CLOCK_MONOTONIC) > deadline
            ui.fatal("SSH on #{address} did not answer in time; check the firewall ruleset allows port 22")
            exit 1
          end
          noderings_client.sleep_for(5)
        end
        noderings_client.sleep_for(config.fetch(:ssh_settle_seconds, 20))
      end

      def tcp_open?(address, port)
        Timeout.timeout(5) { TCPSocket.new(address, port.to_i).close }
        true
      rescue Timeout::Error, SystemCallError, SocketError, IOError
        false
      end
    end
  end
end
