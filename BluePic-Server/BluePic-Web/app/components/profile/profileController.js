
angular.module('bluepicWebApp')
    .controller('profileController', ['$scope', 'usersPhotos', 'userName', 'fbProfileImg', 'fbCoverImg',
        function($scope, usersPhotos, userName, fbProfileImg, fbCoverImg) {
            'use strict';
            
            $scope.photos = usersPhotos.data.records;
            $scope.photoCount = usersPhotos.data.number_of_records;
            $scope.userName = userName.data.name;
            $scope.fbProfileImg = fbProfileImg;
            $scope.fbCoverImg = fbCoverImg;
            $scope.searchTerm = { value: ""};

        }]);
