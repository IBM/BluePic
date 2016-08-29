
angular.module('bluepicWebApp')
    .controller('profileController', ['$scope', 'usersPhotos',
        function($scope, usersPhotos) {
            'use strict';

            $scope.usersPhotos = usersPhotos.data.records;
            $scope.photoCount = usersPhotos.data.number_of_records;

            // Get user profile for whoever is logged in
            // TODO: check to make sure user is logged in.
            FB.api('/me/picture?type=normal', function (response) {
                console.log("url: " + response.data.url)
                $scope.profileImg = response.data.url;
                // var im = document.getElementById("profileImage").setAttribute("src", response.data.url);

            });

        }]);
