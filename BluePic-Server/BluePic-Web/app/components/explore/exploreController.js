
angular.module('bluepicWebApp')
.controller('exploreController', ['$scope', 'photos',
    function($scope, photos) {
        'use strict';

        $scope.photos = photos.data.records;

        $scope.searchTerm = { value: ""};


    }]);
