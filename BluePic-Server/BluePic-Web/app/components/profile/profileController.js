
angular.module('bluepicWebApp')
    .controller('profileController', ['$scope',   'fbProfileImg', 'fbCoverImg', 'PropertiesService',
                                      '$state', 'fbHometown', 'usersPhotos', 'userName',
        function($scope, fbProfileImg, fbCoverImg, PropertiesService,
                 $state, fbHometown, usersPhotos, userName) {
            'use strict';
                                      
            $scope.state = $state;
            
            $scope.photos = usersPhotos.data.records;

            $scope.photoCount = usersPhotos.data.number_of_records;
                                      
            $scope.userName = PropertiesService.getFbUserName();
                                      
            $scope.hometown = fbHometown;
                                      
            $scope.backupUserName = userName.data.name;
                                      
            $scope.fbProfileImg = fbProfileImg;
                                      
            $scope.fbCoverImg = fbCoverImg;
                                      
            $scope.searchTerm = { value: ""};

        }]);
