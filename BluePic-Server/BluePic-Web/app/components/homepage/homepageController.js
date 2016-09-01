
angular.module('bluepicWebApp')
.controller('homepageController', ['$scope', 'photos', 'PropertiesService', '$state',
    function($scope, photos, PropertiesService, $state) {
        'use strict';

        $scope.photos = photos.data.records;

        $scope.openPhoto = function(id, index) {
            console.log("index: "+index);
            PropertiesService.setPhotos($scope.photos);
            PropertiesService.setPhotoIndex(index);
            PropertiesService.setPhotoId(id);
            $state.go("singlePhoto", {photoId:id });
        }

}]);
