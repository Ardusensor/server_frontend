//Get the context of the canvas element we want to select
var ctx = document.getElementById("lines").getContext("2d");

var data = {
	labels : ["January","February","March","April","May","June","July"],
	datasets : [
		{
			fillColor : "rgba(220,220,220,0.5)",
			strokeColor : "rgba(220,220,220,1)",
			pointColor : "rgba(220,220,220,1)",
			pointStrokeColor : "#fff",
			data : [65,59,90,81,56,55,40]
		},
		{
			fillColor : "rgba(151,187,205,0.5)",
			strokeColor : "rgba(151,187,205,1)",
			pointColor : "rgba(151,187,205,1)",
			pointStrokeColor : "#fff",
			data : [28,48,40,19,96,27,100]
		}
	]
}

var chart = new Chart(ctx).Line(data);

function ControllersCtrl($scope, $http) {
	$scope.controllers = [];

	$http({method: 'GET', url: 'http://zeitl.com/api/controllers'}).
  	success(function(data, status, headers, config) {
  			$scope.controllers = data;
  	}).
  	error(function(data, status, headers, config) {
  		console.log(data, status);
	});
}