window.uiCharts = {}

uiCharts.tempChart = null
uiCharts.hueChart = null
uiCharts.batChart = null
uiCharts.sigChart = null

uiCharts.putData = (labels, data, container, chart, min, max) ->
	return if data.length == 0

	chart = null

	elm = document.querySelector(container + " .chart")
	elm.innerHTML = ""

	chart = new Rickshaw.Graph(
		element: elm,
		renderer: 'line',
		height: 200,
		width: 600,
		min: min,
		max: max,
		series: [
			data: data,
			color: "#c05020"
		]
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

	uiCharts.putData(labels, temp, '#temp', uiCharts.tempChart, -20, 40)
	uiCharts.putData(labels, hue, '#hue', uiCharts.hueChart, 500, 1400)
	uiCharts.putData(labels, battery, '#battery', uiCharts.batChart, 2.5, 3.5)
	uiCharts.putData(labels, signal, '#signal', uiCharts.sigChart, "auto")

	if done?
		done()

	true
