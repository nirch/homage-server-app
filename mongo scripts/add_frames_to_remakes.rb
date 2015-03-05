require 'fileutils'
require 'logger'
require 'rubygems'
require 'streamio-ffmpeg'

log = Logger.new('/Users/dangal/Documents/homage/crashes/log.txt') 
log.debug "Log file created"

folderpath = "/Users/dangal/Documents/homage/crashes"
i = 0
Dir.foreach(folderpath) do |item|
  puts item
  next if item == '.' or item == '..' or item == 'log.txt' or item == 'Original Result' or item == '.DS_Store'
  # do work on real items
  dirname = File.dirname(folderpath + '/' + item + '/Frames/test.1' )
	puts dirname
	unless File.directory?(dirname)
	  	FileUtils.mkdir_p(dirname)
	end

  FFMPEG.ffmpeg_binary = '/usr/local/bin/ffmpeg'

  movie = FFMPEG::Movie.new(folderpath + '/' + item + '/' + item + '.mov')
  #puts movie.duration
  puts movie.video_codec
  movie.transcode(folderpath + '/' + item + '/Frames/' + 'image-%4d.jpg', "-q:v 1")

  # puts 'ffmpeg -i ' + folderpath + '/' + item + '/' + item + '.mov -q:v 1 ' + folderpath + '/' + item + '/Frames/' + 'image-%4d.jpg'
  # system 'ffmpeg -i ' + folderpath + '/' + item + '/' + item + '.mov -q:v 1 ' + folderpath + '/' + item + '/Frames/' + 'image-%4d.jpg'
  i = i +1
  puts i
end

