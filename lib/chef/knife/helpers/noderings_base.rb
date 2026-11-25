# frozen_string_literal: true

#
# Copyright:: NodeRings
# License:: Apache-2.0
#

require "chef/knife"

class Chef
  class Knife
    # Options and helpers shared by every knife noderings command.
    module NoderingsBase
      def self.included(includer)
        includer.class_eval do
          deps do
            require_relative "../../../knife-noderings/version"
            require_relative "../../../knife-noderings/compute"
          end

          option :noderings_api_token,
            long: "--noderings-api-token TOKEN",
            description: "NodeRings API token. Defaults to knife[:noderings_api_token], then the NODERINGS_TOKEN environment variable."

          option :noderings_api_url,
            long: "--noderings-api-url URL",
            description: "NodeRings API endpoint (default https://api.noderings.com)."

          option :noderings_organization_id,
            long: "--noderings-organization-id ID",
            description: "Organization to act in, for tokens that can reach more than one."
        end
      end

      # Tests plug an in-memory API in here.
      class << self
        attr_accessor :transport, :sleeper
      end

      # Reads a setting from the command line, then knife config, then the environment.
      def noderings_setting(key, *env_vars)
        value = config[key]
        value = Chef::Config[:knife][key] if value.to_s.empty? && Chef::Config[:knife]
        value = env_vars.map { |v| ENV[v] }.find { |v| !v.to_s.empty? } if value.to_s.empty?
        value.to_s.empty? ? nil : value
      end

      def noderings_client
        @noderings_client ||= KnifeNoderings::Client.new(
          token: noderings_setting(:noderings_api_token, *KnifeNoderings::TOKEN_ENV_VARS),
          api_url: noderings_setting(:noderings_api_url, "NODERINGS_API_URL"),
          organization_id: noderings_setting(:noderings_organization_id, "NODERINGS_ORGANIZATION_ID"),
          user_agent: "knife-noderings/#{KnifeNoderings::VERSION} (knife #{defined?(Chef::Knife::VERSION) ? Chef::Knife::VERSION : "unknown"})",
          transport: NoderingsBase.transport,
          sleeper: NoderingsBase.sleeper
        )
      end

      # Runs an API call and turns a failure into a readable error and exit 1.
      def noderings_call(what)
        yield
      rescue KnifeNoderings::APIError, KnifeNoderings::UsageError, KnifeNoderings::WaitTimeout => e
        ui.fatal("#{what}: #{e.message}")
        exit 1
      end

      def compute
        KnifeNoderings::Compute
      end

      # The VM with this hostname or ID; exits when there is none.
      def find_vm!(name_or_id)
        vm = noderings_call("looking up #{name_or_id}") { compute.find_vm(noderings_client, name_or_id) }
        return vm if vm

        ui.fatal("No NodeRings virtual machine is named #{name_or_id}")
        exit 1
      end

      def msg_pair(label, value, color = :cyan)
        return if value.nil? || value.to_s.empty?

        ui.msg("#{ui.color(label, color)}: #{value}")
      end

      def power_color(state)
        { "running" => :green, "stopped" => :red }.fetch(state, :yellow)
      end
    end
  end
end
