$SHARED_FOLDER = "\\path_to_shared_folder\$USERNAME\"
$LOG_DIR = "FileSystem::\\$SHARED_FOLDER\log"
$LOG_FILE = "_vpn_logs.txt"
$LOG_PATH = "$LOG_DIR\$LOG_FILE"

$DOMAIN = $env:UserDomain
$DOMAIN_NAME =(gwmi WIN32_ComputerSystem).Domain
$USERNAME = $env:UserName
$COMPUTER_NAME = $env:ComputerName

$BASE_CRT_DIR = "FileSystem::\\$SHARED_FOLDER\$USERNAME\"
$CRT_PREFIX = ""
$CRT_PREFIX_AFETR = "_"
$CRT_SUFFIX = ".crt"

$PRIV_PREFIX = ""
$PRIV_PREFIX_AFTER = "_"
$PRIV_SUFFIX = ".prv"
$CRT_PATH = $BASE_CRT_DIR + $CRT_PREFIX + $USERNAME +$CRT_SUFFIX
$CRT_PATH_AFTER = $BASE_CRT_DIR + $CRT_PREFIX_AFETR + $USERNAME +$CRT_SUFFIX
$PRIV_PATH = $BASE_CRT_DIR + $PRIV_PREFIX + $USERNAME +$PRIV_SUFFIX
$PRIV_PATH_AFTER = $BASE_CRT_DIR + $PRIV_PREFIX_AFETR + $USERNAME +$PRIV_SUFFIX

$CRT_IMPORT_DESTINATION = "Cert:\CurrentUser\My"

# Default install paths
$FP_PGDATA_CERT = "C:\ProgramData\Forcepoint\VPN Client\certificates"
$FP_BASE_REGPATH = "HKLM:\SOFTWARE\WOW6432Node\Forcepoint\VPN Client"
$ERROR_CODE = 0

function Get-Formated-Date {
    return Get-Date -Format "MM/dd/yyyy HH:mm"
}

function Append-To-LogFile ($type, $content) {
	try {
		$date = Get-Formated-Date
		echo "[$type]`t$USERNAME`t$date | $content" >> $LOG_PATH
		Write-Host "[$type]`t$USERNAME`t$date | $content"
		return 
	} catch {
		$delay = Get-Random -Minimum 10 -Maximum 50
		Start-Sleep -Milliseconds $delay 
		$content += " [+${delay}ms]"
		Append-To-LogFile $type $content
	}
}

function Remove-All-VPN-Certificates {
	foreach ($certificate in (Get-ChildItem -Path $CRT_IMPORT_DESTINATION)){
		if ($certificate.Subject -eq "CN=$USERNAME@$DOMAIN_NAME"){
			try {
				Remove-Item -LiteralPath $certificate.PSPath
				Append-To-LogFile "INFO" "($COMPUTER_NAME) Certificate $($certificate.subject) ($($certificate.Thumbprint)). Valid from: $($certificate.NotBefore) to $($certificate.NotAfter) deleted."
			} catch {
				$ErrorMessage = $_.Exception.Message
				Append-To-LogFile "ERROR" "($COMPUTER_NAME) Error trying to delete certificate $($certificate.subject) ($($certificate.Thumbprint)). Valid from: $($certificate.NotBefore) to $($certificate.NotAfter) deleted.`n$ErrorMessage"
			}
		}
	}
	foreach ($certificate in (Get-ChildItem -Path $FP_PGDATA_CERT)){
	try {
		$certificate | Remove-Item
		Append-To-LogFile "INFO" "($COMPUTER_NAME) Certificate file ($certificate) removed"
	}
	catch {
		$ErrorMessage = $_.Exception.Message
		Append-To-LogFile "ERROR" "($COMPUTER_NAME) Error trying to delete certificate file`n$ErrorMessage"
	}
	}
}

function Delete-Certificates-Registry {
		foreach ($certificate_key in (Get-ChildItem -Path $FP_BASE_REGPATH\Certificates)){
			try {
				if ((Get-ItemProperty -LiteralPath HKLM:\$certificate_key).subject -eq "$USERNAME@$DOMAIN_NAME") {
					Append-To-LogFile "INFO" "($COMPUTER_NAME) Trying to delete certificate registry: $($certificate_key.PSChildName)"
					Remove-Item -LiteralPath $certificate_key.PSPath
					Append-To-LogFile "INFO" "($COMPUTER_NAME) Deleted certificate registry: $($certificate_key.PSChildName)"
				}
			} catch {
				$ErrorMessage = $_.Exception.Message
				Append-To-LogFile "ERROR" "($COMPUTER_NAME) Error while deleting certificate registry: $($certificate_key.PSChildName)`n$ErrorMessage"
			}			
		}
}

function Edit-Gateway-Registry {
	try {
		Append-To-LogFile "INFO" "($COMPUTER_NAME) Editing gateways registry: $FP_BASE_REGPATH\Gateways\1"
		Set-Itemproperty -path '$FP_BASE_REGPATH\Gateways\1' -Name 'Certificate' -value $USERNAME
		Append-To-LogFile "INFO" "($COMPUTER_NAME) $FP_BASE_REGPATH\Gateways\1, Certificate successfully edited to $USERNAME"
	} catch {
		$ErrorMessage = $_.Exception.Message
		Append-To-LogFile "ERROR" "($COMPUTER_NAME) Error while editing gateways registry: $FP_BASE_REGPATH\Gateways\1`n$ErrorMessage"
	}
}

function Copy-And-Log ($source, $dest){
	try {
		Append-To-LogFile "INFO" "($COMPUTER_NAME) Copying $source to $dest"
		Copy-Item -Path $source -Destination $dest
		Append-To-LogFile "INFO" "($COMPUTER_NAME) Successfully copied $source for $DOMAIN\$USERNAME ($COMPUTER_NAME) to $dest !"
	} catch {
		$ErrorMessage = $_.Exception.Message
		Append-To-LogFile "ERROR" "($COMPUTER_NAME) Error while copying $source to $dest`n$ErrorMessage"
	}
}

function Delete-And-Log ($filepath) {
	try {
		Append-To-LogFile "INFO" "Deleting $filepath"
		Remove-Item -Path $PRIV_PATH
		Append-To-LogFile "INFO" "$filepath deleted successfully"
	} catch {
		$ErrorMessage = $_.Exception.Message
		Append-To-LogFile "ERROR" "Error while deleting $filepath`n$ErrorMessage"
	}
}

function Move-And-Log ($source, $dest) {
	try {
		Append-To-LogFile "INFO" "Moving $filepath to $dest"
		Move-Item -Path $source -Destination $dest
		Append-To-LogFile "INFO" "$source moved successfully to $dest"
	} catch {
		$ErrorMessage = $_.Exception.Message
		Append-To-LogFile "ERROR" "Error while moving $source to $dest`n$ErrorMessage"
	}
}

function Clean-And-Log {
	Delete-And-Log $PRIV_PATH
	Move-And-Log $CRT_PATH $CRT_PATH_AFTER	
}

function Stop-Service-And-Log {
	try {
		Append-To-LogFile "INFO" "Stopping vpnclient service"
		Get-Service sgipsecvpn | Stop-Service
		Append-To-LogFile "INFO" "Vpn client stopped"	
	} catch {
	$ErrorMessage = $_.Exception.Message
		Append-To-LogFile "ERROR" "Error while stopping vpnclient service`n$ErrorMessage"
	}
}

function Start-Service-And-Log {
	try {
		Append-To-LogFile "INFO" "Stopping vpnclient service"
		Get-Service sgipsecvpn | Start-Service
		Append-To-LogFile "INFO" "Vpn client stopped"	
	} catch {
	$ErrorMessage = $_.Exception.Message
		Append-To-LogFile "ERROR" "Error while stopping vpnclient service`n$ErrorMessage"
	}
}


try {
	if (Test-Path $CRT_PATH_AFTER -PathType Leaf) {
		Append-To-LogFile "INFO" "Nothing to do. CRT already imported."
		exit 0
	}
    Append-To-LogFile "INFO" "Launching script for $DOMAIN\$USERNAME ($COMPUTER_NAME)"
	
	# CLEAN OLD CONF
	Remove-All-VPN-Certificates

	
	# ADD NEW CERTS
	Copy-And-Log $CRT_PATH $FP_PGDATA_CERT
	Copy-And-Log $PRIV_PATH $FP_PGDATA_CERT

	#Stop-Service-And-Log --> need admin rights for user
	#Delete-Certificates-Registry --> need admin rights for user
	#Start-Service-And-Log --> need admin rights for user
	
	# CLEAN AND END
	Clean-And-Log
} catch {
    $ErrorMessage = $_.Exception.Message
    $ERROR_CODE += 1
    Append-To-LogFile "ERROR" "$ErrorMessage"
} finally {
    Append-To-LogFile "INFO" "script exited with code error $ERROR_CODE`n----"
	if ($ERROR_CODE -eq 0){
		Read-Host "Pour terminer, allez dans les proprietes du VPN Client, puis:`n`t - Allez sur l'onglet 'Gateways',`n`t - Effectuez un clic droit sur 'sgw-mci-sg',`n`t`tAuthentication -> Certificate -> [Selectionnez le certificat tout en bas de la liste : $USERNAME@$DOMAIN_NAME]`n`nEn cas de probleme, quittez le client VPN et relancez le.`nSi le probleme est toujours présent, re-basculez en authentification 'username' et contactez un membre de l'equipe ASN.`n`nAppuyez sur 'entree' pour terminer l'execution du script"		
	}
	exit $ERROR_CODE
}