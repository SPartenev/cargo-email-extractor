# Git команди за качване на всички файлове в GitHub репозиторията
# Репозиторий: SPartenev/cargo-email-extractor

Write-Host "=== CargoFlow Documentation - GitHub Upload Script ===" -ForegroundColor Green
Write-Host ""

# Проверка дали Git е инсталиран
try {
    $gitVersion = git --version
    Write-Host "✓ Git намерен: $gitVersion" -ForegroundColor Green
} catch {
    Write-Host "✗ Git не е инсталиран! Моля инсталирайте Git първо." -ForegroundColor Red
    exit 1
}

# Навигация към директорията
Set-Location "C:\Python_project\CargoFlow\Documentation"

Write-Host "Текуща директория: $(Get-Location)" -ForegroundColor Cyan
Write-Host ""

# Стъпка 1: Инициализиране на Git репозиторий (ако няма)
if (-not (Test-Path ".git")) {
    Write-Host "[1/6] Инициализиране на Git репозиторий..." -ForegroundColor Yellow
    git init
    Write-Host "✓ Git репозиторий инициализиран" -ForegroundColor Green
} else {
    Write-Host "[1/6] Git репозиторий вече съществува" -ForegroundColor Green
}

Write-Host ""

# Стъпка 2: Добавяне на remote (ако няма)
Write-Host "[2/6] Проверка на remote репозиторий..." -ForegroundColor Yellow
$remoteExists = git remote | Select-String -Pattern "origin"

if (-not $remoteExists) {
    Write-Host "Добавяне на remote: https://github.com/SPartenev/cargo-email-extractor.git" -ForegroundColor Cyan
    git remote add origin https://github.com/SPartenev/cargo-email-extractor.git
    Write-Host "✓ Remote добавено" -ForegroundColor Green
} else {
    Write-Host "Remote вече съществува. Обновяване на URL..." -ForegroundColor Cyan
    git remote set-url origin https://github.com/SPartenev/cargo-email-extractor.git
    Write-Host "✓ Remote URL обновен" -ForegroundColor Green
}

Write-Host ""

# Стъпка 3: Добавяне на всички файлове
Write-Host "[3/6] Добавяне на всички файлове..." -ForegroundColor Yellow
git add .
$fileCount = (git status --short | Measure-Object -Line).Lines
Write-Host "✓ Добавени $fileCount файла/промени" -ForegroundColor Green

Write-Host ""

# Стъпка 4: Проверка на статуса
Write-Host "[4/6] Статус на промените:" -ForegroundColor Yellow
git status --short

Write-Host ""

# Стъпка 5: Commit
Write-Host "[5/6] Създаване на commit..." -ForegroundColor Yellow
$commitMessage = "Replace all files with CargoFlow Documentation project

- Complete documentation (19 files)
- All module documentation (6 modules)
- System architecture and deployment guides
- Database schema documentation
- n8n workflow files
- Configuration templates"

git commit -m $commitMessage
Write-Host "✓ Commit създаден" -ForegroundColor Green

Write-Host ""

# Стъпка 6: Push към GitHub
Write-Host "[6/6] Качване към GitHub..." -ForegroundColor Yellow
Write-Host "ВНИМАНИЕ: Това ще замени всички файлове в main branch!" -ForegroundColor Red
Write-Host ""

$confirm = Read-Host "Продължи с push? (yes/no)"
if ($confirm -eq "yes" -or $confirm -eq "y") {
    Write-Host "Извършване на force push към main branch..." -ForegroundColor Yellow
    git push -f origin main
    Write-Host ""
    Write-Host "✓ Файловете са качени успешно!" -ForegroundColor Green
    Write-Host "Репозиторий: https://github.com/SPartenev/cargo-email-extractor" -ForegroundColor Cyan
} else {
    Write-Host "Push отменен." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "За да качите файловете по-късно, изпълнете:" -ForegroundColor Cyan
    Write-Host "  git push -f origin main" -ForegroundColor White
}

Write-Host ""
Write-Host "=== Готово ===" -ForegroundColor Green

