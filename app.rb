require "sinatra"
require "sinatra/activerecord"
require "json"
require "dotenv/load"
require_relative "./models/user"
require_relative "./models/message"

set :database_file, "config/database.yml"

get "/" do
  "Chat API is running!"
end
