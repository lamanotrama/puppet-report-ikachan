require 'puppet'
require 'puppet/network/http_pool'
require 'uri'
require 'string-irc'

Puppet::Reports.register_report(:ikachan) do
  def process
    configfile = File.join([File.dirname(Puppet.settings[:config]), "ikachan.yaml"])
    raise(Puppet::ParseError, "IRC report config file #{configfile} not readable") unless File.exist?(configfile)
    @config = YAML.load_file(configfile)
    @config["channels"].each do |channel|
      channel.gsub!(/^\\/, '')
      Net::HTTP.start(@config["host"], @config["port"]) {|http|
        body = "channel=#{channel}"
        res = http.post('/join', body)
        self.logs.each do |log|
          message = sprintf "%s %s %s: %s", self.host, log.source, log.level, log.message
          if log.level == :err
            message = StringIrc.new(message)
            message.pink
          end
          body = "channel=#{channel}&message=#{message}"
          res = http.post('/notice', body)
        end
      }
    end
  end
end

