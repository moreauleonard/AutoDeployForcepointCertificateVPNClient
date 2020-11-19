$BASE_PATH = "\\path-to-script-directory"
$BASE_PATH_FS = "FileSystem::$BASE_PATH"
$USER_LIST_FILE = "$BASE_PATH_FS\users.txt"
$USERS = (Get-Content $USER_LIST_FILE).split()
$OUTPUT_USER_FILE = "$BASE_PATH_FS\pfx-pass_users.txt"
$PASSWORD_LENGTH = 20 # TODO, check that this is an integer

'' | Out-File -FilePath $OUTPUT_USER_FILE # create or empty file

foreach ($user in $USERS) {
	# TODO : check that directories exists, or create it (_PRIVKEY, _CRT, _PFX)
	$key = "$BASE_PATH\_PRIVKEY\$user.key"
	$crt = "$BASE_PATH\_CRT\$user.crt"
	$pfx = "$BASE_PATH\_PFX\$user.pfx"
	$pfx_pass = openssl rand -hex ($PASSWORD_LENGTH / 2) # 1 hex = 2 char
	"$user,$pfx_pass`n" | Out-File -FilePath $OUTPUT_USER_FILE -Append # we store pfx password somewhere, need it to import it later
	openssl pkcs12 -export -inkey $key -in $crt -passout pass:$pfx_pass -out $pfx
}
