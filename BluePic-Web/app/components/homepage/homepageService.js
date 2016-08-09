
angular.module('bluepicWebApp')

    .service('PhotosService', ['$http', function ($http) {

    this.getAllPhotos = function() {

        var url = 'http://bluepic-unprofessorial-inexpressibility.mybluemix.net/images';

        return $http.get(url);

    }
}]);