require 'rest_client'
require 'benchmark'

def response_time site
  begin
    Benchmark.realtime{ RestClient.head site }
  rescue => e
    $stderr.puts "!! Polling #{site} failed with error #{e}"
    -1
  end
end

def get_sites_to_poll reporting_server
  JSON.parse(RestClient.get reporting_server + '/sites')
end

def poll site
  $stderr.puts "  -> #{site}"
  response_time site
end

name = ARGV[0]
reporting_server = ARGV[1] || 'localhost:4567'
$stderr.puts "Probe time!"

sample_sites = get_sites_to_poll(reporting_server)

times = sample_sites.each_with_object({}) do |(group, sites), result|
  next if sites.empty?
  $stderr.puts "  #{group.capitalize}"
  result[group] = sites.map{|site| poll site}
end

puts JSON.pretty_generate times
RestClient.post(reporting_server + '/pings', {  name: name, pings: JSON.generate(times) })
