require 'fileutils'
require 'logger'
log = Logger.new('D:\homage\Crash\log.txt') 
log.debug "Log file created"

mov_ext = [".mov", ".mp4"]
accepted_formats = [".mov", ".mp4", ".ctr"]


folderpath = 'D:/homage/Crash'

Dir.foreach(folderpath) do |item|
  next if item == '.' or item == '..' or item == 'log.txt' or item == 'Original Result'
  remakeid = File.basename( item, ".*" )

  if accepted_formats.include? File.extname(item)

  	dirname = File.dirname(folderpath + '/' + remakeid )
	unless File.directory?(dirname)
	  	FileUtils.mkdir_p(dirname)
	end

	dirname = File.dirname(folderpath + '/' + remakeid + '/Frames/test.1' )
	puts dirname
	unless File.directory?(dirname)
	  	FileUtils.mkdir_p(dirname)
	end

  	src = folderpath + '/' + item
  	dst = folderpath + '/' + remakeid + '/' + item
  	FileUtils.mkdir_p(File.dirname(dst))
  	FileUtils.mv(src, dst)  	
  end
  # puts item
  if mov_ext.include? File.extname(item)
  	puts 'ffmpeg -i ' + folderpath + '/' + remakeid + '/' + remakeid + File.extname(item) + ' -q:v 1 ' + folderpath + '/' + remakeid + '/Frames/' + 'image-%4d.jpg'
  	system 'ffmpeg -i ' + folderpath + '/' + remakeid + '/' + remakeid + File.extname(item) + ' -q:v 1 ' + folderpath + '/' + remakeid + '/Frames/' + 'image-%4d.jpg'
  end
end