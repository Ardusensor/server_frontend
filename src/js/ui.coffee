ui = angular.module 'ui', ->

kPageSize = 400

ui.controller "MainController", ($scope, $http, $location, $filter) ->
  $scope.setVariablesFromHashbang = (hashbang) ->
    $scope.base = "/" + hashbang[1] + "/" + hashbang[2]
    $scope.sensor_url = (if hashbang.length > 3 then hashbang[3] else null)
    $scope.range = (if hashbang.length > 4 then hashbang[4] else 'Month')
    $scope.chartStart = (if hashbang.length > 5 then moment.utc(hashbang[5], 'X') else moment().subtract(1, 'month'))
    $scope.chartEnd = (if hashbang.length > 6 then moment.utc(hashbang[6], 'X') else moment())

  $scope.setVariablesFromHashbang($location.path().split("/"))

  if $scope.base != ""
    $http.get('/api/coordinators' + $scope.base).success((data) ->
      $scope.selectCoordinator(if data then data else null)
    ).error((data, status, headers, config) ->
      $scope.errorMsg = data or status or "Couldn't find coordinator, please check your URL."
    )

  $scope.chartView = true
  $scope.ticks = []
  $scope.page = 1
  $scope.pages = 1
  $scope.dotsPerDay = 12
  $scope.errorMsg = null
  $scope.latestCoordinatorReading = null

  $scope.editingCoordinatorLabel = false

  $scope.getUnitForRage = ->
    if $scope.range is 'Quarter'
      return 'Month'
    return $scope.range

  $scope.correctAmount = (amount) ->
    if $scope.range is 'Quarter'
      return amount * 3
    return amount

  $scope.slideRange = (amount) ->
    $scope.chartStart.add($scope.correctAmount(amount), $scope.getUnitForRage())
    $scope.chartEnd.add($scope.correctAmount(amount), $scope.getUnitForRage())
    $scope.setURI()
    $scope.loadSensorData()

  $scope.getLatestCoordinatorReading = (coordinator) ->
    $http.get('/api/coordinators/' + $scope.selectedCoordinator.id + '/readings?start=0&end=0').success((data) ->
      $scope.latestCoordinatorReading = data[0]
    )

  $scope.selectCoordinator = (coordinator) ->
    $scope.selectedCoordinator = coordinator
    $scope.getLatestCoordinatorReading(coordinator)
    $http.get('/api/coordinators/' + $scope.selectedCoordinator.id + '/sensors').success (data) ->
      # avoid angular automatic reorder/rerender so we can update currentSensor properties
      $scope.sensors = _.sortBy(data, (x) -> -1 * (moment(x.last_tick).utc()))
      $scope.predicate = 'last_tick'
      if $scope.sensor_url
        sensor = $scope.findbyID $scope.sensors, $scope.sensor_url
      else
        sensor = if $scope.sensors.length > 0 then $scope.sensors[0] else null
      $scope.selectSensor(sensor)

  $scope.findbyID = (input, id) ->
    for item in input
      if item.id is id
        return item
    return null  

  $scope.loadTicks = ->
    if not $scope.selectedSensor
      $scope.renderTicks null
      return
    $http.get('/api/sensors/' + $scope.selectedSensor.id + 
      '/ticks?start=' + $scope.chartStart.unix() +
      '&end=' + $scope.chartEnd.unix()).success((data) ->
        $scope.renderTicks data
        $scope.setCurrentSensorLatestReading data
    ).error((data, status, headers, config) ->
      $scope.errorMsg = data or status or "Couldn't load list data from backend."
    )

  $scope.renderTicks = (data) ->
    if data is "null"
      data = null
    $scope.ticks = if data? then data.reverse() else []
    $scope.paginatedTicks = $scope.ticks.slice 0, kPageSize
    $scope.pages = Math.floor $scope.ticks.length / kPageSize
    $scope.pages += 1 if $scope.ticks.length % kPageSize
    $scope.page = 1

  $scope.setCurrentSensorLatestReading = (data) ->
    if not $scope.selectedSensor or not data
      return
    $scope.selectedSensor.last_tick = _.max(_.map(data, (x) -> moment(x.datetime)))

  $scope.loadSensorData = ->
    if $scope.chartView
      $scope.loadDots()
      return
    $scope.loadTicks()

  $scope.loadDots = ->
    if not $scope.selectedSensor
      $scope.renderDots []
      return
    $http.get('/api/sensors/' + $scope.selectedSensor.id + 
      '/dots?start=' + $scope.chartStart.unix() + 
      '&end=' + $scope.chartEnd.unix() +
      '&dots_per_day=' + $scope.dotsPerDay).success((data) ->
        $scope.renderDots data
        $scope.setCurrentSensorLatestReading data
    ).error((data, status, headers, config) ->
      $scope.errorMsg = data or status or "Couldn't load chart data from backend."
    )

  $scope.renderDots = (data) ->
    if not data?
      $scope.errorMsg = "Backend didn't return any usable data"
      return
    $scope.processing = true
    setTimeout(->
      uiCharts.drawChart data, () ->
        $scope.$apply(()->
          $scope.processing = false
        )
    , 0)

  $scope.buildURI = (sensor) ->
    $scope.base + "/" + 
    sensor.id + "/" + 
    $scope.range + "/" + 
    $scope.chartStart.unix() + "/" + 
    $scope.chartEnd.unix()

  $scope.setURI = (sensor) ->
    sensor ||= $scope.selectedSensor
    document.location.hash = $scope.buildURI(sensor)

  $scope.selectSensor = (sensor) ->
    $scope.setURI(sensor)
    $scope.selectedSensor = sensor
    $scope.loadSensorData()

  $scope.toggleChartView = (active) ->
    $scope.chartView = active
    $scope.loadSensorData()

  $scope.selectRange = (range) ->
    $scope.range = range
    $scope.chartStart = moment($scope.chartEnd).subtract($scope.correctAmount(1), $scope.getUnitForRage())
    switch $scope.range
      when 'Year' then $scope.dotsPerDay = 1
      when 'Quarter' then $scope.dotsPerDay = 4
      when 'Month' then $scope.dotsPerDay = 12
      when 'Day' then $scope.dotsPerDay = 24
      when 'Week' then $scope.dotsPerDay = 24
      else $scope.dotsPerDay = null
    $scope.setURI()
    $scope.loadSensorData()

  $scope.setToday = () ->
    $scope.chartEnd = moment()
    $scope.selectRange($scope.range)

  $scope.saveCoordinatorLabel = (coordinator) ->
    $http.put('/api/coordinators/' + coordinator.id, coordinator)
    coordinator.editingLabel = false

  $scope.saveSensor = (sensor) ->
    $http.put('/api/sensors/' + sensor.id, sensor).success((data) ->
      sensor = data
    )
    sensor.calibrating = false
    sensor.editingLabel = false

  $scope.setPage = (page) ->
    page = 1 if page < 1
    page = $scope.pages if page > $scope.pages
    $scope.page = page
    start = kPageSize*($scope.page-1)
    end = start+kPageSize
    $scope.paginatedTicks = $scope.ticks.slice start, end

  $scope.pageRange = () ->
    [1..$scope.pages]

# Filters are to be used in HTML markup only
ui.filter 'human_date', -> (value) -> 
  time = moment(value)
  if moment().diff(time) < 950400000
    return time.fromNow(true)
  time.format("DD.MM.YYYY HH:mm")
ui.filter 'moment_date', -> (value) -> value.format("DD.MM.YYYY")
ui.filter 'last_four', -> (value) -> value.substr(value.length - 4, 4)
ui.filter 'valid_uri', -> (sensor, scope) -> scope.buildURI(sensor)
ui.filter 'float2', -> (value) -> Math.round((if value then (parseFloat(value) / 100) else 0) * 100) / 100
