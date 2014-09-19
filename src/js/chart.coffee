window.uiCharts = {}

uiCharts.mainChart = null
uiCharts.hueChart = null
uiCharts.batChart = null
uiCharts.sigChart = null

uiCharts.resizeChart = (chart) ->
  if chart?
    chart.configure {
      width: window.innerWidth - 165
    }
    chart.render()

resize = () ->
  uiCharts.resizeChart(uiCharts.mainChart)

window.addEventListener 'resize', resize

uiCharts.clearInner = (selector) ->
  elem = document.querySelector(selector)
  if elem?
    elem.innerHTML = ""

uiCharts.putData = (labels, temp, hue, container, min, max, name) ->
  return null if temp.length == 0 || hue.length == 0

  chart = null

  uiCharts.clearInner(container + " .chart")

  temp_min = _.min(_.pluck(temp, 'y'))
  temp_max = _.max(_.pluck(temp, 'y'))
  
  hue_min = _.min(_.pluck(hue, 'y'))
  hue_max = _.max(_.pluck(hue, 'y'))


  chart = new Rickshaw.Graph(
    element: document.querySelector(container + " .chart"),
    renderer: 'multi',
    height: 200,
    width: window.innerWidth - 165,
    dotSize: 5,
    series: [
      {
        name: "Temperature",
        data: temp,
        color: "#c05020",
        renderer: 'stack',
        scale: d3.scale.linear().domain([temp_min, temp_max]).nice(),
      },
      {
        name: "Humidity",
        data: hue,
        color: "#428bca",
        renderer: 'line',
        scale: d3.scale.pow().domain([hue_min, hue_max]).nice()
      }
    ]
  )

  uiCharts.clearInner('#slider')

  new Rickshaw.Graph.RangeSlider.Preview({
    graph: chart,
    element: document.querySelector('#slider')
  })

  new Rickshaw.Graph.HoverDetail({
    graph: chart
  })

  uiCharts.clearInner('#legend')

  legend = new Rickshaw.Graph.Legend({
    graph: chart,
    element: document.querySelector('#legend')
  })
  
  highlighter = new Rickshaw.Graph.Behavior.Series.Highlight({
    graph: chart,
    legend: legend,
    disabledColor: () -> return 'rgba(0, 0, 0, 0.2)'
  })

  highlighter = new Rickshaw.Graph.Behavior.Series.Toggle({
    graph: chart,
    legend: legend
  })

  new Rickshaw.Graph.Axis.Time({
    graph: chart
  })

  uiCharts.clearInner('#axis0')
  uiCharts.clearInner('#axis1')

  new Rickshaw.Graph.Axis.Y.Scaled({
    element: document.getElementById('axis0'),
    graph: chart,
    orientation: 'left',
    scale: d3.scale.linear().domain([temp_min, temp_max]).nice(),
    pixelsPerTick: 20
  })

  new Rickshaw.Graph.Axis.Y.Scaled({
    element: document.getElementById('axis1'),
    graph: chart,
    grid: false,
    orientation: 'right',
    scale: d3.scale.pow().domain([hue_min, hue_max]).nice(),
    tickFormat: Rickshaw.Fixtures.Number.formatKMBT,
    pixelsPerTick: 20
  })

  chart.render()

  return chart

uiCharts.drawChart = (data, done) ->
  labels = []
  temp = []
  hue = []
  battery = []
  signal = []

  _.each(data, (model, idx) ->
    xlabel = +moment(model.datetime).format('X')
    temp.push({x: xlabel, y: (if model.temperature? then parseFloat(model.temperature) else null)})
    hue.push({x: xlabel, y: (if model.sensor2? then parseInt(model.sensor2) else null)})
  )

  uiCharts.mainChart = uiCharts.putData(labels, temp, hue, '#chart', -30, 40, "Temperature")

  if done?
    done()

  true
