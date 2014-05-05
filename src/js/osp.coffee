osp = angular.module 'osp', ->

host = 'http://zeitl.com'
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

  $scope.getUnitForRage = ->
    if $scope.range == 'Biweek'
      'Week'
    else if $scope.range == 'Quarter'
      'Month'
    else
      $scope.range

  $scope.correctAmount = (amount) ->
    if $scope.range == 'Biweek'
      amount * 2
    else if $scope.range == 'Quarter'
      amount * 3
    else
      amount

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
        sensor = $filter('get_by_id')($scope.sensors, $scope.sensor_url)
      else
        sensor = if $scope.sensors.length > 0 then $scope.sensors[0] else null
      $scope.selectSensor(sensor)

  $scope.loadTicks = ->
    $http.get(host + '/api/sensors/' + $scope.selectedSensor.id + 
      '/ticks?start=' + $scope.chartStart.unix() +
      '&end=' + $scope.chartEnd.unix()).success((data) ->
        $scope.ticks = data.reverse()
        $scope.paginatedTicks = $scope.ticks.slice 0, kPageSize
        $scope.pages = Math.floor $scope.ticks.length / kPageSize
        $scope.pages += 1 if $scope.ticks.length % kPageSize
        $scope.page = 1
    ).error((data, status, headers, config) ->
      $scope.errorMsg = "Couldn't load list data from backend."
    )

  $scope.loadSensorData = ->
    if $scope.chartView
      $scope.loadDots()
    else
      $scope.loadTicks()

  $scope.loadDots = ->
    $scope.processing = true
    $http.get(host + '/api/sensors/' + $scope.selectedSensor.id + 
      '/dots?start=' + $scope.chartStart.unix() + 
      '&end=' + $scope.chartEnd.unix() +
      '&dots_per_day=' + $scope.dotsPerDay).success((data) ->
        if data?
          setTimeout(->
            ospMap.drawMap data, () ->
              $scope.$apply(()->
                $scope.processing = false
              )
          , 0)
        else
          $scope.errorMsg = "Backend didn't return any usable data"
    ).error((data, status, headers, config) ->
      $scope.errorMsg = "Couldn't load chart data from backend."
    )

  $scope.selectSensor = (sensor) ->
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

  $scope.saveCoordinatorName = (coordinator) ->
    $http.put(host + '/api/coordinators/' + $scope.selectedCoordinator.id, $scope.selectedCoordinator)

  $scope.setPage = (page) ->
    page = 1 if page < 1
    page = $scope.pages if page > $scope.pages
    $scope.page = page
    start = kPageSize*($scope.page-1)
    end = start+kPageSize
    $scope.paginatedTicks = $scope.ticks.slice start, end

osp.filter 'human_date', -> (value) -> moment(value).format("DD.MM.YYYY HH:mm")
osp.filter 'unnamed', -> (value) ->  if value then value else '(unnamed)'
osp.filter 'moment_date', -> (value) -> value.format("DD.MM.YYYY")
osp.filter 'get_by_id', -> (input, id) -> 
  for item in input
    if +item.id == +id
      return item
  return null