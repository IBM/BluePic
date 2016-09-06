
angular.module('bluepicWebApp')
.controller('homepageController', ['$scope', 'photos',
    function($scope, photos) {
        'use strict';

        $scope.photos = photos.data.records;

        $scope.sortType = 'tags';
        $scope.searchTerm = { value: ""};

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
