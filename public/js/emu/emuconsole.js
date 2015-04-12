$(window).on("load",function(){
        var winheight = $(window).height();
        if($(document).height() > $(window).height()){
            winheight = $(document).height();
        }
        $('.leftbackground').height(winheight);  
    });


function CreatePackageFields(method){
	// pack = JSON.parse(pack);

	display = document.getElementById("display");


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

	var inputname = document.createElement('input');
	inputname.id = "pack_name";
	inputname.type = "text";

	inputnamecoldiv.appendChild(inputname);
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

	var inputname = document.createElement('input');
	inputname.id = "icon2xfile";
	inputname.type = "file";
	inputname.accept = "image/*";
	inputname.name = "icon2x"

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

	var inputname = document.createElement('input');
	inputname.id = "icon3xfile";
	inputname.type = "file";
	inputname.accept = "image/*";
	inputname.name = "icon3x"

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
	imgname.id = "iconMask"

	var inputname = document.createElement('input');
	inputname.id = "icon_maskfile";
	inputname.type = "file";
	inputname.accept = "image/*";
	inputname.name = "icon_mask"

	inputnamecoldiv.appendChild(inputname);
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
	activecheckbox.value = "Active";
	activecheckbox.id = "active";

	parent_form.appendChild(activecheckbox);

	// END ACTIVE

	parent_form.appendChild(document.createElement('br'));

	// DEV ONLY

	parent_form.innerHTML += " Dev Only: ";

	var devonlycheckbox = document.createElement('input');
	devonlycheckbox.type = "checkbox";
	devonlycheckbox.name = "dev_only";
	devonlycheckbox.value = "Dev Only";
	devonlycheckbox.id = "dev_only";

	parent_form.appendChild(devonlycheckbox);

	// END DEV ONLY

	parent_form.appendChild(document.createElement('br'));

	// BUTTON UPDATE

	var saveButton = document.createElement('button');
	saveButton.className = "btn btn-default";
	saveButton.type = "button"
	saveButton.innerHTML = "Save"
	saveButton.onclick = function(){ save(method);};

	parent_form.appendChild(saveButton);

	display.appendChild(parent_form);

	// END BUTTON UPDATE
}

function DisplayPackage(pack) {

	CreatePackageFields('PUT');

	// NAME
	pack_name = document.getElementById("pack_name");
	pack_name.value = pack.name;
	// END NAME

	// LABEL
	pack_label = document.getElementById("pack_label");
	pack_label.value = pack.label;
	// END LABEL

	// ICON2X
	img2xname = document.getElementById("icon2ximg");
	img2xname.src = "https://homage-emu-dev-test.s3.amazonaws.com/packages/" + pack.name + "/" + pack.icon_name + "%402x.png"
	// END ICON2X

	// ICON3X
	img3xname = document.getElementById("icon3ximg");
	img3xname.src = "https://homage-emu-dev-test.s3.amazonaws.com/packages/" + pack.name + "/" + pack.icon_name + "%403x.png"
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
	icon_maskfile = document.getElementById("icon_maskfile");
	icon_maskfile.src = "https://homage-emu-dev-test.s3.amazonaws.com/packages/" + pack.name + "/" + pack.icon_name + "-mask.png"
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

function CreatePackage(pack) {

	CreatePackageFields('POST');

}


function save(method){

	var query = "";
	form = document.getElementById("parent_form");
	var formData = new FormData(form);

	pack_name = document.getElementById("pack_name").value;
	query += "?name=" + pack_name;
	pack_label = document.getElementById("pack_label").value;
	query += "&label=" + pack_label;
	icon2xfile = document.getElementById("icon2xfile");
	if(icon2xfile.files && icon2xfile.files[0]){
		formData.append('icon_2x', icon2xfile.files[0]);
	}
	
	icon3xfile = document.getElementById("icon3xfile");
	if(icon3xfile.files && icon3xfile.files[0]){
		formData.append('icon_3x', icon3xfile.files[0]);
	}

	icon_maskfile = document.getElementById("icon_maskfile");
	if(icon_maskfile.files && icon_maskfile.files[0]){
		formData.append('icon_mask', icon_maskfile.files[0]);
	}
	// emuticons defaults
	duration = document.getElementById("duration").value;
	query += "&duration=" + duration;
	frames_count = document.getElementById("frames_count").value;
	query += "&frames_count=" + frames_count;
	thumbnail_frame_index = document.getElementById("thumbnail_frame_index").value;
	query += "&thumbnail_frame_index=" + thumbnail_frame_index;

	active = document.getElementById("active").checked;
	query += "&active=" + "false";
	if(active){
		query += "&active=" + "true";
	}

	dev_only = document.getElementById("dev_only").checked;
	query += "&dev_only=" + "false";
	if(dev_only){
		query += "&dev_only=" + "true";
	}

	var theUrl = form.getAttribute('action') + query;

	var xmlHttp = null;

	    xmlHttp = new XMLHttpRequest();

	   //  xmlHttp.onreadystatechange=function()
		  // {
		  // if (xmlHttp.readyState==4 && xmlHttp.status==200)
		  //   {
		  //   	alert("Saved Package")
		  //   }
		  //   else{
		  //   	alert("Save Package FAILED!!!")
		  //   }
		  // }

		var USERNAME = 'homage';
		var PASSWORD = 'homageit10';

	    xmlHttp.open( method, theUrl, true );
	    xmlHttp.setRequestHeader("Authorization", "Basic " + btoa(USERNAME + ":" + PASSWORD));
	    xmlHttp.setRequestHeader("SCRATCHPAD", "true");
	    xmlHttp.send( formData );
	    // xmlHttp.send( null );

	    return false;

}