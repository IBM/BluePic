
angular.module('bluepicWebApp')

    .directive('fbParseDirective', function() {
        return {
            restrict: 'E',
            link: function (scope, iElement, iAttrs) {
                if (FB) {
                    FB.XFBML.parse(iElement[0].parent);
                }
            }
        }
    });