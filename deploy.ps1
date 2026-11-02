
param(
    [string]$Mensagem = "Atualizacao automatica do ALFRED X"
)

$ErrorActionPreference = "Stop"

Write-Host "`n=== ALFRED X - AUTOMATIZADOR ===" -ForegroundColor Cyan

# 1. Verificar a pasta do projeto
if (-not (Test-Path ".git")) {
    throw "Pasta Git nao encontrada."
}

# 2. Proteger o arquivo de credenciais
git check-ignore services/api/.env
if ($LASTEXITCODE -ne 0) {
    throw "ATENCAO: arquivo .env nao esta protegido."
}

$trackedEnv = git ls-files services/api/.env
if ($trackedEnv) {
    throw "ATENCAO: .env esta versionado. Publicacao cancelada."
}

# 3. Verificar o Python
python --version
if ($LASTEXITCODE -ne 0) {
    throw "Python nao encontrado."
}

# 4. Testar sintaxe da API
python -m compileall -q services/api/app
if ($LASTEXITCODE -ne 0) {
    throw "Erro na verificacao do codigo Python."
}

Write-Host "Codigo Python validado." -ForegroundColor Green

# 5. Adicionar alteracoes
git add -A
if ($LASTEXITCODE -ne 0) {
    throw "Erro ao preparar arquivos."
}

# 6. Bloquear arquivos secretos e temporarios
$files = @(git diff --cached --name-only)

$unsafe = $files | Where-Object {
    $_ -match '(^|/)\.env($|\.)' -or
    $_ -match '(^|/)__pycache__/' -or
    $_ -match '\.pyc$'
}

if ($unsafe) {
    git reset
    throw "Arquivos nao permitidos encontrados. Publicacao cancelada."
}

# 7. Criar commit se houver alteracoes
if ($files.Count -gt 0) {
    git commit -m $Mensagem
    if ($LASTEXITCODE -ne 0) {
        throw "Falha ao criar commit."
    }
}
else {
    Write-Host "Nenhuma alteracao nova."
}

# 8. Enviar ao GitHub
git push origin master
if ($LASTEXITCODE -ne 0) {
    throw "Falha no envio ao GitHub."
}

Write-Host "`nPUBLICACAO ENVIADA AO GITHUB!" -ForegroundColor Green
Write-Host "O Render podera iniciar o deploy automatico." -ForegroundColor Green
