
function bind_gif_loading(missing_gif_url)
{
    $("#gif")
    .load(function() { 
        $('#shares-container').fadeIn();
        $("#gif").fadeIn();
    })
    .error(function() {
        var gif = $("#gif");
        gif.unbind("load");
        gif.unbind("error");
        gif.attr("src", missing_gif_url);
        gif.fadeIn();
        $('#shares-container').fadeOut();
    });
}


function analytics(oid)
{
    var ref = getUrlParameter('r');
    if (!ref) ref = 'undefined';
    var name = getUrlParameter('n');
    if (!name) name = 'undefined';

    // Track the view of the page
    mixpanel.track("Web:EmuSharedGifPage:View", {"Reference":ref, "name":name, "oid":oid});

    // Track links to landing page
    mixpanel.track_links("#header a", "Web:EmuSharedGifPage:LinkToLandingPage", {"Reference":ref, "name":name, "oid":oid, "sender":"header"});
    mixpanel.track_links("#footer a", "Web:EmuSharedGifPage:LinkToLandingPage", {"Reference":ref, "name":name, "oid":oid, "sender":"footer"});
    mixpanel.track_links("#emu", "Web:EmuSharedGifPage:LinkToLandingPage", {"Reference":ref, "name":name, "oid":oid, "sender":"emu"});

    // Track share links
    mixpanel.track_links("#share-facebook", "Web:EmuSharedGifPage:ShareClicked", {"Reference":ref, "name":name, "oid":oid, "shareMethod":"facebook"});
    mixpanel.track_links("#share-pinterest", "Web:EmuSharedGifPage:ShareClicked", {"Reference":ref, "name":name, "oid":oid, "shareMethod":"pinterest"});
    mixpanel.track_links("#share-tumblr", "Web:EmuSharedGifPage:ShareClicked", {"Reference":ref, "name":name, "oid":oid, "shareMethod":"tumblr"});
    mixpanel.track_links("#share-reddit", "Web:EmuSharedGifPage:ShareClicked", {"Reference":ref, "name":name, "oid":oid, "shareMethod":"reddit"});
}


/** 
    helper functions 
**/
function getUrlParameter(sParam)
{
    var sPageURL = window.location.search.substring(1);
    var sURLVariables = sPageURL.split('&');
    for (var i = 0; i < sURLVariables.length; i++) 
    {
        var sParameterName = sURLVariables[i].split('=');
        if (sParameterName[0] == sParam) 
        {
            return sParameterName[1];
        }
    }
} 