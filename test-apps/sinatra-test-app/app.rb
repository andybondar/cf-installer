require 'rubygems'
require 'sinatra'

get '/' do
  host = ENV['VCAP_APP_HOST']
  port = ENV['VCAP_APP_PORT']
  <<-EOS
  <h3>Sinatra Test app for CF Vagrant Installer</h3>
      Hello from #{host}:#{port}! <br/>
  EOS
end
