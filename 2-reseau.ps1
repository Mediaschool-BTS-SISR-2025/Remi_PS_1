#############################################
# Script pour configurer le réseau Windows Server 2022
#############################################

Clear-Host
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host "  CONFIGURATION RÉSEAU WINDOWS SERVER 2022  " -ForegroundColor Cyan
Write-Host "=========================================" -ForegroundColor Cyan
Write-Host ""

# Obtenir les adaptateurs réseau disponibles
$adapters = @(Get-NetAdapter | Where-Object { $_.Status -eq "Up" })

if ($adapters.Count -eq 0) {
    Write-Host "Aucun adaptateur réseau actif n'a été trouvé." -ForegroundColor Red
    Read-Host "Appuyez sur Entrée pour revenir au menu principal"
    return
}

# Afficher les adaptateurs disponibles
Write-Host "Adaptateurs réseau disponibles :" -ForegroundColor Yellow
for ($i = 0; $i -lt $adapters.Count; $i++) {
    Write-Host "$($i+1) - $($adapters[$i].Name) ($($adapters[$i].InterfaceDescription))"
}

Write-Host ""
$choixAdapter = Read-Host "Sélectionnez l'adaptateur à configurer (numéro)"

# Vérifier le choix
if (-not ($choixAdapter -match "^\d+$") -or [int]$choixAdapter -lt 1 -or [int]$choixAdapter -gt $adapters.Count) {
    Write-Host "Choix invalide." -ForegroundColor Red
    Read-Host "Appuyez sur Entrée pour revenir au menu principal"
    return
}

$selectedAdapter = $adapters[[int]$choixAdapter-1]
Write-Host "Adaptateur sélectionné : " -NoNewline
Write-Host "$($selectedAdapter.Name)" -ForegroundColor Green
Write-Host ""

# Afficher la configuration actuelle
$currentConfig = Get-NetIPConfiguration -InterfaceIndex $selectedAdapter.ifIndex
Write-Host "Configuration actuelle :" -ForegroundColor Yellow
Write-Host "IP : $($currentConfig.IPv4Address.IPAddress)"
Write-Host "Masque : $($currentConfig.IPv4Address.PrefixLength)"
Write-Host "Passerelle : $($currentConfig.IPv4DefaultGateway.NextHop)"
$dnsServers = (Get-DnsClientServerAddress -InterfaceIndex $selectedAdapter.ifIndex -AddressFamily IPv4).ServerAddresses
Write-Host "Serveurs DNS : $($dnsServers -join ', ')"
Write-Host ""

# Menu de configuration
Write-Host "Options de configuration :" -ForegroundColor Yellow
Write-Host "1 - Configurer IP statique"
Write-Host "2 - Configurer DHCP"
Write-Host "3 - Configurer les serveurs DNS uniquement"
Write-Host ""
$choixConfig = Read-Host "Choisissez une option"

switch ($choixConfig) {
    "1" {
        # Configuration IP statique
        Write-Host "Configuration d'une adresse IP statique :" -ForegroundColor Cyan
        $ipAddress = Read-Host "Adresse IP"
        
        # Vérification du format de l'adresse IP
        if (-not ($ipAddress -match "^(\d{1,3}\.){3}\d{1,3}$")) {
            Write-Host "Format d'adresse IP invalide." -ForegroundColor Red
            Read-Host "Appuyez sur Entrée pour revenir au menu principal"
            return
        }
        
        $subnetMask = Read-Host "Masque de sous-réseau (CIDR, ex: 24 pour 255.255.255.0)"
        
        # Vérification du format du masque
        if (-not ($subnetMask -match "^\d{1,2}$") -or [int]$subnetMask -lt 0 -or [int]$subnetMask -gt 32) {
            Write-Host "Format de masque invalide." -ForegroundColor Red
            Read-Host "Appuyez sur Entrée pour revenir au menu principal"
            return
        }
        
        $gateway = Read-Host "Passerelle par défaut"
        
        # Vérification du format de la passerelle
        if (-not ($gateway -match "^(\d{1,3}\.){3}\d{1,3}$")) {
            Write-Host "Format de passerelle invalide." -ForegroundColor Red
            Read-Host "Appuyez sur Entrée pour revenir au menu principal"
            return
        }
        
        $dns1 = Read-Host "Serveur DNS primaire"
        
        # Vérification du format DNS1
        if (-not ($dns1 -match "^(\d{1,3}\.){3}\d{1,3}$")) {
            Write-Host "Format de serveur DNS invalide." -ForegroundColor Red
            Read-Host "Appuyez sur Entrée pour revenir au menu principal"
            return
        }
        
        $dns2 = Read-Host "Serveur DNS secondaire (laissez vide si aucun)"
        
        # Vérification du format DNS2 s'il n'est pas vide
        if ($dns2 -ne "" -and -not ($dns2 -match "^(\d{1,3}\.){3}\d{1,3}$")) {
            Write-Host "Format de serveur DNS secondaire invalide." -ForegroundColor Red
            Read-Host "Appuyez sur Entrée pour revenir au menu principal"
            return
        }
        
        # Confirmation
        Write-Host ""
        Write-Host "Récapitulatif de la configuration :" -ForegroundColor Yellow
        Write-Host "Adaptateur : $($selectedAdapter.Name)"
        Write-Host "IP : $ipAddress"
        Write-Host "Masque : $subnetMask"
        Write-Host "Passerelle : $gateway"
        Write-Host "DNS primaire : $dns1"
        if ($dns2 -ne "") {
            Write-Host "DNS secondaire : $dns2"
        }
        
        $confirmation = Read-Host "Confirmez-vous ces paramètres ? (O/N)"
        if ($confirmation -ne "O" -and $confirmation -ne "o") {
            Write-Host "Configuration annulée." -ForegroundColor Yellow
            Read-Host "Appuyez sur Entrée pour revenir au menu principal"
            return
        }
        
        try {
            # Supprimer la configuration existante
            Remove-NetIPAddress -InterfaceIndex $selectedAdapter.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
            Remove-NetRoute -InterfaceIndex $selectedAdapter.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
            
            # Appliquer la nouvelle configuration
            New-NetIPAddress -InterfaceIndex $selectedAdapter.ifIndex -IPAddress $ipAddress -PrefixLength $subnetMask -DefaultGateway $gateway
            
            # Configurer les DNS
            $dnsServers = @()
            if ($dns1 -ne "") { $dnsServers += $dns1 }
            if ($dns2 -ne "") { $dnsServers += $dns2 }
            
            if ($dnsServers.Count -gt 0) {
                Set-DnsClientServerAddress -InterfaceIndex $selectedAdapter.ifIndex -ServerAddresses $dnsServers
            }
            
            Write-Host ""
            Write-Host "Configuration réseau appliquée avec succès !" -ForegroundColor Green
        }
        catch {
            Write-Host "Erreur lors de la configuration réseau : $_" -ForegroundColor Red
        }
    }
    
    "2" {
        # Configuration DHCP
        try {
            Write-Host "Configuration DHCP en cours..." -ForegroundColor Cyan
            
            # Supprimer la configuration existante
            Remove-NetIPAddress -InterfaceIndex $selectedAdapter.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
            Remove-NetRoute -InterfaceIndex $selectedAdapter.ifIndex -AddressFamily IPv4 -Confirm:$false -ErrorAction SilentlyContinue
            
            # Configurer DHCP pour l'IP
            Set-NetIPInterface -InterfaceIndex $selectedAdapter.ifIndex -Dhcp Enabled
            
            # Configurer DHCP pour les DNS
            $dnsQuestion = Read-Host "Voulez-vous obtenir les serveurs DNS automatiquement via DHCP ? (O/N)"
            if ($dnsQuestion -eq "O" -or $dnsQuestion -eq "o") {
                Set-DnsClientServerAddress -InterfaceIndex $selectedAdapter.ifIndex -ResetServerAddresses
            }
            else {
                $dns1 = Read-Host "Serveur DNS primaire"
                $dns2 = Read-Host "Serveur DNS secondaire (laissez vide si aucun)"
                
                $dnsServers = @()
                if ($dns1 -ne "") { $dnsServers += $dns1 }
                if ($dns2 -ne "") { $dnsServers += $dns2 }
                
                if ($dnsServers.Count -gt 0) {
                    Set-DnsClientServerAddress -InterfaceIndex $selectedAdapter.ifIndex -ServerAddresses $dnsServers
                }
            }
            
            Write-Host "Configuration DHCP appliquée avec succès !" -ForegroundColor Green
        }
        catch {
            Write-Host "Erreur lors de la configuration DHCP : $_" -ForegroundColor Red
        }
    }
    
    "3" {
        # Configuration DNS uniquement
        try {
            $dns1 = Read-Host "Serveur DNS primaire"
            if ($dns1 -eq "") {
                Write-Host "Erreur : Le serveur DNS primaire ne peut pas être vide." -ForegroundColor Red
                Read-Host "Appuyez sur Entrée pour revenir au menu principal"
                return
            }
            
            $dns2 = Read-Host "Serveur DNS secondaire (laissez vide si aucun)"
            
            $dnsServers = @()
            if ($dns1 -ne "") { $dnsServers += $dns1 }
            if ($dns2 -ne "") { $dnsServers += $dns2 }
            
            Set-DnsClientServerAddress -InterfaceIndex $selectedAdapter.ifIndex -ServerAddresses $dnsServers
            
            Write-Host "Serveurs DNS configurés avec succès !" -ForegroundColor Green
        }
        catch {
            Write-Host "Erreur lors de la configuration des serveurs DNS : $_" -ForegroundColor Red
        }
    }
    
    default {
        Write-Host "Option invalide." -ForegroundColor Red
    }
}

# Afficher la nouvelle configuration
Write-Host ""
Write-Host "Nouvelle configuration :" -ForegroundColor Yellow
$newConfig = Get-NetIPConfiguration -InterfaceIndex $selectedAdapter.ifIndex
Write-Host "IP : $($newConfig.IPv4Address.IPAddress)"
Write-Host "Masque : $($newConfig.IPv4Address.PrefixLength)"
Write-Host "Passerelle : $($newConfig.IPv4DefaultGateway.NextHop)"
$dnsServers = (Get-DnsClientServerAddress -InterfaceIndex $selectedAdapter.ifIndex -AddressFamily IPv4).ServerAddresses
Write-Host "Serveurs DNS : $($dnsServers -join ', ')"

# Pause avant de revenir au menu principal
Write-Host ""
Read-Host "Appuyez sur Entrée pour revenir au menu principal"