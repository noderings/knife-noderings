# frozen_string_literal: true

describe "knife noderings server commands" do
  it "lists servers" do
    order_vm("web-1")
    cmd = knife(Chef::Knife::NoderingsServerList)
    cmd.run
    expect(@stdout.string).to include("web-1").and include("192.0.2.50").and include("running")
  end

  it "shows one server" do
    vm = order_vm("web-1")
    cmd = knife(Chef::Knife::NoderingsServerShow, ["web-1"])
    cmd.config[:format] = "json"
    cmd.run
    expect(JSON.parse(@stdout.string)).to include("id" => vm["id"], "hostname" => "web-1")
  end

  it "stops, starts and reboots servers" do
    vm = order_vm("web-1")
    knife(Chef::Knife::NoderingsServerStop, ["web-1"]).run
    expect(@fake.vms[vm["id"]]["operationStatus"]).to eq "OPERATION_STATUS_STOPPED"
    knife(Chef::Knife::NoderingsServerStart, ["web-1"]).run
    knife(Chef::Knife::NoderingsServerReboot, [vm["id"]]).run
    expect(@fake.writes.map(&:last).last(2)).to eq ["/v1/virtual-machines/#{vm["id"]}:start", "/v1/virtual-machines/#{vm["id"]}:restart"]
  end

  it "deletes a server after confirmation and purges the node" do
    order_vm("web-1")
    cmd = knife(Chef::Knife::NoderingsServerDelete, %w{web-1 --purge})
    allow(cmd.ui).to receive(:confirm).and_return(true)
    node = instance_double(Chef::Node, destroy: true)
    client = instance_double(Chef::ApiClient, destroy: true)
    allow(Chef::Node).to receive(:load).with("web-1").and_return(node)
    allow(Chef::ApiClient).to receive(:load).with("web-1").and_return(client)
    cmd.run
    expect(@fake.vms).to be_empty
    expect(node).to have_received(:destroy)
    expect(client).to have_received(:destroy)
  end

  it "fails clearly for an unknown server" do
    cmd = knife(Chef::Knife::NoderingsServerShow, ["nope"])
    expect { cmd.run }.to raise_error(SystemExit)
    expect(@stderr.string).to include("No NodeRings virtual machine is named nope")
  end

  it "lists regions, distros, plans and SSH keys" do
    @fake.ssh_keys["k1"] = { "id" => "k1", "name" => "laptop", "keyType" => "ed25519", "publicKey" => "x" }
    knife(Chef::Knife::NoderingsRegionList).run
    knife(Chef::Knife::NoderingsDistroList).run
    knife(Chef::Knife::NoderingsPlanList, ["--country", "United States", "--city", "Ashburn"]).run
    knife(Chef::Knife::NoderingsSshKeyList).run
    expect(@stdout.string).to include("Ashburn").and include("ubuntu_24_04").and include("SC-GC-1C-1G-20").and include("laptop")
    expect(@fake.calls.find { |c| c[1] == "/v1/marketplace/plans" }[2]).to include("filterCity" => "Ashburn")
  end

  it "needs a token" do
    Chef::Config[:knife].delete(:noderings_api_token)
    cmd = knife(Chef::Knife::NoderingsServerList)
    expect { cmd.run }.to raise_error(SystemExit)
    expect(@stderr.string).to include("token is required")
  end
end
