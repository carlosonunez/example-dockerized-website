require 'sinatra'
require 'kramdown'

configure do
  set :bind, '0.0.0.0'
  set :port, 8080
  enable :dump_errors
end

get '/' do
  erb :index
end
