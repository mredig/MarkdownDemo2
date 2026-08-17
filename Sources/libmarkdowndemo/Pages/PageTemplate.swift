import Foundation
import yaHDSL

struct PageTemplate<Content: HTMLContentProvider, FooterContent: HTMLNode>: HTMLPage {
	var title: String { content.title }

	var breadcrumbPath: [String] { content.breadcrumbPath }

	let content: Content
	let footerContent: FooterContent

	init(content: Content) where FooterContent == Empty {
		self.content = content
		self.footerContent = Empty()
	}

	init(content: Content, footerContent: FooterContent) {
		self.content = content
		self.footerContent = footerContent
	}

	var head: any HeadProtocol {
		Head {
			Title(title)

			Meta(attributes: [.charset: AttributeValue.string("utf-8")])
			Meta(attributes: [
				.name: AttributeValue.string("viewport"),
				.content: AttributeValue.list(["width=device-width", "initial-scale=1", "user-scalable=no"]),
			])

			Link(href: URL(string: "/css/modern.css"), rel: .Link.stylesheet)

			let script = """
				var lastRequest = 0;
				var lastAttempt = 0;

				function showResult(str, updateAttempt) {
					if (updateAttempt === undefined) updateAttempt = 1;
					var date = new Date();
					var currentTime = date.getTime();
					var timeElapsed = currentTime - lastRequest;

					var minimumPassingTime = 300;

					if (str.length == 0) {
						document.getElementById("markdownRepoLiveSearch").innerHTML = "";
						document.getElementById("markdownRepoLiveSearch").style.border = "0px";
						return;
					}
					if (timeElapsed < minimumPassingTime) {
						if (updateAttempt == 1) {
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
						if (this.readyState == 4 && this.status == 200) {
							document.getElementById("markdownRepoLiveSearch").innerHTML = this.responseText;
							document.getElementById("markdownRepoLiveSearch").style.border = "1px solid #A5ACB2";
						}
					}
					xmlhttp.open("GET", "livesearch/?search=" + str, true);
					xmlhttp.send();
				}

				function delayedSubmission(timeSubmitted, submission) {
					if (timeSubmitted == lastAttempt) {
						showResult(submission, false);
					}
				}
				"""

			Script(script)
		}
	}

	private var breadcrumbParagraph: P {
		// for some reason, the result builder couldn't handle this, so I had to write it more manually
		var p = P()
		p.addChildNode(A("Home", href: "/"))
		p.addChildNode(" / ")

		var builder: [String] = []

		for ancestorDirectory in breadcrumbPath {
			guard ancestorDirectory != "" else { continue }
			builder.append(ancestorDirectory)

			let linkPath = builder.joined(separator: "/")
			p.addChildNode(A(href: "?directory=\(linkPath)") { ancestorDirectory })
			p.addChildNode(" / ")
		}

		return p
	}

	var body: any BodyProtocol {
		get throws {
			try Body {
				Form {
					Button { "Go" }
						.withType(.submit)
						.addClass("btn")
						.addClass("btn-default")

					Div {
						Input(inputType: .search, name: "search", id: "search")
							.addClass("form-control")
							.withPlaceholder("search")
							.withValue("")
							.setOnKeyUp("showResult(this.value)")
							.setOnSearch("showResult(this.value)")
							.withAutoComplete(.off)
					}
					.addClass("form-group")

					Div().setID("markdownRepoLiveSearch")
				}
				.setClasses(["form-inline", "headerSearch"])
				.withAction("/search")
				.withMethod(.get)


				let breadcrumbs = breadcrumbParagraph
				breadcrumbs
				
				try content.content()
				
				Hr()

				footerContent

				breadcrumbs
			}
		}
	}
}
