$('.campaign-button').on('click' , function() {
            current_email = $("#email_text_field").val();
            if (current_email == "")
            {
                current_email = $("#email_text_field_mobile").val();
            }
            console.log(current_email);
            if (current_email != "") 
            {
                params = {"email_address":current_email};
                $.post('/emu/sign_up', params , function(data,status){
                     alert("Emu says: Thanks for joining!");
                     $("#email_text_field").val("");
                     $("#email_text_field_mobile").val("");
                });
            } else {
                alert("why U no put email?!");
            }
        })


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

// $(window).on("load",function(){

//         var winwidth = $(window).width();
//         $('.footer-lg').width(winwidth); 
//     });


// $( document ).resize(function() {
//         var docheight = $(document).height();
//         var footerPos = $(".footer-lg").offset().top;
//         $('.footer-lg').height(docheight- footerPos);
// });


