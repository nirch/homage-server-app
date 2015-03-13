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