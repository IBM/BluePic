angular.module('bluepicWebApp')
    .controller('photoCardsController', ['$scope', '$state', 'PropertiesService',
        function($scope, $state, PropertiesService) {
            'use strict';

            $scope.convertDMS = function(lat, lng) {

                return PropertiesService.getDMSCoordinates(lat, lng);
            }

            $scope.formatTimestamp = function(timestamp) {

                return PropertiesService.getFormattedTimestamp(timestamp);
            }

            $scope.openPhoto = function(id, index) {

                PropertiesService.setPhotos($scope.photos);
                PropertiesService.setPhotoIndex(index);
                PropertiesService.setPhotoId(id);
                $state.go("singlePhoto", {photoId:id });
            }

}]);