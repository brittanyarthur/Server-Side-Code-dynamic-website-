// Author: Ian Gudger (igudger@ucsc.edu)
// CMPS 112 Final Project, Go implementation
// March 21, 2014

package main

import (
	"database/sql"
	"errors"
	"fmt"
	"github.com/dpapathanasiou/go-recaptcha"
	_ "github.com/lib/pq"
	"html/template"
	"net"
	"net/http"
	"net/http/fcgi"
	"reflect"
	"strconv"
	"strings"
	"time"
)

const recaptcha_private_key = "6LcBCO8SAAAAAPHaeA_qes6GcgpYYjnd57vgweZQ"
const recaptcha_public_key = "6LcBCO8SAAAAAEkLHW7EZzRX75HlnZJf75WvWWY4"

// Shared template store
var templates = make(map[string]*template.Template)

// Define templates
const rootPageTemplateHtml = `
<!DOCTYPE html>
<html>
  <head>
	<title>{{.PageTitle}}</title>
	<style type="text/css" media="all">
		<!--
			.your_entry { background: yellow; }
			.other_entry { background: #00FFFF; }
			.errortext { color: red; font-weight: bold }
			body { font-family: Helvetica, Arial, Sans-Serif; }
		-->
	</style>
  </head>
  <body>
	{{template "pageHeader" .}}
	{{template "pageContent" .}}
	{{template "pageFooter" .}}
  </body>
</html>
`

const headerTemplateHtml = `<h1>Gratitude Journal</h1>`

const footerTemplateHtml = `<p>This web page was served with Go!<p>`

const homePageContentTemplateHtml = `
<form action="{{.formaction}}" method="POST">
{{template "dropDown" .}}
	<input type="text" value="{{.oldentry}}" name="entry"></input>
	<script src="https://www.google.com/recaptcha/api/challenge?k={{.recaptcha_public_key}}" type="text/javascript"> </script>
	<input type="submit" value="Submit"></input>
</form>
{{.formerrors}}
<br />
{{template "coloredTable" .}}
<form action="{{.formaction}}" method="GET">
	<input type="hidden" value="{{.showall}}" name="showall"></input>
	<input type="submit" value="Show {{.show}}"></input>
</form>
`

const dropDownTemplateHtml = `
<select name="{{.name}}">
{{$selected := .selected}}
{{range $id, $option := $.options}}
	<option value="{{$id}}"{{if eq $id $selected}} selected=""{{end}}>{{$option}}</option>
{{end}}
</select>
`

const coloredTableTemplateHtml = `
<table>
{{$user_id := .user_id}}
{{range $line_number, $row := $.lines}}
	{{$row_user_id := index $row 0}}{{$line := index $row 1}}
	<tr class="{{if eq $row_user_id $user_id}}your_entry{{else}}other_entry{{end}}"><td>{{$line}}</td></tr>
{{end}}
</table>
`

type FastCGIServer struct{}

func get_error_message(err error) string {
	s := err.Error()
	return fmt.Sprintf("%q\n", s)
}

// --------------------------------------------------
func execTemplate(tmpl *template.Template, w *http.ResponseWriter, pc *map[string]interface{}) {
	if err := tmpl.Execute(*w, *pc); err != nil {
		http.Error(*w, err.Error(), http.StatusInternalServerError)
	}
}

// From http://stackoverflow.com/questions/17211027/go-with-parseglob-how-to-render-more-than-two-templates-in-golang
// --------------------------------------------------

// Checks submission data to verify validity
func checkSubmission(db *sql.DB, starter_id, entry, ip_address, challenge, recaptcha_resp string) (err error) {
	if len(entry) == 0 {
		return errors.New("Entry field cannot be left blank")
	}
	var number_of_starters int
	err = db.QueryRow("SELECT count(*) FROM starters WHERE starters.id = $1", starter_id).Scan(&number_of_starters)
	if err != nil {
		return err
	}
	if number_of_starters != 1 {
		return errors.New("Invalid starter")
	}
	result := recaptcha.Confirm(ip_address, challenge, recaptcha_resp)
	if !result {
		return errors.New("Invalid captcha")
	}
	return nil
}

// Creates a new user and entry
func newUserSubmission(resp http.ResponseWriter, db *sql.DB, ip, starter_id, entry string) (user_id int, err error) {
	err = db.QueryRow(`
		WITH user_row AS (
			INSERT INTO "users" (ip_address)
			VALUES ($1)
			RETURNING id
		)
		INSERT INTO entries (user_id, starter_id, entry)
			VALUES ((SELECT id FROM user_row), $2, $3)
			RETURNING (SELECT id FROM user_row)
	`, ip, starter_id, entry).Scan(&user_id)
	if err != nil {
		return 0, err
	}
	http.SetCookie(resp, &http.Cookie{Name: "user", Value: strconv.Itoa(user_id), Expires: time.Now().AddDate(10, 0, 0)})
	return user_id, nil
}

// Creates a new entry. Calls newUserSubmission if the current user id is not valid.
func newSubmission(resp http.ResponseWriter, db *sql.DB, user_id int, ip, starter_id, entry string) (int, error) {
	var number_of_users int = 0
	err := db.QueryRow("SELECT count(*) FROM users WHERE users.id = $1", user_id).Scan(&number_of_users)
	if err != nil {
		return 0, err
	}
	if number_of_users != 1 {
		return newUserSubmission(resp, db, ip, starter_id, entry)
	}
	_, err = db.Query(`
		INSERT INTO entries (user_id, starter_id, entry)
			VALUES ($1, $2, $3)
	`, user_id, starter_id, entry)
	if err != nil {
		return 0, err
	}
	return user_id, nil
}

// Gathers data and assembles it for the user.
func (s FastCGIServer) ServeHTTP(resp http.ResponseWriter, req *http.Request) {
	db, err := connect()
	if err != nil {
		resp.Write([]byte(get_error_message(err)))
		return
	}
	var user_id int = 0
	cookie, err := req.Cookie("user")
	if err == nil {
		user_id, err = strconv.Atoi(cookie.Value)
		if err != nil {
			user_id = 0
		}
	}
	ip_address := strings.Split(req.RemoteAddr, ":")[0]
	data := map[string]interface{}{"PageTitle": "Gratitude Journal", "recaptcha_public_key": recaptcha_public_key, "name": "starter", "formaction": req.URL.Path[1:]}
	if req.Method == "POST" {
		entry := req.PostFormValue("entry")
		starter_id := req.PostFormValue("starter")
		err := checkSubmission(db, starter_id, entry, ip_address, req.PostFormValue("recaptcha_challenge_field"), req.PostFormValue("recaptcha_response_field"))
		if err != nil {
			data["formerrors"] = template.HTML("<br /><span class=\"errortext\">Error: " + get_error_message(err) + "</span><br />")
			data["selected"] = starter_id
			data["oldentry"] = entry
		} else {
			user_id, err = newSubmission(resp, db, user_id, ip_address, starter_id, entry)
			if err != nil {
				resp.Write([]byte(get_error_message(err)))
			}
		}
	} else {
		data["oldentry"] = ""
		data["selected"], err = random_starter_id(db)
		if err != nil {
			resp.Write([]byte(get_error_message(err)))
		}
	}
	var showall bool = req.FormValue("showall") == "true"
	if showall {
		data["showall"] = "false"
		data["show"] = "Fewer"
	} else {
		data["showall"] = "true"
		data["show"] = "All"
	}
	entries, err := list_entries(db, showall)
	//resp.Write([]byte(strconv.Itoa(len(entries))))
	if err != nil {
		resp.Write([]byte(get_error_message(err)))
		return
	}
	starters, err := list_starters(db)
	if err != nil {
		resp.Write([]byte(get_error_message(err)))
		return
	}
	data["options"] = starters
	data["user_id"] = strconv.Itoa(user_id)
	data["lines"] = entries
	execTemplate(templates["home"], &resp, &data)
	db.Close()
}

// Sets up templates and reCaptcha
func init() {
	funcMap := template.FuncMap{
		"eq": func(args ...interface{}) bool {
			if len(args) == 0 {
				return false
			}
			x := args[0]
			switch x := x.(type) {
			case string, int, int64, byte, float32, float64:
				for _, y := range args[1:] {
					if x == y {
						return true
					}
				}
				return false
			}
			for _, y := range args[1:] {
				if reflect.DeepEqual(x, y) {
					return true
				}
			}
			return false
		},
	}
	templates["home"] = template.Must(template.New("rootPage").Funcs(funcMap).Parse(rootPageTemplateHtml))
	templates["home"].New("pageHeader").Parse(headerTemplateHtml)
	templates["home"].New("pageFooter").Parse(footerTemplateHtml)
	templates["home"].New("pageContent").Parse(homePageContentTemplateHtml)
	templates["home"].New("dropDown").Parse(dropDownTemplateHtml)
	templates["home"].New("coloredTable").Parse(coloredTableTemplateHtml)
	recaptcha.Init(recaptcha_private_key)
}

// Establishes connection to Postgres database
func connect() (*sql.DB, error) {
	db, err := sql.Open("postgres", "user=cmps112 dbname=cmps112 password=Winter.js sslmode=disable")
	return db, err
}

// Requests a listing of all entries with their respective starters from the database and returns them as a slice of slices of strings
func list_entries(db *sql.DB, showall bool) ([][]string, error) {
	var show_limit string
	var entries [][]string
	if !showall {
		show_limit = " LIMIT 10"
	}
	rows, err := db.Query("SELECT starter, entry, user_id FROM starters, entries WHERE entries.starter_id = starters.id ORDER BY entries.id DESC" + show_limit)
	if err != nil {
		return entries, err
	}
	for rows.Next() {
		var starter string
		var entry string
		var user_id int
		err = rows.Scan(&starter, &entry, &user_id)
		if err != nil {
			return entries, err
		} else {
			entries = append(entries, []string{strconv.Itoa(user_id), starter + entry})
		}
	}
	return entries, nil
}

// Requests a listing of all entries with their respective starters from the database and formats them as an HTML table.
func print_entries(db *sql.DB, user_id int, showall bool) (string, error) {
	var show_limit string
	if !showall {
		show_limit = " LIMIT 10"
	}
	rows, err := db.Query("SELECT starter, entry, user_id FROM starters, entries WHERE entries.starter_id = starters.id ORDER BY entries.id DESC" + show_limit)
	var entries string = ""
	if err != nil {
		return entries, err
	}
	for rows.Next() {
		var starter string
		var entry string
		var entry_user_id int
		err = rows.Scan(&starter, &entry, &entry_user_id)
		if err != nil {
			return entries, err
		} else {
			var highlight string = ""
			if user_id == entry_user_id {
				highlight = " class=\"your_entry\" "
			} else {
				highlight = " class=\"other_entry\" "
			}
			entries += "<tr" + highlight + "><td>" + starter + entry + "</td></tr>"
		}
	}
	return entries, nil
}

// Requests a listing of all starters from the database and returns them as a string map
func list_starters(db *sql.DB) (map[string]interface{}, error) {
	starters := map[string]interface{}{}
	rows, err := db.Query("SELECT id, starter FROM starters")
	if err != nil {
		return starters, err
	}
	for rows.Next() {
		var id string
		var starter string
		err = rows.Scan(&id, &starter)
		if err != nil {
			return starters, err
		} else {
			starters[id] = starter
		}
	}
	return starters, nil
}

// Gets a random starter id from the database
func random_starter_id(db *sql.DB) (id string, err error) {
	err = db.QueryRow("select id from starters offset floor(random() * (select count(*) from starters)) limit 1").Scan(&id)
	return
}

func main() {
	listener, _ := net.Listen("tcp", "127.0.0.1:9001")
	srv := new(FastCGIServer)
	fcgi.Serve(listener, srv)
}
