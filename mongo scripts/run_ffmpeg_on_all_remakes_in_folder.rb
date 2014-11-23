require 'fileutils'
require 'logger'
log = Logger.new('D:/homage/moviesnoframes/log.txt') 
log.debug "Log file created"

folderpath = 'D:/homage/moviesnoframes'
i = 0
Dir.foreach(folderpath) do |item|
  next if item == '.' or item == '..' or item == 'log.txt' or item == 'Original Result'
  # do work on real items
  #Dir.mkdir folderpath + '/' + item + '/Frames'
  puts 'ffmpeg -i ' + folderpath + '/' + item + '/' + item + '.mov -q:v 1 ' + folderpath + '/' + item + '/Frames/' + 'image-%4d.jpg'
  system 'ffmpeg -i ' + folderpath + '/' + item + '/' + item + '.mov -q:v 1 ' + folderpath + '/' + item + '/Frames/' + 'image-%4d.jpg'
  i = i +1
  puts i
end
