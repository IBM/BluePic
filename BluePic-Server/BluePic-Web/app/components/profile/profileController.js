
angular.module('bluepicWebApp')
    .controller('profileController', ['$scope', 'usersPhotos',
        function($scope, usersPhotos) {
            'use strict';

            $scope.usersPhotos = usersPhotos.data.records;
            $scope.photoCount = usersPhotos.data.number_of_records;

        }]);
