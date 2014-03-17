ENV['RACK_ENV'] = 'test'

require 'minitest/autorun'
require 'rack/test'
require '../homage_server_app'

GLOBAL = "nir"