
angular.module("bluepicWebApp", ['ui.router', 'ngResource']);

angular.module('bluepicWebApp')
    .config(['$stateProvider', '$urlRouterProvider', function($stateProvider, $urlRouterProvider) {

        $stateProvider
            .state('homepage', {
                url: '/',
                templateUrl: 'app/components/homepage/homepage.html',
                resolve: {
                    photos: ['PhotosService', function (PhotosService) {
                        console.log("in routes resolve")
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