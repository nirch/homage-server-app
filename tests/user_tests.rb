require File.expand_path '../test_helper.rb', __FILE__

module BSON
      class ObjectId

        def converted_to_s
          @data.map {|e| v=e.to_s(16); v.size == 1 ? "0#{v}" : v }.join
        end

        # Monkey patching to_json so it will return
        # ObjectId as json and not as a simple string containg the oid
        def to_json(*a)
          "{\"$oid\": \"#{converted_to_s}\"}"
        end

        # Monkey patching as_json so it will return
        # ObjectId as json and not as a simple string containg the oid
        def as_json(options ={})
          {"$oid" => converted_to_s}
        end

        def to_s
            {"$oid" => converted_to_s}.to_s
        end

      end
  end


class UserTest < MiniTest::Unit::TestCase
	include Rack::Test::Methods

  USERS = DB.collection("Users")
  REMAKES = DB.collection("Remakes")


  GUEST_USER =  {  :is_public => "NO", 
                   :device => {:identifier_for_vendor => "3DACF253-C0B7-4F4C-843E-435A43699715", :name => "Nir's iPhone", :system_name => "iPhone", :system_version => "7.1", :model => "5s" , :push_token => "<09377d71 ddffb776 6d5e8d08 6e649cd9 b50497f2 cba5281f b80a5fed a912b748>" } 
                }

  GUEST_USER_MONKEY =  {  :is_public => "NO", 
                    :campaign_id => BSON::ObjectId.from_string("54919516454c61f4080000e5"),
                   :device => {:identifier_for_vendor => "3DACF253-C0B7-4F4C-843E-435A43699715", :name => "Nir's iPhone", :system_name => "iPhone", :system_version => "7.1", :model => "5s" }
                }


  FACEBOOK_USER = { :email => "unit_facebook@test.com",
                    :is_public => "YES", 
                    :device => { :identifier_for_vendor => "3DACF253-C0B7-4F4C-843E-435A43612084", :name => "Nir's iPhone", :system_name => "iPhone", :system_version => "7.1", :model => "5s" }, 
                    :facebook => { :id => "929292929299", :name => "Bla Bla", :first_name => "Nir" }
                  }

  FACEBOOK_USER_MONKEY = { :email => "unit_facebook@test.com",
                    :campaign_id => BSON::ObjectId.from_string("54919516454c61f4080000e5"),
                    :is_public => "YES", 
                    :device => { :identifier_for_vendor => "3DACF253-C0B7-4F4C-843E-435A43612084", :name => "Nir's iPhone", :system_name => "iPhone", :system_version => "7.1", :model => "5s" }, 
                    :facebook => { :id => "929292929299", :name => "Bla Bla", :first_name => "Nir" }
                  }


  EMAIL_USER = {  :email => "unit_email@test.com",
                  :password => "qwerty123",
                  :is_public => "YES", 
                  :device => { :identifier_for_vendor => "3DACF253-C0B7-4F4C-843E-435A436A1932", :name => "Nir's iPhone", :system_name => "iPhone", :system_version => "7.1", :model => "5s" }, 
                }

  EMAIL_USER_MONKEY = {  :email => "unit_email@test.com",
                    :campaign_id => BSON::ObjectId.from_string("54919516454c61f4080000e5"),
                  :password => "qwerty123",
                  :is_public => "YES", 
                  :device => { :identifier_for_vendor => "3DACF253-C0B7-4F4C-843E-435A436A1932", :name => "Nir's iPhone", :system_name => "iPhone", :system_version => "7.1", :model => "5s" }, 
                }

  GUEST_ANDROID_USER =  {  :is_public => "YES", 
                   :device => {:device_id => "ff54-c06c-c2d2-b84a", :name => "Nir's Nexus", :system_name => "Android", :system_version => "4.4", :model => "5", :android_push_token => "APA91bE4MZmyhKWNiYyecfa8r0cHzai6KGv_LJTz59mdWlCFUQ_Y6fIu9U3V0myH7yfKWL3qr_ru8f4xkThOVsTtbbaSFwiZpBryF6zy9At4h3Q7ySQQEbKQMfH1PXYzJwm_HykxTltsHZDaykGNZj5c6Fv3TFKtyw"} 
                }

  FACEBOOK_ANDROID_USER = { :email => "unit_facebook@test.com",
                    :is_public => "YES", 
                    :device => { :identifier_for_vendor => "3DACF253-C0B7-4F4C-843E-435A43612084", :name => "Nir's iPhone", :system_name => "iPhone", :system_version => "7.1", :model => "5s" }, 
                    :facebook => { :id => "929292929299", :name => "Bla Bla", :first_name => "Nir" }
                  }

    PUBLIC_USER = {  :is_public => "YES", 
                   :device => {:identifier_for_vendor => "3DACF253-C0B7-4F4C-843E-435A43699715", :name => "Nir's iPhone", :system_name => "iPhone", :system_version => "7.1", :model => "5s" } 
                }

    PRIVATE_USER = {  :is_public => "NO", 
                   :device => {:identifier_for_vendor => "3DACF253-C0B7-4F4C-843E-435A43699715", :name => "Nir's iPhone", :system_name => "iPhone", :system_version => "7.1", :model => "5s" } 
                }


	def app
		Sinatra::Application
	end

	def setup
    @delete_user = nil
  end

  def test_update_user_public_true
    put '/user/old', { :user_id => "nir@homage.it", :is_public => "YES" }
    json_response = JSON.parse(last_response.body)
    assert_equal "nir@homage.it", json_response["_id"]
    assert_equal true, json_response["is_public"]
  end

  def test_update_user_public_false
    put '/user/old', { :user_id => "nir@homage.it", :is_public => "NO" }
    json_response = JSON.parse(last_response.body)
    assert_equal "nir@homage.it", json_response["_id"]
    assert_equal false, json_response["is_public"]
  end

  def test_create_user_guest
    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal false, json_response["is_public"]
    assert json_response["devices"]
    assert_nil json_response["facebook"]

    user = USERS.find_one(user_id)
    assert user["campaign_id"]
    assert user

    # deleting the user
    USERS.remove({_id: user_id})
    user = USERS.find_one(user_id)
    assert_nil user
  end

  def test_create_user_facebook_new
    post '/user', FACEBOOK_USER

    # checking the response
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal true, json_response["is_public"]
    assert json_response["devices"]
    assert json_response["facebook"]

    # checking that the user exists in the DB
    user = USERS.find_one(user_id)
    assert user["campaign_id"]
    assert user

    # deleting the user
    USERS.remove({_id: user_id})
    user = USERS.find_one(user_id)
    assert_nil user
  end

  def test_create_user_facebook_login  
    post '/user', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    new_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    login_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    # checking that that the new user and the loged-in user both have the same user id
    assert_equal new_user_id, login_user_id

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: login_user_id})
    user = USERS.find_one(login_user_id)
    assert_nil user
    user = USERS.find_one(new_user_id)
    assert_nil user
  end

  def test_create_user_password_new
    post '/user', EMAIL_USER

    # checking the response
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal true, json_response["is_public"]
    assert json_response["devices"]
    assert_equal "unit_email@test.com", json_response["email"]
    assert json_response["password_hash"]
    assert_nil json_response["password"]

    # checking that the user exists in the DB
    user = USERS.find_one(user_id)
    assert user
    assert_equal true, user["is_public"]
    assert user["campaign_id"]
    assert user["devices"]
    assert_equal "unit_email@test.com", user["email"]
    assert user["password_hash"]
    assert_nil user["password"]

    # deleting the user
    USERS.remove({_id: user_id})
    user = USERS.find_one(user_id)
    assert_nil user
  end

  def test_create_user_password_login_successful
    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    new_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    login_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    # checking that that the new user and the loged-in user both have the same user id
    assert_equal new_user_id, login_user_id

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: login_user_id})
    user = USERS.find_one(login_user_id)
    assert_nil user
    user = USERS.find_one(new_user_id)
    assert_nil user
  end

  def test_create_user_password_login_401
    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    new_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    wrong_password_user = EMAIL_USER.clone
    wrong_password_user[:password] = "123qwerty"
    post '/user', wrong_password_user

    assert_equal 401, last_response.status
    json_response = JSON.parse(last_response.body)
    assert_equal 1001, json_response["error_code"]

    USERS.remove({_id: new_user_id})
    user = USERS.find_one(new_user_id)
    assert_nil user
  end

  def test_reset_password
    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    new_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    # user has password
    user = USERS.find_one(new_user_id)
    assert user["password_hash"]

    # delete password
    USERS.update({_id: new_user_id}, {"$unset" => {password_hash: ""}})
    user = USERS.find_one(new_user_id)
    assert_nil user["password_hash"]

    # new password
    new_password_user = EMAIL_USER.clone
    new_password_user[:password] = "newPassword"
    post '/user', new_password_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    new_password_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    # checking that that the new user and the loged-in user both have the same user id
    assert_equal new_user_id, new_password_id

    USERS.remove({_id: new_user_id})
    user = USERS.find_one(new_user_id)
    assert_nil user
  end

  def test_user_types
    assert_equal UserType::GuestUser, user_type(GUEST_USER.to_json)
    assert_equal UserType::FacebookUser, user_type(FACEBOOK_USER.to_json)    
    assert_equal UserType::EmailUser, user_type(EMAIL_USER.to_json)
  end

  # def test_facebook_login_update_info
  # end

  # def test_update_user_not_exist
  # end

  def test_guest_to_facebook
    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::GuestUser, user_type(json_response)

    guest_to_facebook_user = FACEBOOK_USER.clone
    guest_to_facebook_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_facebook_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::FacebookUser, user_type(json_response)

    assert_equal guest_user_id, facebook_user_id

    # checking that the user exists in the DB
    user = USERS.find_one(facebook_user_id)
    assert user
    assert user["facebook"]

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: guest_user_id})
    user = USERS.find_one(guest_user_id)
    assert_nil user
    user = USERS.find_one(facebook_user_id)
    assert_nil user
  end

  def test_guest_user_with_remake_no_fullname
    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::GuestUser, user_type(json_response)

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => guest_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_nil remake["user_fullname"]

    # deleting the user
    USERS.remove({_id: guest_user_id})
    user = USERS.find_one(guest_user_id)
    assert_nil user    
  end

  def test_facebook_user_with_remake_and_fullname
    post '/user', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::FacebookUser, user_type(json_response)

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => facebook_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_equal "Bla Bla", remake["user_fullname"]

    # deleting the user
    USERS.remove({_id: facebook_user_id})
    user = USERS.find_one(facebook_user_id)
    assert_nil user    
  end

  def test_email_user_with_remake_and_fullname
    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::EmailUser, user_type(json_response)

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => email_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_equal "Unit Email", remake["user_fullname"]

    # deleting the user
    USERS.remove({_id: email_user_id})
    user = USERS.find_one(email_user_id)
    assert_nil user    
  end


  def test_guest_to_email_with_remake_check_fullname
    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::GuestUser, user_type(json_response)

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => guest_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_nil remake["user_fullname"]

    # Guest to email
    guest_to_email_user = EMAIL_USER.clone
    guest_to_email_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_email_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::EmailUser, user_type(json_response)

    assert_equal guest_user_id, email_user_id

    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_equal "Unit Email", remake["user_fullname"]

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: guest_user_id})
    user = USERS.find_one(guest_user_id)
    assert_nil user
    user = USERS.find_one(email_user_id)
    assert_nil user       
  end


  def test_guest_to_facebook_with_remake_check_fullname
    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::GuestUser, user_type(json_response)

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => guest_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_nil remake["user_fullname"]

    # Guest to facebook
    guest_to_facebook_user = FACEBOOK_USER.clone
    guest_to_facebook_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_facebook_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::FacebookUser, user_type(json_response)

    assert_equal guest_user_id, facebook_user_id

    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_equal "Bla Bla", remake["user_fullname"]

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: guest_user_id})
    user = USERS.find_one(guest_user_id)
    assert_nil user
    user = USERS.find_one(facebook_user_id)
    assert_nil user       
  end

  def test_guest_to_facebook_with_remake_check_privacy
    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    assert_equal false, json_response["is_public"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::GuestUser, user_type(json_response)

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => guest_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_nil remake["user_fullname"]
    assert_equal false, remake["is_public"]

    # Guest to facebook
    guest_to_facebook_user = FACEBOOK_USER.clone
    guest_to_facebook_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_facebook_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    assert_equal true, json_response["is_public"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::FacebookUser, user_type(json_response)

    assert_equal guest_user_id, facebook_user_id

    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_equal "Bla Bla", remake["user_fullname"]
    assert_equal true, remake["is_public"]

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: guest_user_id})
    user = USERS.find_one(guest_user_id)
    assert_nil user
    user = USERS.find_one(facebook_user_id)
    assert_nil user       
  end

  def test_guest_to_email_with_remake_check_privacy
    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    assert_equal false, json_response["is_public"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::GuestUser, user_type(json_response)

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => guest_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_nil remake["user_fullname"]
    assert_equal false, remake["is_public"]

    # Guest to email
    guest_to_email_user = EMAIL_USER.clone
    guest_to_email_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_email_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    assert_equal true, json_response["is_public"]
    email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::EmailUser, user_type(json_response)

    assert_equal guest_user_id, email_user_id

    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_equal "Unit Email", remake["user_fullname"]
    assert_equal true, remake["is_public"]

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: guest_user_id})
    user = USERS.find_one(guest_user_id)
    assert_nil user
    user = USERS.find_one(email_user_id)
    assert_nil user       
  end


  # There is an existing facebook user in the DB. A new guest user upgrades to the same existing facebook user => the guest user should merge into the existing facebook user
  def test_guest_to_existing_facebook
    post '/user', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    guest_to_facebook_user = FACEBOOK_USER.clone
    guest_to_facebook_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_facebook_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_to_facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal facebook_user_id, guest_to_facebook_user_id

    # Guest user should already be deleted
    user = USERS.find_one(guest_user_id)
    assert_nil user

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: facebook_user_id})
    user = USERS.find_one(facebook_user_id)
    assert_nil user
    user = USERS.find_one(guest_to_facebook_user_id)
    assert_nil user
  end

  # There is an existing facebook user in the DB. A new guest user upgrades to the same existing facebook user => the guest user should merge into the existing facebook user
  def test_guest_to_existing_facebook_other_campaign
    post '/user', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user', GUEST_USER_MONKEY

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    guest_to_facebook_user = FACEBOOK_USER_MONKEY.clone
    guest_to_facebook_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_facebook_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_to_facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert facebook_user_id != guest_to_facebook_user_id

    # Guest user should exist and should be facebook
    user = USERS.find_one(guest_user_id)
    assert user
    assert user["facebook"]

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: facebook_user_id})
    user = USERS.find_one(facebook_user_id)
    assert_nil user
    user = USERS.find_one(guest_to_facebook_user_id)
    assert user
    USERS.remove({_id: guest_to_facebook_user_id})
    user = USERS.find_one(guest_to_facebook_user_id)
    assert_nil user
  end



  def test_guest_to_password
    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::GuestUser, user_type(json_response)

    guest_to_email_user = EMAIL_USER.clone
    guest_to_email_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_email_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::EmailUser, user_type(json_response)

    assert_equal guest_user_id, email_user_id

    # checking that the user exists in the DB
    user = USERS.find_one(email_user_id)
    assert user
    assert user["email"]
    assert user["password_hash"]
    assert_nil user["password"]

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: guest_user_id})
    user = USERS.find_one(guest_user_id)
    assert_nil user
    user = USERS.find_one(email_user_id)
    assert_nil user    
  end

  # There is an existing email user in the DB. A new guest user upgrades to the same existing facebook user => the guest user should merge into the existing facebook user
  def test_guest_to_existing_passoword_success
    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    guest_to_email_user = EMAIL_USER.clone
    guest_to_email_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_email_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_to_email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal email_user_id, guest_to_email_user_id

    # Guest user should already be deleted
    user = USERS.find_one(guest_user_id)
    assert_nil user

    # deleting the user, and checking that both ids (which is the same id) doesn't exist in the DB
    USERS.remove({_id: email_user_id})
    user = USERS.find_one(email_user_id)
    assert_nil user
    user = USERS.find_one(guest_to_email_user_id)
    assert_nil user
  end

  def test_guest_to_existing_passoword_401
    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    guest_to_email_user_401 = EMAIL_USER.clone
    guest_to_email_user_401[:user_id] = guest_user_id.to_s
    guest_to_email_user_401[:password] = "123qwerty"
    put '/user', guest_to_email_user_401

    assert_equal 401, last_response.status
    json_response = JSON.parse(last_response.body)
    assert_equal 1001, json_response["error_code"]

    USERS.remove({_id: email_user_id})
    user = USERS.find_one(email_user_id)
    assert_nil user
    user = USERS.find_one(guest_user_id)
    assert user
    USERS.remove({_id: guest_user_id})
    user = USERS.find_one(guest_user_id)
    assert_nil user
  end

  def test_guest_to_existing_passoword_other_campaign
    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user', GUEST_USER_MONKEY

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    guest_to_email_user = EMAIL_USER_MONKEY.clone
    guest_to_email_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_email_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_to_email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert email_user_id != guest_to_email_user_id

    # Guest user should exists and should have a mail
    user = USERS.find_one(guest_user_id)
    assert user
    assert user["email"]

    # deleting the user, and checking that both ids (which is the same id) doesn't exist in the DB
    USERS.remove({_id: email_user_id})
    user = USERS.find_one(email_user_id)
    assert_nil user
    user = USERS.find_one(guest_to_email_user_id)
    assert user
    USERS.remove({_id: guest_to_email_user_id})
    user = USERS.find_one(guest_to_email_user_id)
    assert_nil user
  end


  def test_facebook_to_password
    post '/user', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    new_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    facebook_to_email_user = EMAIL_USER.clone
    facebook_to_email_user[:email] = FACEBOOK_USER[:email]
    post '/user', facebook_to_email_user

    assert_equal 403, last_response.status
    json_response = JSON.parse(last_response.body)
    assert_equal ErrorCodes::FacebookToEmailForbidden, json_response["error_code"]

    USERS.remove({_id: new_user_id})
    user = USERS.find_one(new_user_id)
    assert_nil user
  end

  def test_password_to_facebook
    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::EmailUser, user_type(json_response)

    email_to_facebook_user = FACEBOOK_USER.clone
    email_to_facebook_user[:email] = EMAIL_USER[:email]
    post '/user', email_to_facebook_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::FacebookUser, user_type(json_response)

    assert_equal email_user_id, facebook_user_id

    # checking that the user exists in the DB
    user = USERS.find_one(facebook_user_id)
    assert user
    assert user["facebook"]
    assert_nil user["password"]

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: email_user_id})
    user = USERS.find_one(email_user_id)
    assert_nil user
    user = USERS.find_one(facebook_user_id)
    assert_nil user    
  end


  def test_password_to_facebook_with_remake_and_fullname
    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::EmailUser, user_type(json_response)

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => email_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_equal "Unit Email", remake["user_fullname"]

    email_to_facebook_user = FACEBOOK_USER.clone
    email_to_facebook_user[:email] = EMAIL_USER[:email]
    post '/user', email_to_facebook_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::FacebookUser, user_type(json_response)

    assert_equal email_user_id, facebook_user_id

    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_equal "Bla Bla", remake["user_fullname"]

    # checking that the user exists in the DB
    user = USERS.find_one(facebook_user_id)
    assert user
    assert user["facebook"]
    assert_nil user["password"]

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: email_user_id})
    user = USERS.find_one(email_user_id)
    assert_nil user
    user = USERS.find_one(facebook_user_id)
    assert_nil user    
  end

  def test_password_to_facebook_with_remake_and_privacy
    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    assert_equal true, json_response["is_public"]
    email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::EmailUser, user_type(json_response)

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => email_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_equal "Unit Email", remake["user_fullname"]
    assert_equal true, remake["is_public"]

    email_to_facebook_user = FACEBOOK_USER.clone
    email_to_facebook_user[:email] = EMAIL_USER[:email]
    post '/user', email_to_facebook_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    assert_equal true, json_response["is_public"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    assert_equal UserType::FacebookUser, user_type(json_response)

    assert_equal email_user_id, facebook_user_id

    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_equal "Bla Bla", remake["user_fullname"]
    assert_equal true, remake["is_public"]

    # checking that the user exists in the DB
    user = USERS.find_one(facebook_user_id)
    assert user
    assert user["facebook"]
    assert_nil user["password"]

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: email_user_id})
    user = USERS.find_one(email_user_id)
    assert_nil user
    user = USERS.find_one(facebook_user_id)
    assert_nil user    
  end

  def test_add_devices
    post '/user', GUEST_USER

    guest_user_1 = JSON.parse(last_response.body)
    assert guest_user_1["_id"]["$oid"]
    guest_user_id_1 = BSON::ObjectId.from_string(guest_user_1["_id"]["$oid"])

    guest_user_another_device = GUEST_USER.clone
    guest_user_another_device[:device][:identifier_for_vendor] = "3DACF253-C0B7-4F4C-843E-435A436AAA12"
    post '/user', guest_user_another_device

    guest_user_2 = JSON.parse(last_response.body)
    assert guest_user_2["_id"]["$oid"]
    guest_user_id_2 = BSON::ObjectId.from_string(guest_user_2["_id"]["$oid"])

    add_devices(USERS, guest_user_1, guest_user_2, guest_user_id_2)

    guest_user_1 = USERS.find_one(guest_user_id_1)
    guest_user_2 = USERS.find_one(guest_user_id_2)
    assert_equal 1, guest_user_1["devices"].count
    assert_equal 2, guest_user_2["devices"].count

    USERS.remove({_id: guest_user_id_1})
    user = USERS.find_one(guest_user_id_1)
    assert_nil user
    USERS.remove({_id: guest_user_id_2})
    user = USERS.find_one(guest_user_id_2)
    assert_nil user
  end

  def test_add_devices_same_device
    post '/user', GUEST_USER

    guest_user_1 = JSON.parse(last_response.body)
    assert guest_user_1["_id"]["$oid"]
    guest_user_id_1 = BSON::ObjectId.from_string(guest_user_1["_id"]["$oid"])

    post '/user', GUEST_USER

    guest_user_2 = JSON.parse(last_response.body)
    assert guest_user_2["_id"]["$oid"]
    guest_user_id_2 = BSON::ObjectId.from_string(guest_user_2["_id"]["$oid"])

    add_devices(USERS, guest_user_1, guest_user_2, guest_user_id_2)

    guest_user_1 = USERS.find_one(guest_user_id_1)
    guest_user_2 = USERS.find_one(guest_user_id_2)
    assert_equal 1, guest_user_1["devices"].count
    assert_equal 1, guest_user_2["devices"].count

    USERS.remove({_id: guest_user_id_1})
    user = USERS.find_one(guest_user_id_1)
    assert_nil user
    USERS.remove({_id: guest_user_id_2})
    user = USERS.find_one(guest_user_id_2)
    assert_nil user
  end

  def test_add_devices_3
    post '/user', GUEST_USER

    guest_user_1 = JSON.parse(last_response.body)
    assert guest_user_1["_id"]["$oid"]
    guest_user_id_1 = BSON::ObjectId.from_string(guest_user_1["_id"]["$oid"])

    guest_user_another_device = GUEST_USER.clone
    guest_user_another_device[:device][:identifier_for_vendor] = "3DACF253-C0B7-4F4C-843E-435A436CCC12"
    post '/user', guest_user_another_device

    guest_user_2 = JSON.parse(last_response.body)
    assert guest_user_2["_id"]["$oid"]
    guest_user_id_2 = BSON::ObjectId.from_string(guest_user_2["_id"]["$oid"])

    add_devices(USERS, guest_user_1, guest_user_2, guest_user_id_2)

    guest_user_1 = USERS.find_one(guest_user_id_1)
    guest_user_2 = USERS.find_one(guest_user_id_2)
    assert_equal 1, guest_user_1["devices"].count
    assert_equal 2, guest_user_2["devices"].count

    guest_user_another_device = GUEST_USER.clone
    guest_user_another_device[:device][:identifier_for_vendor] = "3DACF253-C0B7-4F4C-843E-435A436BBB12"
    post '/user', guest_user_another_device

    guest_user_3 = JSON.parse(last_response.body)
    assert guest_user_3["_id"]["$oid"]
    guest_user_id_3 = BSON::ObjectId.from_string(guest_user_3["_id"]["$oid"])

    add_devices(USERS, guest_user_2, guest_user_3, guest_user_id_3)

    guest_user_2 = USERS.find_one(guest_user_id_2)
    guest_user_3 = USERS.find_one(guest_user_id_3)
    assert_equal 2, guest_user_2["devices"].count
    assert_equal 3, guest_user_3["devices"].count

    USERS.remove({_id: guest_user_id_1})
    user = USERS.find_one(guest_user_id_1)
    assert_nil user
    USERS.remove({_id: guest_user_id_2})
    user = USERS.find_one(guest_user_id_2)
    assert_nil user
    USERS.remove({_id: guest_user_id_3})
    user = USERS.find_one(guest_user_id_3)
    assert_nil user
  end

  def test_add_device_facebook
    post '/user', FACEBOOK_USER

    facebook_user_1 = JSON.parse(last_response.body)
    assert facebook_user_1["_id"]["$oid"]
    facebook_user_1_id = BSON::ObjectId.from_string(facebook_user_1["_id"]["$oid"])

    facebook_user_another_device = FACEBOOK_USER.clone
    facebook_user_another_device[:device][:identifier_for_vendor] = "3DACF253-C0B7-4F4C-843E-435A436AAA12"
    post '/user', facebook_user_another_device

    facebook_user_2 = JSON.parse(last_response.body)
    assert facebook_user_2["_id"]["$oid"]
    facebook_user_2_id = BSON::ObjectId.from_string(facebook_user_2["_id"]["$oid"])

    # checking that that the new user and the loged-in user both have the same user id
    assert_equal facebook_user_1_id, facebook_user_2_id

    user = USERS.find_one(facebook_user_1_id)
    assert_equal 2, user["devices"].count

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: facebook_user_1_id})
    user = USERS.find_one(facebook_user_1_id)
    assert_nil user
    user = USERS.find_one(facebook_user_2_id)
    assert_nil user
  end

  def test_add_device_password
    post '/user', EMAIL_USER

    email_user_1 = JSON.parse(last_response.body)
    assert email_user_1["_id"]["$oid"]
    email_user_1_id = BSON::ObjectId.from_string(email_user_1["_id"]["$oid"])

    email_user_another_device = EMAIL_USER.clone
    email_user_another_device[:device][:identifier_for_vendor] = "3DACF253-C0B7-4F4C-843E-435A436AAA12"
    post '/user', email_user_another_device

    email_user_2 = JSON.parse(last_response.body)
    assert email_user_2["_id"]["$oid"]
    email_user_2_id = BSON::ObjectId.from_string(email_user_2["_id"]["$oid"])

    # checking that that the new user and the loged-in user both have the same user id
    assert_equal email_user_1_id, email_user_2_id

    user = USERS.find_one(email_user_1_id)
    assert_equal 2, user["devices"].count

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: email_user_1_id})
    user = USERS.find_one(email_user_1_id)
    assert_nil user
    user = USERS.find_one(email_user_2_id)
    assert_nil user  
  end

  def test_add_device_facebook_from_guest
    post '/user', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    guest_to_facebook_user = FACEBOOK_USER.clone
    guest_to_facebook_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_facebook_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_to_facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal facebook_user_id, guest_to_facebook_user_id

    # Guest user should already be deleted
    user = USERS.find_one(guest_user_id)
    assert_nil user

    user = USERS.find_one(facebook_user_id)
    assert_equal 2, user["devices"].count

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: facebook_user_id})
    user = USERS.find_one(facebook_user_id)
    assert_nil user
    user = USERS.find_one(guest_to_facebook_user_id)
    assert_nil user
  end

  def test_add_device_facebook_from_guest_android
    post '/user', FACEBOOK_ANDROID_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user', GUEST_ANDROID_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    guest_to_facebook_user = FACEBOOK_ANDROID_USER.clone
    guest_to_facebook_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_facebook_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_to_facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal facebook_user_id, guest_to_facebook_user_id

    # Guest user should already be deleted
    user = USERS.find_one(guest_user_id)
    assert_nil user

    user = USERS.find_one(facebook_user_id)
    assert_equal 2, user["devices"].count

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: facebook_user_id})
    user = USERS.find_one(facebook_user_id)
    assert_nil user
    user = USERS.find_one(guest_to_facebook_user_id)
    assert_nil user
  end

  def test_add_device_ios_facebook_from_android_guest
    post '/user', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user', GUEST_ANDROID_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    guest_to_facebook_user = FACEBOOK_USER.clone
    guest_to_facebook_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_facebook_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_to_facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal facebook_user_id, guest_to_facebook_user_id

    # Guest user should already be deleted
    user = USERS.find_one(guest_user_id)
    assert_nil user

    user = USERS.find_one(facebook_user_id)
    assert_equal 2, user["devices"].count

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: facebook_user_id})
    user = USERS.find_one(facebook_user_id)
    assert_nil user
    user = USERS.find_one(guest_to_facebook_user_id)
    assert_nil user
  end

  def test_add_device_android_facebook_from_ios_guest
    post '/user', FACEBOOK_ANDROID_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    guest_to_facebook_user = FACEBOOK_ANDROID_USER.clone
    guest_to_facebook_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_facebook_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_to_facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal facebook_user_id, guest_to_facebook_user_id

    # Guest user should already be deleted
    user = USERS.find_one(guest_user_id)
    assert_nil user

    user = USERS.find_one(facebook_user_id)
    assert_equal 2, user["devices"].count

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: facebook_user_id})
    user = USERS.find_one(facebook_user_id)
    assert_nil user
    user = USERS.find_one(guest_to_facebook_user_id)
    assert_nil user
  end


  def test_add_device_facebook_from_email
    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    guest_to_email_user = EMAIL_USER.clone
    guest_to_email_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_email_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_to_email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal email_user_id, guest_to_email_user_id

    # Guest user should already be deleted
    user = USERS.find_one(guest_user_id)
    assert_nil user

    user = USERS.find_one(email_user_id)
    assert_equal 2, user["devices"].count
    
    # deleting the user, and checking that both ids (which is the same id) doesn't exist in the DB
    USERS.remove({_id: email_user_id})
    user = USERS.find_one(email_user_id)
    assert_nil user
    user = USERS.find_one(guest_to_email_user_id)
    assert_nil user    
  end

  def test_first_use_facebook_true
    post '/user', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal true, json_response["first_use"]

    USERS.remove({_id: facebook_user_id})
    user = USERS.find_one(facebook_user_id)
    assert_nil user
  end

  def test_first_use_facebook_false
    post '/user', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal true, json_response["first_use"]

    post '/user', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id_2 = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal false, json_response["first_use"]

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: facebook_user_id})
    user = USERS.find_one(facebook_user_id)
    assert_nil user
    user = USERS.find_one(facebook_user_id_2)
    assert_nil user
  end

  def test_first_use_email_true
    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal true, json_response["first_use"]

    USERS.remove({_id: email_user_id})
    user = USERS.find_one(email_user_id)
    assert_nil user
  end

  def test_first_use_facebook_false
    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    email_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal true, json_response["first_use"]

    post '/user', EMAIL_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    email_user_id2 = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal false, json_response["first_use"]

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: email_user_id})
    user = USERS.find_one(email_user_id)
    assert_nil user
    user = USERS.find_one(email_user_id2)
    assert_nil user
  end

  # def test_add_device_merge_users
  # end

  # def test_empty_password
  # end


  def test_create_user_old
    user_id = "delete@test.com"
    post '/user/old', { :user_id =>  user_id}
    json_response = JSON.parse(last_response.body)
    assert_equal user_id, json_response["_id"]
    assert_equal true, json_response["is_public"]

    # deleting the user
    USERS.remove({_id: user_id})
    user = USERS.find_one({_id: user_id})
    assert_nil(user)
  end

  def test_update_push_token_ios
    post '/user', GUEST_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    guest_device_id = GUEST_USER[:device][:identifier_for_vendor]

    new_push_token = "<09377d71 ddffb776 6d5e8d08 6e649cd9 b50497f2 cba5281f b80a5fed a912bXXX>"

    # Updating push token
    put '/user/push_token', {:user_id => guest_user_id.to_s, :device_id => guest_device_id, :ios_push_token => new_push_token}
    assert_equal 200, last_response.status
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    assert_equal new_push_token, json_response["devices"][0]["push_token"]

    user = USERS.find_one(guest_user_id)
    assert_equal new_push_token, user["devices"][0]["push_token"]

    # deleting the user
    USERS.remove({_id: guest_user_id})
    user = USERS.find_one(guest_user_id)
    assert_nil user
  end

  def test_update_push_token
    post '/user', GUEST_ANDROID_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    guest_device_id = GUEST_ANDROID_USER[:device][:device_id]

    new_push_token = "APA91bE4MZmyhKWNiYyecfa8r0cHzai6KGv_LJTz59mdWlCFUQ_Y6fIu9U3V0myH7yfKWL3qr_ru8f4xkThOVsTtbbaSFwiZpBryF6zy9At4h3Q7ySQQEbKQMfH1PXYzJwm_HykxTltsHZDaykGNZj5c6Fv3TFKNEW"

    # Updating push token
    put '/user/push_token', {:user_id => guest_user_id.to_s, :device_id => guest_device_id, :android_push_token => new_push_token}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    assert_equal new_push_token, json_response["devices"][0]["android_push_token"]

    user = USERS.find_one(guest_user_id)
    assert_equal new_push_token, user["devices"][0]["android_push_token"]

    # deleting the user
    USERS.remove({_id: guest_user_id})
    user = USERS.find_one(guest_user_id)
    assert_nil user
  end

  def test_update_push_token_invalid_user
    post '/user', GUEST_ANDROID_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    guest_device_id = GUEST_ANDROID_USER[:device][:device_id]

    new_push_token = "APA91bE4MZmyhKWNiYyecfa8r0cHzai6KGv_LJTz59mdWlCFUQ_Y6fIu9U3V0myH7yfKWL3qr_ru8f4xkThOVsTtbbaSFwiZpBryF6zy9At4h3Q7ySQQEbKQMfH1PXYzJwm_HykxTltsHZDaykGNZj5c6Fv3TFKNEW"

    new_user_id = BSON::ObjectId.new

    # Updating push token
    put '/user/push_token', {:user_id => new_user_id, :device_id => guest_device_id, :android_push_token => new_push_token}

    assert_equal 404, last_response.status
    json_response = JSON.parse(last_response.body)
    assert_equal 1002, json_response["error_code"]

    user = USERS.find_one(guest_user_id)
    assert_equal GUEST_ANDROID_USER[:device][:android_push_token], user["devices"][0]["android_push_token"]

    # deleting the user
    USERS.remove({_id: guest_user_id})
    user = USERS.find_one(guest_user_id)
    assert_nil user
  end

  def test_update_push_token_invalid_device
    post '/user', GUEST_ANDROID_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    guest_device_id = GUEST_ANDROID_USER[:device][:device_id]

    new_push_token = "APA91bE4MZmyhKWNiYyecfa8r0cHzai6KGv_LJTz59mdWlCFUQ_Y6fIu9U3V0myH7yfKWL3qr_ru8f4xkThOVsTtbbaSFwiZpBryF6zy9At4h3Q7ySQQEbKQMfH1PXYzJwm_HykxTltsHZDaykGNZj5c6Fv3TFKNEW"

    new_device_id = "ff54-c06c-c2d2-xxxx"

    # Updating push token
    put '/user/push_token', {:user_id => guest_user_id.to_s, :device_id => new_device_id, :android_push_token => new_push_token}

    assert_equal 404, last_response.status
    json_response = JSON.parse(last_response.body)
    assert_equal 1006, json_response["error_code"]

    user = USERS.find_one(guest_user_id)
    assert_equal GUEST_ANDROID_USER[:device][:android_push_token], user["devices"][0]["android_push_token"]

    # deleting the user
    USERS.remove({_id: guest_user_id})
    user = USERS.find_one(guest_user_id)
    assert_nil user    
  end

  def test_update_push_token_multiple_devices
    post '/user', FACEBOOK_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    post '/user', GUEST_ANDROID_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    guest_to_facebook_user = FACEBOOK_USER.clone
    guest_to_facebook_user[:user_id] = guest_user_id.to_s
    put '/user', guest_to_facebook_user

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    guest_to_facebook_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    assert_equal facebook_user_id, guest_to_facebook_user_id

    # Guest user should already be deleted
    user = USERS.find_one(guest_user_id)
    assert_nil user

    user = USERS.find_one(facebook_user_id)
    assert_equal 2, user["devices"].count

    guest_device_id = GUEST_ANDROID_USER[:device][:device_id]

    new_push_token = "APA91bE4MZmyhKWNiYyecfa8r0cHzai6KGv_LJTz59mdWlCFUQ_Y6fIu9U3V0myH7yfKWL3qr_ru8f4xkThOVsTtbbaSFwiZpBryF6zy9At4h3Q7ySQQEbKQMfH1PXYzJwm_HykxTltsHZDaykGNZj5c6Fv3TFKNEW"

    # Updating push token
    put '/user/push_token', {:user_id => guest_to_facebook_user_id.to_s, :device_id => guest_device_id, :android_push_token => new_push_token}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    user = USERS.find_one(guest_to_facebook_user_id)

    for device in user["devices"]
        android_device = device if device["device_id"] == guest_device_id
    end
    assert_equal new_push_token, android_device["android_push_token"]

    # deleting the user, and checking that both ids (which is the same id) doesn;t exist in the DB
    USERS.remove({_id: facebook_user_id})
    user = USERS.find_one(facebook_user_id)
    assert_nil user
    user = USERS.find_one(guest_to_facebook_user_id)
    assert_nil user    
  end

  def test_user_name_facebook
    user = Hash.new
    user["facebook"] = Hash.new
    user["facebook"]["name"] = "Bla Bla"
    name = user_name(user)
    assert_equal("Bla Bla", name)
  end

  def test_user_email_with_dot
    user = Hash.new
    user["email"] = "nir.channes@gmail.com"
    name = user_name(user)
    assert_equal("Nir Channes", name)
  end

  def test_user_email_with_underscore
    user = Hash.new
    user["email"] = "nir_channes@gmail.com"
    name = user_name(user)
    assert_equal("Nir Channes", name)
  end

  def test_user_email_with_middle_name
    user = Hash.new
    user["email"] = "nir.james.channes@gmail.com"
    name = user_name(user)
    assert_equal("Nir James Channes", name)
  end

  def test_user_email_with_first_only
    user = Hash.new
    user["email"] = "nir@gmail.com"
    name = user_name(user)
    assert_equal("Nir", name)
  end

  def test_remake_is_public_true
    post '/user', PUBLIC_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    public_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => public_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_equal true, remake["is_public"]

    # deleting the user
    USERS.remove({_id: public_user_id})
    user = USERS.find_one(public_user_id)
    assert_nil user    
  end


def test_remake_is_public_false
    post '/user', PRIVATE_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    private_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => private_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake = REMAKES.find_one(remake_id)
    assert remake
    assert_equal false, remake["is_public"]

    # deleting the user
    USERS.remove({_id: private_user_id})
    user = USERS.find_one(private_user_id)
    assert_nil user    
  end

  def test_update_user_to_private
    post '/user', PUBLIC_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    public_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    public_user = USERS.find_one(public_user_id)

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => public_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id_1 = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake_1 = REMAKES.find_one(remake_id_1)
    assert remake_1
    assert_equal true, remake_1["is_public"]

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => public_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id_2 = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake_2 = REMAKES.find_one(remake_id_2)
    assert remake_2
    assert_equal true, remake_2["is_public"]

    put '/user', { :user_id => public_user_id, :is_public => "NO" }

    public_user = USERS.find_one(public_user_id)
    remake_1 = REMAKES.find_one(remake_id_1)
    remake_2 = REMAKES.find_one(remake_id_2)

    assert_equal false, public_user["is_public"]
    assert_equal false, remake_1["is_public"]
    assert_equal false, remake_2["is_public"]

    # deleting the user
    USERS.remove({_id: public_user_id})
    user = USERS.find_one(public_user_id)
    assert_nil user   
  end


  def test_update_user_to_public
    post '/user', PRIVATE_USER

    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    private_user_id = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    private_user = USERS.find_one(private_user_id)

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => private_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id_1 = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake_1 = REMAKES.find_one(remake_id_1)
    assert remake_1
    assert_equal false, remake_1["is_public"]

    # Creating a remake for the testing (deleting him in the teardown)
    post '/remake', {:story_id => "52de83db8bc427751c000305", :user_id => private_user_id.to_s}
    json_response = JSON.parse(last_response.body)
    assert json_response["_id"]["$oid"]
    remake_id_2 = BSON::ObjectId.from_string(json_response["_id"]["$oid"])
    remake_2 = REMAKES.find_one(remake_id_2)
    assert remake_2
    assert_equal false, remake_2["is_public"]

    put '/user', { :user_id => private_user_id, :is_public => "YES" }

    private_user = USERS.find_one(private_user_id)
    remake_1 = REMAKES.find_one(remake_id_1)
    remake_2 = REMAKES.find_one(remake_id_2)

    assert_equal true, private_user["is_public"]
    assert_equal true, remake_1["is_public"]
    assert_equal true, remake_2["is_public"]


    # deleting the user
    USERS.remove({_id: private_user_id})
    user = USERS.find_one(private_user_id)
    assert_nil user    
  end



  def test_env
    get '/test/env'
    assert_equal 'test', last_response.body
  end

  def teardown
    if @delete_user then
      #puts "Deleting user: " + @delete_user
      #USERS.remove({_id: @delete_user})
    else
      #puts "no user to delete"
    end
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