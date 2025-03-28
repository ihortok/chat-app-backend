require "sinatra"
require "sinatra/activerecord"
require "json"
require "dotenv/load"
require "sinatra/json"
require "sinatra/cross_origin"
require_relative "./models/user"
require_relative "./models/message"

configure do
  enable :cross_origin
end

before do
  content_type :json
  response.headers["Access-Control-Allow-Origin"] = "*"
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

post "/users" do
  data = JSON.parse(request.body.read)
  user = User.create(username: data["username"], email: data["email"])
  if user.persisted?
    status 201
    json user
  else
    status 422
    json error: user.errors.full_messages
  end
end

post "/messages" do
  data = JSON.parse(request.body.read)
  user = User.find_by(id: data["user_id"])

  if user
    message = user.messages.create(content: data["content"])
    if message.persisted?
      status 201
      json message
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
