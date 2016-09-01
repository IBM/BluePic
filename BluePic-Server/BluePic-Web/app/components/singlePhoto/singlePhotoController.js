angular.module('bluepicWebApp')
    .controller('singlePhotoController', ['$scope', 'photo', 'PropertiesService',
        function($scope, photo, PropertiesService) {
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

            //var num = $scope.photos.data.number_of_records;

        }]);