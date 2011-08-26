(function( $, amplify ) {

$(function() {

    function htmlToJson( data )
    {
        var params = {};
        $(data).find('.ar').each(function(index, val) {
            if ($.trim($(val).html()).length > 0)
            {
                params[$(val).attr('id')] = $(val).html();
            }
        })
        return params;
    }

    /*
     * Handles page gets.
     * Can handle JSON or XML response. Transforms XML response into JSON.
     */
    amplify.request.define( "pageGet", "ajax", {
        type: 'GET',
        url: "{url}",
        decoder: function( data, status, xhr, success, error ) {
            // Lets check if it's already an object
            if ($.isPlainObject(data))
            {
                success(data);
            }
            else
            {
                // Else parse the HTML into an object
                var params = htmlToJson(data);

                if (params.result && params.result == 'success')
                    params['pageRefresh'] = true;
                success(params);
            }
        }
    });

    /*
     * Handles actions that use POST (votes, etc).
     */
    amplify.request.define( "postAction", "ajax", {
        type: "POST",
        url: "{url}",
        decoder: function( data, status, xhr, success, error ) {
            // Lets check if it's already an object
            if ($.isPlainObject(data))
            {
                success(data);
            }
            else
            {
                // Else parse the XML into an object
                success(htmlToJson(data));
            }
        }
    });

    /*
     * Handles actions that use GET (topic edit form).
     */
    amplify.request.define( "getAction", "ajax", {
        type: "GET",
        url: "{url}",
        decoder: function( data, status, xhr, success, error ) {
            // Lets check if it's already an object
            if ($.isPlainObject(data))
            {
                success(data);
            }
            else
            {
                // Else parse the XML into an object
                success(htmlToJson(data));
            }
        }
    });

    /*
     * Handles form submissions.
     */
    amplify.request.define( "formSubmit", "ajax", {
        type: 'POST',
        url: "{url}",
        decoder: function( data, status, xhr, success, error ) {
            // Lets check if it's already an object
            if ($.isPlainObject(data))
            {
                success(data);
            }
            else
            {
                // Else parse the XML into an object
                success(htmlToJson(data));
            }
        }
    });

});

}( jQuery, amplify ) );