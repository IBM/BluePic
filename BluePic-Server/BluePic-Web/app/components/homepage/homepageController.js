
angular.module('bluepicWebApp')
.controller('homepageController', ['$scope', 'photos', 'PropertiesService',
    function($scope, photos, PropertiesService) {
        'use strict';

        console.log("here's my token: " + PropertiesService.getAccessToken())
        $scope.photos = photos.data.records;

}]);
