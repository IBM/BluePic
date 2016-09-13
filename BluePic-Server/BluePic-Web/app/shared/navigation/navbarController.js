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

                PropertiesService.setSearchTerm("");
                $state.go('homepage');
            }

            $scope.checkPlaceholder = function () {

                var input = document.getElementById("placeholder");
                var classList = input.classList;

                if (classList.contains("placeholderIcon") && input.value != "" ) {
                    classList.remove("placeholderIcon");

                } else if(!classList.contains("placeholderIcon") && input.value == "" ){
                    classList.add("placeholderIcon");

                }
            }

        }]);
