require "singleton"

class WebSocketManager
  include Singleton

  def initialize
    @connections = []
  end

  def add(ws)
    @connections << ws
  end

  def remove(ws)
    @connections.delete(ws)
  end

  def broadcast(message)
    @connections.each do |conn|
      conn.send(message)
    end
  end

  def count
    @connections.size
  end
end
