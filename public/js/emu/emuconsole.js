$(window).on("load",function(){
        var winheight = $(window).height();
        if($(document).height() > $(window).height()){
            winheight = $(document).height();
        }
        $('.leftbackground').height(winheight);  
    });