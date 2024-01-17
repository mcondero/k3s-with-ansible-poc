#!/bin/bash

set -x

function AddGPGKeys () {
  curl -fsSL https://downloads.k8slens.dev/keys/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/lens-archive-keyring.gpg > /dev/null
}

function AddK8sLensRepo () {
  echo "deb [arch=amd64 signed-by=/usr/share/keyrings/lens-archive-keyring.gpg] https://downloads.k8slens.dev/apt/debian stable main" | sudo tee /etc/apt/sources.list.d/lens.list > /dev/null
}

function InstallK8sLens () {
  sudo nala update
  sudo nala install lens -y
}

AddGPGKeys
AddK8sLensRepo
InstallK8sLens
