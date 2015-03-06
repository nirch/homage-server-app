NormalFractionGraphType = 0
NormalValueGraphType    = 1
AvgValueGraphType       = 2
StoryViewsGraphType     = 3
PieChartGraphType       = 4
UndefinedGraphType      = 5

ViewSourceIos     = 0
ViewSourceAndroid = 1
ViewSourceDesktop = 2
viewSourceMobile  = 3

function prepareDataForDaysDisplay(start_date,end_date,data_type,data_series,data_format) {
	sd = new Date(start_date);
	ed = new Date(end_date);

	id = sd;
	color = 0;
	final_result = [];

	x_date_series        = ["x"];
	remake_views_series  = ["remake views"];
	story_views_series   = ["story views"];
	ios_views_series     = ["iOS views"];
	android_views_series = ["Android views"];
	desktop_views_series = ["Desktop views"];
	mobile_views_series  = ["Mobile views"];

	if (data_type == StoryViewsGraphType) {
		data_series = aggregateStoryViews(start_date,end_date,data_series);
	}

	if (data_type == PieChartGraphType) {
		Object.keys(data_series).forEach(function(key) {
			//var colors = ["#2484c1","#0c6197","#4daa4b","#90c469","#daca61","#e4a14b","#e98125"];
			//j = Math.floor(Math.random() * colors.length) + 1;
			final_result.push({"label": key, "value": data_series[key]});
		});
	} else {
		while (id <= ed) {
			date_key = genDataKeyFormatForDate(id);
			if (data_series[date_key]) {
				data_set = data_series[date_key];
			} else {
				data_set = 0;
			}		
			switch (data_type) {
				case NormalFractionGraphType:
				if (data_set == 0) {
					data_set = [0,0];
				}

				if (data_set[1] == 0) {
					nom_value   = data_format["nominator"];
					denom_value = data_format["denominator"];
					info = "Value: " + 0 + ", " + data_format["nominator"] + 0 + ", " + data_format["denominator"] + 0 
					final_result.push({"date": id, "value": 0, "nominator": data_set[0], "denominator": data_set[1], "info": info});
				} else {
					value = (data_set[0]/data_set[1]).toFixed(3)/1;
					info = "Value: " +  value + ", " 
							+ data_format["nominator"] + data_set[0] + ", " + data_format["denominator"] + data_set[1];
					final_result.push({"date": id, "value": value, "nominator": data_set[0], "denominator": data_set[1], "info": info});
				}
				break;
				case NormalValueGraphType:
				value = data_set;
				info = "Value: " + value;
				final_result.push({"date": id, "value": value, "info": info});
				break;
				case AvgValueGraphType:
				value = data_set.toFixed(3)/1;
				info = "Value: " + value;
				final_result.push({"date": id, "value": value, "info": info});
				break;
				case StoryViewsGraphType:		
				x_date_series.push(id);

				remake_views = 0
				if (data_set.hasOwnProperty("remake_views")) remake_views = data_set["remake_views"];
				remake_views_series.push(remake_views);

				story_views = 0
				if (data_set.hasOwnProperty("story_views")) story_views = data_set["story_views"];
				story_views_series.push(story_views);
				
				ios_views = 0
				if (data_set.hasOwnProperty(ViewSourceIos)) ios_views = data_set[ViewSourceIos];
				ios_views_series.push(ios_views);
				
				android_views = 0
				if (data_set.hasOwnProperty(ViewSourceAndroid)) android_views = data_set[ViewSourceAndroid];
				android_views_series.push(android_views);

				desktop_views = 0
				if (data_set.hasOwnProperty(ViewSourceDesktop)) desktop_views = data_set[ViewSourceDesktop];
				desktop_views_series.push(desktop_views);

				mobile_views = 0
				if (data_set.hasOwnProperty(ViewSourceDesktop)) mobile_views = data_set[viewSourceMobile];
				mobile_views_series.push(mobile_views);

				break;
				case UndefinedGraphType:
				//console.log("undefined graph type");
				final_result.push({"date": id, "value": {}});
				break;
			}
			id = addDays(id,1);
		}
	}	

	if (data_type == StoryViewsGraphType) {
		final_result = [x_date_series,remake_views_series,story_views_series,ios_views_series,
						android_views_series,desktop_views_series,mobile_views_series];
	}

	return final_result;
}


function aggregateDataForDisplay(start_date,end_date,data_type,data_series,data_format,aggregation_type) {
	final_result = [];
	if (data_type == PieChartGraphType) {
		Object.keys(data_series).forEach(function(key) {
			//var colors = ["#2484c1","#0c6197","#4daa4b","#90c469","#daca61","#e4a14b","#e98125"];
			//j = Math.floor(Math.random() * colors.length) + 1;
			final_result.push({"label": key, "value": data_series[key]});
		});
		return final_result;	
	}

	if (data_type == StoryViewsGraphType) {
		data_series = aggregateStoryViews(start_date,end_date,data_series);
	}

	sd = new Date(start_date);
	ed = new Date(end_date);

	x_date_series        = ["x"];
	remake_views_series  = ["remake views"];
	story_views_series   = ["story views"];
	ios_views_series     = ["iOS views"];
	android_views_series = ["Android views"];
	//web_views_series     = ["web views"];
	desktop_views_series = ["Desktop views"];
	mobile_views_series  = ["Mobile views"];
	
	nominator_sum = 0;
	denominator_sum = 0;
	remake_views = 0;
	story_views = 0;
	ios_views = 0; 
	android_views = 0;
	//web_views = 0;
	desktop_views = 0;
	mobile_views = 0;

	id = sd;
	new_interval_start_date = sd;
	while (id <= ed) {

		date_key = genDataKeyFormatForDate(id);

 		if (data_series[date_key]) {
			data_set = data_series[date_key];		
		} else {
			data_set = 0;
		}	

		var aggregation_condition;
		if (aggregation_type == "week") {
			aggregation_condition = (id.getDay() == 6 || +id == +ed);
		} else if (aggregation_type == "month") {
			aggregation_condition = (isLastDayOfMonth(id) || +id == +ed);
		}

		switch (data_type) {
			case NormalFractionGraphType:
				if (data_set != 0) {
					nominator_sum += data_set[0];
					denominator_sum += data_set[1];
				}
				break;
			case NormalValueGraphType:
				nominator_sum += data_set;
				denominator_sum = 1;
				break;
			case AvgValueGraphType:
				nominator_sum += data_set;
				denominator_sum += 1;
				break;
			case StoryViewsGraphType:
				if (data_set.hasOwnProperty("remake_views")) remake_views += data_set["remake_views"];
				if (data_set.hasOwnProperty("story_views")) story_views += data_set["story_views"];
				if (data_set.hasOwnProperty(ViewSourceIos)) ios_views += data_set[ViewSourceIos];
				if (data_set.hasOwnProperty(ViewSourceAndroid)) android_views += data_set[ViewSourceAndroid];
				//if (data_set.hasOwnProperty(ViewSourceWeb)) web_views += data_set[ViewSourceWeb];
				if (data_set.hasOwnProperty(ViewSourceDesktop)) desktop_views += data_set[ViewSourceDesktop];
				if (data_set.hasOwnProperty(viewSourceMobile)) mobile_views += data_set[viewSourceMobile];	
				break;

			case UndefinedGraphType:
				//console.log("undefined graph type");
				final_result.push({"date": id, "value": {}});
				break;
		}

		if (aggregation_condition) { 
			if (data_type == StoryViewsGraphType) {
				x_date_series.push(id);
				remake_views_series.push(remake_views);
				story_views_series.push(story_views);
				ios_views_series.push(ios_views);
				android_views_series.push(android_views);
				//web_views_series.push(web_views);
				desktop_views_series.push(desktop_views);
				mobile_views_series.push(mobile_views);

				remake_views = 0;
				story_views = 0;
				ios_views = 0; 
				android_views = 0;
				//web_views = 0
				desktop_views = 0;
				mobile_views = 0;


			} else if (data_type == NormalValueGraphType || data_type == NormalFractionGraphType) {			
				week_info = "Time frame: " + new_interval_start_date + " to: " + id;
				if (denominator_sum == 0) {
					info = "Value: " + 0 + ", " + 
							data_format["nominator"] + 0 + ", " + data_format["denominator"] + 0 + ", " + 
							week_info;
					final_result.push({"date": id, "value": 0, "info": info}); 
				} else {
					value = (nominator_sum / denominator_sum).toFixed(3)/1;
					info = "Value: " + value + ", " + 
							data_format["nominator"] + nominator_sum + ", " + data_format["denominator"] + denominator_sum + ", " + 
							week_info;
					final_result.push({"date": id, "value": value, "info": info}); 
				}
				
				nominator_sum = 0;
				denominator_sum = 0;
			
			} else if (data_type == AvgValueGraphType) {
				week_info = "Time frame: " + new_interval_start_date + " to: " + id;
				value = (nominator_sum / denominator_sum).toFixed(3)/1;
				info = "Value: " + value + ", " + week_info;
				final_result.push({"date": id, "value": value, "info": info}); 
				nominator_sum = 0;
				denominator_sum = 0;
			}

			new_interval_start_date = addDays(id,1);
		}

		id = addDays(id,1);
	}

	if (data_type == StoryViewsGraphType) {
		final_result = [x_date_series,remake_views_series,story_views_series,ios_views_series,
						android_views_series,desktop_views_series,mobile_views_series];
	}

	return final_result;

}


/*function genDataForWeeksDisplay(start_date,end_date,data_type,data_series,data_format) {
	sd = new Date(start_date);
	ed = new Date(end_date);

	res = genDataForDaysDisplay(start_date,end_date,data_type,data_series,data_format)

	id = sd;
	x_date_series        = ["x"];
	remake_views_series  = ["remake views"];
	story_views_series   = ["story views"];
	ios_views_series     = ["iOS views"];
	android_views_series = ["Android views"];
	web_views_series     = ["web views"];
	final_result = [];
	nominator_sum = 0;
	denominator_sum = 0;
	remake_views = 0;
	story_views = 0;
	ios_views = 0; 
	android_views = 0;
	web_views = 0

	if (data_type == StoryViewsGraphType) {
		data_series = aggregateStoryViews(start_date,end_date,data_series);
	}

	if (data_type == PieChartGraphType) {
		Object.keys(data_series).forEach(function(key) {
			var colors = ["#2484c1","#0c6197","#4daa4b","#90c469","#daca61","#e4a14b","#e98125"];
			i = Math.floor(Math.random() * colors.length) + 1;
			final_result.push({"label": key, "value": data_series[key], "color": colors[i]});
		});
	} else {
		week_start = id;
		while (id <= ed) {
			date_key = genDataKeyFormatForDate(id);

			if (data_series[date_key]) {
				data_set = data_series[date_key];		
			} else {
				data_set = 0;
			}	

			switch (data_type) {
				case NormalFractionGraphType:
					if (data_set != 0) {
						nominator_sum += data_set[0];
						denominator_sum += data_set[1];
					}
					break;
				case NormalValueGraphType:
					nominator_sum += data_set;
					denominator_sum = 1;
					break;
				case AvgValueGraphType:
					nominator_sum += data_set;
					denominator_sum += 1;
					break;
				case StoryViewsGraphType:
					if (data_set.hasOwnProperty("remake_views")) remake_views += data_set["remake_views"];
					if (data_set.hasOwnProperty("story_views")) story_views += data_set["story_views"];
					if (data_set.hasOwnProperty(ViewSourceIos)) ios_views += data_set[ViewSourceIos];
					if (data_set.hasOwnProperty(ViewSourceAndroid)) android_views += data_set[ViewSourceAndroid];
					if (data_set.hasOwnProperty(ViewSourceWeb)) web_views += data_set[ViewSourceWeb];	
					break;

				case UndefinedGraphType:
					//console.log("undefined graph type");
					final_result.push({"date": id, "value": {}});
					break;
			}

			if (id.getDay() == 6 || +id == +ed ) { //its saturday or the end of the data set, need to sum of the week and make a new sum
				if (data_type == StoryViewsGraphType) {
					x_date_series.push(id);
					remake_views_series.push(remake_views);
					story_views_series.push(story_views);
					ios_views_series.push(ios_views);
					android_views_series.push(android_views);
					web_views_series.push(web_views);

					remake_views = 0;
					story_views = 0;
					ios_views = 0; 
					android_views = 0;
					web_views = 0

				} else if (data_type == NormalValueGraphType || data_type == NormalFractionGraphType) {			
					week_info = "Time frame: " + week_start + " to: " + id;
					if (denominator_sum == 0) {
						info = "Value: " + 0 + ", " + 
								data_format["nominator"] + 0 + ", " + data_format["denominator"] + 0 + ", " + 
								week_info;
						final_result.push({"date": id, "value": 0, "info": info}); 
					} else {
						value = (nominator_sum / denominator_sum).toFixed(3)/1;
						info = "Value: " + value + ", " + 
								data_format["nominator"] + nominator_sum + ", " + data_format["denominator"] + denominator_sum + ", " + 
								week_info;
						final_result.push({"date": id, "value": value, "info": info}); 
					}
					
					nominator_sum = 0;
					denominator_sum = 0;
				
				} else if (data_type == AvgValueGraphType) {
					week_info = "Time frame: " + week_start + " to: " + id;
					value = (nominator_sum / denominator_sum).toFixed(3)/1;
					info = "Value: " + value + ", " + week_info;
					final_result.push({"date": id, "value": value, "info": info}); 
					nominator_sum = 0;
					denominator_sum = 0;
				}

				week_start = addDays(id,1);
			}

			id = addDays(id,1);
		}
	}

	if (data_type == StoryViewsGraphType) {
		final_result = [x_date_series,remake_views_series,story_views_series,ios_views_series,android_views_series,web_views_series];
	}
	
	return final_result
}*/

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

function aggregateStoryViews(start_date,end_date,data_series) {
	remake_views = 0;
	story_views = 0;
	ios_views = 0; 
	android_views = 0;
	//web_views = 0;
	desktop_views = 0;
	mobile_views = 0;

	aggregated_data_series = {};

	index_d = start_date;
	ed = end_date;

	//init each aggregated_data_series[date_key]
	while (index_d <= ed) {
		date_key = genDataKeyFormatForDate(index_d);
		aggregated_data_series[date_key] = {};
		aggregated_data_series[date_key]["remake_views"] = 0;
		aggregated_data_series[date_key]["story_views"] = 0;
		aggregated_data_series[date_key][ViewSourceIos] = 0;
		aggregated_data_series[date_key][ViewSourceAndroid] = 0;
		//aggregated_data_series[date_key][ViewSourceWeb] = 0;
		aggregated_data_series[date_key][ViewSourceDesktop] = 0;
		aggregated_data_series[date_key][viewSourceMobile] = 0;

		index_d = addDays(index_d,1);
	}

	for (var story_id_key in data_series) {
		single_story_obj = data_series[story_id_key];

		for (date_key in single_story_obj) {
			single_story_data_for_date = single_story_obj[date_key];
			if(aggregated_data_series.hasOwnProperty(date_key)){
				if (single_story_data_for_date.hasOwnProperty("remake_views") && aggregated_data_series[date_key].hasOwnProperty("remake_views"))
				 aggregated_data_series[date_key]["remake_views"] += single_story_data_for_date["remake_views"];
				if (single_story_data_for_date.hasOwnProperty("story_views") && aggregated_data_series[date_key].hasOwnProperty("story_views"))
				 aggregated_data_series[date_key]["story_views"] += single_story_data_for_date["story_views"];
				if (single_story_data_for_date.hasOwnProperty(ViewSourceIos) && aggregated_data_series[date_key].hasOwnProperty(ViewSourceIos))
				 aggregated_data_series[date_key][ViewSourceIos] += single_story_data_for_date[ViewSourceIos];
				if (single_story_data_for_date.hasOwnProperty(ViewSourceAndroid) && aggregated_data_series[date_key].hasOwnProperty(ViewSourceAndroid))
				 aggregated_data_series[date_key][ViewSourceAndroid] += single_story_data_for_date[ViewSourceAndroid];
				/*if (single_story_data_for_date.hasOwnProperty(ViewSourceWeb))
				 aggregated_data_series[date_key][ViewSourceWeb] += single_story_data_for_date[ViewSourceWeb];*/
				if (single_story_data_for_date.hasOwnProperty(ViewSourceDesktop) && aggregated_data_series[date_key].hasOwnProperty(ViewSourceDesktop))
				 aggregated_data_series[date_key][ViewSourceDesktop] += single_story_data_for_date[ViewSourceDesktop];
				if (single_story_data_for_date.hasOwnProperty(viewSourceMobile) && aggregated_data_series[date_key].hasOwnProperty(viewSourceMobile))
				 aggregated_data_series[date_key][viewSourceMobile] += single_story_data_for_date[viewSourceMobile];
			}
		}
	}

	return aggregated_data_series;
}

function isLastDayOfMonth(date) {
	month = date.getMonth();
	last_day = new Date(id.getFullYear(),month+1,0);
	if (date.getDate() == last_day.getDate() && date.getMonth() == last_day.getMonth() && date.getFullYear() == last_day.getFullYear()) {
		return true;
	} else {
		return false;
	}
}






