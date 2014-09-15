
function drawD3LineChart(data,chart_name) {
	var w = 450,
	h = 275;

	var monthNames = [ "January", "February", "March", "April", "May", "June",
	"July", "August", "September", "October", "November", "December" ];

	var maxDataPointsForDots = 50,
	transitionDuration = 1000;

	var margin = 40;
	var max = d3.max(data, function(d) { return d.value });
	var min = 0;
	var pointRadius = 4;
	var x = d3.time.scale().range([0, w - margin * 2]).domain([data[0].date, data[data.length - 1].date]);
	var y = d3.scale.linear().range([h - margin * 2, 0]).domain([min, max]);

	var xAxis = d3.svg.axis()
					.scale(x).tickSize(h - margin * 2).tickPadding(10).ticks(7);
	var yAxis = d3.svg.axis()
					.scale(y).orient('left').tickSize(-w + margin * 2).tickPadding(10);
	var t = null;

	svg = d3.select(chart_name).select('svg').select('g');

	if (svg.empty()) {
		svg = d3.select(chart_name)
			.append('svg:svg')
				.attr('width', w)
				.attr('height', h)
				.attr('class', 'viz')
			.append('svg:g')
				.attr('transform', 'translate(' + margin + ',' + margin + ')');

		yAxisGroup = svg.append('svg:g')
			.attr('class', 'yTick')
			.call(yAxis);

		xAxisGroup = svg.append('svg:g')
			.attr('class', 'xTick')
			.call(xAxis);

		svg.append('svg:g').attr('id' , 'data_line_g');
		svg.append('svg:g').attr('id' , 'data_circle_g' );
	}

	t = svg.transition().duration(transitionDuration);
	t.select('.yTick').call(yAxis);
	t.select('.xTick').call(xAxis);
	dataLinesGroup = svg.select('#data_line_g');
	dataCirclesGroup = svg.select('#data_circle_g');

	var dataLines = dataLinesGroup.selectAll('.data-line')
			.data([data]);

	var line = d3.svg.line()
		// assign the X function to plot our line as we wish
		.x(function(d,i) { 
			// verbose logging to show what's actually being done
			//console.log('Plotting X value for date: ' + d.date + ' using index: ' + i + ' to be at: ' + x(d.date) + ' using our xScale.');
			// return the X coordinate where we want to plot this datapoint
			//return x(i); 
			return x(d.date); 
		})
		.y(function(d) { 
			// verbose logging to show what's actually being done
			//console.log('Plotting Y value for data value: ' + d.value + ' to be at: ' + y(d.value) + " using our yScale.");
			// return the Y coordinate where we want to plot this datapoint
			//return y(d); 
			return y(d.value); 
		})
		.interpolate("linear");


		var garea = d3.svg.area()
		.interpolate("linear")
		.x(function(d) { 
			// verbose logging to show what's actually being done
			return x(d.date); 
		})
		.y0(h - margin * 2)
		.y1(function(d) { 
			// verbose logging to show what's actually being done
			return y(d.value); 
		});

	dataLines
		.enter()
		.append('svg:path')
            	.attr("class", "area")
            	.attr("id" , "line_chart_path")
            	//.attr("d", garea(data));

	dataLines.enter().append('path')
		 .attr('class', 'data-line')
		 .style('opacity', 0.3)
		 .attr("id" , "line_chart_path")
		 .attr("d", line(data));

	dataLines.transition()
		.attr("d", line)
		.duration(transitionDuration)
			.style('opacity', 1)
                        .attr("transform", function(d) { return "translate(" + x(d.date) + "," + y(d.value) + ")"; });

	dataLines.exit()
		.transition()
		.attr("d", line)
		.duration(transitionDuration)
                        .attr("transform", function(d) { return "translate(" + x(d.date) + "," + y(0) + ")"; })
			.style('opacity', 1e-6)
			.remove();

	d3.selectAll(".area").transition()
		.duration(transitionDuration)
		//.attr("d", garea(data));

	var circles = dataCirclesGroup.selectAll('.data-point')
		.data(data);

	circles
		.enter()
			.append('svg:circle')
				.attr('class', 'data-point')
				.style('opacity', 1e-6)
				.attr('cx', function(d) { return x(d.date) })
				.attr('cy', function() { return y(0) })
				.attr('r', function() { return (data.length <= maxDataPointsForDots) ? pointRadius : 0 })
			.transition()
			.duration(transitionDuration)
				.style('opacity', 1)
				.attr('cx', function(d) { return x(d.date) })
				.attr('cy', function(d) { return y(d.value) });

	circles
		.transition()
		.duration(transitionDuration)
			.attr('cx', function(d) { return x(d.date) })
			.attr('cy', function(d) { return y(d.value) })
			.attr('r', function() { return (data.length <= maxDataPointsForDots) ? pointRadius : 0 })
			.style('opacity', 1);

	circles
		.exit()
			.transition()
			.duration(transitionDuration)
				// Leave the cx transition off. Allowing the points to fall where they lie is best.
				//.attr('cx', function(d, i) { return xScale(i) })
				.attr('cy', function() { return y(0) })
				.style("opacity", 1e-6)
				.remove();

      $('svg circle').tipsy({ 
        gravity: 'w', 
        html: true, 
        title: function() {
          var d = this.__data__;
	  var pDate = d.date;
          return 'Date: ' + pDate.getDate() + " " + monthNames[pDate.getMonth()] + " " + pDate.getFullYear() + '<br>Value: ' + d.value; 
        }
      });
}