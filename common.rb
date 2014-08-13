module ProbeCommon
  require 'rest-client'
  require 'macaddr'

  def default_server
    'localhost:3000'
  end
  def probe_uid
    Mac.addr.gsub(/:/, '')
  end

  def log message=""
    $stderr.puts message
  end

end
