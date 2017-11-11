
angular.module('bluepicWebApp')
.controller('homepageController', ['$scope', "PropertiesService", 'photos',
    function($scope, PropertiesService, photos) {
        'use strict';
                            
        $scope.photos = photos.data;

        // searchTerm initializes to "" or to a string set by Explore page
        $scope.searchTerm = { value: PropertiesService.getSearchTerm()};

        $scope.tags = extractTags();

        function extractTags () {

            var tagsArray = [], index, tagIndex, photoTags;
            var photosArray = $scope.photos;

            for (index in photosArray) {

                photoTags = photosArray[index].tags;
                for (tagIndex in photoTags) {

                    if(tagIsOriginal(photoTags[tagIndex], tagsArray)) {
                        tagsArray.push(photoTags[tagIndex])
                    }
                }
            }
            return tagsArray;
        }

        function tagIsOriginal(tag, tagsArray) {

            var index;

            for (index in tagsArray) {
                if (tagsArray[index].label === tag.label){
                    return false;
                }
            }
            return true;
        }
}]);
