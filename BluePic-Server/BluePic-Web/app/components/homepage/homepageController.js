
angular.module('bluepicWebApp')
.controller('homepageController', ['$scope', 'photos', 'PropertiesService', '$state',
    function($scope, photos, PropertiesService, $state) {
        'use strict';

        $scope.photos = photos.data.records;

        $scope.openPhoto = function(id) {
            $state.go("singlePhoto", {photoId:id})
        }

}]);
