angular.module('bluepicWebApp')
    .controller('singlePhotoController', ['$scope', 'photo', 'PropertiesService', '$state',
        function($scope, photo, PropertiesService, $state) {
            'use strict';

            $scope.photoUrl = photo.data.url;
            $scope.userName = photo.data.user.name;
            $scope.locationName = photo.data.location.name;
            $scope.coords = convertDMS(photo.data.location.latitude, photo.data.location.longitude);
            $scope.caption = photo.data.caption;
            $scope.timestamp = formatTimestamp();

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

            function convertDMS(lat, lng) {
                var convertLat = Math.abs(lat);
                var LatDeg = Math.floor(convertLat);
                var LatMin = (Math.floor((convertLat - LatDeg) * 60));
                var LatCardinal = ((lat > 0) ? "N" : "S");

                var convertLng = Math.abs(lng);
                var LngDeg = Math.floor(convertLng);
                var LngMin = (Math.floor((convertLng - LngDeg) * 60));
                var LngCardinal = ((lng > 0) ? "E" : "W");

                return LatDeg  + "\xB0 " + LatMin  + "' " + LatCardinal + ", " + LngDeg +"\xB0 "  + LngMin + "' " + LngCardinal;
            }

            function formatTimestamp() {
                // Format: April 27th, 2015 @ 1:15 PM

                var d = new Date(photo.data.uploadedTs);

                var month = getMonthName(d.getMonth());
                var date = d.getDate();
                var dateNth = date + nth(date);
                var year = d.getFullYear();
                var time = d.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'});

                return month + " " + dateNth + ", " + year + " @ " + time;

            }

            function nth(date) {
                if(date > 3 && date < 21) return 'th';
                switch (date % 10) {
                    case 1:  return "st";
                    case 2:  return "nd";
                    case 3:  return "rd";
                    default: return "th";
                }
            }

            function getMonthName(index) {

                var months = [
                    "January", "February", "March",
                    "April", "May", "June",
                    "July", "August", "September",
                    "October", "November", "December"
                ]

                return months[index];
            };
    }]);