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
 
  var _chart_area = chart_name.replace(/^#/, "");
  chart_area = document.getElementById(_chart_area);
  svg = d3.select(chart_area).select('svg');

  var empty = $(chart_area).is(':empty'); 
  
  if ( !empty )  {
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

