
angular.module('bluepicWebApp')

    .service('ExplorePhotosService', ['$http', function ($http) {

    this.getExplorePhotos = function() {

        var url = '/images';
        return $http.get(url);

    }
}]);