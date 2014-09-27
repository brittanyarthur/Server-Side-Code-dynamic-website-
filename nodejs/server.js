var http = require('http');
var os = require('os');
var pg = require('pg');
var url = require('url');
var fs = require('fs');
var async = require('async');
var conString = "cmps112://cmps112:Winter.js@localhost/cmps112";
var querystring = require('querystring');
var simple_recaptcha = require('simple-recaptcha');
flag = false;

recaptcha_private_key = "6LcBCO8SAAAAAPHaeA_qes6GcgpYYjnd57vgweZQ"
recaptcha_public_key = "6LcBCO8SAAAAAEkLHW7EZzRX75HlnZJf75WvWWY4"

//source: http://stackoverflow.com/questions/3393854/get-and-set-a-single-cookie-with-node-js-http-server
function parseCookies (request) {
    var list = {},
        rc = request.headers.cookie;

    rc && rc.split(';').forEach(function( cookie ) {
        console.log('COOKIE HERE');
        var parts = cookie.split('=');
        list[parts.shift().trim()] = unescape(parts.join('='));
    });
    return list;
}

// --------------------------------------------------
function processPost(request, response, callback) {
   var queryData = "";
   if (typeof callback !== 'function') return null; //what kind of things does this prevent?
   if (request.method == 'POST') {
      request.on('data', function (data) {
         queryData += data;
         if (queryData.length > 1e6) { //what is 1e6?
            queryData = "";
            response.writeHead(413, {
               'Content-Type': 'text/plain'
            }).end();
            request.connection.destroy();
         }
      });
      request.on('end', function () {
         response.post = querystring.parse(queryData);
         callback();
      });
   } else {
      response.writeHead(405, {
         'Content-Type': 'text/plain'
      });
      response.end();
   }
}

// From http://stackoverflow.com/questions/4295782/how-do-you-extract-post-data-in-node-js
function strip_tags(input, allowed) {
  allowed = (((allowed || '') + '')
    .toLowerCase()
    .match(/<[a-z][a-z0-9]*>/g) || [])
    .join(''); // making sure the allowed arg is a string containing only tags in lowercase (<a><b><c>)
  var tags = /<\/?([a-z][a-z0-9]*)\b[^>]*>/gi,
    commentsAndPhpTags = /<!--[\s\S]*?-->|<\?(?:php)?[\s\S]*?\?>/gi;
  return input.replace(commentsAndPhpTags, '')
    .replace(tags, function($0, $1) {
      return allowed.indexOf('<' + $1.toLowerCase() + '>') > -1 ? $0 : '';
    });
}

// http://phpjs.org/functions/strip_tags/
// --------------------------------------------------

function processForm(request, response, client) {
	console.log('processForm called');
	var cookie = 0;
	cookies = parseCookies(request);
	if (request.method == 'POST') {
		processPost(request, response, function () {
			cookies = parseCookies(request);
			console.log("cookie:  " + cookies["user"]);
			cookie = parseInt(cookies["user"]);
			if(!(cookie > 0)){
				cookie = 0;
				var ip = request.headers['x-forwarded-for'] || 
					request.connection.remoteAddress || 
					request.socket.remoteAddress ||
					request.connection.socket.remoteAddress;
				client.query('INSERT INTO users (ip_address) VALUES ($1) RETURNING id', [String(ip)], function (err, result) {
					if (err) {
							console.log("THERE WAS AN ERROR AT INSERTING");
							console.log(err);
					} else {
						cookie = result.rows[0].id
						console.log(result);
						console.log("UserID from DATAbase: " + cookie);
						var curdate = new Date();
						response.writeHead(200, {
							'Set-Cookie':'user=' + cookie + '; expires=' + (new Date(new Date().getTime()+1000*60*60*24*356*10))
						});
						finishForm (request, response, client, cookie);
					}
				});
			} else {
				finishForm (request, response, client, cookie);
			}
		});
	} else {
		if(cookies["user"] == undefined) {
			cookie = 0; //if there was an error getting the cookie
		} else {
			cookie = cookies["user"];
		}
		randStarter(request, response, client, cookie, "\n", 0);
	}
	var finishForm = function (request, response, client, cookie) {
		console.log("finishForm");
		console.log("cookie after if else:  " + cookie);
		console.log("Entry: " + response.post.entry);
		//console.log("Starter: " + response.post.starter);
		processRecaptcha(response, cookie, function(cookie, errors) {
			var errors = "\n";
			console.log("cookie in processRecaptcha is: " + cookie);
			if (response.post.entry.length > 0 && flag == true) {
				console.log('EXPECTED: 1 and response.post.entry.length == ' + response.post.entry.length);
				client.query('INSERT INTO Entries (user_id,starter_id,entry) VALUES ($1, $2, $3)', [cookie,response.post.starter, response.post.entry], function (err, result) {
					if (err) {
						console.log("THERE WAS AN ERROR AT INSERTING");
						console.log(err);
					}
				});
			}
			else if (!(response.post.entry.length > 0)) {
				errors += errorHTML("Required field cannot be left blank")
			}
			else if (!(flag == true)) {
				errors += errorHTML("Invalid Captcha")
			}
			randStarter(request, response, client, cookie, errors, response.post.starter);
		});
	}
}

function errorHTML(message) {
	return "<br /><span class=\"errortext\">" + message + "</span><br /><br />"
}

function randStarter(request, response, client, cookie, errors, starter) {
	console.log("randStarter");
	client.query("select id from starters offset floor(random() * (select count(*) from starters)) limit 1", function (err, result) {
		if (err) {
				console.log(err);
		} else {
			var starter_id = result.rows[0].id
			if (errors != "\n") {
				starter_id = starter;
			}
			printPage(request, response, client, cookie, errors, starter_id);
		}
	});
}


function printPage(request, response, client, cookie, errors, starter_id) {
	console.log('printPage');
	var url_parts = url.parse(request.url, true);
	if (url_parts.pathname == '/nodejs') {
	   console.log('PATHNAME IS OKAY');
	   
	}

	var lVars = url.parse(request.url, true);
	var lQuery = lVars.query.q;
	console.log(url_parts);
	//add in a check to make sure that the front end is feeding in valid information
	//so that no users are messing with the website. 
	//300s are redirects


	response.write(
            '<!DOCTYPE html>\n' +
            '<html>\n' +
            '<head>\n' +
            '<title>\n' +
            'Gratitude Journal' +
            '</title>\n' +
            '</head>\n' +
            '\n' +
            '<body>\n' +
            '<h1>Gratitude Journal</h1>\n' +
            '<p>Complete the sentence!</p>\n' +
            '\n' +
            '<form  name="input" action="/nodejs" method="post"> \n' +
            '</br>\n' +
            '<select id="myList" name="starter">\n');

	client.query("SELECT id, starter FROM starters ORDER BY id", function (err, result) {
	   console.log("SELECT id, starter FROM starters ORDER BY id");
	   if (err) {
		  console.log(err);
	   } else {
		  for (var i = result.rows.length - 1; i >= 0; i--) {
		     response.write('<option value="' + result.rows[i].id + '"');
		     if (result.rows[i].id == starter_id) {
		     	response.write(' selected');
		     }
		     response.write('>' + result.rows[i].starter + '</option>\n');
		  }
	   }
	   response.write('</select>\n' +
                          '</br>\n' +
                          'Entry:  \n' +
                          '</br>\n' +
                          '<textarea type="text" name="entry" rows="6" cols="80"/>');
	if (errors != "\n") {
		response.write(response.post.entry);
	}
        response.write('</textarea>\n' +
        '</br>\n' +
        '    <script type="text/javascript"\n' +
        '       src="http://www.google.com/recaptcha/api/challenge?k=6LcBCO8SAAAAAEkLHW7EZzRX75HlnZJf75WvWWY4">\n' +
        '    </script>\n' +
        '    <noscript>\n' +
        '       <iframe src="http://www.google.com/recaptcha/api/noscript?k=6LcBCO8SAAAAAEkLHW7EZzRX75HlnZJf75WvWWY4"\n' +
        '           height="300" width="500" frameborder="0"></iframe><br>\n' +
        '       <textarea name="recaptcha_challenge_field" rows="3" cols="40">\n' +
        '       </textarea>\n' +
        '       <input type="hidden" name="recaptcha_response_field"\n' +
        '           value="manual_challenge">\n' +
        '    </noscript>\n' +
        '<input type="submit" value="Submit">\n' +
        '</form>\n' +
        errors +
        '<br />\n');
		var search = 'SELECT A.starter, B.entry, B.user_id, B.id FROM Starters as A, Entries as B WHERE A.id = B.starter_id ORDER BY B.id';
		client.query(search, function (err, result) {
		   console.log(search);
		   if (err) {
			  console.log(err);
		   } else {
			  response.write('<table>');
			  for (var i = result.rows.length - 1; i >= 0; i--) {
				 if(result.rows[i].user_id == cookie){
				    response.write('<tr bgcolor=yellow><td>' + result.rows[i].starter + strip_tags(result.rows[i].entry) + '</td></tr>');
				 }else{
				    response.write('<tr bgcolor="#00FFFF"><td>' + result.rows[i].starter + strip_tags(result.rows[i].entry) + '</td></tr>');
				 }
			  }
			  response.write('</table>');
			  response.write('</html>');
			  response.end();
			  console.log("End HTML");
		   }
		});
	});
}

function processRecaptcha(response, cookie, callback){
	console.log('processRecaptcha');
	var ifaces=os.networkInterfaces();
	var ip = "";
        // reference: http://stackoverflow.com/questions/3653065/get-local-ip-address-in-node-js
	for (var dev in ifaces) {
	   var alias=0;
	   ifaces[dev].forEach(function(details){
	   if (details.family=='IPv4') {
		  ip = (dev+(alias?':'+alias:''),details.address) + ip;
		  ++alias;
	   }
	   });
	}
	console.log(ip);
	flag = false;
	var challenge = response.post.recaptcha_challenge_field;
	var response = response.post.recaptcha_response_field;
	console.log(challenge);
	simple_recaptcha(recaptcha_private_key, ip, challenge, response, function(err) {
		if (err) {
			console.log('recaptcha did NOT work');
			flag = false;
			callback(cookie);
		}
		else{
			console.log('recaptcha did work');
			flag = true;
			callback(cookie);
		}
	}); 
}


/*
This is where the HTML and postgreSQL  is connected. We also create the server here. 
*/
http.createServer(function (request, response) {
	pg.connect(conString, function (err, client) {
		if (err) {
			console.log(err);
		} else {
			processForm(request, response, client); ;
		}
	});
}).listen(9002, "127.0.0.1");
console.log('Server running at http://127.0.0.1:9002/');

