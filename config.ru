require_relative 'app'

use Rack::Deflater, include: ['text/html']

if ENV['RACK_ENV'] == 'production'
  run App
else
  use Rack::Reloader, 0
  run ->(env){ App[env] }
end
