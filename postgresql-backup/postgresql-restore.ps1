# Предварительно включить
# Set-ExecutionPolicy RemoteSigned
#   - затем выбрать Y
#
# Это позволит запускать локальные скрипты (созданные на локальной машине),
# но потребует подписи для загруженных скриптов.

# --------------------------------------------------------------------
# Параметры утилиты
# --------------------------------------------------------------------
param (
    [string]$service,
    [string]$pghost,
    [string]$username,
    [int]$port,
    [object]$log = $true
)

. "$PSScriptRoot/config.ps1"
. "$PSScriptRoot/common.ps1"

function Get-BackupData {
    $backupData = @()
    $index = 1

    # Проходим по каждому тенанту в заданном порядке
    foreach ($tenant in $tenants) {
        $tenantDir = Join-Path $baseDir $tenant

        # Путь к сервису для текущего тенанта
        $servicePath = Join-Path $tenantDir $service
        if (Test-Path $servicePath) {
            # Если папка с сервисом существует, собираем информацию о бэкапах
            Get-ChildItem -Path $servicePath -Filter "*.$dumpFileExtension" | ForEach-Object {
                $backupData += [PSCustomObject]@{
                    Index   = $index
                    Tenant  = $tenant
                    Service = $service
                    Backup  = $_.Name
                    Size    = "{0:N2} MB" -f ($_.Length / 1MB)
                    Date    = $_.LastWriteTime
                    Path    = $_.FullName
                }
                $index++
            }
        } else {
            Write-Host "Service '$service' not found for tenant: $tenant"
        }
    }

    # Сортировка данных: сначала по порядку в списке тенантов, затем по дате (по убыванию)
    $sortedBackupData = $backupData | Sort-Object @{Expression = { [array]::IndexOf($tenants, $_.Tenant) }}, @{Expression = { $_.Date }; Descending=$true}

    # Перенумеровываем данные после сортировки
    $finalIndex = 1
    $sortedBackupData | ForEach-Object {
        $_.Index = $finalIndex
        $finalIndex++
    }

    return $sortedBackupData
}

function Show-FormatedBackupData {
    # Переменная для хранения предыдущего тенанта
    $previousTenant = ""

    # Выводим отсортированную таблицу с бэкапами, добавляя пустую строку между тенантами
    if ($backupData.Count -eq 0) {
        Write-Host "No backups found for service '$service'."
    } else {
        # Выводим заголовок с правильным выравниванием столбцов
        Write-Host ""
        Write-Host ("{0,-5} {1,-7} {2,-15} {3,-45} {4,-10} {5,-20} {6}" -f "Index", "Tenant", "Service", "Backup", "Size", "Date", "Path")
        Write-Host ("-" * 150)

        $backupData | ForEach-Object {
            # Если тенант изменился, добавляем пустую строку для разделения
            if ($_.Tenant -ne $previousTenant) {
                if ($previousTenant -ne "") {
                    Write-Host ("-" * 150)
                }
                $previousTenant = $_.Tenant
            }

            # Форматированный вывод данных
            "{0,-5} {1,-7} {2,-15} {3,-45} {4,-10} {5,-20} {6}" -f `
                $_.Index, $_.Tenant, $_.Service, $_.Backup, $_.Size, $_.Date, $_.Path | Write-Host
        }
        Write-Host ""
    }
}

# --------------------------------------------------------------------
# Меняем кодировку терминала на UTF-8
Initialize-Terminal

# --------------------------------------------------------------------
# Проверяем наличие файла pg_restore.exe
if (-Not (Test-Path $pgRestorePath)) {
    Write-Host "Указанный исполняемый файл не найден: $pgRestorePath" -ForegroundColor Red
    exit
}

# Устанавливаем логирование
$logEnabled = Set-Log
$tenant = "local"
$service = Set-Service
$pghost = Set-PgHost
$port = Set-Port
$username = Set-Username
$dbPrefix = Get-DBPrefix
$dbSuffix = Get-DBSuffix

# --------------------------------------------------------------------
# Формирование таблицы
# --------------------------------------------------------------------

# Получаем список доступных бекапов всех определенных тенантов
$backupData = Get-BackupData

# Показываем оформленную таблицу со списком доступных бекапов
Show-FormatedBackupData

# Пользователь выбирает бэкап по индексу
$selectedIndex = Read-Host "Enter the index of the selected backup"

# Находим бэкап по индексу
$selectedBackup = $backupData | Where-Object { $_.Index -eq [int]$selectedIndex }

if ($selectedBackup) {
    Write-Host "You selected backup: $($selectedBackup.Backup)"
    Write-Host "Backup path: $($selectedBackup.Path)" -ForegroundColor Yellow
} else {
    Write-Host "No backup found with the given index."
}

# --------------------------------------------------------------------
# Запуск восстановления
# --------------------------------------------------------------------

# Имя базы данных
$dbName = $dbPrefix + $service + $dbSuffix

$pgRestoreArgumentList = (
    "--verbose --host=$pghost --port=$port " +
    "--username=$username --disable-triggers --clean --format=c --dbname=$dbName $($selectedBackup.Path)"
)

Write-Host "Restore command: $pgRestorePath $pgRestoreArgumentList"

# Запрашиваем пароль от postgresql, на который будем производить восстановление данных
Write-Host
Set-PgPassword
Write-Host

# Инициализируем таймер
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Запуск процесса восстановления бекапа
Start-Command -PgCommandPath $pgRestorePath -pgCommandArgumentList $pgRestoreArgumentList -logPrefix restore

Remove-PgPassword

# Выводим результат
Write-Host "`rRestore complete!" -ForegroundColor Green
$elapsedTime = $stopwatch.Elapsed.ToString("hh\:mm\:ss")
Write-Host ("Restore duration: $elapsedTime")
