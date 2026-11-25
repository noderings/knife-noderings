# frozen_string_literal: true

describe Chef::Knife::NoderingsServerCreate do
  let(:args) do
    ["--hostname", "web-1", "--plan", "SC-GC-1C-1G-20", "--country", "United States", "--city", "Ashburn", "--distro", "debian-13", "--noderings-ssh-key", "laptop", "--noderings-tags", "web,chef", "--firewall-ruleset", "web", "-i", "~/.ssh/id_ed25519", "-r", "role[web]"]
  end
  let(:cmd) { knife(described_class, args) }

  before do
    @fake.ssh_keys["k1"] = { "id" => "k1", "name" => "laptop", "publicKey" => "ssh-ed25519 AAAA laptop" }
    @fake.call("POST", "https://api.noderings.com/v1/firewall/rulesets", {}, '{"ruleset":{"name":"web"}}', 1)
    allow(cmd).to receive(:wait_for_sshd)
  end

  it "connects over SSH as root by default" do
    cmd.plugin_setup!
    expect(cmd.config).to include(connection_protocol: "ssh", connection_user: "root", connection_port: 22)
  end

  it "uses the hostname as the node name" do
    cmd.plugin_validate_options!
    expect(cmd.config[:chef_node_name]).to eq "web-1"
  end

  it "orders the cheapest matching offer and targets its address" do
    cmd.plugin_setup!
    cmd.plugin_validate_options!
    cmd.plugin_create_instance!
    body = @fake.created_vm_bodies.last
    expect(body).to include("hostname" => "web-1", "planId" => FakeNodeRings::PLAN_ID, "distro" => "DISTRO_DEBIAN_13",
      "sshKeyIds" => ["k1"], "tags" => %w{chef web})
    expect(@fake.vms.values.first["firewallRulesetId"]).to eq @fake.rulesets.keys.first
    expect(cmd.server_name).to eq "192.0.2.50"
    expect(cmd.config[:hints]["noderings"]).to include("hostname" => "web-1")
    expect(cmd).to have_received(:wait_for_sshd).with("192.0.2.50")
  end

  it "sends the User-Agent and token" do
    cmd.plugin_validate_options!
    cmd.plugin_create_instance!
    headers = @fake.calls.last[4]
    expect(headers["Authorization"]).to eq "Bearer test-token"
    expect(headers["User-Agent"]).to start_with("knife-noderings/#{KnifeNoderings::VERSION}")
  end

  it "refuses to order a hostname that exists" do
    order_vm("web-1")
    cmd.plugin_validate_options!
    expect { cmd.plugin_create_instance! }.to raise_error(SystemExit)
    expect(@stderr.string).to include("already exists")
  end

  it "explains missing options" do
    bare = knife(described_class, %w{--hostname web-1})
    expect { bare.plugin_validate_options! }.to raise_error(SystemExit)
    expect(@stderr.string).to include("--plan, --country and --city").and include("--noderings-ssh-key is required")
  end

  it "explains an offer that does not exist" do
    other = knife(described_class, args.map { |a| a == "Ashburn" ? "Nowhere" : a })
    allow(other).to receive(:wait_for_sshd)
    other.plugin_validate_options!
    expect { other.plugin_create_instance! }.to raise_error(SystemExit)
    expect(@stderr.string).to include("No offer for plan code SC-GC-1C-1G-20 in Nowhere")
  end

  it "summarises the server" do
    cmd.plugin_validate_options!
    cmd.plugin_create_instance!
    cmd.plugin_finalize
    expect(@stdout.string).to include("192.0.2.50").and include("debian_13").and include("role[web]")
  end
end
