$(window).on("load",function(){
        var winheight = $(window).height();
        if($(document).height() > $(window).height()){
            winheight = $(document).height();
        }
        $('.leftbackground').height(winheight);  
    });

$(document).on("ready", function(){

	$("body").on("click", ".emuButton", function(){
			var pack = $(this).data("pack");
			var emu = $(this).data("emu");
			DisplayEmuticon(pack, emu);
	});

	$("body").on("click", ".newemuButton", function(){
			var pack = $(this).data("pack");
			CreateEmuticon(pack);
	});

	$("body").on("click", ".emuticonsButton", function(){
			var pack = $(this).data("package");
			DisplayEmuticons(pack);
	});

	$("body").on("click", ".packButton", function(){
			var pack = $(this).data("package");
			DisplayPackage(pack);
	});

	$("body").on("change", ".input_file", function(){
		if(this.id == 'icon2xfile'){
			readURL(this, '#icon2ximg');
		}

		else if(this.id == 'icon3xfile'){
			readURL(this, '#icon3ximg');
		}

		else if(this.id == 'icon_maskfile'){
			readURL(this, '#icon_maskimg');
		}

		else if(this.id == 'source_back_layer_file'){
			readURL(this, '#source_back_layer_img');
		}

		else if(this.id == 'source_front_layer_file'){
			readURL(this, '#source_front_layer_img');
		}

		else if(this.id == 'source_user_layer_mask_file'){
			readURL(this, '#source_user_layer_mask_img');
		}
			
	});

	// $(".input_file").change(function(){
 //        readURL(this);
 //    });
});

function readURL(input,imgid) {
        if (input.files && input.files[0]) {
            var reader = new FileReader();

            reader.onload = function (e) {
                $(imgid).attr('src', e.target.result);
            }

            reader.readAsDataURL(input.files[0]);
        }
    }

// PACKAGE

function CreatePackageFields(method){

	var display = document.getElementById("display");


	// Reset display
	display.innerHTML = "";

	// CREATE FORM 
	var parent_form = document.createElement('form');
	parent_form.id = "parent_form";
	parent_form.action = '/emuapi/package';
	parent_form.enctype = "multipart/form-data";

	// NAME
	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "Name:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var labelname = null;
	if(method == 'PUT'){
		labelname = document.createElement('label');
		labelname.id = "pack_name";
	}else{
		labelname = document.createElement('input');
		labelname.id = "pack_name";
		labelname.type = "text"
	}

	inputnamecoldiv.appendChild(labelname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	parent_form.appendChild(rownamediv);

	// END NAME

	// LABEL
	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "Label:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var inputname = document.createElement('input');
	inputname.id = "pack_label";
	inputname.type = "text";

	inputnamecoldiv.appendChild(inputname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	parent_form.appendChild(rownamediv);

	// END LABEL

	// ICON2X
	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "Icon2x:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var imgname = document.createElement('img');
	imgname.id = "icon2ximg"
	imgname.className = "input_img"

	var inputname = document.createElement('input');
	inputname.id = "icon2xfile";
	inputname.type = "file";
	inputname.accept = "image/*";
	inputname.name = "icon2x"
	inputname.className = "input_file"


	inputnamecoldiv.appendChild(imgname);
	inputnamecoldiv.appendChild(inputname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	parent_form.appendChild(rownamediv);

	// END ICON2X

	// ICON3X
	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "Icon3x:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var imgname = document.createElement('img');
	imgname.id = "icon3ximg"
	imgname.className = "input_img"

	var inputname = document.createElement('input');
	inputname.id = "icon3xfile";
	inputname.type = "file";
	inputname.accept = "image/*";
	inputname.name = "icon3x"
	inputname.className = "input_file"

	inputnamecoldiv.appendChild(imgname);
	inputnamecoldiv.appendChild(inputname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	parent_form.appendChild(rownamediv);

	parent_form.appendChild(document.createElement('br'));

	// END ICON3X

  	// EMUTICON DEFAULTS

  	
  	var fieldset = document.createElement('fieldset');
  	var legend = document.createElement('legend');
  	legend.innerHTML = "Emuticons Defaults:";
  	fieldset.appendChild(legend);


  	// DURATION
	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "Duration:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var inputname = document.createElement('input');
	inputname.id = "duration";
	inputname.type = "text";

	inputnamecoldiv.appendChild(inputname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	fieldset.appendChild(rownamediv);

	// END DURATION

	// FRAMES COUNT
	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "Frames Count:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var inputname = document.createElement('input');
	inputname.id = "frames_count";
	inputname.type = "text";

	inputnamecoldiv.appendChild(inputname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	fieldset.appendChild(rownamediv);

	// END FRAMES COUNT

	// THUMBNAIL FRAME INDEX
	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "Thumbnail Frame Index:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var inputname = document.createElement('input');
	inputname.id = "thumbnail_frame_index";
	inputname.type = "text";

	inputnamecoldiv.appendChild(inputname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	fieldset.appendChild(rownamediv);

	// END THUMBNAIL FRAME INDEX

	// ICON MASK
	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "Icon Mask:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var imgname = document.createElement('img');
	imgname.id = "icon_maskimg"
	imgname.className = "input_img"

	var inputname = document.createElement('input');
	inputname.id = "icon_maskfile";
	inputname.type = "file";
	inputname.accept = "image/*";
	inputname.name = "icon_mask"
	inputname.className = "input_file"

	inputnamecoldiv.appendChild(inputname);
	inputnamecoldiv.appendChild(imgname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	fieldset.appendChild(rownamediv);

	// END ICON MASK
	parent_form.appendChild(fieldset);

	// END EMUTICON DEFAULTS

	parent_form.appendChild(document.createElement('br'));

	// ACTIVE

	parent_form.innerHTML += " Active: ";

	var activecheckbox = document.createElement('input');
	activecheckbox.type = "checkbox";
	activecheckbox.name = "active";
	activecheckbox.id = "active";

	parent_form.appendChild(activecheckbox);

	// END ACTIVE

	parent_form.appendChild(document.createElement('br'));

	// DEV ONLY

	parent_form.innerHTML += " Dev Only: ";

	var devonlycheckbox = document.createElement('input');
	devonlycheckbox.type = "checkbox";
	devonlycheckbox.name = "dev_only";
	devonlycheckbox.id = "dev_only";

	parent_form.appendChild(devonlycheckbox);

	// END DEV ONLY

	parent_form.appendChild(document.createElement('br'));

	// BUTTON SAVE

	var saveButton = document.createElement('button');
	saveButton.className = "btn btn-default";
	saveButton.type = "button";
	saveButton.innerHTML = "Save";
	saveButton.id = "saveButton";
	saveButton.onclick = function(){ savePackage(method);};

	parent_form.appendChild(saveButton);

	// END BUTTON SAVE

	// BUTTON ZIP

	if(method == 'PUT'){
		var zipButton = document.createElement('button');
		zipButton.className = "btn btn-default";
		zipButton.type = "button";
		zipButton.innerHTML = "Zip";
		zipButton.id = "zipButton";
		zipButton.onclick = function(){ zipPackage();};

		parent_form.appendChild(zipButton);
	}

	// END BUTTON ZIP

	display.appendChild(parent_form);

	if(method == 'POST'){
		var active = document.getElementById("active")
		active.checked = true;

		var duration = document.getElementById("duration")
		duration.value = 2;

		var frames_count = document.getElementById("frames_count")
		frames_count.value = 24;

		var thumbnail_frame_index = document.getElementById("thumbnail_frame_index")
		thumbnail_frame_index.value = 23;

	}
	

	// END BUTTON UPDATE
}

function DisplayPackage(pack) {

	CreatePackageFields('PUT');

	// NAME
	pack_name = document.getElementById("pack_name");
	pack_name.innerHTML = pack.name;
	// END NAME

	// LABEL
	pack_label = document.getElementById("pack_label");
	pack_label.value = pack.label;
	// END LABEL

	// ICON2X
	img2xname = document.getElementById("icon2ximg");
	img2xname.src = "https://homage-emu-dev-test.s3.amazonaws.com/packages/" + pack.name + "/" + pack.icon_name + "%402x.gif";
	// END ICON2X

	// ICON3X
	img3xname = document.getElementById("icon3ximg");
	img3xname.src = "https://homage-emu-dev-test.s3.amazonaws.com/packages/" + pack.name + "/" + pack.icon_name + "%403x.gif";
	// END ICON3X

  	// EMUTICON DEFAULTS

  	// DURATION
	duration = document.getElementById("duration");
	duration.value = pack.emuticons_defaults.duration;
	// END DURATION

	// FRAMES COUNT
	frames_count = document.getElementById("frames_count");
	frames_count.value = pack.emuticons_defaults.frames_count;
	// END FRAMES COUNT

	// THUMBNAIL FRAME INDEX
	thumbnail_frame_index = document.getElementById("thumbnail_frame_index");
	thumbnail_frame_index.value = pack.emuticons_defaults.thumbnail_frame_index;
	// END THUMBNAIL FRAME INDEX

	// ICON MASK
	icon_maskimg = document.getElementById("icon_maskimg");
	icon_maskimg.src = "https://homage-emu-dev-test.s3.amazonaws.com/packages/" + pack.name + "/" + pack.emuticons_defaults["source_user_layer_mask"];
	// END ICON MASK

	// END EMUTICON DEFAULTS

	// ACTIVE
	active = document.getElementById("active");
	active.checked = pack.active;
	// END ACTIVE

	// DEV ONLY
	dev_only = document.getElementById("dev_only");
	dev_only.checked = pack.dev_only;
	// END DEV ONLY

}

function CreatePackage() {

	CreatePackageFields('POST');

}


function savePackage(method){

	var query = "";
	form = document.getElementById("parent_form");
	saveButton = document.getElementById("saveButton");
	
	var formData = new FormData(form);

	var pack_name = ""
	if(method == 'PUT'){
		pack_name = document.getElementById("pack_name").innerHTML;
		query += "?name=" + pack_name;
	}else{
		pack_name = document.getElementById("pack_name").value.trim().toLowerCase();
		query += "?name=" + pack_name;
	}

	if (!/^[a-z0-9_\-\ ]+$/.test(pack_name) || pack_name == ""){
		alert("fuck you! pack_name must contain only lowercase letters, numbers, - , _ , space")
		return
	}

	pack_label = document.getElementById("pack_label").value;
	query += "&label=" + pack_label;

	var updateIcons = 0;

	icon2xfile = document.getElementById("icon2xfile");
	if(icon2xfile.files && icon2xfile.files[0]){
		formData.append('icon_2x', icon2xfile.files[0]);
		updateIcons++;
	}
	
	icon3xfile = document.getElementById("icon3xfile");
	if(icon3xfile.files && icon3xfile.files[0]){
		formData.append('icon_3x', icon3xfile.files[0]);
		updateIcons++;
	}

	if(updateIcons == 1){
		alert("Cannot update only one icon size you fucking bastard!")
		return
	}

	icon_maskfile = document.getElementById("icon_maskfile");
	if(icon_maskfile.files && icon_maskfile.files[0]){
		formData.append('source_user_layer_mask', icon_maskfile.files[0]);
	}
	// emuticons defaults
	duration = document.getElementById("duration").value;
	query += "&duration=" + duration;

	frames_count = document.getElementById("frames_count").value;
	query += "&frames_count=" + frames_count;

	thumbnail_frame_index = document.getElementById("thumbnail_frame_index").value;
	query += "&thumbnail_frame_index=" + thumbnail_frame_index;

	active = document.getElementById("active").checked;
	
	if(active){
		query += "&active=" + "true";
	}
	else{
		query += "&active=" + "false";
	}

	dev_only = document.getElementById("dev_only").checked;
	
	if(dev_only){
		query += "&dev_only=" + "true";
	}
	else{
		query += "&dev_only=" + "false";
	}

	saveButton.disabled = true;
	saveButton.innerHTML = "Saving Please Fking wait..";

	var theUrl = form.getAttribute('action') + query;

	var xmlHttp = null;

	    xmlHttp = new XMLHttpRequest();

	    xmlHttp.onreadystatechange=function()
		  {
		  if (xmlHttp.readyState==4 && xmlHttp.status==200)
		    {
		    	alert("Saved Package")
		    	document.getElementById("display").innerHTML = "";
		    	location.reload();
		    }
		  }

		var USERNAME = 'homage';
		var PASSWORD = 'homageit10';

	    xmlHttp.open( method, theUrl, true );
	    xmlHttp.setRequestHeader("Authorization", "Basic " + btoa(USERNAME + ":" + PASSWORD));
	    xmlHttp.setRequestHeader("SCRATCHPAD", "true");
	    xmlHttp.send( formData );
	    // xmlHttp.send( null );

	    return false;

}

function zipPackage(){

	var query = "";
	form = document.getElementById("parent_form");
	zipButton = document.getElementById("zipButton");

	var pack_name = document.getElementById("pack_name").innerHTML;

	query = "?package_name=" + pack_name;

	zipButton.disabled = true;
	zipButton.innerHTML = "Zipping Please Fking wait..";

	var theUrl = "/emuconsole/zip" + query;

	var xmlHttp = null;

	    xmlHttp = new XMLHttpRequest();

	    xmlHttp.onreadystatechange=function()
		  {
		  if (xmlHttp.readyState==4 && xmlHttp.status==200)
		    {
		    	alert("Zipped Package")
		    	document.getElementById("display").innerHTML = "";
		    }
		  }

		var USERNAME = 'homage';
		var PASSWORD = 'homageit10';

	    xmlHttp.open( 'POST', theUrl, true );
	    xmlHttp.setRequestHeader("Authorization", "Basic " + btoa(USERNAME + ":" + PASSWORD));
	    xmlHttp.setRequestHeader("SCRATCHPAD", "true");
	    xmlHttp.send( null );
	    // xmlHttp.send( null );

	    return false;

}

// END PACKAGE

// EMUTICON

function DisplayEmuticons(pack){
	var emuticonsdiv = document.getElementById(pack.name + '-emuticons');
	var emuticonsplusbutton = document.getElementById(pack.name + '-plus-button');

	if(emuticonsplusbutton.innerHTML == '+'){
		emuticonsdiv.innerHTML += "*** " + pack.name + " emuticons ***";
		for (emuticon in pack.emuticons) {
			var emuticonButton = document.createElement('button');
			emuticonButton.className = "btn btn-default emuButton";
			emuticonButton.type = "button";
			emuticonButton.id = pack.emuticons[emuticon].name + "-button"
			emuticonButton.innerHTML = pack.emuticons[emuticon].name;
			var currentemuticon = JSON.stringify(pack.emuticons[emuticon]);
			var stringcurrentemuticon = String(currentemuticon);
			$(emuticonButton).data("pack", pack);
			$(emuticonButton).data("emu", pack.emuticons[emuticon]);
			// emuticonButton.onclick = function(){ DisplayEmuticon(stringcurrentemuticon);}
			
			emuticonsdiv.appendChild(emuticonButton);
		};

		var newemuticonButton = document.createElement('button');
			newemuticonButton.className = "btn btn-default newemuButton";
			newemuticonButton.type = "button";
			newemuticonButton.id = "new-emuticon-button"
			newemuticonButton.innerHTML = "Add +";
			$(newemuticonButton).data("pack", pack);

		emuticonsdiv.appendChild(newemuticonButton);

		emuticonsdiv.appendChild(document.createElement("br"));
		emuticonsdiv.appendChild(document.createElement("br"));
		// emuticonsdiv.innerHTML += "******************";
		emuticonsplusbutton.innerHTML = '-';
	}else{
		emuticonsdiv.innerHTML = "";
		emuticonsplusbutton.innerHTML = '+';
	}

}

function DisplayEmuticon(pack, emuticon) {

	CreateEmuticonFields(pack, 'PUT');

	 // addEmuticon(package_name,
    	// name,
    	// source_back_layer,
    	// source_front_layer,
    	// source_user_layer_mask,
    	// palette,
    	// patched_on,
    	// tags,
    	// use_for_preview)

	// NAME
	emuticon_name = document.getElementById("emuticon_name");
	emuticon_name.innerHTML = emuticon.name;
	// END NAME

	// source_back_layer
	source_back_layer = document.getElementById("source_back_layer_img");
	source_back_layer.src = "https://homage-emu-dev-test.s3.amazonaws.com/packages/" + pack.name + "/" + emuticon.source_back_layer;
	// END source_back_layer

	// source_front_layer
	source_front_layer = document.getElementById("source_front_layer_img");
	source_front_layer.src = "https://homage-emu-dev-test.s3.amazonaws.com/packages/" + pack.name + "/" + emuticon.source_front_layer;
	// END source_front_layer

	// source_user_layer_mask
	source_user_layer_mask = document.getElementById("source_user_layer_mask_img");
	source_user_layer_mask.src = "https://homage-emu-dev-test.s3.amazonaws.com/packages/" + pack.name + "/" + emuticon.source_user_layer_mask;
	// END source_user_layer_mask

	// palette
	palette = document.getElementById("palette");
	if(emuticon.palette && emuticon.palette != ""){
		palette.value = emuticon.palette;
	}
	// END palette

	// tags
	tags = document.getElementById("tags");
	tags.value = emuticon.tags;
	// END tags

	// use_for_preview
	use_for_preview = document.getElementById("use_for_preview");
	use_for_preview.checked = emuticon.use_for_preview;
	// END use_for_preview

}

function CreateEmuticon(pack) {

	CreateEmuticonFields(pack, 'POST');

}

function CreateEmuticonFields(pack, method){
	var display = document.getElementById("display");

    // addEmuticon(package_name,
    	// name,
    	// source_back_layer,
    	// source_front_layer,
    	// source_user_layer_mask,
    	// palette,
    	// patched_on,
    	// tags,
    	// use_for_preview)

	// Reset display
	display.innerHTML = "";

	// CREATE FORM 
	var parent_form = document.createElement('form');
	parent_form.id = "parent_form";
	parent_form.action = '/emuapi/emuticon';
	parent_form.enctype = "multipart/form-data";

	// PACK

	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";

	var labelpackname = document.createElement('label');
	labelpackname.id = "pack_name";
	labelpackname.innerHTML = pack.name;

	labelnamecoldiv.appendChild(labelpackname);
	rownamediv.appendChild(labelnamecoldiv);
	parent_form.appendChild(rownamediv);

	// END PACK

	// NAME
	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "Name:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var labelname = null;
	if(method == 'PUT'){
		labelname = document.createElement('label');
		labelname.id = "emuticon_name";
	}else{
		labelname = document.createElement('input');
		labelname.id = "emuticon_name";
		labelname.type = "text"
	}

	inputnamecoldiv.appendChild(labelname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	parent_form.appendChild(rownamediv);

	// END NAME

	// source_back_layer
	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "source_back_layer:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var imgname = document.createElement('img');
	imgname.id = "source_back_layer_img"
	imgname.className = "input_img"

	var inputname = document.createElement('input');
	inputname.id = "source_back_layer_file";
	inputname.type = "file";
	inputname.accept = "image/*";
	inputname.name = "source_back_layer"
	inputname.className = "input_file"
	
	inputnamecoldiv.appendChild(inputname);
	inputnamecoldiv.appendChild(imgname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	parent_form.appendChild(rownamediv);

	// END source_back_layer

	// source_front_layer
	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "source_front_layer:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var imgname = document.createElement('img');
	imgname.id = "source_front_layer_img"
	imgname.className = "input_img"

	var inputname = document.createElement('input');
	inputname.id = "source_front_layer_file";
	inputname.type = "file";
	inputname.accept = "image/*";
	inputname.name = "source_front_layer"
	inputname.className = "input_file"

	
	inputnamecoldiv.appendChild(inputname);
	inputnamecoldiv.appendChild(imgname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	parent_form.appendChild(rownamediv);

	parent_form.appendChild(document.createElement('br'));

	// END source_front_layer

	// source_user_layer_mask
	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "source_user_layer_mask:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var imgname = document.createElement('img');
	imgname.id = "source_user_layer_mask_img"
	imgname.className = "input_img"

	var inputname = document.createElement('input');
	inputname.id = "source_user_layer_mask_file";
	inputname.type = "file";
	inputname.accept = "image/*";
	inputname.name = "source_user_layer_mask"
	inputname.className = "input_file"

	inputnamecoldiv.appendChild(inputname);
	inputnamecoldiv.appendChild(imgname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	parent_form.appendChild(rownamediv);

	// END source_user_layer_mask

	parent_form.appendChild(document.createElement('br'));

	// palette

	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "palette:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var inputname = document.createElement('input');
	inputname.id = "palette";
	inputname.type = "text";

	inputnamecoldiv.appendChild(inputname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	parent_form.appendChild(rownamediv);

	// END palette

	// tags

	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = "tags:"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	var inputname = document.createElement('input');
	inputname.id = "tags";
	inputname.type = "text";

	inputnamecoldiv.appendChild(inputname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);
	parent_form.appendChild(rownamediv);

	// END tags

	// use_for_preview

	parent_form.innerHTML += " use_for_preview: ";

	var use_for_previewcheckbox = document.createElement('input');
	use_for_previewcheckbox.type = "checkbox";
	use_for_previewcheckbox.id = "use_for_preview";

	parent_form.appendChild(use_for_previewcheckbox);

	// END use_for_preview

	parent_form.appendChild(document.createElement('br'));


	parent_form.appendChild(document.createElement('br'));

	// BUTTON UPDATE

	var saveButton = document.createElement('button');
	saveButton.className = "btn btn-default";
	saveButton.type = "button"
	saveButton.innerHTML = "Save"
	saveButton.id = "saveButton";
	saveButton.onclick = function(){ saveEmuticon(method);};

	parent_form.appendChild(saveButton);

	display.appendChild(parent_form);

	// END BUTTON UPDATE
}

function saveEmuticon(method){

	// addEmuticon(package_name,
    	// name,
    	// source_back_layer,
    	// source_front_layer,
    	// source_user_layer_mask,
    	// palette,
    	// patched_on,
    	// tags,
    	// use_for_preview)

	var query = "";
	form = document.getElementById("parent_form");

	saveButton = document.getElementById("saveButton");
	

	var formData = new FormData(form);

	pack_name = document.getElementById("pack_name").innerHTML;
	query += "?package_name=" + pack_name;

	emuticon_name = "";
	if(method == 'PUT'){
		emuticon_name = document.getElementById("emuticon_name").innerHTML;
		query += "&name=" + emuticon_name;
	}
	else{
		emuticon_name = document.getElementById("emuticon_name").value.trim().toLowerCase();
		query += "&name=" + emuticon_name;
	}

	if (!/^[a-z0-9_\-\ ]+$/.test(emuticon_name) || emuticon_name == ""){
		alert("emuticon_name must contain only lowercase letters, numbers, - , _ , space")
		return
	}

	source_back_layer_file = document.getElementById("source_back_layer_file");
	if(source_back_layer_file.files && source_back_layer_file.files[0]){
		formData.append('source_back_layer', source_back_layer_file.files[0]);
	}
	
	source_front_layer_file = document.getElementById("source_front_layer_file");
	if(source_front_layer_file.files && source_front_layer_file.files[0]){
		formData.append('source_front_layer', source_front_layer_file.files[0]);
	}

	source_user_layer_mask_file = document.getElementById("source_user_layer_mask_file");
	if(source_user_layer_mask_file.files && source_user_layer_mask_file.files[0]){
		formData.append('source_user_layer_mask', source_user_layer_mask_file.files[0]);
	}

	palette = document.getElementById("palette").value;
	query += "&palette=" + escape(palette);

	tags = document.getElementById("tags").value;
	query += "&tags=" + escape(tags);

	if (!/^[a-z0-9\,]+$/.test(tags) || tags == ""){
		alert("tags may contain only lowercase letters, numbers, seperated by commas and must have at least one value fok yuuuu")
		return
	}
	
	use_for_preview = document.getElementById("use_for_preview").checked;
	
	if(use_for_preview){
		query += "&use_for_preview=" + "true";
	}
	else{
		query += "&use_for_preview=" + "false";
	}

	saveButton.disabled = true;
	saveButton.innerHTML = "Saving Please Fking wait..";

	var theUrl = form.getAttribute('action') + query;

	var xmlHttp = null;

	    xmlHttp = new XMLHttpRequest();

	    xmlHttp.onreadystatechange=function()
		  {
		  if (xmlHttp.readyState==4 && xmlHttp.status==200)
		    {
		    	alert("Saved Emuticon")
		    	document.getElementById("display").innerHTML = "";
		    	location.reload();
		    }
		  }

		var USERNAME = 'homage';
		var PASSWORD = 'homageit10';

	    xmlHttp.open( method, theUrl, true );
	    xmlHttp.setRequestHeader("Authorization", "Basic " + btoa(USERNAME + ":" + PASSWORD));
	    xmlHttp.setRequestHeader("SCRATCHPAD", "true");
	    xmlHttp.send( formData );
	    // xmlHttp.send( null );

	    return false;

}

// END EMUTICON

