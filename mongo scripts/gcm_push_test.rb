require 'gcm'

# Homage: AIzaSyBLZSS5D3k07As3GS2HXKc8aMqV8xh5KSQ  
# Monkey: AIzaSyCzVRX3TmfgJt8gCdi17UjfH6Vf62ZiEt8
gcm = GCM.new("AIzaSyBLZSS5D3k07As3GS2HXKc8aMqV8xh5KSQ") 
# you can set option parameters in here
#  - all options are pass to HTTParty method arguments
#  - ref: https://github.com/jnunemaker/httparty/blob/master/lib/httparty.rb#L40-L68
#  gcm = GCM.new("my_api_key", timeout: 3)

# Push new remake
# an array of one or more client registration IDs
registration_ids= ["APA91bG1QfqwHjQPELs2smrpMOjRoyGrb_KDKGisLHtHuhyyHug04CubR8UesYA9A9EY7qpnp54vQbetVMfGxRSK-oPQi6OI_eR-StVdrsj3XMux6dC5UrzeoOR2hQmL5py5SX8QC-NQMIsKUSI0Egj8ppZcTr1bOWMi6jsjVcr7FMMfYqEYsGA"] 
options = {data: {type: 0, title: "Video is Ready!", remake_id: "5415863ab8fef16bc5000012", story_id: "53ce9bc405f0f6e8f2000655"}}
response = gcm.send(registration_ids, options)
puts response.to_s
# push new story
# registration_ids= ["APA91bEeKiq223zljYqEQKwWDcVRx05R4QRxTu70ts0DlOePp3gCCpghFSgV_J2v0N13oDMiXeOJxFV45D1BUlQRmtQGTvUk9s7P1eSmGuh-i8jUuDbYvInPry8oeN-41234_ZjIcVKibNpK48H89wYy8x_Lccanpg"] # an array of one or more client registration IDs
# options = {data: {type: 2, story_id: "5789012345678901234567890browsers", title:"New Story!"}}
# response = gcm.send(registration_ids, options)