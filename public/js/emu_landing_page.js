$('.campaign-button').on('click' , function() {
            current_email = $("#email_text_field").val();
            if (current_email == "")
            {
                current_email = $("#email_text_field_mobile").val();
            }
            console.log(current_email);
            if (current_email != "") 
            {
                if(validateEmail(current_email)){
                    alert("Emu says: Thanks for joining!");
                    
                    params = {"email_address":current_email};
                    $.post('/emu/sign_up', params , function(data,status){
                         $("#email_text_field").val("");
                         $("#email_text_field_mobile").val("");
                    });
                }
                else{
                    alert("Emu says: Not valid email address");
                }
            } else {
                alert("why U no put email?!");
            }
        })

function validateEmail(email) {
    var re = /^([\w-]+(?:\.[\w-]+)*)@((?:[\w-]+\.)*\w[\w-]{0,66})\.([a-z]{2,6}(?:\.[a-z]{2})?)$/i;
    return re.test(email);
}

$(window).on("load",function(){

        if ($('.footer-lg').is(':hidden')) {
            // device is == eXtra Small
        } else {
            // device is >= SMaller 
            var winheight = $(window).height();
            if($(document).height() > $(window).height()){
                winheight = $(document).height();
            }
            var footerHeight = $(".footer-lg").height();
            var headerHeight = $(".header").height();
            $('#content').height(winheight-footerHeight-headerHeight);  
            $('.intro-header').height(winheight-footerHeight-headerHeight);  
        }
    });

$(document).on("ready", function(){

    mixpanel.track(
            "EmuLandingPageView"
        );

});

// $(window).on("load",function(){

//         var winwidth = $(window).width();
//         $('.footer-lg').width(winwidth); 
//     });


// $( document ).resize(function() {
//         var docheight = $(document).height();
//         var footerPos = $(".footer-lg").offset().top;
//         $('.footer-lg').height(docheight- footerPos);
// });


