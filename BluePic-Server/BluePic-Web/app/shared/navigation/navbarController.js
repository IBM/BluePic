angular.module('bluepicWebApp')
    .controller('navbarController', ['$scope', 'PropertiesService', '$state',
        function($scope, PropertiesService, $state) {
            'use strict';

            $scope.goToProfile = function() {

                // Redirect to profile page only if user is logged in
                if (PropertiesService.getAccessToken()) {
                    $state.go('profile');
                }
                else {
                    $state.go('login');
                }

            }

            $scope.goToHomepage = function() {
                $state.go('homepage')

            }

        }]);
