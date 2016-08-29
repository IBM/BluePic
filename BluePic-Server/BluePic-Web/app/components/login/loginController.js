
angular.module('bluepicWebApp')
.controller('loginController', ['$scope', '$state',
    function($scope, $state) {
        'use strict';

        $scope.checkLoginState = function() {
            FB.getLoginStatus(function(response) {
                $scope.statusChangeCallback(response);
            });
        }

        // This is called with the results from from FB.getLoginStatus().
        $scope.statusChangeCallback = function(response) {
            console.log('statusChangeCallback');
            console.log(response);

            var fbLogin = document.getElementById('facebookLogin'),
                fbLogout = document.getElementById('facebookLogout')

            if (response.status === 'connected') {
                // Logged into your app and Facebook.
                fbLogin.style.display = 'none';
                fbLogout.style.display = 'inline';
                $scope.testAPI();
                $state.go("homepage")
                //App.greetUser();
                // Send user data if not logged in already.
                if (localStorage.getItem('app_social_uid') === '') {
                    // Send the user data to the server.
                    //App.sendUserData();
                }
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
            console.log('Welcome!  Fetching your information.... ');
            FB.api('/me', function(response) {
                console.log('Successful login for: ' + response.name);
            });
        }

        $scope.loginUsingFacebook = function() {
            FB.login(function(response) {
                FB.getLoginStatus(function(response) {
                    $scope.statusChangeCallback(response);
                });
            }, {scope: 'public_profile, email'});
        }

        $scope.logoutFacebook = function() {
            FB.logout(function(response) {
                FB.getLoginStatus(function(response) {
                    $scope.statusChangeCallback(response);
                });
            });
        }
}]);
