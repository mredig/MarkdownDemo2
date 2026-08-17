var lastRequest = 0;
var lastAttempt = 0;

function showResult(str, updateAttempt) {
	if (updateAttempt === undefined) updateAttempt = 1;
	var date = new Date();
	var currentTime = date.getTime();
	var timeElapsed = currentTime - lastRequest;

	var minimumPassingTime = 300;

	if (str.length === 0) {
		document.getElementById("markdownRepoLiveSearch").innerHTML = "";
		document.getElementById("markdownRepoLiveSearch").style.border = "0px";
		return;
	}
	if (timeElapsed < minimumPassingTime) {
		if (updateAttempt === 1) {
			lastAttempt = currentTime;
		}
		var thisAttempt = lastAttempt;
		var timeout = minimumPassingTime + 5;
		setTimeout(delayedSubmission, timeout, thisAttempt, str);
		return;
	}
	lastAttempt = currentTime;
	lastRequest = currentTime;
	//    alert(lastRequest);

	if (window.XMLHttpRequest) {
		// code for IE7+, Firefox, Chrome, Opera, Safari
		xmlhttp = new XMLHttpRequest();
	} else {
		// code for IE6, IE5
		xmlhttp = new ActiveXObject("Microsoft.XMLHTTP");
	}
	xmlhttp.onreadystatechange = function() {
		if (this.readyState === 4 && this.status === 200) {
			document.getElementById("markdownRepoLiveSearch").innerHTML = this.responseText;
			document.getElementById("markdownRepoLiveSearch").style.border = "1px solid #A5ACB2";
		}
	}
	xmlhttp.open("GET", "livesearch/?search=" + encodeURIComponent(str), true);
	xmlhttp.send();
}

function delayedSubmission(timeSubmitted, submission) {
	if (timeSubmitted === lastAttempt) {
		showResult(submission, false);
	}
}
