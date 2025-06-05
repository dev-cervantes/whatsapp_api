#!/bin/bash
set -e

REQUIRED_GO_VERSION="1.23"
GO_EXEC="/snap/bin/go"

echo "===== Iniciando build para Elastic Beanstalk ====="

# Função para comparar versões
version_lt() {
    [ "$(printf '%s\n' "$1" "$2" | sort -V | head -n1)" != "$2" ]
}

# Verifica se o Go está instalado e sua versão
if command -v go >/dev/null 2>&1; then
    INSTALLED_VERSION=$(go version | awk '{print $3}' | sed 's/go//')
    echo "Go encontrado: versão $INSTALLED_VERSION"

    if version_lt "$INSTALLED_VERSION" "$REQUIRED_GO_VERSION"; then
        echo "Go está desatualizado. Instalando Go $REQUIRED_GO_VERSION via snap..."
        sudo snap install go --classic
    fi
else
    echo "Go não encontrado. Instalando Go $REQUIRED_GO_VERSION via snap..."
    sudo snap install go --classic
fi

# Verifica se o Snap está usando a versão correta
GO_VERSION_INSTALLED=$($GO_EXEC version | awk '{print $3}' | sed 's/go//')
if version_lt "$GO_VERSION_INSTALLED" "$REQUIRED_GO_VERSION"; then
    echo "Erro: o Snap não instalou a versão mínima necessária ($REQUIRED_GO_VERSION)."
    echo "Versão atual: $GO_VERSION_INSTALLED"
    exit 1
fi

echo "Go snap ativo: $GO_EXEC (versão $GO_VERSION_INSTALLED)"

BINARY_NAME="web"
ZIP_NAME="whatsappapi.zip"

echo "[1/5] Buildando binário GO para Linux amd64 com $GO_EXEC..."
chmod +x *

# Build usando a versão correta do Go
GOOS=linux GOARCH=amd64 $GO_EXEC build -o "$BINARY_NAME"

echo "[2/5] Garantindo permissão de execução no binário..."
chmod +x "$BINARY_NAME"

echo "[3/5] Preparando pacote .zip..."
rm -f "$ZIP_NAME"

zip -r "$ZIP_NAME" "$BINARY_NAME" Procfile go.sum go.mod .ebextensions static

echo "===== Build e empacotamento finalizados com sucesso ====="
