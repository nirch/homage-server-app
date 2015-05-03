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

function paintPackageButtons(){
	for(i in packs_scratchpad){
		for(j in packs_public){
			scratchpad_pack_name = packs_scratchpad[i].name
			public_pack_name = packs_public[j].name
			var packButton = document.getElementById(scratchpad_pack_name + '-button')

			if(public_pack_name == scratchpad_pack_name){
				packButton.className = "btn btn-default packButton buttonDeployed";
				break;
			}else{
				packButton.className = "btn btn-default packButton buttonUndeployed";
			}
		}
	}
}

$(document).on("ready", function(){

	setAllPacks($("#mydata").data("pscratchpad"), $("#mydata").data("ppublic"));

	paintPackageButtons();

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

function getPackageByName(pack_name, packs_list){
	for (packnum in packs_list){
		if(pack_name == packs_list[packnum].name){
			return packs_list[packnum];
		}
	}
	return null;
}

function getEmuticonByName(pack_name, emuticon_name, packs_list){
	for (packnum in packs_list){
		if(pack_name == packs_list[packnum].name){
			for(emuticonnum in packs_list[packnum].emuticons)
			{
				if(emuticon_name == packs_list[packnum].emuticons[emuticonnum].name){
					return packs_list[packnum].emuticons[emuticonnum];
				}
			}
		}
	}
	return null;
}


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

	var inputnamecoldiv = document.createElement('div');
	inputnamecoldiv.className = "col-sm-8 align-left";

	var labelnamecoldiv = null;
	var inputname = null;
	var imgname = null;
	var imgchkbxlbl = null;
	var imgchkbx = null;

	var labelname = document.createElement('label');
	labelname.innerHTML = label + ": "

	if(isFile){
		imgname = document.createElement('img');
		imgname.id = element_id + "img"
		imgname.className = "input_img"
		
		if(method == 'PUT' ){
			imgchkbxlbl = document.createElement('label');
			imgchkbxlbl.innerHTML = " remove image: "
			imgchkbx = document.createElement('input');
			imgchkbx.type = "checkbox"
			imgchkbx.id = element_id + "checkbox"
		
		}
		inputname = document.createElement(element_type);
		inputname.id = element_id + "file";
		inputname.type = input_type;
		inputname.accept = content_type;
		inputname.name = element_id
		inputname.className = classname
	}else{
		inputname = null;
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


	inputnamecoldiv.appendChild(labelname);
	inputnamecoldiv.appendChild(inputname);
	if(imgchkbxlbl != null){
		inputnamecoldiv.appendChild(imgchkbxlbl);
		inputnamecoldiv.appendChild(imgchkbx);
	}
	if(imgname != null){
		inputnamecoldiv.appendChild(document.createElement('br'));
		inputnamecoldiv.appendChild(imgname);
	}
	rownamediv.appendChild(inputnamecoldiv);
	rownamediv.appendChild(compareLabel(element_id));

	return rownamediv;
}

function compareLabel(element_id){
	var inputnamecoldiv = document.createElement('div');
	inputnamecoldiv.className = "col-sm-3";

	compare_label = document.createElement('label');
	compare_label.id = element_id + "compare";
	compare_label.innerHTML = "*value changed*";
	compare_label.className = "comparelabel";
	compare_label.style.display = 'none';

	inputnamecoldiv.appendChild(compare_label);
	return inputnamecoldiv;
}

function displayCompareForField(element_id, public_value, scratch_value){
	if(scratch_value != public_value){
		document.getElementById(element_id + "compare").style.display = 'block';
		return true;
	}
	return false;
}

function emuticonsValuesUpdate(pack, public_pack){

	var valuesChanged = false;
	for (i = 0; i <  pack.emuticons.length; i++) {
		var keylist = Object.keys(pack.emuticons[i])
		if(public_pack.emuticons.length > i){
			var publickeylist = Object.keys(public_pack.emuticons[i])
			for(item in keylist){
				if(keylist[item] != "id" && keylist[item] != "name"){
					if(!public_pack.emuticons[i].hasOwnProperty(keylist[item])){
						valuesChanged = true;
				    	break;
					}
					if(public_pack.emuticons[i][keylist[item]] == "" && pack.emuticons[i][keylist[item]] == ""){
						continue;
					}
				    if(public_pack.emuticons[i][keylist[item]] != pack.emuticons[i][keylist[item]]){
				    	valuesChanged = true;
				    	break;
				    }
				}
			}
		}
		else{
			valuesChanged = true;
		}

	}
	return valuesChanged;
}

function emuticonsValidated(pack){
	var validated = true;
	var message = "";
	for (i in  pack.emuticons) {
		emuticon = pack.emuticons[i];
		if(emuticon.source_back_layer == null || emuticon.source_back_layer == ""){
			validated = false;
			message += "\nemuticon: " + emuticon.name + " does not have a back layer";
		}
		if(emuticon.tags == null || emuticon.tags == ""){
			validated = false;
			message +=  "\nemuticon: " + emuticon.name + " does not have tags";
		}
	}
	if(message != ""){
		message +=  "\nYou will not be aloud to deploy until you fix these errors";
		alert(message);
	}
	
	return validated;
}

function emuticonsSourcesChanged(pack){
	var valuesChanged = false;
	if(public_pack.emuticons.length == pack.emuticons.length){
		for (i = 0; i <  pack.emuticons.length; i++) {
			var keylist = Object.keys(pack.emuticons[i])
				var publickeylist = Object.keys(public_pack.emuticons[i])
				for(item in keylist){
					if(keylist[item] == "source_back_layer" || keylist[item] != "source_front_layer" || keylist[item] != "source_user_layer_mask"){
						if(!public_pack.emuticons[i].hasOwnProperty(keylist[item])){
							valuesChanged = true;
					    	break;
						}
						if(public_pack.emuticons[i][keylist[item]] == "" && pack.emuticons[i][keylist[item]] == ""){
							continue;
						}
					    if(public_pack.emuticons[i][keylist[item]] != pack.emuticons[i][keylist[item]]){
					    	valuesChanged = true;
					    	break;
					    }
					}
				}
		}
	}
	else{
		valuesChanged = true;
	}

	return valuesChanged;
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

	parent_form.appendChild(document.createElement('br'));

	// LABEL
	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Label", "pack_label", "input", "text", false, false, "", ""));
	// END LABEL

	parent_form.appendChild(document.createElement('br'));

	// ICON2X

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Icon2x", "icon2x", 'input', "file", false, true, "image/*", "input_file"));
	// END ICON2X

	parent_form.appendChild(document.createElement('br'));

	// ICON3X
	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Icon3x", "icon3x", 'input', "file", false, true, "image/*", "input_file"));

	// END ICON3X

	parent_form.appendChild(document.createElement('br'));

  	// EMUTICON DEFAULTS

  	
  	var fieldset = document.createElement('fieldset');
  	var legend = document.createElement('legend');
  	legend.innerHTML = "Emuticons Defaults:";
  	fieldset.appendChild(legend);


  	// DURATION

	fieldset.appendChild(createInputOrLabelRowElementDiv(method, "Duration", "duration", 'input', "text", false, false, "", ""));
	// END DURATION

	fieldset.appendChild(document.createElement('br'));

	// FRAMES COUNT

	fieldset.appendChild(createInputOrLabelRowElementDiv(method, "Frames Count", "frames_count", 'input', "text", false, false, "", ""));

	// END FRAMES COUNT

	fieldset.appendChild(document.createElement('br'));

	// THUMBNAIL FRAME INDEX

	fieldset.appendChild(createInputOrLabelRowElementDiv(method, "Thumbnail Frame Index", "thumbnail_frame_index", 'input', "text", false, false, "", ""));

	// END THUMBNAIL FRAME INDEX

	fieldset.appendChild(document.createElement('br'));

	// ICON MASK

	fieldset.appendChild(createInputOrLabelRowElementDiv(method, "Source Layer User Mask", "icon_mask", 'input', "file", false, true, "image/*", "input_file"));

	// END ICON MASK
	parent_form.appendChild(fieldset);

	// END EMUTICON DEFAULTS

	parent_form.appendChild(document.createElement('br'));

	// ACTIVE

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Active", "active", "input", "checkbox", false, false, "", ""));

	// END ACTIVE

	parent_form.appendChild(document.createElement('br'));

	// DEV ONLY

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Dev Only", "dev_only", "input", "checkbox", false, false, "", ""));

	// END DEV ONLY

	parent_form.appendChild(document.createElement('br'));

	// notification_text

		parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Notifiy text", "notification_text", 'input', "text", false, false, "", ""));

		// END notification_text

		// first_published_on

		parent_form.innerHTML += " Notify users when deployed: ";

		var first_published_oncheckbox = document.createElement('input');
		first_published_oncheckbox.type = "checkbox";
		first_published_oncheckbox.name = "first_published_on";
		first_published_oncheckbox.id = "first_published_on";

		parent_form.appendChild(first_published_oncheckbox);

		// END first_published_on

	parent_form.appendChild(document.createElement('br'));
	parent_form.appendChild(document.createElement('br'));

	// BUTTON SAVE

	var saveButton = document.createElement('button');
	saveButton.className = "btn btn-default";
	saveButton.type = "button";
	saveButton.innerHTML = "Save";
	saveButton.id = "saveButton";
	saveButton.setAttribute("data-method", method);
	if(method == 'PUT' && pack.cms_proccessing == true){
		saveButton.disabled = true;
	}

	parent_form.appendChild(saveButton);

	parent_form.appendChild(document.createElement('br'));
	parent_form.appendChild(document.createElement('br'));

	// END BUTTON SAVE

	

	if(method == 'PUT'){

		// BUTTON ZIP

		

		var zipButton = document.createElement('button');
		zipButton.className = "btn btn-default";
		zipButton.type = "button";
		zipButton.innerHTML = "Zip";
		zipButton.id = "zipButton";
		zipButton.setAttribute("data-package", JSON.stringify(pack));
		if(pack.cms_proccessing == true || pack.cms_state != "zip" || (pack.emuticons != null && pack.emuticons.length < 6)){
			zipButton.disabled = true;
		}

		parent_form.appendChild(zipButton);

		parent_form.appendChild(document.createElement('br'));
		parent_form.appendChild(document.createElement('br'));
		

		// END BUTTON ZIP

		// BUTTON DEPLOY

		parent_form.appendChild(document.createElement('br'));
		parent_form.appendChild(document.createElement('br'));

		var deployButton = document.createElement('button');
		deployButton.className = "btn btn-default";
		deployButton.type = "button";
		deployButton.innerHTML = "Deploy";
		deployButton.id = "deployButton";
		deployButton.setAttribute("data-package", JSON.stringify(pack));
		if(pack.cms_proccessing == true || pack.cms_state == "zip" || (pack.emuticons != null && pack.emuticons.length < 6)){
			deployButton.disabled = true;
		}

		parent_form.appendChild(deployButton);

		parent_form.appendChild(document.createElement('br'));

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

	public_pack = getPackageByName(pack.name, packs_public);

	var values_update = false;

	CreatePackageFields('PUT', pack);

	// NAME
	pack_name = document.getElementById("pack_name");
	pack_name.innerHTML = pack.name;
	// END NAME

	// LABEL
	pack_label = document.getElementById("pack_label");
	pack_label.value = pack.label;
	if(public_pack != null){
		var result = displayCompareForField("pack_label", public_pack.label, pack.label);
		if(!values_update){
			values_update = result;
		}
	}
	// END LABEL

	// ICON2X
	img2xname = document.getElementById("icon2ximg");
	img2xname.src = awsfolder + pack.name + "/" + pack.cms_icon_2x;
	if(public_pack != null){
		var result = displayCompareForField("icon2x", public_pack.cms_icon_2x, pack.cms_icon_2x);
		if(!values_update){
			values_update = result;
		}
	}
	// END ICON2X

	// ICON3X
	img3xname = document.getElementById("icon3ximg");
	img3xname.src = awsfolder + pack.name + "/" + pack.cms_icon_3x;
	if(public_pack != null){
		var result = displayCompareForField("icon3x", public_pack.cms_icon_3x, pack.cms_icon_3x);
		if(!values_update){
			values_update = result;
		}
	}
	// END ICON3X

  	// EMUTICON DEFAULTS

  	// DURATION
	duration = document.getElementById("duration");
	duration.value = pack.emuticons_defaults.duration;
	if(public_pack != null){
		var result = displayCompareForField("duration", public_pack.emuticons_defaults.duration, pack.emuticons_defaults.duration);
		if(!values_update){
			values_update = result;
		}
	}
	// END DURATION

	// FRAMES COUNT
	frames_count = document.getElementById("frames_count");
	frames_count.value = pack.emuticons_defaults.frames_count;
	if(public_pack != null){
		var result = displayCompareForField("frames_count", public_pack.emuticons_defaults.frames_count, pack.emuticons_defaults.frames_count);
		if(!values_update){
			values_update = result;
		}
	}
	// END FRAMES COUNT

	// THUMBNAIL FRAME INDEX
	thumbnail_frame_index = document.getElementById("thumbnail_frame_index");
	thumbnail_frame_index.value = pack.emuticons_defaults.thumbnail_frame_index;
	if(public_pack != null){
		var result = displayCompareForField("thumbnail_frame_index", public_pack.emuticons_defaults.thumbnail_frame_index, pack.emuticons_defaults.thumbnail_frame_index);
		if(!values_update){
			values_update = result;
		}
	}
	// END THUMBNAIL FRAME INDEX

	// ICON MASK
	icon_maskimg = document.getElementById("icon_maskimg");
	icon_maskimg.src = awsfolder + pack.name + "/" + pack.emuticons_defaults["source_user_layer_mask"];
	if(public_pack != null){
		var result = displayCompareForField("icon_mask", public_pack.emuticons_defaults["source_user_layer_mask"], pack.emuticons_defaults["source_user_layer_mask"]);
		if(!values_update){
			values_update = result;
		}
	}
	// END ICON MASK

	// END EMUTICON DEFAULTS

	// ACTIVE
	active = document.getElementById("active");
	active.checked = pack.active;
	if(public_pack != null){
		var result = displayCompareForField("active", public_pack.active, pack.active);
		if(!values_update){
			values_update = result;
		}
	}
	// END ACTIVE

	// DEV ONLY
	dev_only = document.getElementById("dev_only");
	dev_only.checked = pack.dev_only;
	if(public_pack != null){
		var result = displayCompareForField("dev_only", public_pack.dev_only, pack.dev_only);
		if(!values_update){
			values_update = result;
		}
	}
	// END DEV ONLY

	// first_published_on
	first_published_on = document.getElementById("first_published_on");
	if(pack.first_published_on != null){
		first_published_on.checked = true;
	}
	if(public_pack != null){
		var result = ((first_published_on.checked == true && public_pack.first_published_on == null) || 
						(first_published_on.checked == false && public_pack.first_published_on != null));
		if(!values_update){
			values_update = result;
		}
	}

	// END first_published_on

	// notification_text
	notification_text = document.getElementById("notification_text");
	if(pack.notification_text && pack.notification_text != ""){
		notification_text.value = pack.notification_text;
	}
	if(public_pack != null){
		var result = displayCompareForField("notification_text", public_pack.notification_text, pack.notification_text);
		if(!values_update){
			values_update = result;
		}
	}
	// END notification_text
	
	// Check emuticons values
	if(public_pack != null){
		var result = emuticonsValuesUpdate(pack, public_pack);
		if(!values_update){
			values_update = result;
		}
	}
	else
	{
		if(!values_update){
			values_update = true;
		}
	}

	if(values_update == true){
		document.getElementById("deployButton").disabled = false;
	}
	else{
		document.getElementById("deployButton").disabled = true;
	}

	// Validations
	if(pack.zipped_package_file_name == null || pack.cms_proccessing == true || pack.cms_state == "zip" || (pack.emuticons != null && pack.emuticons.length < 6)){
		document.getElementById("deployButton").disabled = true;
	}

	if(!emuticonsValidated(pack)){
		document.getElementById("deployButton").disabled = true;
	}

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

	if (!/^[a-z0-9_\-]+$/.test(pack_name) || pack_name == ""){
		alert("pack_name must contain only lowercase letters, numbers, - , _");
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

	if (pack_label == ""){ //!/^[A-Za-z0-9_\-\ ]+$/.test(pack_label) || 
		alert("label may not be empty"); // must contain only letters, numbers, - , _ , space");
		return;
	}


	var updateIcons = 0;

	icon2xfile = document.getElementById("icon2xfile");
	if(icon2xfile.files.length > 0 && icon2xfile.files[0]){
		formData.append('icon_2x', icon2xfile.files[0]);
		updateIcons++;
	}

	if(method == 'PUT'){
		icon2xfilecheckbox = document.getElementById("icon2xcheckbox");
		if (icon2xfilecheckbox.checked){
			query += "&removeicon2x=" + "true";
		}
	}
	
	icon3xfile = document.getElementById("icon3xfile");
	if(icon3xfile.files.length > 0 && icon3xfile.files[0]){
		formData.append('icon_3x', icon3xfile.files[0]);
		updateIcons++;
	}

	if(method == 'PUT'){
		icon3xfilecheckbox = document.getElementById("icon3xcheckbox");
		if (icon3xfilecheckbox.checked){
			query += "&removeicon3x=" + "true";
		}
	}

	if(method == 'POST' && updateIcons < 2){
		alert("Cannot create only one icon size or no icons at all");
		return;
	}

	icon_maskfile = document.getElementById("icon_maskfile");
	if(icon_maskfile.files.length > 0 && icon_maskfile.files[0]){
		formData.append('source_user_layer_mask', icon_maskfile.files[0]);
	}

	if(method == 'PUT'){
		icon_maskcheckbox = document.getElementById("icon_maskcheckbox");
		if (icon_maskcheckbox.checked){
			query += "&removesource_user_layer_mask=" + "true";
		}
	}
	// emuticons defaults
	duration = document.getElementById("duration").value;
	query += "&duration=" + duration;

	frames_count = document.getElementById("frames_count").value;
	query += "&frames_count=" + frames_count;

	thumbnail_frame_index = document.getElementById("thumbnail_frame_index").value;
	query += "&thumbnail_frame_index=" + thumbnail_frame_index;

	if(duration == "" || frames_count == "" || thumbnail_frame_index == ""){
		alert("Must fill in Duration, frames_count, thumbnail_frame_index in defaults")
		return;
	}

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

	first_published_on = document.getElementById("first_published_on").checked;
	
	if(first_published_on){
		query += "&first_published_on=" + "true";
	}
	else{
		query += "&first_published_on=" + "false";
	}

	notification_text = document.getElementById("notification_text").value;
	if(notification_text != ""){
		query += "&notification_text=" + notification_text;
	}

	if(first_published_on && notification_text == ""){
		alert("if notify users selected must fill in notification text")
		return;
	}


	saveButton.disabled = true;
	saveButton.innerHTML = "Saving Please wait..";

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

	if(pack.emuticons != null && pack.emuticons.length < 6){
		alert("Trying to zip with less than 6 emuticons?");
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
	zipButton.innerHTML = "Zipping Please wait..";
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
	deployButton.innerHTML = "Deploying Please wait..";

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
			newemuticonButton.innerHTML = "Add New";
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

	public_emuticon = getEmuticonByName(pack.name, emuticon.name, packs_public)

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
	if(public_emuticon){
		displayCompareForField("source_back_layer", public_emuticon.source_back_layer, emuticon.source_back_layer);
	}
	// END source_back_layer

	// source_front_layer
	source_front_layer = document.getElementById("source_front_layerimg");
	source_front_layer.src = awsfolder + pack.name + "/" + emuticon.source_front_layer;
	if(public_emuticon){
		displayCompareForField("source_front_layer", public_emuticon.source_front_layer, emuticon.source_front_layer);
	}
	// END source_front_layer

	// source_user_layer_mask
	source_user_layer_mask = document.getElementById("source_user_layer_maskimg");
	source_user_layer_mask.src = awsfolder + pack.name + "/" + emuticon.source_user_layer_mask;
	if(public_emuticon){
		displayCompareForField("source_user_layer_mask", public_emuticon.source_user_layer_mask, emuticon.source_user_layer_mask);
	}
	// END source_user_layer_mask

	// DURATION
	duration = document.getElementById("duration");
	if(emuticon.duration && emuticon.duration != ""){
		duration.value = emuticon.duration;
		if(public_emuticon){
			values_update = displayCompareForField("duration", public_emuticon.duration, emuticon.duration);
		}
	}
	// END DURATION

	// FRAMES COUNT
	frames_count = document.getElementById("frames_count");
	if(emuticon.frames_count && emuticon.frames_count != ""){
		frames_count.value = emuticon.frames_count;
		if(public_emuticon){
			values_update = displayCompareForField("frames_count", public_emuticon.frames_count, emuticon.frames_count);
		}
	}
	// END FRAMES COUNT

	// THUMBNAIL FRAME INDEX
	thumbnail_frame_index = document.getElementById("thumbnail_frame_index");
	if(emuticon.thumbnail_frame_index && emuticon.thumbnail_frame_index != ""){
		thumbnail_frame_index.value = emuticon.thumbnail_frame_index;
		if(public_emuticon){
			values_update = displayCompareForField("thumbnail_frame_index", public_emuticon.thumbnail_frame_index, emuticon.thumbnail_frame_index);
		}
	}
	// END THUMBNAIL FRAME INDEX

	// palette
	palette = document.getElementById("palette");
	if(emuticon.palette && emuticon.palette != ""){
		palette.value = emuticon.palette;
		if(public_emuticon){
			displayCompareForField("palette", public_emuticon.palette, emuticon.palette);
		}
	}
	// END palette

	// tags
	tags = document.getElementById("tags");
	if(emuticon.tags && emuticon.tags != ""){
		tags.value = emuticon.tags;
		if(public_emuticon){
			displayCompareForField("tags", public_emuticon.tags, emuticon.tags);
		}
	}
	// END tags

	// use_for_preview
	use_for_preview = document.getElementById("use_for_preview");
	use_for_preview.checked = emuticon.use_for_preview;
	if(public_emuticon){
		displayCompareForField("use_for_preview", public_emuticon.use_for_preview, emuticon.use_for_preview);
	}
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

	parent_form.appendChild(document.createElement('br'));

	// source_back_layer

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "source_back_layer", "source_back_layer", 'input', "file", false, true, "image/*", "input_file"));

	// END source_back_layer

	parent_form.appendChild(document.createElement('br'));

	// source_front_layer

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "source_front_layer", "source_front_layer", 'input', "file", false, true, "image/*", "input_file"));

	// END source_front_layer

	parent_form.appendChild(document.createElement('br'));

	// source_user_layer_mask

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "source_user_layer_mask", "source_user_layer_mask", 'input', "file", false, true, "image/*", "input_file"));

	// END source_user_layer_mask

	parent_form.appendChild(document.createElement('br'));

	// DURATION

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Duration", "duration", 'input', "text", false, false, "", ""));
	// END DURATION

	parent_form.appendChild(document.createElement('br'));

	// FRAMES COUNT

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Frames Count", "frames_count", 'input', "text", false, false, "", ""));

	// END FRAMES COUNT

	parent_form.appendChild(document.createElement('br'));

	// THUMBNAIL FRAME INDEX

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "Thumbnail Frame Index", "thumbnail_frame_index", 'input', "text", false, false, "", ""));

	// END THUMBNAIL FRAME INDEX

	parent_form.appendChild(document.createElement('br'));

	// palette

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "palette", "palette", "input", "text", false, false, "", ""));

	// END palette

	parent_form.appendChild(document.createElement('br'));

	// tags

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "tags", "tags", "input", "text", false, false, "", ""));

	// END tags

	parent_form.appendChild(document.createElement('br'));

	// use_for_preview

	parent_form.appendChild(createInputOrLabelRowElementDiv(method, "use for preview", "use_for_preview", "input", "checkbox", false, false, "", ""));

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

	if (!/^[a-z0-9_\-]+$/.test(emuticon_name) || emuticon_name == ""){
		alert("emuticon_name must contain only lowercase letters, numbers, - , _ ")
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

	if(method == 'POST' && source_back_layerfile.files.length == 0){
		alert("Must have a background layer");
		return;
	}

	source_user_layer_maskfile = document.getElementById("source_user_layer_maskfile");
	if(source_user_layer_maskfile != null && source_user_layer_maskfile.files.length > 0 && source_user_layer_maskfile.files[0]){
		formData.append('source_user_layer_mask', source_user_layer_maskfile.files[0]);
	}

	if(method == 'PUT'){
		source_back_layercheckbox = document.getElementById("source_back_layercheckbox");
		if (source_back_layercheckbox.checked){
			query += "&removesource_back_layer=" + "true";
		}

		source_front_layercheckbox = document.getElementById("source_front_layercheckbox");
		if (source_front_layercheckbox.checked){
			query += "&removesource_front_layer=" + "true";
		}

		source_user_layer_maskcheckbox = document.getElementById("source_user_layer_maskcheckbox");
		if (source_user_layer_maskcheckbox.checked){
			query += "&removesource_user_layer_mask=" + "true";
		}
	}

	palette = document.getElementById("palette").value;
	if(palette != null && palette != ""){
		query += "&palette=" + escape(palette);
	}

	if(duration != null && duration != ""){
		duration = document.getElementById("duration").value;
		query += "&duration=" + duration;
	}

	if(frames_count != null && frames_count != ""){
		frames_count = document.getElementById("frames_count").value;
		query += "&frames_count=" + frames_count;
	}

	if(thumbnail_frame_index != null && thumbnail_frame_index != ""){
		thumbnail_frame_index = document.getElementById("thumbnail_frame_index").value;
		query += "&thumbnail_frame_index=" + thumbnail_frame_index;
	}

	tags = document.getElementById("tags").value;
	query += "&tags=" + escape(tags);

	if (!/^[a-z0-9\,]+$/.test(tags) || tags == ""){
		alert("tags may contain only lowercase letters, numbers, seperated by commas and must have at least one value")
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
	saveButton.innerHTML = "Saving Please wait..";

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

