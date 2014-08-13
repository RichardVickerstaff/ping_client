#!/usr/bin/env ruby

require 'benchmark'
require_relative 'common'
include ProbeCommon

Site = Struct.new :url, :success, :response_ms do
  def to_json *_
    initialised_values = to_h.reject{|_,v| v.nil?}
    JSON.generate( initialised_values )
  end
end

def server_site_list_url
  $server + "/sites/sample"
end

def server_report_url
  $server + "/probes/#{probe_uid}/runs"
end

def sites_to_poll
  log "Acquiring sites to poll from #{server_site_list_url}"
  response = JSON.parse(RestClient.get server_site_list_url)
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

def upload_results(pings)
  log "Posting results to #{server_report_url}"
  probe_response = JSON.pretty_generate({pings: pings})
  log "  -> #{probe_response}"
  RestClient.post(server_report_url, probe_response)
end

#####################################################
################ BEGIN MAIN SCRIPT ##################
#####################################################

$server = ARGV[0] || default_server

log "Probe activated"
sample_sites = sites_to_poll

log "Probing sites"
pings = sample_sites.map { |site| poll site }

log "Probing complete, reporting to server"
upload_results(pings)

log "All done!"
