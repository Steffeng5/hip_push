<?php
$config = yaml_parse(file_get_contents("config.yaml"));

$code = htmlspecialchars($_GET["code"]);

$postdata = http_build_query(
    array(
        'grant_type' => 'authorization_code',
        'client_id' => $config['pushbullet_client_id'],
        'client_secret' => $config['pushbullet_client_secret'],
        'code' => $code
    )
);

$opts = array('http' =>git
    array(
        'method'  => 'POST',
        'content' => $postdata
    )
);

$context  = stream_context_create($opts);
$result = file_get_contents('https://api.pushbullet.com/oauth2/token', false, $context);

$token = json_decode($result);

$access_token_file = fopen($config['access_token_file_path'], "a") or die("Unable to open file!");
fwrite($access_token_file, $token->access_token.PHP_EOL);
fclose($access_token_file);

echo "<h1>Diese tolle Seite zeigt dir, dass du nun Pushbenachrichtigungen bekommst</h1>";
?>