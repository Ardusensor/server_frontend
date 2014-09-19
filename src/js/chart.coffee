window.uiCharts = {}

uiCharts.tempChart = null
uiCharts.hueChart = null
uiCharts.batChart = null
uiCharts.sigChart = null

uiCharts.resizeChart = (chart) ->
	if chart?
		chart.configure {
			width: window.innerWidth * 0.9
		}
		chart.render()

resize = () ->
	uiCharts.resizeChart(uiCharts.tempChart)
	uiCharts.resizeChart(uiCharts.hueChart)
	uiCharts.resizeChart(uiCharts.batChart)
	uiCharts.resizeChart(uiCharts.sigChart)
		

window.addEventListener 'resize', resize

uiCharts.putData = (labels, data, container, min, max, name) ->
	return null if data.length == 0

	chart = null

	elm = document.querySelector(container + " .chart")
	elm.innerHTML = ""

	chart = new Rickshaw.Graph(
		element: elm,
		renderer: 'line',
		height: 200,
		width: window.innerWidth * 0.9,
		min: min,
		max: max,
		series: [
			data: data,
			color: "#c05020",
			name: name
		]
	)

	xFormat = (x) ->
		""

	yFormat = (y) ->
		Math.round(y * 100) / 100

	hoverDetail = new Rickshaw.Graph.HoverDetail(
		graph: chart,
		xFormatter: xFormat,
		yFormatter: yFormat
	)

	format = (n) ->
		labels[n]

	xelm = document.querySelector(container + " .x_axis")
	xelm.innerHTML = ""

	x_ticks = new Rickshaw.Graph.Axis.X(
		graph: chart,
		orientation: 'bottom',
		element: xelm,
		ticks: 5,
		pixelsPerTick: 150,
		tickFormat: format,
		width: 750
	)

	yelm = document.querySelector(container + ' .y_axis')
	yelm.innerHTML = ""

	y_ticks = new Rickshaw.Graph.Axis.Y(
		graph: chart,
		orientation: 'left',
		pixelsPerTick: 20,
		tickFormat: Rickshaw.Fixtures.Number.formatKMBT,
		element: yelm,
	)

	chart.render()

	return chart

uiCharts.drawChart = (data, done) ->
	labels = []
	temp = []
	hue = []
	battery = []
	signal = []

	_.each(data, (model, idx) ->
		labels.push(moment(model.datetime).format("DD.MM.YYYY"))
		temp.push({x: idx, y: (if model.temperature? then parseFloat(model.temperature) else null)})
		hue.push({x: (idx + 1), y: (if model.sensor2? then parseInt(model.sensor2) else null)})
		battery.push({x: (idx + 1), y: (if model.battery_voltage_visual? then parseFloat(model.battery_voltage_visual) else null)})
		signal.push({x: (idx + 1), y: (if model.radio_quality? then parseInt(model.radio_quality) else null)})
	)

	uiCharts.tempChart = uiCharts.putData(labels, temp, '#temp', -20, 40, "Temperature")
	uiCharts.hueChart = uiCharts.putData(labels, hue, '#hue', 400, 1000, "Humidity")
	uiCharts.batChart = uiCharts.putData(labels, battery, '#battery', 2.5, 3.5, "Battery")
	uiCharts.sigChart = uiCharts.putData(labels, signal, '#signal', "auto", "auto", "Signal strength")

	if done?
		done()

	true
