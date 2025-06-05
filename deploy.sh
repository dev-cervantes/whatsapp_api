#!/bin/bash
set -e

echo "===== Iniciando build para Elastic Beanstalk ====="

# Verifica se o Go está instalado e na versão correta (>= 1.23)
if command -v go &> /dev/null; then
  GO_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
  echo "Go encontrado: versão $GO_VERSION"
else
  GO_VERSION=""
fi

REQUIRED_VERSION="1.23"

# Função para comparar versões
version_ge() {
  # Retorna 0 se $1 >= $2
  printf '%s\n%s\n' "$2" "$1" | sort -C -V
}

if [ -z "$GO_VERSION" ] || ! version_ge "$GO_VERSION" "$REQUIRED_VERSION"; then
  echo "Go não está instalado ou está com versão inferior a $REQUIRED_VERSION."
  echo "Instalando Go $REQUIRED_VERSION via snap..."

  # Verifica se snap está instalado
  if ! command -v snap &> /dev/null; then
    echo "Snap não encontrado. Instalando snapd..."
    sudo apt update && sudo apt install -y snapd
  fi

  # Instala Go via snap (com --classic para evitar problemas de confinamento)
  sudo snap install go --classic

  # Atualiza o PATH para usar snap bin se necessário
  export PATH=$PATH:/snap/bin

  # Confirma a instalação
  go version
else
  echo "Versão do Go satisfaz o requisito."
fi

BINARY_NAME="web"
ZIP_NAME="whatsappapi.zip"

echo "[1/5] Buildando binário GO para Linux amd64..."
chmod +x *
GOOS=linux GOARCH=amd64 go build -o "$BINARY_NAME"

echo "[2/5] Garantindo permissão de execução no binário..."
chmod +x "$BINARY_NAME"

echo "[3/5] Preparando pacote .zip..."
rm -f "$ZIP_NAME"
zip -r "$ZIP_NAME" "$BINARY_NAME" Procfile go.sum go.mod .ebextensions static

echo "===== Build e empacotamento finalizados com sucesso ====="