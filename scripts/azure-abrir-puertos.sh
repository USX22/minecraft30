#!/usr/bin/env bash
# Se ejecuta en la CLOUD SHELL de Azure (no en la VM). Crea el firewall de
# Azure (NSG) de la máquina y abre SOLO: SSH 22, Java 25565, Bedrock 19132
# TCP/UDP y 19133 UDP. Muestra la IP pública al final.
#   curl -sL https://raw.githubusercontent.com/usx22/minecraft30/claude/eager-newton-q1uimf/scripts/azure-abrir-puertos.sh | bash
# Variables opcionales: RG (grupo de recursos), VM (nombre), LOC (región)
set -euo pipefail
RG="${RG:-minecraft30}"; VM="${VM:-minecraft30}"; NSG="${NSG:-minecraft30-nsg}"
LOC="${LOC:-$(az vm show -g "$RG" -n "$VM" --query location -o tsv)}"

reglas() {  # reglas <grupo> <nsg>
  local g="$1" n="$2"
  az network nsg rule create -g "$g" --nsg-name "$n" -n SSH               --priority 300 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 22    -o none
  az network nsg rule create -g "$g" --nsg-name "$n" -n Minecraft-Java    --priority 310 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 25565 -o none
  az network nsg rule create -g "$g" --nsg-name "$n" -n Bedrock-RakNet    --priority 320 --direction Inbound --access Allow --protocol Udp --destination-port-ranges 19132 -o none
  az network nsg rule create -g "$g" --nsg-name "$n" -n Bedrock-Senal     --priority 330 --direction Inbound --access Allow --protocol Tcp --destination-port-ranges 19132 -o none
  az network nsg rule create -g "$g" --nsg-name "$n" -n Bedrock-NetherNet --priority 340 --direction Inbound --access Allow --protocol Udp --destination-port-ranges 19133 -o none
}

NIC="$(az vm show -g "$RG" -n "$VM" --query "networkProfile.networkInterfaces[0].id" -o tsv)"
EXISTENTE="$(az network nic show --ids "$NIC" --query networkSecurityGroup.id -o tsv)"
if [[ -n "$EXISTENTE" ]]; then
  echo "La máquina ya tiene firewall (${EXISTENTE##*/}): se le añaden las reglas."
  reglas "$(echo "$EXISTENTE" | cut -d/ -f5)" "${EXISTENTE##*/}"
else
  az network nsg create -g "$RG" -n "$NSG" -l "$LOC" -o none
  reglas "$RG" "$NSG"
  az network nic update --ids "$NIC" --network-security-group "$(az network nsg show -g "$RG" -n "$NSG" --query id -o tsv)" -o none
fi
SUBNET="$(az network nic show --ids "$NIC" --query "ipConfigurations[0].subnet.id" -o tsv)"
SNSG="$(az network vnet subnet show --ids "$SUBNET" --query networkSecurityGroup.id -o tsv)"
if [[ -n "$SNSG" ]]; then
  echo "La subred también tiene firewall (${SNSG##*/}): se le añaden las reglas."
  reglas "$(echo "$SNSG" | cut -d/ -f5)" "${SNSG##*/}"
fi
echo "IP PUBLICA: $(az vm show -d -g "$RG" -n "$VM" --query publicIps -o tsv)"
