
angular.module('bluepicWebApp')
    .controller('profileController', ['$scope', 'usersPhotos', 'userName', 'fbProfileImg', 'fbCoverImg', 'PropertiesService', '$state',
        function($scope, usersPhotos, userName, fbProfileImg, fbCoverImg, PropertiesService, $state) {
            'use strict';
                                      
            $scope.state = $state;
            
            $scope.photos = usersPhotos.data.records;

            $scope.photoCount = usersPhotos.data.number_of_records;
                                      
            $scope.userName = PropertiesService.getFbUserName();
                                      
            $scope.backupUserName = userName.data.name;
                                      
            $scope.fbProfileImg = fbProfileImg;
                                      
            $scope.fbCoverImg = fbCoverImg;
                                      
            $scope.searchTerm = { value: ""};

        }]);
