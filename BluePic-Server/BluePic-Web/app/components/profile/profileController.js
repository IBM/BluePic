
angular.module('bluepicWebApp')
    .controller('profileController', ['$scope', 'usersPhotos', 'userName', 'fbProfileImg', 'fbCoverImg',
        function($scope, usersPhotos, userName, fbProfileImg, fbCoverImg) {
            'use strict';

            // TODO: check to make sure user is logged in.
            // What to do when user isn't logged in?  Redirect to login page?

            $scope.usersPhotos = usersPhotos.data.records;
            $scope.photoCount = usersPhotos.data.number_of_records;
            $scope.userName = userName.data.name;
            $scope.fbProfileImg = fbProfileImg;
            $scope.fbCoverImg = fbCoverImg;

        }]);
