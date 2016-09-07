angular.module('bluepicWebApp')
    .controller('tagCloudController', ['$scope',
        function($scope) {
            'use strict';

            $scope.searchTag = function (label) {

                $scope.searchTerm.value.$ = label;
            }

        }]);