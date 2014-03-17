ENV['RACK_ENV'] = 'test'

require '../homage_server_app'
require 'test/unit'
require 'rack/test'

class UserTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    puts "App..."
    Sinatra::Application
  end

  def setup
  	super
  	puts "Setup..."
  end

  def test_env
  	puts "Start-Testing..."
    get '/test/env'
    assert_equal 'test', last_response.body
  	puts "End-Testing..."
  end

  def teardown
  	super
  	puts "Tearing-down..."
  end

  # def test_with_params
  #   get '/meet', :name => 'Frank'
  #   assert_equal 'Hello Frank!', last_response.body
  # end

  # def test_with_rack_env
  #   get '/', {}, 'HTTP_USER_AGENT' => 'Songbird'
  #   assert_equal "You're using Songbird!", last_response.body
  # end
end