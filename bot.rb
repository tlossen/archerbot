require 'snmp'
require 'net/http'
require 'yaml'

GATEWAY_IP = "192.168.1.1"
PUBLIC_IP = SNMP::ObjectId.new("1.3.6.1.2.1.4.20.1")

CONFIG = YAML.load_file("noip.yaml")

def public_ip
  SNMP::Manager.new(host: GATEWAY_IP)
    .get_next(PUBLIC_IP)
    .varbind_list[0].value.to_s
end

def update_noip(ip)
  uri = URI.parse("http://dynupdate.no-ip.com/nic/update?hostname=#{CONFIG['host']}&myip=#{ip}")
  http = Net::HTTP.new(uri.host, uri.port)
  req = Net::HTTP::Get.new(uri.request_uri, "UserAgent" => "TP-Link MR400/0.1 #{CONFIG['user']}")
  req.basic_auth(CONFIG['user'], CONFIG['pass'])
  res = http.start {|h| h.request(req) }
  res.body
end

last_ip = nil
last_time = 0
while true 
  current_ip = public_ip
  current_time = Time.now.to_i
  if (current_ip != last_ip) or (current_time - last_time > 3600)
    puts "#{Time.now} -- #{update_noip(current_ip)}"
    last_ip = current_ip
    last_time = current_time
  end
  sleep(60)
end

