<!DOCTYPE html>
<html>
<!-- STEVEN CHOU -->
	<head>
		<title> Gratitude Journal </title>
	</head>
<body>
	<?php
//--------------------------------------------------------------
// -- DATABASE CONNECTION VALIDATION
//--------------------------------------------------------------
      $db_login = "host=cmps112.tk
                   dbname=cmps112
                   user=cmps112
                   password=Winter.js
                  ";
      $db = pg_connect($db_login);
      if (!$db)
      {
         echo "Cannot connect to database: CMPS112.\n";
         exit;
      }
   ?>
	<h1> Gratitude Journal </h1>
	<p> Directions: Complete the sentence! </p>
<?php
//--------------------------------------------------------------
// -- COOKIE VALIDATION
//--------------------------------------------------------------
//    echo gethostbyaddr($_SERVER['REMOTE_ADDR']) . "<br>";
//    echo $_SERVER["REMOTE_ADDR"] . "<br>";
//--------------------------------------------------------------
   $name = "user";
   $user_id;
   if (isset($_COOKIE[$name]))
   {
      $user_id = $_COOKIE[$name];
      echo "Welcome User : " . $_COOKIE[$name] . "!<br>";
   }
   else
   {
      $input = "INSERT INTO users (ip_address)
                VALUES ('" . pg_escape_string($_SERVER['REMOTE_ADDR']) . "')
                RETURNING id";
      $output = pg_query($db, $input);
      $row = pg_fetch_row($output);
      $user_id = $row[0];
      echo "$input";
      $expire = time()+3600 *24 *365*10;      //expires in 10 years.
      setcookie($name, $user_id, $expire);
      echo "Welcome New User" . $_COOKIE[$name] . "!<br>";
   }
   echo "<br>Today's date: ";
   echo date("m-d-Y") . "<br><br>";    // Today's date.
//--------------------------------------------------------------
// -- SAVE USER INPUTS
//--------------------------------------------------------------
   $entry   = pg_escape_string($_POST['entry']);
   $starter = pg_escape_string($_POST['starter']);
//--------------------------------------------------------------
// -- RECAPTCHA CONNECTION VALIDATION
//--------------------------------------------------------------
   require_once('recaptchalib.php');
   $privatekey = "6Lesze8SAAAAANZsvyvYB-PE4rDiG40RULY1joDC";
   $resp = recaptcha_check_answer ($privatekey,
                            $_SERVER["REMOTE_ADDR"],
                            $_POST["recaptcha_challenge_field"],
                            $_POST["recaptcha_response_field"]);
   $error = false;
   if (!$resp->is_valid)
   {
//--------------------------------------------------------------
// -- RECAPTCHA IMPLEMENTATION
//      CREDIT: http://developers.google.com/recaptcha/docs/php
//--------------------------------------------------------------
      if (isset($_POST["recaptcha_response_field"]))
      {
         echo "The reCAPTCHA wasn't entered correctly.
               Go back and try it again." .
              "(reCAPTCHA said: " . $resp->error . ")<br><br>";
         $error = true;
      }
   }
   else
   {
//--------------------------------------------------------------
// -- USER INPUT INSERTION VALIDATION
//--------------------------------------------------------------
      $input = "INSERT INTO Entries (user_id, starter_id, entry)
                VALUES ('$user_id', '$starter', '$entry')";
      $output = pg_query($db, $input);
   }
?>
<form action="index.php" method="post">	
<!-- User INPUT OPTIONS for Starters [table] -->
   <select name="starter" autofocus>
<!-- NOTES: HARDCODED OPTIONS DROPDOWN LIST -->
<!--
   <option selected disabled> -- Please Select One -- </option>
   <option value = '2'> Today was fun because </option>
   <option value = '3'> I appreciate </option>
   <option value = '4'> I am grateful for </option>
   <option value = '5'> Before I die,  </option>
   <option value = '6'> My most memorable moment today was when,
                                                       </option>
   <option value = '7'> I am looking forward to </option>
-->
   <?php
//--------------------------------------------------------------
// -- LIMITING THE SHOWING OF DATABASE CONTENTS
//--------------------------------------------------------------
      $selection;
      if ($error)
      {
         $selection = $_POST['starter'];
      }
      else
      {
        $query = "SELECT id
                  FROM Starters
                  OFFSET floor(random() * (SELECT count(*)
                                           FROM starters))
                                           LIMIT 1";
        $results = pg_query($db,$query);
        $row = pg_fetch_row($results);
        $selection = $row[0];
      }
      $query   = "SELECT   Starters.starter,
                           Starters.id
                  FROM     Starters
                  ORDER BY Starters.id";
//--------------------------------------------------------------
// -- DEBUGGING USE
//--------------------------------------------------------------
//    $query = "SELECT Entries.entry FROM Entries";
//    $query = "SELECT Entries.user_id FROM Entries";
//    $query = "SELECT Entries.starter_id FROM Entries";
//--------------------------------------------------------------
// -- PRINT SELECTED DATABASE CONTENTS && HIGHLIGHT USER INPUTS
//--------------------------------------------------------------
      $results = pg_query($db,$query);
      if (!$results)
      {
         echo "An error with query.\n";
      }
      while ($row = pg_fetch_row($results))
      {
         echo "<option ";
         if ($row[1] == $selection)
         {
            echo "selected";
         }
         echo " value ='" . $row[1] . "'>" . $row[0] . "</option>\n";
      }
   ?>
   </select>
<!-- USER ENTRY SUBMISSION FORM -->
<!-- INPUT for Users for Entries [table] -->
   <input type="text" name="entry" value = "
                <?php if ($error) { echo $_POST['entry']; } ?>
                " size 100 required>
   <br>
   <?php
      require_once('recaptchalib.php');
      $publickey = "6Lesze8SAAAAAIRyjwx6MrLITLdtUtSpdQWvJ-Ck";
      echo recaptcha_get_html($publickey);
   ?>
   <input type="submit" value="Submit" />
</form>
<br>
<?php
//--------------------------------------------------------------
// -- RETRIEVE DATABASE CONTENTS
//--------------------------------------------------------------
$query   = "SELECT   Starters.starter,
                     Entries.entry,
                     Entries.user_id
            FROM     Starters,
                     Entries
            WHERE    Entries.starter_id = Starters.id
            ORDER BY Entries.id DESC";
if ($_GET["showall"] != "true")
{
   $query .= " LIMIT 10";
}
//--------------------------------------------------------------
// -- DEBUGGING USE
//--------------------------------------------------------------
//    $query = "SELECT Entries.entry FROM Entries";
//    $query = "SELECT Entries.user_id FROM Entries";
//    $query = "SELECT Entries.starter_id FROM Entries";
//--------------------------------------------------------------
// -- PRINT SELECTED DATABASE CONTENTS && HIGHLIGHT USER INPUTS
//--------------------------------------------------------------
$results = pg_query($db,$query);
if (!$results)
{
   echo "An error with query.\n";
}
while ($row = pg_fetch_row($results))
{
   $text = $row[0] . " " . strip_tags($row[1]) . "<br>";
   if ($_COOKIE[$name] == $row[2])
   {
      echo "<mark>" . $text ."</mark>";
   }
   else
   {
      echo "<mark style=background:#00FFFF;>" . $text ."</mark>";
   }
}
?>
<!-- SHOW ALL OR A SELECTED AMOUNT OF DATABASE ENTRIES -->
<form action="index.php" method="GET">
	<input type="hidden" value="<?php if ($_GET["showall"] == "true"){echo "false";}else{echo "true";} ?>" name="showall"></input>
	<input type="submit" value="Show <?php if ($_GET["showall"] == "true"){echo "Fewer";}else{echo "All";} ?>"></input>
</form>
<?php
   echo "<br>This was constructed with PHP";
//--------------------------------------------------------------
// -- FREE MEMORY && CLOSE CONNECTION
//--------------------------------------------------------------
   pg_free_result($results);
   pg_free_result($output);
   pg_close($db);
?>
</body>
</html>
