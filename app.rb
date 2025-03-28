require "sinatra"
require "sinatra/activerecord"
require "json"
require "dotenv/load"
require "sinatra/json"
require "sinatra/cross_origin"
require "faye/websocket"
require_relative "./websocket_manager"
require_relative "./models/user"
require_relative "./models/message"

configure do
  enable :cross_origin
end

before do
  content_type :json
  response.headers["Access-Control-Allow-Origin"] = "*"
end

get "/ws" do
  if Faye::WebSocket.websocket?(env)
    ws = Faye::WebSocket.new(env)

    ws.on :open do
      WebSocketManager.instance.add(ws)
      puts "WebSocket opened (#{WebSocketManager.instance.count} connections)"
    end

    ws.on :close do
      WebSocketManager.instance.remove(ws)
      puts "WebSocket closed (#{WebSocketManager.instance.count} remaining)"
      ws = nil
    end

    ws.rack_response
  else
    status 400
    body "WebSocket connection expected"
  end
end

options "*" do
  response.headers["Allow"] = "GET, POST, OPTIONS"
  response.headers["Access-Control-Allow-Headers"] = "Content-Type"
  200
end

set :database_file, "config/database.yml"

get "/" do
  "Chat API is running!"
end

post "/signup" do
  data = JSON.parse(request.body.read)

  user = User.new(
    username: data["username"],
    email: data["email"],
    password: data["password"]
  )

  if user.save
    status 201
    json user
  else
    status 422
    json error: user.errors.full_messages
  end
end

post "/login" do
  data = JSON.parse(request.body.read)

  user = User.find_by(email: data["email"])

  if user && user.authenticate(data["password"])
    status 200
    json user
  else
    status 401
    json error: "Invalid email or password"
  end
end

post "/messages" do
  data = JSON.parse(request.body.read)
  user = User.find_by(id: data["user_id"])

  if user
    message = user.messages.create(content: data["content"])
    if message.persisted?
      # Broadcast to all connected clients
      payload = {
        id: message.id,
        content: message.content,
        user: {
          id: user.id,
          username: user.username
        },
        created_at: message.created_at
      }

      WebSocketManager.instance.broadcast(payload.to_json)

      status 201
      json payload
    else
      status 422
      json error: message.errors.full_messages
    end
  else
    status 404
    json error: "User not found"
  end
end

get "/messages" do
  messages = Message.includes(:user).order(created_at: :asc)
  json messages.map { |msg|
    {
      id: msg.id,
      content: msg.content,
      user: {
        id: msg.user.id,
        username: msg.user.username
      },
      created_at: msg.created_at
    }
  }
end
