angular.module('bluepicWebApp')

    .service('PropertiesService', function () {

        var accessToken = "";
        var userId = "1002";  //temporary test userID

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
            }
        };
    });