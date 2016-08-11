
angular.module('bluepicWebApp')

    .service('ExplorePhotosService', ['$http', function ($http) {

    this.getExplorePhotos = function() {

        var url = 'http://bluepic-accretive-preexcitation.eu-gb.mybluemix.net/images';
        return $http.get(url);

    }
}]);