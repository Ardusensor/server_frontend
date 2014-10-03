ui = angular.module 'ui', ->

ui.controller "MainController", ($scope, $http, $location, $filter) ->
  $scope.setVariablesFromHashbang = (hashbang) ->
    $scope.base = "/" + hashbang[1] + "/" + hashbang[2]

  $scope.setVariablesFromHashbang($location.path().split("/"))

  if $scope.base != ""
    $http.get('/api/coordinators' + $scope.base).success((data) ->
      $scope.selectCoordinator(if data then data else null)
    ).error((data, status, headers, config) ->
      $scope.errorMsg = data or status or "Couldn't find coordinator, please check your URL."
    )

  $scope.dotsPerDay = 24
  $scope.errorMsg = null
  $scope.latestCoordinatorReading = null

  $scope.editingCoordinatorLabel = false

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
      $scope.loadSensors()

  $scope.findbyID = (input, id) ->
    for item in input
      if item.id is id
        return item
    return null  

  $scope.setCurrentSensorLatestReading = (data) ->
    if not $scope.selectedSensor or not data
      return
    $scope.selectedSensor.last_tick = _.max(_.map(data, (x) -> moment(x.datetime)))

  $scope.renderDotsForSensor = (sensor) ->
    $scope.processing = true
    setTimeout(->
      uiCharts.drawChart sensor.dots, $filter('sensor_label')(sensor), () ->
        $scope.$apply(()->
          $scope.processing = false
        )
    , 0)

  $scope.dotsForSensor = (sensor) ->
    $http.get('/api/sensors/' + sensor.id + 
      '/dots?start=' + moment().subtract(1, 'month').unix() + 
      '&end=' + moment().unix() +
      '&dots_per_day=' + $scope.dotsPerDay).success((data) ->
        sensor.dots = data
        $scope.renderDotsForSensor(sensor)
    ).error((data, status, headers, config) ->
      $scope.errorMsg = data or status or "Couldn't load chart data from backend."
    )

  $scope.loadSensors = ->
    _.each($scope.sensors, (sensor) -> $scope.dotsForSensor(sensor))

  $scope.renderDots = (data) ->
    if not data?
      $scope.errorMsg = "Backend didn't return any usable data"
      return
    $scope.processing = true
    setTimeout(->
      uiCharts.drawChart data, $filter('last_four')($scope.selectedSensor.id), () ->
        $scope.$apply(()->
          $scope.processing = false
        )
    , 0)

  $scope.saveCoordinatorLabel = (coordinator) ->
    $http.put('/api/coordinators/' + coordinator.id, coordinator)
    coordinator.editingLabel = false

  $scope.saveSensor = (sensor) ->
    $http.put('/api/sensors/' + sensor.id, sensor).success((data) ->
      sensor = data
    )
    sensor.calibrating = false
    sensor.editingLabel = false

# Filters are to be used in HTML markup only
ui.filter 'human_date', -> (value) -> 
  time = moment(value)
  if moment().diff(time) < 950400000
    return time.fromNow(true)
  time.format("DD.MM.YYYY HH:mm")
ui.filter 'moment_date', -> (value) -> value.format("DD.MM.YYYY")
ui.filter 'last_four', -> (value) -> value.substr(value.length - 4, 4)
ui.filter 'float2', -> (value) -> Math.round((if value then (parseFloat(value) / 100) else 0) * 100) / 100
ui.filter 'sensor_label', -> (sensor) ->
  if sensor.label? && sensor.label.length > 0
    sensor.label
  else
    sensor.id.substr(sensor.id.length - 4, 4)
