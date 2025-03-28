require "sinatra"
require "sinatra/activerecord"
require "json"
require "dotenv/load"

set :database_file, "config/database.yml"

get "/" do
  "Chat API is running!"
end
