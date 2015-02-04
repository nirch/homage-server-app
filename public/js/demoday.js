$(document).ready(function(){


	$("body").on("click", ".grade_form", function(e){
		e.stopPropagation();
		e.preventDefault();

	});

	$("body").on("click", ".caption", function(e){
		e.stopPropagation();
		e.preventDefault();

	});

	$("body").on("click", ".grade_form input[type='submit']", function(e){
		e.stopPropagation();
		e.preventDefault();
		$(this).closest('form').submit();
	})

	// // form submit ajax
	// $('form').onclick(function(event) {
 //        event.preventDefault();
 //        //console.log('submit closest done');
 //        $.ajax({
 //            type: "POST",
 //            url: $(this).attr('action'),
 //            data: $(this).serialize(),
 //            success: function(data){
 //                alert('Grade successfully applied!');
 //            }
 //        });
 //    });

	// $( ".container" ).change(function(event) {
	//   alert(event.target.options[event.target.selectedIndex].value);
	//   $('#remakes').load(document.URL + ' #remakes');
	// });

})

function getuserinfo(event, button, created_at, remake_id){
	button.innerHTML = '-';
	button.disabled = true
	var theUrl = '/getuser/' + remake_id;

	var xmlHttp = null;

	    xmlHttp = new XMLHttpRequest();

	    xmlHttp.onreadystatechange=function()
		  {
		  if (xmlHttp.readyState==4 && xmlHttp.status==200)
		    {
	    		button.disabled = false;
	    		button.innerHTML = '+';
	    		var user_info = JSON.parse(xmlHttp.responseText);
	    		user_info_string = JSON.stringify(user_info, null, "\t");
	    		showmessage(event, "Remake Created at: " + String(created_at) + "\n" + user_info_string);
		    }
		  }

	    xmlHttp.open( "GET", theUrl, true );
	    xmlHttp.send( null );
}

function refreshpage(){
	var ispublic = document.getElementById("ispublic").checked;

	var selcampaigns = document.getElementById("selcampaigns");
	var campaign = selcampaigns.options[selcampaigns.selectedIndex].value;

	var selstories = document.getElementById("selstories");
	var story = selstories.options[selstories.selectedIndex].value;

	var selraw = document.getElementById("selraw");
	var raw = selraw.options[selraw.selectedIndex].value;

	var selgrade = document.getElementById("selgrade");
	var grade = selgrade.options[selgrade.selectedIndex].value;

	var surl = String(document.URL);
	var date = surl.substring(surl.indexOf("te/") + 3,surl.indexOf("te/") +  11);

	var pagebuilder = "/date/" + date + "?ispublic=" + ispublic;

	if(campaign){
		pagebuilder += "&campaign_name=" + campaign;
	}
	if(story){
		pagebuilder += "&story_id=" + story;
	}
	if(raw){
		pagebuilder += "&raw=" + raw;
	}
	if(grade){
		pagebuilder += "&grade=" + grade;
	}
	// alert(pagebuilder);
	window.location.assign(String(pagebuilder));
}

//Download the remake from S3
function DownloadRemake(button, remake_id) {

	button.innerHTML = '<span class="glyphicon glyphicon-refresh glyphicon-refresh-animate" ></span> Loading...';
	button.disabled = true
	var theUrl = '/download/remake/' + remake_id;

	var xmlHttp = null;

	    xmlHttp = new XMLHttpRequest();

	    xmlHttp.onreadystatechange=function()
		  {
		  if (xmlHttp.readyState==4 && xmlHttp.status==200)
		    {
		    	button.disabled = false
		    	var pom = document.createElement('a');
			  pom.setAttribute('href', xmlHttp.responseText);
			  pom.setAttribute('download', remake_id + '.zip');
			  pom.setAttribute('type', 'application/zip');
			  pom.click();
			  button.innerHTML = 'Download';
		    }
		  }

	    xmlHttp.open( "GET", theUrl, true );
	    xmlHttp.send( null );
}

//Update the grade
function updateGrade(button, remake_id, grade) {

	// button.innerHTML = '<span class="glyphicon glyphicon-refresh glyphicon-refresh-animate" ></span>';
	// button.disabled = true
	var theUrl = "/update/gradeasync?grade=" + grade + "&remake_id=" + remake_id;

	var xmlHttp = null;

	    xmlHttp = new XMLHttpRequest();

	    xmlHttp.onreadystatechange=function()
		  {
		  if (xmlHttp.readyState==4 && xmlHttp.status==200)
		    {
		    	button.checked = true;
		    	// button.innerHTML = grade;
		    }
		    else{
		    	// button.disabled = false
		    	// button.innerHTML = grade;
		    	// alert("did not grade")
		    }
		  }

	    xmlHttp.open( "GET", theUrl, true );
	    // xmlHttp.setRequestHeader("X-Requested-With","XMLHttpRequest");
	    // xmlHttp.setRequestHeader("Content-Type","application/x-www-form-urlencoded; charset=UTF-8");
		xmlHttp.send();
}


//Download the remake from S3-------------------------
function closemessage(){
	var message = document.getElementById('message');
	message.style.visibility='hidden';
	message.innerHTML = "";
}

function showmessage(event, text){
	var message = document.getElementById('message');
	message.style.visibility='visible';
	message.style.top = String(event.pageY) + "px";
	// message.style.left = String(event.clientX) + "px";
	message.innerHTML = '<button id="closemessage" onclick="closemessage()" class="closebutton">X</button>' + '<code><pre>' + text + '</pre></code>';
}

function showRemake(event, remake_id){

	url = "/" + remake_id;
	var win = window.open(url, '_blank');
  	win.focus();
}

function closevideoplayer(){
	var videoplayer = document.getElementById('videoplayer');
	videoplayer.style.visibility='hidden';
	videoplayer.innerHTML = "";
}

function showvideoplayer(event, text){
	var videoplayer = document.getElementById('videoplayer');
	videoplayer.style.visibility='visible';
	// videoplayer.style.top = String(event.pageY-180) + "px";
	// message.style.left = String(event.clientX) + "px";
	videoplayer.innerHTML = '<button id="closemessage" onclick="closevideoplayer()" class="closebutton">X</button>' +
	 '<video style="background-color:black;" width="640" height="360" controls><source src='+ text +' type="video/mp4">Your browser does not support the video tag.</video>'
}
