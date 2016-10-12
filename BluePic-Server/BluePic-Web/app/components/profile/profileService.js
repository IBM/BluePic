angular.module('bluepicWebApp')

    .service('ProfilePhotoService', ['$http', '$q', '$rootScope', 'PropertiesService',
        function ($http, $q, $rootScope, PropertiesService) {


        this.getUsersPhotos = function () {

            var token = PropertiesService.getAccessToken();
            var userId = PropertiesService.getUserId();
            var url = '/users/' +userId+ '/images';
                                     
            var req = {
                method: 'GET',
                url: url,
                headers: {
                    'X-token-type': 'FacebookToken',
                    'content-type': 'application/json',
                    'access_token': token
                }
            }

            return $http(req);
        }

        this.getUserName = function () {

            var token = PropertiesService.getAccessToken();
            var userId = PropertiesService.getUserId();
            var url = '/users/' +userId;
                                     
            var req = {
                method: 'GET',
                url: url,
                headers: {
                    'X-token-type': 'FacebookToken',
                    'content-type': 'application/json',
                    'access_token': token
                }
            }

            return $http(req);
        }

        this.getProfileImg = function () {

            var deferred = $q.defer();

            FB.api('/me/picture?type=normal', function (response) {

                if(response.data && response.data.url) {
                    $rootScope.$apply(deferred.resolve(response.data.url));
                }
                else {  // if user has no profile photo, return default image
                    $rootScope.$apply(deferred.resolve("../../assets/img/puppy.jpg"));
                }
            });

            return deferred.promise;
        }

        this.getProfileCoverImg = function () {

            var deferred = $q.defer();

            FB.api('/me?fields=cover', function(response) {
                if(response.cover && response.cover.source){
                    $rootScope.$apply(deferred.resolve(response.cover.source));
                }
                else {  // if user has no cover photo, return default image
                    $rootScope.$apply(deferred.resolve("../../assets/img/nature-small.png"));
                }
            });

            return deferred.promise;
        }

    }]);
