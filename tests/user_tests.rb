require File.expand_path '../test_helper.rb', __FILE__

class UserTest < MiniTest::Unit::TestCase
  include Rack::Test::Methods

  def app
    puts "App..."
    Sinatra::Application
  end

  def setup
  	puts "Setup..."
  end

  def test_env
  	puts "Start-Testing..."
  	puts GLOBAL
    get '/test/env'
    assert_equal 'test', last_response.body
  	puts "End-Testing..."
  end

def test_stories
	get '/stories'
	puts last_response.body
end

  def teardown
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