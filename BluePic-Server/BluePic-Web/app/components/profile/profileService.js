angular.module('bluepicWebApp')

    .service('ProfilePhotoService', ['$http', '$q', '$rootScope', 'PropertiesService',
        function ($http, $q, $rootScope, PropertiesService) {


        this.getUsersPhotos = function () {

            var token = PropertiesService.getAccessToken();
            var userId = PropertiesService.getUserId();

            var req = {
                method: 'GET',
                url: '/users/' +userId+ '/images',
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

            var req = {
                method: 'GET',
                url: '/users/' +userId,
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
                $rootScope.$apply(deferred.resolve(response.data.url));
            });

            return deferred.promise;
        }

        this.getProfileCoverImg = function () {

            var deferred = $q.defer();

            FB.api('/me?fields=cover', function(response) {
                $rootScope.$apply(deferred.resolve(response.cover.source));
            });

            return deferred.promise;
        }

    }]);