# frozen_string_literal: true

require "chef/knife"
require "chef/knife/bootstrap"
require "chef/node"
require "chef/api_client"
require_relative "support/fake_noderings"
Dir[File.expand_path("../lib/chef/knife/*.rb", __dir__)].sort.each { |f| require f }
require_relative "../lib/knife-noderings/compute"
require_relative "../lib/knife-noderings/version"

RSpec.configure do |config|
  config.before do
    @fake = FakeNodeRings.new
    Chef::Knife::NoderingsBase.transport = @fake
    Chef::Knife::NoderingsBase.sleeper = ->(_s) {}
    Chef::Config.reset
    Chef::Config[:knife][:noderings_api_token] = "test-token"
  end
end

# Builds a knife command with captured output.
def knife(klass, args = [])
  cmd = klass.new(args)
  cmd.merge_configs
  @stdout ||= StringIO.new
  @stderr ||= StringIO.new
  cmd.ui = Chef::Knife::UI.new(@stdout, @stderr, $stdin, cmd.config)
  cmd
end

def order_vm(hostname = "web-1")
  client = KnifeNoderings::Client.new(token: "t", transport: @fake, sleeper: ->(_s) {})
  KnifeNoderings::Compute.order_vm(client, hostname, FakeNodeRings::PLAN_ID, FakeNodeRings::REGION_ID, password: "pw")
end
