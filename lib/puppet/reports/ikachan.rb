require 'puppet'
require 'puppet/network/http_pool'
require 'uri'

Puppet::Reports.register_report(:ikachan) do
  def process
    configfile = File.join([File.dirname(Puppet.settings[:config]), "ikachan.yaml"])
    raise(Puppet::ParseError, "IRC report config file #{configfile} not readable") unless File.exist?(configfile)
    @config = YAML.load_file(configfile)

    host = @config["host"]
    port = @config["port"]

    @config["channels"].each do |channel|
      channel.gsub!(/^\\/, '')
      Net::HTTP.start(host, port) {|http|
        body = "channel=#{channel}"
        res = http.post('/join', body)
      }

      Net::HTTP.start(host, port) {|http|
        self.logs.each do |log|
          message = sprintf "%s %s %s: %s", self.host, log.source, log.level, log.message
          body = "channel=#{channel}&message=#{message}"
          res = http.post('/notice', body)
        end
      }
    end
  end
end

