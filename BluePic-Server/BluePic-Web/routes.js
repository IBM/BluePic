
angular.module("bluepicWebApp", ['ui.router', 'ngResource']);

angular.module('bluepicWebApp')
    .config(['$stateProvider', '$urlRouterProvider', function($stateProvider, $urlRouterProvider) {

        $stateProvider
            .state('login', {
                url: '/',
                templateUrl: 'app/components/login/login.html'
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