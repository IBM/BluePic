
angular.module('bluepicWebApp')
.controller('homepageController', ['$scope', 'photos',
    function($scope, photos) {
        'use strict';

        $scope.photos = photos.data.records;

}]);
