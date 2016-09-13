angular.module('bluepicWebApp')

    .service('PropertiesService', function () {

        var accessToken = "";
        var userName = "";
        var userId = "1002";  // Isaac Newton test userID: 102496306870321
        var photos = [];
        var photoId = null;
        var photoIndex = -1;
        var searchTerm = "";

        function nth(date) {
            if(date > 3 && date < 21) return 'th';
            switch (date % 10) {
                case 1:  return "st";
                case 2:  return "nd";
                case 3:  return "rd";
                default: return "th";
            }
        }

        function getMonthName(index) {

            var months = [
                "January", "February", "March",
                "April", "May", "June",
                "July", "August", "September",
                "October", "November", "December"
            ]

            return months[index];
        }

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
            },
            getFbUserName: function () {
                return userName;
            },
            setFbUserName: function (value) {
                userName = value;
            },
            getSearchTerm: function () {
                return searchTerm;
            },
            setSearchTerm: function (value) {
                searchTerm = value;
            },
            getFormattedTimestamp: function (timestamp) {

                // Format: April 27th, 2015 @ 1:15 PM

                var d = new Date(timestamp);

                var month = getMonthName(d.getMonth());
                var date = d.getDate();
                var dateNth = date + nth(date);
                var year = d.getFullYear();
                var time = d.toLocaleTimeString([], {hour: '2-digit', minute: '2-digit'});

                return month + " " + dateNth + ", " + year + " @ " + time;
            },
            getDMSCoordinates: function (lat, lng) {

                var convertLat = Math.abs(lat);
                var LatDeg = Math.floor(convertLat);
                var LatMin = (Math.floor((convertLat - LatDeg) * 60));
                var LatCardinal = ((lat > 0) ? "N" : "S");

                var convertLng = Math.abs(lng);
                var LngDeg = Math.floor(convertLng);
                var LngMin = (Math.floor((convertLng - LngDeg) * 60));
                var LngCardinal = ((lng > 0) ? "E" : "W");

                return LatDeg  + "\xB0 " + LatMin  + "' " + LatCardinal + ", " + LngDeg +"\xB0 "  + LngMin + "' " + LngCardinal;
            }
        };
    });