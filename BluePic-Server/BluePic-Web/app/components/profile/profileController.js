
angular.module('bluepicWebApp')
    .controller('profileController', ['$scope', 'usersPhotos', 'userName', 'fbProfileImg', 'fbCoverImg', 'PropertiesService',
        function($scope, usersPhotos, userName, fbProfileImg, fbCoverImg, PropertiesService) {
            'use strict';
            
            $scope.photos = usersPhotos.data.records;
            $scope.photoCount = usersPhotos.data.number_of_records;
            $scope.userName = PropertiesService.getFbUserName();
            $scope.backupUserName = userName.data.name;
            $scope.fbProfileImg = fbProfileImg;
            $scope.fbCoverImg = fbCoverImg;
            $scope.searchTerm = { value: ""};

        }]);
