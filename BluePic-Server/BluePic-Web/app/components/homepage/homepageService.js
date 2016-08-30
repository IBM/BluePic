
angular.module('bluepicWebApp')

    .service('PhotosService', ['$http', function ($http) {

        this.getAllPhotos = function() {
            var url = '/images';
            return $http.get(url);
        }
}]);