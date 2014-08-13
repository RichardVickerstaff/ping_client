#!/usr/bin/env ruby

require_relative 'common'
include ProbeCommon

$server = ARGV[0] || default_server

log "Getting my global IP"
ip_address = RestClient.get 'http://whatismyip.akamai.com'
log "My IP is #{ip_address}"

registration_url = $server + "/probes/#{probe_uid}"
payload = JSON.pretty_generate(probe: { ip: ip_address , location: 'adhara'})

log "Registering with server at #{registration_url}"
log "  -> #{payload}"
RestClient.put(registration_url, payload, content_type: :json)
