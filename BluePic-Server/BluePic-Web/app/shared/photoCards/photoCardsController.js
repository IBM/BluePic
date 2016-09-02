angular.module('bluepicWebApp')
    .controller('photoCardsController', ['$scope', '$state', 'PropertiesService',
        function($scope, $state, PropertiesService) {
            'use strict';

    $scope.openPhoto = function(id, index) {

        PropertiesService.setPhotos($scope.photos);
        PropertiesService.setPhotoIndex(index);
        PropertiesService.setPhotoId(id);
        $state.go("singlePhoto", {photoId:id });
    }

}]);