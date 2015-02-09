require 'mixpanel_client'

@client = Mixpanel::Client.new(
  api_key:    'a64151ad9709488f19cb9e263afb8723', 
  api_secret: '5ebdf53dd0a9cd22fa6adb32b51acbe7'
)

# data = client.request(
#   'events',
#   event:     '["MEDeleteRemake"]',
#   type:      'general',
#   unit:      'day',
#   from_date: '2015-01-01',
#   to_date:   '2015-02-01',
# )

# puts "data"
# puts data


def getEventForDates(event_names, data_type, unit, from_date, to_date) 
	puts "rafi"
	puts "event names: " + event_names.to_s
	puts "data_type:" + data_type.to_s
	puts "unit:" + unit.to_s
	data = @client.request(
		'events',
		event:     event_names,
		type:      data_type,
		unit:      unit,
		from_date: from_date,
		to_date:   to_date,
	)
	return data
end

# puts "Rafidfkljdsfklds"
# data = getEventForDates('["REEnterRecorder","REUserPressedHelpButton","RECameraNotStable",
# 	"REShowScript","REexpandMenu","REMenuSceneDirection","RESeePreview","RERetakeLast",
# 	"RECreateMovie"]' , 'general' , 'month' , '2014-08-01' , '2015-02-01')


data = @client.request(
	'segmentation/average',
	event: 'stop_playing_video',
	from_date: '2014-11-10',
	to_date: '2015-02-08',
	on: 'number(properties["playing_time"])',
	unit: 'month',
	where: "properties[\"originating_screen\"]==3",
)

puts data



	




