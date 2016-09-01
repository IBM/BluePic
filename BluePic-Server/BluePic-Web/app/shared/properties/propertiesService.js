angular.module('bluepicWebApp')

    .service('PropertiesService', function () {

        var accessToken = "";
        var userId = "1002";  //temporary test userID
        var photos = [];
        var photoId = null;
        var photoIndex = -1;

        return {
            getAccessToken: function () {
                return accessToken;
            },
            setAccessToken: function (value) {
                accessToken = value;
            },
            getUserId: function () {
                return userId;
            },
            setUserId: function (value) {
                userId = value;
            },
            getPhotos: function () {
                return photos;
            },
            setPhotos: function (value) {
                photos = value;
            },
            getPhotoId: function () {
                return photoId;
            },
            setPhotoId: function (value) {
                photoId = value;
            },
            getPhotoIndex: function () {
                return photoIndex;
            },
            setPhotoIndex: function (value) {
                photoIndex = value;
            }
        };
    });