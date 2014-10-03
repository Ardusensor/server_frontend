window.uiCharts = {}

uiCharts.mainChart = null
uiCharts.series = []

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

uiCharts.palette = new Rickshaw.Color.Palette( { scheme: 'munin' } )

uiCharts.initChart = (container) ->
  chart = null

  uiCharts.clearInner(container + " .chart")
  uiCharts.clearInner('#slider')
  uiCharts.clearInner('#legend')
  uiCharts.clearInner('#axis0')
  uiCharts.clearInner('#axis1')

  chart = new Rickshaw.Graph(
    element: document.querySelector(container + " .chart"),
    renderer: 'multi',
    height: 400,
    width: window.innerWidth - 165,
    dotSize: 5,
    pixelsPerTick: 20,
    max: 40,
    min: -30,
    series: uiCharts.series
  )

  chart.render()

  return chart

uiCharts.addSeries = (series) ->
  uiCharts.clearInner('#slider')
  uiCharts.clearInner('#legend')
  uiCharts.clearInner('#axis0')
  uiCharts.clearInner('#axis1')

  uiCharts.series.push(series)

  chart = uiCharts.mainChart

  new Rickshaw.Graph.RangeSlider.Preview({
    graph: chart,
    element: document.querySelector('#slider')
  })

  new Rickshaw.Graph.HoverDetail({
    graph: chart,
    #yFormatter: (y) -> (y + 30) * 8.6 + 400
    formatter: (series, x, y, formattedX, formattedY, d) ->
      if series.ident? && series.ident == 'hue'
        formattedY = (y + 30) * 8.6 + 400
      return series.name + ':&nbsp;' + formattedY
  })

  legend = new Rickshaw.Graph.Legend({
    graph: chart,
    element: document.querySelector('#legend')
  })
  
  new Rickshaw.Graph.Behavior.Series.Highlight({
    graph: chart,
    legend: legend,
    disabledColor: () -> return 'rgba(0, 0, 0, 0.2)'
  })

  new Rickshaw.Graph.Behavior.Series.Toggle({
    graph: chart,
    legend: legend
  })

  new Rickshaw.Graph.Axis.Time({
    graph: uiCharts.mainChart
  })

  new Rickshaw.Graph.Axis.Y({
    element: document.getElementById('axis0'),
    graph: chart,
    orientation: 'left',
    pixelsPerTick: 20
  })

  new Rickshaw.Graph.Axis.Y({
    element: document.getElementById('axis1'),
    graph: chart,
    grid: false,
    orientation: 'right',
    tickFormat: Rickshaw.Fixtures.Number.formatKMBT,
    pixelsPerTick: 20,
    tickFormat: (y) -> (y + 30) * 8.6 + 400
  })

  uiCharts.mainChart.update()

  return chart


uiCharts.drawChart = (data, sensorName, done) ->
  temp = []
  hue = []

  _.each(data, (model, idx) ->
    xlabel = +moment(model.datetime).format('X')
    temp.push({x: xlabel, y: (if model.temperature? then parseFloat(model.temperature) else null)})
    hue.push({x: xlabel, y: (if model.sensor2? then ((parseInt(model.sensor2) - 400) / 8.6 - 30) else null)})
  )

  unless uiCharts.mainChart?
    uiCharts.series = [
      {
        name: "Temperature (" + sensorName + ")",
        data: temp,
        color: uiCharts.palette.color(),
        renderer: 'line',
        ident: "temp",
      }
    ]

    uiCharts.mainChart = uiCharts.initChart('#chart')
  else
    uiCharts.addSeries({
        name: "Temperature (" + sensorName + ")",
        data: temp,
        color: uiCharts.palette.color(),
        renderer: 'line',
        ident: "temp",
      })

  uiCharts.addSeries({
      name: "Humidity (" + sensorName + ")",
      data: hue,
      color: uiCharts.palette.color(),
      renderer: 'line',
      ident: "hue",
    })

  if done?
    done()

  true
