require 'houston'

# Environment variables are automatically read, or can be overridden by any specified options. You can also
# conveniently use `Houston::Client.development` or `Houston::Client.production`.

# Debug (Test)
APN = Houston::Client.development
APN.certificate = File.read("../certificates/homage_push_notification_dev.pem")

# # Prodcution
# APN = Houston::Client.production
# APN.certificate = File.read("../certificates/homage_push_notification_prod.pem")
# APN.passphrase = "homage"

# APN = Houston::Client.production
# APN.certificate = File.read("../certificates/homage_push_notification_prod.pem")
# APN.passphrase = "homage"

# APN_NEW = Houston::Client.production
# APN_NEW.certificate = File.read("../certificates/homage_push_notification_prod_150.pem")
# APN_NEW.passphrase = "homage"

# An example of the token sent back when a device registers for notifications
# Tomer
#token = "<3613e36f b419bfca 0063ddd4 fcdf3374 20491e54 8545779d 793cf71b 4a003b8a>"

# Yoav
#token = "<83b2deb3 26d549ac 5d045055 697a43e5 b8c3e2fb ddd2b74e e2d903ac 8cafd570>"
#token = "<3613e36f b419bfca 0063ddd4 fcdf3374 20491e54 8545779d 793cf71b 4a003b8a>"

# Nir (Tomer)
#token = "<3613e36f b419bfca 0063ddd4 fcdf3374 20491e54 8545779d 793cf71b 4a003b8a>"

# Aviv iPhone 6 Plus
token = "<452d30f7 c6d1964e c5a1cda7 78be8517 b1136b42 ae154783 7fb61e3e 43dc7795>"
# Aviv iPhone 5
#token = "<ec0ad57f 4fcea35f 03e4fab9 1572a145 a2facdef b58a8203 4acdc1d8 186cac0b>"
#token = "<0a7b7b15 3f0fb335 0e252182 38675505 e739547b 47dd8ab2 60e39582 85fbe150>"
#iPhone 4
#token = "<d4d84b6b 923afc59 eb4767ab 73497e0f 3549d836 2028feab a3ac16d8 7927f090>"
#iPad
#token = "<d5356c21 2ad2b3df 71864043 a618fe35 731c7d29 37d200a3 932f1f21 5333a1c0>"

# Yoav production
#token = "<6d214c84 73a8d8a9 c807cca5 3a2751b8 be8d93bd d8e04ff0 a3c07009 affde3e7>"

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
# APN_NEW.push(notification)
