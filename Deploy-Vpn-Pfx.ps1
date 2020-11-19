$SHARED_FOLDER = "\\path_to_shared_folder\$USERNAME\"
$LOG_DIR = "FileSystem::$SHARED_FOLDER"
$LOG_FILE = "_vpn_logs.txt"
$LOG_PATH = "$LOG_DIR\$LOG_FILE"

$DOMAIN = $env:UserDomain
$USERNAME = $env:UserName
$COMPUTER_NAME = $env:ComputerName

$SHARED_FOLDER = "\\path_to_shared_folder\$USERNAME\"
$BASE_CRT_DIR = "FileSystem::$SHARED_FOLDER"
$CRT_PREFIX = ""
$CRT_PREFIX_AFETR = "_"
$CRT_SUFFIX = ".pfx"
$CRT_PATH = $BASE_CRT_DIR + $CRT_PREFIX + $USERNAME +$CRT_SUFFIX
$CRT_PATH_AFTER = $BASE_CRT_DIR + $CRT_PREFIX_AFETR + $USERNAME +$CRT_SUFFIX
$CRT_IMPORT_DESTINATION = "Cert:\CurrentUser\My"

$ERROR_CODE = 0

function Get-Formated-Date {
    return Get-Date -Format "MM/dd/yyyy HH:mm"
}

function Append-To-LogFile ($type, $content) {
	try {
		$date = Get-Formated-Date
		echo "[$type]`t$USERNAME`t$date | $content" >> $LOG_PATH
		return 
	} catch {
		# Script can be run at the same time by multiple users
		$delay = Get-Random -Minimum 500 -Maximum 1000
		Start-Sleep -Milliseconds $delay 
		$content += " [+${delay}ms]"
		Append-To-LogFile $type $content
	}
}

function Get-Pfx-Password {
	try {
		return ConvertTo-SecureString (Get-Content -Path "$BASE_CRT_DIR$USERNAME.txt") -AsPlainText -Force
	} catch {
		return $null
	}
}


try {
	if (Test-Path $CRT_PATH_AFTER -PathType Leaf) {
		Append-To-LogFile "INFO" "Nothing to do. PFX already imported."
		exit 0
	}
    Append-To-LogFile "INFO" "Launching script for $DOMAIN\$USERNAME ($COMPUTER_NAME)"
    Append-To-LogFile "INFO" "Getting PFX Password"
    $pfx_password = Get-Pfx-Password
	if ($pfx_password -eq $null) {
		$ERROR_CODE += 9
		throw "$DOMAIN\$USERNAME could not find linked pfx: $CRT_PATH"
	}
	Append-To-LogFile "INFO" "Importing PFX Certificate to $CRT_IMPORT_DESTINATION"
	Import-PfxCertificate -FilePath $CRT_PATH -CertStoreLocation $CRT_IMPORT_DESTINATION -Password $pfx_password
	Append-To-LogFile "INFO" "Successfully imported $CRT_PATH for $DOMAIN\$USERNAME ($COMPUTER_NAME) at $CRT_IMPORT_DESTINATION !"
	Append-To-LogFile "INFO" "rename pfx on fileshare: $CRT_PATH for $DOMAIN\$USERNAME ($COMPUTER_NAME) to $CRT_PATH_AFTER !"
	Move-Item -Path $CRT_PATH -Destination $CRT_PATH_AFTER	
} catch {
    $ErrorMessage = $_.Exception.Message
    $ERROR_CODE += 1
    Append-To-LogFile "ERROR" "$ErrorMessage"
} finally {
    Append-To-LogFile "INFO" "script exited with code error $ERROR_CODE`n----"
	exit $ERROR_CODE
}