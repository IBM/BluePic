angular.module('bluepicWebApp')

    .service('ProfilePhotoService', ['$http', function ($http) {

        /*
         * For testing purposes, we'll grab all the photos.
         * After we've worked out login, we'll grab photos for an individual for the profile.
         */

        this.getUsersPhotos = function() {

            var url = 'https://bluepic-unshort-apery.mybluemix.net/images';
            return $http.get(url);
        }
    }]);