require 'zip'

def zipListOfFiles(download_folder, input_filenames, zip_file_name)
	# package_attitude_20150329_114643.zip
	# zipped_packages
	begin
		success = true

		zipfile_name = download_folder + zip_file_name + '.zip'

		Zip::File.open(zipfile_name, Zip::File::CREATE) do |zipfile|
		  	input_filenames.each do |filename|

		  		begin
		  			if(filename != nil)
						zipfile.add(filename, download_folder + filename)
					end
				rescue StandardError => e

					return "Problem Zipping: " + filename

				ensure
				end
			  end
			  #zipfile.get_output_stream("myFile") { |os| os.write "myFile contains just this" }
			  # logger.info 'finished zip'
		end
		# logger.info remake_id.to_s + '.zip'
		return success

	rescue StandardError => e

		return "zipfolder: " + e.to_s

	ensure

	end
end
