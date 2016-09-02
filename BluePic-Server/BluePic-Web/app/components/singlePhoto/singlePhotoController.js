angular.module('bluepicWebApp')
    .controller('singlePhotoController', ['$scope', 'photo', 'PropertiesService', '$state',
        function($scope, photo, PropertiesService, $state) {
            'use strict';

            $scope.photoUrl = photo.data.url;
            $scope.userName = photo.data.user.name;
            $scope.locationName = photo.data.location.name;
            $scope.coords = photo.data.location.longitude +", " + photo.data.location.latitude;
            $scope.caption = photo.data.caption;
            $scope.timestamp = photo.data.uploadedTs;
            $scope.temp = photo.data.location.weather.temperature + " degrees";
            $scope.mapUrl = "http://maps.googleapis.com/maps/api/staticmap?center=" +
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

        }]);