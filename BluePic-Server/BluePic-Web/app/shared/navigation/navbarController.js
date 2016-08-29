angular.module('bluepicWebApp')
    .controller('navbarController', ['$scope', 'PropertiesService', '$state',
        function($scope, PropertiesService, $state) {
            'use strict';

            console.log("in navbarController, here's my token: " + PropertiesService.getAccessToken())

            $scope.goToProfile = function() {
                console.log("in navbarController, here's my token: " + PropertiesService.getAccessToken())
                $state.go("profile");
            }

        }]);
