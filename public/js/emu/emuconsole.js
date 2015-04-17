$(window).on("load",function(){
        var winheight = $(window).height();
        if($(document).height() > $(window).height()){
            winheight = $(document).height();
        }
        $('.leftbackground').height(winheight);  
    });

var awsfolder = "";
var packs_scratchpad = "";
var packs_public = "";

function setAwsFolder(awslink){
	awsfolder = awslink;
}

function setAllPacks(p_scratchpad, p_public){
	packs_scratchpad = p_scratchpad;
	packs_public = p_public;
}

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
			var awslink = $("#mydata").data("awslink");
			setAwsFolder(awslink);
			DisplayEmuticons(pack);
	});

	$("body").on("click", ".packButton", function(){
			var pack = $(this).data("package");
			var awslink = $("#mydata").data("awslink");
			setAwsFolder(awslink);
			DisplayPackage(pack);
	});

	$("body").on("click", ".createPackButton", function(){
			var pack = $(this).data("package");
			CreatePackage(pack);
	});

	$("body").on("click", "#zipButton", function(){
			var pack = $(this).data("package");
			var p_scratchpad = $("#mydata").data("pscratchpad");
			var p_public = $("#mydata").data("ppublic");
			setAllPacks(p_scratchpad, p_public);
			zipPackage(pack,p_scratchpad,p_public);
	});

	$("body").on("click", "#deployButton", function(){
			var pack = $(this).data("package");
			var p_scratchpad = $("#mydata").data("pscratchpad");
			var p_public = $("#mydata").data("ppublic");
			setAllPacks(p_scratchpad, p_public);
			deployPackage(pack,p_scratchpad,p_public);
	});

	$("body").on("click", "#saveButton", function(){
			var method = $(this).data("method");
			var p_scratchpad = $("#mydata").data("pscratchpad");
			var p_public = $("#mydata").data("ppublic");
			setAllPacks(p_scratchpad, p_public);
			savePackage(method,p_scratchpad,p_public);
	});

	$("body").on("click", "#saveEmuButton", function(){
			var method = $(this).data("method");
			var p_scratchpad = $("#mydata").data("pscratchpad");
			var p_public = $("#mydata").data("ppublic");
			setAllPacks(p_scratchpad, p_public);
			saveEmuticon(method,p_scratchpad,p_public);
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

		else if(this.id == 'source_back_layerfile'){
			readURL(this, '#source_back_layerimg');
		}

		else if(this.id == 'source_front_layerfile'){
			readURL(this, '#source_front_layerimg');
		}

		else if(this.id == 'source_user_layer_maskfile'){
			readURL(this, '#source_user_layer_maskimg');
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

function createInputOrLabelRowElementDiv(method, label, element_id, element_type, input_type, cantChangeOnUpdate, isFile, content_type, classname){
	var rownamediv = document.createElement('div');
	rownamediv.className = "row";

	var labelnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-1";
	labelnamecoldiv.innerHTML = label + ":"

	var inputnamecoldiv = document.createElement('div');
	labelnamecoldiv.className = "col-sm-3";

	if(isFile){
		var imgname = document.createElement('img');
		imgname.id = element_id + "img"
		imgname.className = "input_img"
		var inputname = document.createElement(element_type);
		inputname.id = element_id + "file";
		inputname.type = input_type;
		inputname.accept = content_type;
		inputname.name = element_id
		inputname.className = classname
		inputnamecoldiv.appendChild(imgname);
	}else{
		var inputname = null;
		if(cantChangeOnUpdate){
			if(method == 'PUT'){
				inputname = document.createElement('label');
			}else{
				inputname = document.createElement('input');
				inputname.type = input_type
			}
		}
		else{
			inputname = document.createElement(element_type);
			inputname.type = input_type
		}
		inputname.id = element_id;
	}

	

	inputnamecoldiv.appendChild(inputname);
	rownamediv.appendChild(labelnamecoldiv);
	rownamediv.appendChild(inputnamecoldiv);

	return rownamediv;
}

// PACKAGE

function CreatePackageFields(method, pack){

	var display = document.getElementById("display");


	// Reset display
	display.innerHTML = "";

	// CREATE FORM 
	var parent_form = document.createElement('form');
	parent_form.id = "parent_form";
	parent_form.action = '/emuapi/package';
	parent_form.enctype = "multipart/form-data";

	// NAME
	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Name", "pack_name", "input", "text", true, false, "", ""));
	
	// END NAME

	// LABEL
	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Label", "pack_label", "input", "text", false, false, "", ""));

	// END LABEL

	// ICON2X

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Icon2x", "icon2x", 'input', "file", false, true, "image/*", "input_file"));

	// END ICON2X

	// ICON3X
	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Icon3x", "icon3x", 'input', "file", false, true, "image/*", "input_file"));
	parent_form.appendChild(document.createElement('br'));

	// END ICON3X

  	// EMUTICON DEFAULTS

  	
  	var fieldset = document.createElement('fieldset');
  	var legend = document.createElement('legend');
  	legend.innerHTML = "Emuticons Defaults:";
  	fieldset.appendChild(legend);


  	// DURATION

	fieldset.appendChild(createInputOrLabelRowElementDiv(method, "Duration", "duration", 'input', "text", false, false, "", ""));

	// END DURATION

	// FRAMES COUNT

	fieldset.appendChild(createInputOrLabelRowElementDiv(method, "Frames Count", "frames_count", 'input', "text", false, false, "", ""));

	// END FRAMES COUNT

	// THUMBNAIL FRAME INDEX

	fieldset.appendChild(createInputOrLabelRowElementDiv(method, "Thumbnail Frame Index", "thumbnail_frame_index", 'input', "text", false, false, "", ""));

	// END THUMBNAIL FRAME INDEX

	// ICON MASK

	fieldset.appendChild(createInputOrLabelRowElementDiv(method, "Icon Mask", "icon_mask", 'input', "file", false, true, "image/*", "input_file"));

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
	saveButton.setAttribute("data-method", method);
	if(pack.cms_proccessing == true){
		saveButton.disabled = true;
	}

	parent_form.appendChild(saveButton);

	// END BUTTON SAVE

	

	if(method == 'PUT'){

		// BUTTON ZIP

		

		var zipButton = document.createElement('button');
		zipButton.className = "btn btn-default";
		zipButton.type = "button";
		zipButton.innerHTML = "Zip";
		zipButton.id = "zipButton";
		zipButton.setAttribute("data-package", JSON.stringify(pack));
		if(pack.cms_proccessing == true || pack.cms_state != "zip" || pack.emuticons.length < 6){
			zipButton.disabled = true;
		}

		parent_form.appendChild(zipButton);
		

		// END BUTTON ZIP

		// BUTTON DEPLOY

		

		var deployButton = document.createElement('button');
		deployButton.className = "btn btn-default";
		deployButton.type = "button";
		deployButton.innerHTML = "Deploy";
		deployButton.id = "deployButton";
		deployButton.setAttribute("data-package", JSON.stringify(pack));
		if(pack.cms_proccessing == true || pack.cms_state != "deploy" || pack.emuticons.length < 6){
			deployButton.disabled = true;
		}

		parent_form.appendChild(deployButton);
		

		// END BUTTON DEPLOY
	}

	

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

	CreatePackageFields('PUT', pack);

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
	img2xname.src = awsfolder + pack.name + "/" + pack.cms_icon_2x;
	// END ICON2X

	// ICON3X
	img3xname = document.getElementById("icon3ximg");
	img3xname.src = awsfolder + pack.name + "/" + pack.cms_icon_3x;
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
	icon_maskimg.src = awsfolder + pack.name + "/" + pack.emuticons_defaults["source_user_layer_mask"];
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

	CreatePackageFields('POST',null);

}


function savePackage(method, p_scratchpad, p_public){


try {
    

	var query = "";
	form = document.getElementById("parent_form");

	var zipButtonstate = false
	var deployButtonState = false

	saveButton = document.getElementById("saveButton");
	saveButton.disabled = true;
	saveButton.innerHTML = "Saving Please Fking wait..";
	if(method == 'PUT'){
		zipButton = document.getElementById("zipButton");
		zipButtonstate = zipButton.disabled;
		zipButton.disabled = true;
		deployButton = document.getElementById("deployButton");
		deployButtonState = deployButton.disabled;
		deployButton.disabled = true;
	}
	
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
		alert("fuck you! pack_name must contain only lowercase letters, numbers, - , _ , space");
		return;
	}

	if(method == 'POST'){
		for (scrathpack in p_scratchpad){
			if(pack_name == p_scratchpad[scrathpack].name)
			{
				alert("Package name already in use");
				return;
			}
		}
	}

	pack_label = document.getElementById("pack_label").value;
	query += "&label=" + pack_label;

	var updateIcons = 0;

	icon2xfile = document.getElementById("icon2xfile");
	if(icon2xfile.files.length > 0 && icon2xfile.files[0]){
		formData.append('icon_2x', icon2xfile.files[0]);
		updateIcons++;
	}
	
	icon3xfile = document.getElementById("icon3xfile");
	if(icon3xfile.files.length > 0 && icon3xfile.files[0]){
		formData.append('icon_3x', icon3xfile.files[0]);
		updateIcons++;
	}

	if(updateIcons == 1){
		alert("Cannot update only one icon size you fucking bastard!");
		return;
	}

	icon_maskfile = document.getElementById("icon_maskfile");
	if(icon_maskfile.files.length > 0 && icon_maskfile.files[0]){
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

	var theUrl = form.getAttribute('action') + query;

	var xmlHttp = null;

	    xmlHttp = new XMLHttpRequest();

	    xmlHttp.onreadystatechange=function()
		  {
		  if (xmlHttp.readyState==4 && xmlHttp.status==200)
		    {

		    	result = JSON.parse(xmlHttp.responseText);
		    	if(result.error == true){
		    		alert("Saved Package successfully");
		    		location.reload();
		    	}else{
		    		alert(result.error);
		    		saveButton.disabled = false;
					saveButton.innerHTML = "Save";
					zipButton.disabled = zipButtonstate;
					deployButton.disabled = deployButtonState;
		    	}
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
catch(err) {
    alert(err.message);
    return;
}

}

function zipPackage(pack, p_scratchpad, p_public){

try{
	// Validations

	if(pack.emuticons.length < 6){
		alert("Trying to zip with less than 6 emuticons? who the fuck do you think you are? Chuck norris??!@#$");
		return;
	}

	// END validations

	var query = "";
	form = document.getElementById("parent_form");

	var zipButtonstate = false
	var deployButtonState = false

	saveButton = document.getElementById("saveButton");
	saveButton.disabled = true;
	zipButton = document.getElementById("zipButton");
	zipButtonstate = zipButton.disabled;
	zipButton.disabled = true;
	zipButton.innerHTML = "Zipping Please Fking wait..";
	deployButton = document.getElementById("deployButton");
	deployButtonState = deployButton.disabled;
	deployButton.disabled = true;

	var pack_name = document.getElementById("pack_name").innerHTML;

	query = "?package_name=" + pack_name;

	var theUrl = "/emuconsole/zip" + query;

	var xmlHttp = null;

	    xmlHttp = new XMLHttpRequest();

	    xmlHttp.onreadystatechange=function()
		  {
		  if (xmlHttp.readyState==4 && xmlHttp.status==200)
		    {

		    	result = JSON.parse(xmlHttp.responseText);
		    	if(result.error == true){
		    		alert("Zipped Package successfully");
		    		location.reload();
		    	}else{
		    		alert(result.error);
		    		saveButton.disabled = false;
					zipButton.innerHTML = "Zip";
					zipButton.disabled = zipButtonstate;
					deployButton.disabled = deployButtonState;
		    	}
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
catch(err) {
    alert(err.message);
    return;
}

}

function deployPackage(pack,p_scratchpad,p_public){

try{

	// validations



	// END validations

	var query = "";
	form = document.getElementById("parent_form");

	var zipButtonstate = false
	var deployButtonState = false
	
	saveButton = document.getElementById("saveButton");
	saveButton.disabled = true;
	zipButton = document.getElementById("zipButton");
	zipButtonstate = zipButton.disabled;
	zipButton.disabled = true;
	deployButton = document.getElementById("deployButton");
	deployButtonState = deployButton.disabled;
	deployButton.disabled = true;
	deployButton.innerHTML = "Deploying Please Fking wait..";

	var pack_name = document.getElementById("pack_name").innerHTML;

	query = "?package_name=" + pack_name;

	var theUrl = "/emuconsole/deploy" + query;

	var xmlHttp = null;

	    xmlHttp = new XMLHttpRequest();

	    xmlHttp.onreadystatechange=function()
		  {
		  if (xmlHttp.readyState==4 && xmlHttp.status==200)
		    {
		    	result = JSON.parse(xmlHttp.responseText);
		    	if(result.error == true){
		    		alert("Deployed Package successfully");
		    		location.reload();
		    	}else{
		    		alert(result.error);
		    		saveButton.disabled = false;
					deployButton.innerHTML = "Deploy";
					zipButton.disabled = zipButtonstate;
					deployButton.disabled = deployButtonState;
		    	}
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
catch(err) {
    alert(err.message);
    return;
}
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
	source_back_layer = document.getElementById("source_back_layerimg");
	source_back_layer.src = awsfolder + pack.name + "/" + emuticon.source_back_layer;
	// END source_back_layer

	// source_front_layer
	source_front_layer = document.getElementById("source_front_layerimg");
	source_front_layer.src = awsfolder + pack.name + "/" + emuticon.source_front_layer;
	// END source_front_layer

	// source_user_layer_mask
	source_user_layer_mask = document.getElementById("source_user_layer_maskimg");
	source_user_layer_mask.src = awsfolder + pack.name + "/" + emuticon.source_user_layer_mask;
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

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Name", "emuticon_name", "input", "text", true, false, "", ""));

	// END NAME

	// source_back_layer

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "source_back_layer", "source_back_layer", 'input', "file", false, true, "image/*", "input_file"));

	// END source_back_layer

	// source_front_layer

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "source_front_layer", "source_front_layer", 'input', "file", false, true, "image/*", "input_file"));

	// END source_front_layer

	// source_user_layer_mask

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "source_user_layer_mask", "source_user_layer_mask", 'input', "file", false, true, "image/*", "input_file"));

	// END source_user_layer_mask

	parent_form.appendChild(document.createElement('br'));

	// palette

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "palette", "palette", "input", "text", false, false, "", ""));

	// END palette

	// tags

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "tags", "tags", "input", "text", false, false, "", ""));

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
	saveButton.id = "saveEmuButton";
	saveButton.setAttribute("data-method", method);
	if(pack.cms_proccessing == true){
		saveButton.disabled = true;
	}

	parent_form.appendChild(saveButton);

	display.appendChild(parent_form);

	// END BUTTON UPDATE
}

function saveEmuticon(method,p_scratchpad,p_public){
try{
	var query = "";
	form = document.getElementById("parent_form");

	saveButton = document.getElementById("saveEmuButton");
	

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

	if(method == 'POST'){
		for (scrathpack in p_scratchpad){
			for (emu in p_scratchpad[scrathpack].emuticons){
				if(emuticon_name == p_scratchpad[scrathpack].emuticons[emu].name)
				{
					alert("Emuticon name already in use");
					return;
				}
			}
		}
	}

	source_back_layerfile = document.getElementById("source_back_layerfile");
	if(source_back_layerfile != null && source_back_layerfile.files.length > 0 && source_back_layerfile.files[0]){
		formData.append('source_back_layer', source_back_layerfile.files[0]);
	}
	
	source_front_layerfile = document.getElementById("source_front_layerfile");
	if(source_front_layerfile != null && source_front_layerfile.files.length > 0 && source_front_layerfile.files[0]){
		formData.append('source_front_layer', source_front_layerfile.files[0]);
	}

	if(method == 'POST' && source_back_layerfile.files.length == 0 && source_front_layerfile.files.length == 0){
		alert("Must have at least one file for background or foreground");
		return;
	}

	source_user_layer_maskfile = document.getElementById("source_user_layer_maskfile");
	if(source_user_layer_maskfile != null && source_user_layer_maskfile.files.length > 0 && source_user_layer_maskfile.files[0]){
		formData.append('source_user_layer_mask', source_user_layer_maskfile.files[0]);
	}

	palette = document.getElementById("palette").value;
	if(palette != null || palette != ""){
		query += "&palette=" + escape(palette);
	}

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
		    	result = JSON.parse(xmlHttp.responseText);
		    	if(result.error == true){
		    		alert("Saved Emuticon successfully");
		    		location.reload()
		    	}else{
		    		alert(result.error);
		    		saveButton.disabled = false;
					saveButton.innerHTML = "Save";
		    	}
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
catch(err) {
    alert(err.message);
    return;
}
}

// END EMUTICON

