#############################################
# Script pour renommer un Windows Server 2022
#############################################

Clear-Host
Write-Host "=========================================" -ForegroundColor Green
Write-Host "    RENOMMAGE DU SERVEUR WINDOWS 2022    " -ForegroundColor Green
Write-Host "=========================================" -ForegroundColor Green
Write-Host ""

# Afficher le nom actuel du serveur
$currentName = $env:COMPUTERNAME
Write-Host "Nom actuel du serveur : " -NoNewline
Write-Host "$currentName" -ForegroundColor Yellow
Write-Host ""

# Demander le nouveau nom
$newName = Read-Host "Entrez le nouveau nom pour ce serveur"

# Vérifier que le nom n'est pas vide
if ([string]::IsNullOrWhiteSpace($newName)) {
    Write-Host "Erreur : Le nom ne peut pas être vide." -ForegroundColor Red
    Write-Host "Opération annulée." -ForegroundColor Red
    return
}

# Vérifier que le nom respecte les conventions de nommage Windows
if ($newName -notmatch "^[a-zA-Z0-9-]{1,15}$") {
    Write-Host "Erreur : Le nom doit contenir uniquement des lettres, des chiffres ou des tirets et ne pas dépasser 15 caractères." -ForegroundColor Red
    Write-Host "Opération annulée." -ForegroundColor Red
    return
}

# Confirmation
Write-Host ""
Write-Host "Vous allez renommer ce serveur de " -NoNewline
Write-Host "$currentName" -ForegroundColor Yellow -NoNewline
Write-Host " vers " -NoNewline
Write-Host "$newName" -ForegroundColor Green

$confirmation = Read-Host "Confirmez-vous ce changement ? (O/N)"
if ($confirmation -ne "O" -and $confirmation -ne "o") {
    Write-Host "Opération annulée." -ForegroundColor Yellow
    return
}

try {
    # Renommer le PC
    Rename-Computer -NewName $newName -Force -ErrorAction Stop
    
    Write-Host ""
    Write-Host "Le serveur a été renommé avec succès en " -NoNewline
    Write-Host "$newName" -ForegroundColor Green
    
    # Proposer un redémarrage
    Write-Host ""
    $reboot = Read-Host "Un redémarrage est nécessaire pour appliquer le changement. Redémarrer maintenant ? (O/N)"
    
    if ($reboot -eq "O" -or $reboot -eq "o") {
        Write-Host "Le serveur va redémarrer dans 10 secondes..." -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }
    else {
        Write-Host "N'oubliez pas de redémarrer le serveur pour appliquer les changements." -ForegroundColor Yellow
    }
}
catch {
    Write-Host "Erreur lors du renommage du serveur : $_" -ForegroundColor Red
}

# Pause avant de revenir au menu principal
Write-Host ""
Read-Host "Appuyez sur Entrée pour revenir au menu principal"