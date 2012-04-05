require 'puppet'
require 'puppet/network/http_pool'
require 'uri'
require 'string-irc'

Puppet::Reports.register_report(:ikachan) do
  def process
    configfile = File.join([File.dirname(Puppet.settings[:config]), "ikachan.yaml"])
    raise(Puppet::ParseError, "IRC report config file #{configfile} not readable") unless File.exist?(configfile)
    @config = YAML.load_file(configfile)

    return if self.status == "unchanged"

    message = StringIrc.new(sprintf "Puppet status: %s on %s [%s]", self.status, self.host, self.environment)
    if self.status == "changed"
      message.lime
    else
      message.pink
    end

    @config["channels"].each do |channel|
      channel.gsub!(/^\\/, '')
      Net::HTTP.start(@config["host"], @config["port"]) {|http|
        body = "channel=#{channel}"
        res = http.post('/join', body)

        body = "channel=#{channel}&message=#{message}"
        res = http.post('/notice', body)
      }
    end
  end
end

