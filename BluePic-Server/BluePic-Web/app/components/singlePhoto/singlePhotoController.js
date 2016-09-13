angular.module('bluepicWebApp')
    .controller('singlePhotoController', ['$scope', 'photo', 'PropertiesService', '$state',
        function($scope, photo, PropertiesService, $state) {
            'use strict';

            $scope.photoUrl = photo.data.url;
            $scope.userName = photo.data.user.name;
            $scope.locationName = photo.data.location.name;
            $scope.coords = PropertiesService.getDMSCoordinates(photo.data.location.latitude, photo.data.location.longitude);
            $scope.caption = photo.data.caption;
            $scope.timestamp = PropertiesService.getFormattedTimestamp(photo.data.uploadedTs);

            var temp = photo.data.location.weather.temperature;
            $scope.temp = temp ? (temp + "\xB0") : "";
            $scope.mapUrl = "https://maps.googleapis.com/maps/api/staticmap?center=" +
                photo.data.location.latitude + "," +
                photo.data.location.longitude +
                "&zoom=7&" +
                "size=370x150&" +
                "maptype=terrain";

            $scope.photos = PropertiesService.getPhotos();
            var photoId = PropertiesService.getPhotoId();
            var index = PropertiesService.getPhotoIndex();

            var numPhotos = $scope.photos.length;

            $scope.pagePhoto = function (direction) {

                if(direction === "left" && index > 0) {
                    index--;
                }
                else if (direction === "right" && index < numPhotos) {
                    index++;
                }

                var newPhoto = $scope.photos[index];

                PropertiesService.setPhotoIndex(index);
                PropertiesService.setPhotoId(newPhoto._id);
                $state.go("singlePhoto", {photoId:newPhoto._id});

            }

            $scope.tags = photo.data.tags;

            $scope.searchTerm = { value: ""};

    }]);