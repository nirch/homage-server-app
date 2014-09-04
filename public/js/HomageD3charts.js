NormalFractionGraphType = 0
NormalValueGraphType = 1
AvgValueGraphType = 2
StoryViewsGraphType = 3
PieChartGraphType =  4
UndefinedGraphType = 5

//old. new id /js/d3LineChart.js
/*function genLineChart(data,container) {
	
  var	margin = {top: 30, right: 20, bottom: 30, left: 50},
  width = 500 - margin.left - margin.right,
  height = 250 - margin.top - margin.bottom;

  // Parse the date / time
  var parseDate = d3.time.format("%Y-%m-%d").parse;

  // Set the ranges
  var	x = d3.time.scale().range([0, width]);
  var	y = d3.scale.linear().range([height, 0]);

  // Define the axes
  var	xAxis = d3.svg.axis().scale(x)
  .orient("bottom").ticks(5);

  var	yAxis = d3.svg.axis().scale(y)
  .orient("left").ticks(5);

  // Define the line
  var	valueline = d3.svg.line()
  .x(function(d) { return x(d.date); })
  .y(function(d) { return y(d.val); });

  var	chart = container
  .append("svg")
  .attr("width", width + margin.left + margin.right)
  .attr("height", height + margin.top + margin.bottom)
  .append("g")
  .attr("transform", "translate(" + margin.left + "," + margin.top + ")");
  
  data.forEach(function(d) {
    d.date = parseDate(d.date);
    d.val  = +d.val;
  });
  
  x.domain(d3.extent(data, function(d) { return d.date; }));
  y.domain([0, d3.max(data, function(d) { return d.val; })]);

  chart.append("path")
  .attr("class", "line")
  .attr("d", valueline(data));

  	// Add the X Axis
  	chart.append("g")
    .attr("class", "x axis")
    .attr("transform", "translate(0," + height + ")")
    .call(xAxis);

  	// Add the Y Axis
  	chart.append("g")
    .attr("class", "y axis")
    .call(yAxis);
}*/

function genPieChart(data,chart_name) {

  console.log("data: " + data);

  var width = 400,
  height = 220,
  radius = Math.min(width, height) / 2;

  var margin = 100;

  var color = d3.scale.ordinal()
  .range(["#98abc5", "#8a89a6", "#7b6888", "#6b486b", "#a05d56", "#d0743c", "#ff8c00"]);

  var arc = d3.svg.arc()
  .outerRadius(radius - 10)
  .innerRadius(radius - 70);

  var pie = d3.layout.pie()
  .sort(null)
  .value(function(d) { return d.value; });

  svg = d3.select(chart_name).select('svg').select('g');

  if (svg.empty()) {
    svg = d3.select(chart_name)
      .append('svg:svg')
        .attr('width', width)
        .attr('height', height)
      .append('svg:g')
        .attr('transform', 'translate(' + margin + ',' + margin + ')');

    /*yAxisGroup = svg.append('svg:g')
      .attr('class', 'yTick')
      .call(yAxis);

    xAxisGroup = svg.append('svg:g')
      .attr('class', 'xTick')
      .call(xAxis);

    svg.append('svg:g').attr('id' , 'data_line_g');
    svg.append('svg:g').attr('id' , 'data_circle_g' );*/
  }


  /*var chart = container
  .append("svg")
  .attr("width", width)
  .attr("height", height)
  .append("g")
  .attr("transform", "translate(" + width / 2 + "," + height / 2 + ")");*/

  data.forEach(function(d) {
    d.value = +d.value;
  });

  var g = svg.selectAll(".arc")
  .data(pie(data))
  .enter().append("g")
  .attr("class", "arc");

  g.append("path")
  .attr("d", arc)
  .style("fill", function(d) { return color(d.key); });

  g.append("text")
  .attr("transform", function(d) { return "translate(" + arc.centroid(d) + ")"; })
  .attr("dy", ".35em")
  .style("text-anchor", "middle")
  .text(function(d) { return d.key; });
}


function genStackedAndGroupBarChart(data,innerColumns,chart_name) {

  console.log("generating stacked and grouped chart");
  console.log(data);

  var margin = {top: 20, right: 20, bottom: 30, left: 40},
  width = 500 - margin.left - margin.right,
  height = 250 - margin.top - margin.bottom;

  var x0 = d3.scale.ordinal()
  .rangeRoundBands([0, width], 0.05);

  var x1 = d3.scale.ordinal();

  var y = d3.scale.linear()
  .range([height, 0]);

  var xAxis = d3.svg.axis()
  .scale(x0)
  .orient("bottom");

  var yAxis = d3.svg.axis()
  .scale(y)
  .orient("left")
  .tickFormat(d3.format(".2s"));

  var color = d3.scale.ordinal()
  .range(["#98abc5", "#8a89a6", "#7b6888", "#6b486b", "#a05d56", "#d0743c", "#ff8c00"]);
 
  console.log("chart name is: " + chart_name);

  var _chart_area = chart_name.replace(/^#/, "");
  chart_area = document.getElementById(_chart_area);
  svg = d3.select(chart_area).select('svg');

  if ( svg != null ) {
    console.log("grouped chart already populized in: " + chart_name + ". removing svg");
    console.log("chart populized, removing");
    chart_area.innerHTML = ""; // clear out the SVG
  }

  var chart = d3.select(chart_area)
  .append("svg")
  .attr("width", width + margin.left + margin.right)
  .attr("height", height + margin.top + margin.bottom)
  .append("g")
  .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

  var yBegin;
  
  columnHeaders = [];
  for (key in innerColumns) {
    console.log("key:");
    console.log(key);
  	columnHeaders = columnHeaders.concat(innerColumns[key]);
  };
  
  color.domain(columnHeaders);

  data.forEach(function(d) {
    var yColumn = new Array();
    d.columnDetails = columnHeaders.map(function(name) {

      for (ic in innerColumns) {
        if($.inArray(name, innerColumns[ic]) >= 0){
          if (!yColumn[ic]){
            yColumn[ic] = 0;
          }
          yBegin = yColumn[ic];
          yColumn[ic] += +d[name];
          return {name: name, column: ic, yBegin: yBegin, yEnd: +d[name] + yBegin,};
        }
      }
    });
    d.total = d3.max(d.columnDetails, function(d) { 
      return d.yEnd; 
    });
  });

  x0.domain(data.map(function(d) { return d.date; }));
  x1.domain(d3.keys(innerColumns)).rangeRoundBands([0, x0.rangeBand()-50]);

  y.domain([0, d3.max(data, function(d) { 
    return d.total; 
  })]);

  chart.append("g")
  .attr("class", "x axis")
  .attr("transform", "translate(0," + height + ")")
  .call(xAxis);

  chart.append("g")
  .attr("class", "y axis")
  .call(yAxis)
  .append("text")
  .attr("transform", "rotate(-90)")
  .attr("y", 6)
  .attr("dy", ".7em")
  .style("text-anchor", "end")
  .text("");

  var project_stackedbar = chart.selectAll(".project_stackedbar")
  .data(data)
  .enter().append("g")
  .attr("class", "g")
  .attr("transform", function(d) { return "translate(" + x0(d.date) + ",0)"; });

  project_stackedbar.selectAll("rect")
  .data(function(d) { return d.columnDetails; })
  .enter().append("rect")
  .attr("width", x1.rangeBand())
  .attr("x", function(d) { 
    return x1(d.column);
  })
  .attr("y", function(d) { 
    return y(d.yEnd); 
  })
  .attr("height", function(d) { 
    return y(d.yBegin) - y(d.yEnd); 
  })
  .style("fill", function(d) { return color(d.name); });

  var legend = chart.selectAll(".legend")
  .data(columnHeaders.slice().reverse())
  .enter().append("g")
  .attr("class", "legend")
  .attr("transform", function(d, i) { return "translate(0," + i * 20 + ")"; });

  legend.append("rect")
  .attr("x", width - 18)
  .attr("width", 18)
  .attr("height", 18)
  .style("fill", color);

  legend.append("text")
  .attr("x", width - 24)
  .attr("y", 9)
  .attr("dy", ".35em")
  .style("text-anchor", "end")
  .text(function(d) { return d; });

}

