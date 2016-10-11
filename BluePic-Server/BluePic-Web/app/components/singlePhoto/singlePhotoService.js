angular.module('bluepicWebApp')

    .service('SinglePhotoService', ['$http', function ($http) {

        this.getPhoto = function(id) {
            var url = '/images/' + id;
            return $http.get(url);
        }
    }]);
