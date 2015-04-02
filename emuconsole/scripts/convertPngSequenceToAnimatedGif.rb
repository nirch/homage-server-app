require 'RMagick'
include Magick

animation = ImageList.new(*Dir["*.png"])
animation.delay = 10
animation.write("animated.gif")

