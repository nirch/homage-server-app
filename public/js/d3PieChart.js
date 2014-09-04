function drawD3PieChart(data,chart_name) {

	console.log("chart name is: " + chart_name);

	var _chart_area = chart_name.replace(/^#/, "");
	chart_area = document.getElementById(_chart_area);
	svg = d3.select(chart_area).select('svg');

	if ( svg != null ) {
		console.log("chart populized, removing");
		chart_area.innerHTML = ""; // clear out the SVG
		d3.select(chart_area).attr('d3pie', null);
	}

	pie = new d3pie(chart_name, {
	
	"footer": {
		"color": "#999999",
		"fontSize": 10,
		"font": "open sans",
		"location": "bottom-left"
	},
	"size": {
		"canvasWidth": 590,
		"pieInnerRadius": "21%",
		"pieOuterRadius": "84%"
	},
	"data": {
		"sortOrder": "value-desc",
		"content": data
	},
	"labels": {
		"outer": {
			"pieDistance": 32
		},
		"inner": {
			"hideWhenLessThanPercentage": 3
		},
		"mainLabel": {
			"fontSize": 11
		},
		"percentage": {
			"color": "#ffffff",
			"decimalPlaces": 0
		},
		"value": {
			"color": "#adadad",
			"fontSize": 11
		},
		"lines": {
			"enabled": true
		}
	},
	"effects": {
		"pullOutSegmentOnClick": {
			"effect": "linear",
			"speed": 400,
			"size": 8
		}
	},
	"misc": {
		"gradient": {
			"enabled": true,
			"percentage": 100
		}
	}
});
	console.log("created pie:");
	console.log(pie);

}