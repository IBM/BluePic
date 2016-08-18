
angular.module('bluepicWebApp')

    .service('PhotosService', ['$http', function ($http) {

        this.getAllPhotos = function() {
            var url = 'https://bluepic-unshort-apery.mybluemix.net/images';
            return $http.get(url);
        }
}]);