
angular.module('bluepicWebApp')
.controller('homepageController', ['$scope', 'photos', 'PropertiesService',
    function($scope, photos, PropertiesService) {
        'use strict';

        $scope.photos = photos.data.records;

}]);
