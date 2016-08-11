
angular.module('bluepicWebApp')

    .service('PhotosService', ['$http', function ($http) {

    this.getAllPhotos = function() {

        var url = 'http://bluepic-accretive-preexcitation.eu-gb.mybluemix.net/images';
        return $http.get(url);

    }
}]);