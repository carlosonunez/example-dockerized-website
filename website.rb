require 'sinatra'
require 'kramdown'

get '/' do
  markdown :index
end
