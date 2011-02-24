$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), 'lib'))

require 'app'
require 'em-websocket'
require 'evented_redis'
require 'thin'

EventMachine.run do
  @channel = EM::Channel.new

  redis = EventedRedis.connect
  redis.subscribe('resque:publisher') do |type, channel, message|
    @channel.push message
  end

  EventMachine::WebSocket.start(:host => '0.0.0.0', :port => 8080) do |ws|
    ws.onopen do
      sid = @channel.subscribe { |msg|  ws.send msg }

      ws.onclose do
        @channel.unsubscribe(sid)
      end
    end
  end

  Resque::Server.run!({:port => 5679})
end
