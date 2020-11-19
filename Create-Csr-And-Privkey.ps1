#Signature numérique, Chiffrement de la clé (a0)
#Sécurité IP IKE intermédiaire (1.3.6.1.5.5.8.2.2)
#Authentification du serveur (1.3.6.1.5.5.7.3.1)
#Type d’objet=Entité finale
#Contrainte de longueur de chemin d’accès=Aucun(e)

# users.txt contains a list of username, one per line
$BASE_PATH = "\\path-to-script-directory"
$BASE_PATH_FS = "FileSystem::$BASE_PATH"
$USER_LIST_FILE = "$BASE_PATH_FS\users.txt"
$USERS = (Get-Content $USER_LIST_FILE).split()
$DOMAIN = "example.com"

function Create-CSR-For-User ($user, $domain) {
	try {
		$CSR_PATH = "$BASE_PATH\_CSR\$user.csr"
		$PRIVKEY_PATH = "$BASE_PATH\_PRIVKEY\$user.key"
		$subject = "/CN=$user@$domain"
		# domain can be different for email. adapt script for your use case, see subjectAltName=email param
		openssl req -new -newkey rsa:2048 -nodes -keyout $PRIVKEY_PATH -out $CSR_PATH -subj $subject -addext "subjectAltName=email:$user@$domain" -addext "basicConstraints=CA:FALSE, pathlen:0" -addext "keyUsage=digitalSignature, keyEncipherment" -addext "extendedKeyUsage=1.3.6.1.5.5.8.2.2, serverAuth"
	} catch {
		Write-Error "Error while creating CSR for $user"
	}
}

ForEach ($user in $USERS) {
	Create-CSR-For-User $user $DOMAIN
}

