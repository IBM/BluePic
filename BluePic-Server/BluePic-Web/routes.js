
angular.module("bluepicWebApp", ['ui.router', 'ngResource']);

angular.module('bluepicWebApp')
    .config(['$stateProvider', '$urlRouterProvider', function($stateProvider, $urlRouterProvider) {

        window.fbAsyncInit = function() {
            console.log("initializing")
            FB.init({
                appId      : '225552221180006', //'1545401759089721', <-- MIL appId
                cookie     : true,  // enable cookies to allow the server to access
                                    // the session
                xfbml      : true,  // parse social plugins on this page
                version    : 'v2.6' // use graph api version 2.6
            });
        };

        // Load the SDK asynchronously
        (function(d, s, id) {
            console.log("loading async")
            var js, fjs = d.getElementsByTagName(s)[0];
            if (d.getElementById(id)) return;
            js = d.createElement(s); js.id = id;
            js.src = "//connect.facebook.net/en_US/sdk.js";
            fjs.parentNode.insertBefore(js, fjs);
        }(document, 'script', 'facebook-jssdk'));

        $stateProvider
            .state('login', {
                url: '/',
                templateUrl: 'app/components/login/login.html',
                controller: 'loginController'
            })
            .state('homepage', {
                url: '/homepage',
                templateUrl: 'app/components/homepage/homepage.html',
                resolve: {
                    photos: ['PhotosService', function (PhotosService) {
                        return PhotosService.getAllPhotos();
                    }]
                },
                controller: 'homepageController'
            })
            .state('explore', {
                url: '/explore',
                templateUrl: 'app/components/explore/explore.html',
                resolve: {},
                controller: 'exploreController'
            })
            .state('profile', {
                url: '/profile',
                templateUrl: 'app/components/profile/profile.html',
                resolve: {
                    usersPhotos: ['ProfilePhotoService', function (ProfilePhotoService) {
                        return ProfilePhotoService.getUsersPhotos();
                    }]
                },
                controller: 'profileController'
            })

        $urlRouterProvider.otherwise('/');

    }]);