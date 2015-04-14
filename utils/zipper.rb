require 'zip'

def zipfolder(download_folder, input_filenames, zip_file_name)
	# package_attitude_20150329_114643.zip
	# zipped_packages
	zipfile_name = download_folder + zip_file_name + '.zip'

		Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
		  	input_filenames.each do |filename|
			    # Two arguments:
			    # - The name of the file as it will appear in the archive
			    # - The original file, including the path to find it
			    # logger.info 'zipping file' + filename
				zipfile.add(filename, download_folder + filename)
			  end
			  #zipfile.get_output_stream("myFile") { |os| os.write "myFile contains just this" }
			  # logger.info 'finished zip'
		end
		# logger.info remake_id.to_s + '.zip'
		return zip_file_name + '.zip'
end
