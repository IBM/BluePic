
angular.module("bluepicWebApp", ['ui.router', 'ngResource']);

angular.module('bluepicWebApp')
    .config(['$stateProvider', '$urlRouterProvider', function($stateProvider, $urlRouterProvider) {

        $stateProvider
            .state('homepage', {
                url: '/',
                templateUrl: 'app/components/homepage/homepage.html',
                resolve: {
                    photos: ['PhotosService', function (PhotosService) {
                        return PhotosService.getAllPhotos();
                    }]
                },
                controller: 'homepageController'
            })

        $urlRouterProvider.otherwise('/homepage');
    }]);