function drawC3StackedColumnChart(data_for_chart,chart_name) {
	
	var chart = c3.generate({
      bindto: chart_name,
      size: {
        width: 550,
        height: 300
      },
      data: {
      	  x: 'x',
          columns: data_for_chart,
          		//data example
          		/*[
          	  		['x', '2013-01-01', '2013-01-02', '2013-01-03', '2013-01-04', '2013-01-05', '2013-01-06'],	
              		['data1', 30, 200, 200, 400, 150, 250],
              		['data2', 130, 100, 100, 200, 150, 50],
              		['data3', 230, 200, 200, 300, 250, 250]
		         ],*/
          type: 'bar',
          groups: [
              ['remake views', 'story views'],
              ['iOS views','Android views','web views']
          ]
      },
      axis: {
        x: {
            type: 'timeseries',
            tick: {
                format: '%Y-%m-%d'
            }
        }
    },
      grid: {
          y: {
              lines: [{value:0}]
          }
      }
    });
}



                        