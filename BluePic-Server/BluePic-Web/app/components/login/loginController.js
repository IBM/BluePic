
angular.module('bluepicWebApp')
.controller('loginController', ['$scope', '$state', 'PropertiesService',
    function($scope, $state, PropertiesService) {
        'use strict';

        $scope.checkLoginState = function() {
            FB.getLoginStatus(function(response) {
                $scope.statusChangeCallback(response);
            });
        }

        // This is called with the results from from FB.getLoginStatus().
        $scope.statusChangeCallback = function(response) {

            var fbLogin = document.getElementById('facebookLogin'),
                fbLogout = document.getElementById('facebookLogout')

            if (response.status === 'connected') {  // Logged into your app and Facebook.

                fbLogin.style.display = 'none';
                fbLogout.style.display = 'inline';
                $scope.testAPI();

                console.log("token: " + response.authResponse.accessToken)
                var accessToken = response.authResponse.accessToken;

                PropertiesService.setAccessToken(accessToken);

                $state.go("homepage")

            } else if (response.status === 'not_authorized') {
                // The person is logged into Facebook, but not your app.
            } else {
                // The person is not logged into Facebook, so we're not sure if
                // they are logged into this app or not.
                fbLogin.style.display = 'inline';
                fbLogout.style.display = 'none';
            }
        }

        $scope.testAPI = function() {
            FB.api('/me', function(response) {
                PropertiesService.setFbUserName(response.name);
                console.log('Successful login for: ' + response.name);
            });
        }

        $scope.loginUsingFacebook = function() {
            FB.login(function(response) {
                FB.getLoginStatus(function(response) {
                    $scope.statusChangeCallback(response);
                });
            }, {scope: 'public_profile, email',
            auth_type: 'reauthenticate'});
        }

        $scope.logoutFacebook = function() {
            FB.logout(function(response) {
                FB.getLoginStatus(function(response) {
                    $scope.statusChangeCallback(response);
                });
            });
        }

        $scope.signInLater = function () {
            $state.go('homepage')
        }
}]);
