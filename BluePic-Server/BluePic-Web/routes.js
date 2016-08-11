
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
                resolve: {
                    explorePhotos: function() {
                    console.log("explore resolve") }
                },
                controller: 'exploreController'
            })
            .state('profile', {
                url: '/profile',
                templateUrl: 'app/components/profile/profile.html',
                resolve: {
                },
                controller: 'profileController'
            })

        $urlRouterProvider.otherwise('/');
    }]);