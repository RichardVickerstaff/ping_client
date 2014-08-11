require 'socket'
require 'benchmark'
require 'rest_client'

Site = Struct.new :url, :success, :response_ms do
  def to_json *_
    JSON.generate to_h
  end
end

def log message=""
  $stderr.puts message
end

def get_sites_to_poll server
  site_source = server + '/sites/sample'
  log "Acquiring sites to poll from #{site_source}"
  response = JSON.parse(RestClient.get site_source)
  log "  <- #{response}"
  response['sites'].map{|url| Site.new(url)}
end

def poll site
  log "  -> #{site.url}"
  begin
    response_seconds = Benchmark.realtime{ RestClient.head site.url }
    site.response_ms = (response_seconds * 1000).round
    site.success = true
    log "  <- response: #{site.response_ms} ms"
  rescue => e
    site.success = false
    log "  !! Failed: #{e}"
  end
  site
end

server = ARGV[0] || 'localhost:3000'

log "Probe activated"
sample_sites = get_sites_to_poll(server)

log "Probing sites"
pings = sample_sites.map { |site| poll site }

log "Notifying server"
probe_response = JSON.pretty_generate({pings: pings})
log "  -> #{probe_response}"

RestClient.post(server + '/pings', probe_response )

log "All done!"
