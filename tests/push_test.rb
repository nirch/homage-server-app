require 'houston'

# Environment variables are automatically read, or can be overridden by any specified options. You can also
# conveniently use `Houston::Client.development` or `Houston::Client.production`.

# Debug (Test)
#APN = Houston::Client.development
#APN.certificate = File.read("../certificates/homage_push_notification_dev.pem")

# Prodcution
APN = Houston::Client.production
APN.certificate = File.read("../certificates/homage_push_notification_prod.pem")
APN.passphrase = "homage"

# An example of the token sent back when a device registers for notifications
# Tomer
#token = "<3613e36f b419bfca 0063ddd4 fcdf3374 20491e54 8545779d 793cf71b 4a003b8a>"

# Yoav
#token = "<83b2deb3 26d549ac 5d045055 697a43e5 b8c3e2fb ddd2b74e e2d903ac 8cafd570>"
#token = "<3613e36f b419bfca 0063ddd4 fcdf3374 20491e54 8545779d 793cf71b 4a003b8a>"

# Yoav production
token = "<6d214c84 73a8d8a9 c807cca5 3a2751b8 be8d93bd d8e04ff0 a3c07009 affde3e7>"

# Create a notification that alerts a message to the user, plays a sound, and sets the badge on the app
notification = Houston::Notification.new(device: token)
notification.alert = "Take Part in the World Cup! Vamos!"

# Notifications can also change the badge count, have a custom sound, indicate available Newsstand content, or pass along arbitrary data.
#notification.badge = 57
#notification.sound = "sosumi.aiff"
#notification.content_available = true
#notification.custom_data = {type: 0, remake_id: "kjfdkjf333kj3kj3kj3"}
notification.sound = "default"
notification.custom_data = {type: 2, story_id: "53b17db89a452198f80004a6"}

# And... sent! That's all it takes.
APN.push(notification)
