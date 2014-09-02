NormalFractionGraphType = 0
NormalValueGraphType    = 1
AvgValueGraphType       = 2
StoryViewsGraphType     = 3
PieChartGraphType       = 4
UndefinedGraphType      = 5

ViewSourceIos     = 0
ViewSourceAndroid = 1
ViewSourceWeb     = 2

function genDataForDaysDisplay(start_date,end_date,data_type,data_series) {
	console.log("genDataForDaysDisplay start");
	console.log("data type: " + data_type);
	console.log("data_series: ")
	console.log(data_series);
	sd = new Date(start_date);
	ed = new Date(end_date);

	id = sd;
	final_result = [];

	if (data_type == PieChartGraphType) {
		console.log("detected pie chart");
		Object.keys(data_series).forEach(function(key) {
			console.log("key: " + key);
			console.log(data_series[key])
			final_result.push({"key": key, "val": data_series[key]});
		});
	} else {
		while (id <= ed) {
			date_key = genDataKeyFormatForDate(id);
			if (data_series[date_key]) {
				data_set = data_series[date_key];
			} else {
				console.log("no matching record for date: " + date_key + "found. putting 0");
				data_set = 0;
			}		
			console.log(data_set);
			switch (data_type) {
				case NormalFractionGraphType:
				if (data_set[1] == 0) {
					final_result.push({"date": date_key, "val": 0});
				} else {
					val = data_set[0]/data_set[1] 
					final_result.push({"date": date_key, "val": val});
				}
				break;
				case NormalValueGraphType:
				final_result.push({"date": date_key, "val": data_set});
				break;
				case AvgValueGraphType:
				final_result.push({"date": date_key, "val": data_set});
				break;
				case StoryViewsGraphType:
				console.log(data_set);		
				remake_views = 0
				if (data_set.hasOwnProperty("remake_views")) remake_views = data_set["remake_views"];

				story_views = 0
				if (data_set.hasOwnProperty("story_views")) story_views = data_set["story_views"];
				
				ios_views = 0
				if (data_set.hasOwnProperty(ViewSourceIos)) ios_views = data_set[ViewSourceIos];
				
				android_views = 0
				if (data_set.hasOwnProperty(ViewSourceAndroid)) android_views = data_set[ViewSourceAndroid];

				web_views = 0
				if (data_set.hasOwnProperty(ViewSourceWeb)) web_views = data_set[ViewSourceWeb];

				final_result.push({"date":date_key, "remake views": remake_views, "story views": story_views,
				 "ios views":ios_views, "android views":android_views, "web views":web_views});
				break;
				case UndefinedGraphType:
				console.log("undefined graph type");
				final_result.push({"date": date_key, "val": {}});
				break;
			}
			id = addDays(id,1);
		}
	}	

	console.log("displaying final result");
	console.log(final_result);
	return final_result;
}

function genDataForWeeksDisplay(start_date,end_date,data_type,data_series) {
	console.log("genDataForWeeksDisplay start: " + start_date +  "to " + end_date);
	console.log(data_series);
	sd = new Date(start_date);
	ed = new Date(end_date);
	
	id = sd;
	final_result = [];
	nominator_sum = 0;
	denominator_sum = 0;
	remake_views = 0;
	story_views = 0;
	ios_views = 0; 
	android_views = 0;
	web_views = 0

	if (data_type == PieChartGraphType) {
		console.log("detected pie chart");
		Object.keys(data_series).forEach(function(key) {
			console.log("key: " + key);
			console.log(data_series[key])
			final_result.push({"key": key, "val": data_series[key]});
		});

	} else {

		while (id <= ed) {
			data_key = genDataKeyFormatForDate(id);
			data_set = data_series[data_key];

			switch (data_type) {
				case NormalFractionGraphType:
					nominator_sum += data_set[0];
					denominator_sum += data_set[1];
					break;
				case NormalValueGraphType:
					nominator_sum += data_set;
					denominator_sum = 1;
					break;
				case AvgValueGraphType:
					nominator_sum += data_set;
					denominator_sum = 1;
					break;
				case StoryViewsGraphType:
					
				break;
				case UndefinedGraphType:
				console.log("undefined graph type");
				final_result[data_key] = {};
				break;
			}

			if (id.getDay() == 6 || +id == +ed ) { //its saturday or the end of the data set, need to sum of the week and make a new sum
				//console.log("summing up the chunk that end on: " + id.toString());
				final_result[data_key] = nominator_sum / denominator_sum
				nominator_sum = 0;
				denominator_sum = 0;
			}

			id = addDays(id,1);
		}
	}
	
	console.log("displaying final result");
	console.log(final_result);
	return final_result
}

function addDays(today,num_of_days) {
	var needed_date = new Date();
	needed_date.setTime(today.getTime() + num_of_days * 86400000);
    return needed_date;
}

function addWeeks(today,num_of_weeks) {
	var needed_date = new Date();
	needed_date.setTime(today.getTime() + num_of_weeks * 7 * 86400000);
    return needed_date;
}


function genDataKeyFormatForDate(date) {
	day = date.getDate().toString();
	if (day.length == 1) {
		day = "0" + day;
	}

	month_real_num = date.getMonth() + 1
	month = month_real_num.toString();
	if (month.length == 1) {
		month = "0" + month;
	}

	year = date.getFullYear().toString();

	res = year + "-" + month + "-" + day;
	return res;
}







