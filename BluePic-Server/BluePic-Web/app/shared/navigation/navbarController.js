angular.module('bluepicWebApp')
    .controller('navbarController', ['$scope', 'PropertiesService', '$state',
        function($scope, PropertiesService, $state) {
            'use strict';

            $scope.goToProfile = function() {
                $state.go("profile");
            }

        }]);
