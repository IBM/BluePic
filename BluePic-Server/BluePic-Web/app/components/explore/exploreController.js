
angular.module('bluepicWebApp')
.controller('exploreController', ['$scope', '$state', 'PropertiesService', 'photos',
    function($scope, $state, PropertiesService, photos) {
        'use strict';
                                  
        $scope.state = $state;

        $scope.photos = photos.data.records;

        $scope.searchTerm = { value: ""};

        $scope.collections = getCollections();

        $scope.openCollection = function(tagLabel) {

            PropertiesService.setSearchTerm(tagLabel);
            $state.go('homepage');
        }


        function getCollections() {

            var collections = {
                images: [],
                tags: []
            };

            var photoIndex, tagIndex, photoTags, photo, tag, newCollection;

            collections.images = photos.data.records;

            for (photoIndex in collections.images) {

                /*
                 * For each photo, get tags
                 *  for each tag,
                 *  if it doesn't exist in collection, add it and push the index to the photo array
                 *  if it does exist, push the index to the that photo array
                 */

                photo = collections.images[photoIndex];
                photoTags = photo.tags;

                for (tagIndex in photoTags) {

                    tag = photoTags[tagIndex];

                    var colIndex = getIndexIfExists(tag, collections);

                    if(colIndex > -1) {
                        collections.tags[colIndex].photos.push(photoIndex);
                    }
                    else {
                        collections.tags.push(createNewCollection(tag, photoIndex));

                    }
                }
            }
            return collections;
        }

        function createNewCollection(tag, photoIndex, collections) {

            var newCollection = {
                tagLabel: tag.label,
                photos: []
            }
            newCollection.photos.push(photoIndex);

            return newCollection;
        }

        function getIndexIfExists(tag, collections) {

            var index;

            for (index in collections.tags) {
                if (collections.tags[index].tagLabel === tag.label) {
                    return index;
                }
            }
            return -1;
        }

    }]);
