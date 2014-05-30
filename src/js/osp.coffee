osp = angular.module 'osp', ->

host = 'http://ardusensor.com'
#host = 'http://localhost:8084'

kPageSize = 50

osp.controller "MainController", ($scope, $http, $location, $filter) ->
  loc_base = $location.path().split("/")
  $scope.base = "/" + loc_base[1] + "/" + loc_base[2]

  $scope.sensor_url = (if loc_base.length > 3 then loc_base[3] else null)

  if $scope.base != ""
    $http.get(host + '/api/coordinators' + $scope.base).success((data) ->
      $scope.selectCoordinator(if data then data else null)
    ).error((data, status, headers, config) ->
      $scope.errorMsg = data or status or "Couldn't find coordinator, please check your URL."
    )

  $scope.range = 'Month'
  $scope.chartView = true
  $scope.ticks = []
  $scope.page = 1
  $scope.pages = 1
  $scope.chartStart = moment().subtract(1, 'month')
  $scope.chartEnd = moment()
  $scope.dotsPerDay = 12
  $scope.errorMsg = null

  $scope.editingCoordinatorLabel = false

  $scope.getUnitForRage = ->
    if $scope.range is 'Biweek'
      return 'Week'
    if $scope.range is 'Quarter'
      return 'Month'
    return $scope.range

  $scope.correctAmount = (amount) ->
    if $scope.range is 'Biweek'
      return amount * 2
    if $scope.range is 'Quarter'
      return amount * 3
    return amount

  $scope.slideRange = (amount) ->
    $scope.chartStart.add($scope.correctAmount(amount), $scope.getUnitForRage())
    $scope.chartEnd.add($scope.correctAmount(amount), $scope.getUnitForRage())
    $scope.loadSensorData()

  $scope.selectCoordinator = (coordinator) ->
    $scope.selectedCoordinator = coordinator
    $http.get(host + '/api/coordinators/' + $scope.selectedCoordinator.id + '/sensors').success (data) ->
      $scope.sensors = data
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
    $http.get(host + '/api/sensors/' + $scope.selectedSensor.id + 
      '/ticks?start=' + $scope.chartStart.unix() +
      '&end=' + $scope.chartEnd.unix()).success((data) ->
        $scope.renderTicks data
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

  $scope.loadSensorData = ->
    if $scope.chartView
      $scope.loadDots()
      return
    $scope.loadTicks()

  $scope.loadDots = ->
    if not $scope.selectedSensor
      $scope.renderDots []
      return
    $http.get(host + '/api/sensors/' + $scope.selectedSensor.id + 
      '/dots?start=' + $scope.chartStart.unix() + 
      '&end=' + $scope.chartEnd.unix() +
      '&dots_per_day=' + $scope.dotsPerDay).success((data) ->
        $scope.renderDots data
    ).error((data, status, headers, config) ->
      $scope.errorMsg = data or status or "Couldn't load chart data from backend."
    )

  $scope.renderDots = (data) ->
    if not data?
      $scope.errorMsg = "Backend didn't return any usable data"
      return
    $scope.processing = true
    setTimeout(->
      ospMap.drawMap data, () ->
        $scope.$apply(()->
          $scope.processing = false
        )
    , 0)

  $scope.setURI = (sensor) ->
    document.location.hash = $scope.base + "/" + sensor.id

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
      when 'Biweek' then $scope.dotsPerDay = 24
      when 'Week' then $scope.dotsPerDay = 24
      else $scope.dotsPerDay = null
    $scope.loadSensorData()

  $scope.saveCoordinatorLabel = (coordinator) ->
    $http.put(host + '/api/coordinators/' + $scope.selectedCoordinator.id, $scope.selectedCoordinator)
    $scope.editingCoordinatorLabel = false

  $scope.setPage = (page) ->
    page = 1 if page < 1
    page = $scope.pages if page > $scope.pages
    $scope.page = page
    start = kPageSize*($scope.page-1)
    end = start+kPageSize
    $scope.paginatedTicks = $scope.ticks.slice start, end

  $scope.editCoordinatorLabel = -> $scope.editingCoordinatorLabel = true
  $scope.isEditingCoordinatorLabel = -> $scope.editingCoordinatorLabel

# Filters are to be used in HTML markup only
osp.filter 'human_date', -> (value) -> moment(value).format("DD.MM.YYYY HH:mm")
osp.filter 'moment_date', -> (value) -> value.format("DD.MM.YYYY")
osp.filter 'last_four', -> (value) -> value.substr(value.length - 4, 4)
