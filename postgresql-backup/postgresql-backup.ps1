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
    [string]$tenant,
    [string]$username,
    [int]$port,
    [object]$log = $true
)

. "$PSScriptRoot/config.ps1"
. "$PSScriptRoot/common.ps1"

# --------------------------------------------------------------------
# Меняем кодировку терминала на UTF-8
Initialize-Terminal

# --------------------------------------------------------------------
# Запуск создания дампа
# --------------------------------------------------------------------

# Проверяем наличие файла pg_dump.exe
if (-Not (Test-Path $pgDumpPath)) {
    Write-Host "Указанный исполняемый файл не найден: $pgDumpPath" -ForegroundColor Red
    exit
}

# Устанавливаем логирование
$logEnabled = Set-Log
$tenant = Set-Tenant
$service = Set-Service
$pghost = Set-PgHost
$port = Set-Port
$username = Set-Username

# Имя базы данных
$dbName = $dbPrefix + $service

# Путь к файлу дампа
$dumpFile = "$baseDir\$tenant\$service\dump-$tenant-$service-$(Get-Date -Format yyyyMMddHHmm).$dumpFileExtension"

# Создаем директорию, если она не существует
$directory = [System.IO.Path]::GetDirectoryName($dumpFile)

if (-not (Test-Path $directory)) {
    New-Item -ItemType Directory -Path $directory -Force
    $directoryCreated = $true
}
# --------------------------------------------------------------------

$pgDumpArgumentList = (
    "--verbose --host=$pghost --port=$port " +
    "--username=$username --format=c --compress=9 --inserts --file $dumpFile --dbname $dbName"
)

Write-Host "Dump command: $pgDumpPath $pgDumpArgumentList"

# Запрашиваем пароль от postgresql, на который будем производить восстановление данных
Write-Host
Set-PgPassword
Write-Host

# Инициализируем таймер
$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

# Запуск процесса создания дампа
Start-Command -pgCommandPath $pgDumpPath -pgCommandArgumentList $pgDumpArgumentList -logPrefix dump

Remove-PgPassword

# Проверяем, если директория была создана и её размер равен 0, удаляем её
if ($directoryCreated) {
    # Получаем размер всех файлов в директории
    $directorySize = (Get-ChildItem $directory -Recurse | Measure-Object -Property Length -Sum).Sum
    
    # Удаляем директорию, если её размер равен 0
    if ($directorySize -eq 0) {
        Remove-Item $directory -Force -Recurse
    }
}

# Выводим результат
Write-Host "`rDump complete!" -ForegroundColor Green
$elapsedTime = $stopwatch.Elapsed.ToString("hh\:mm\:ss")
Write-Host ("Dump duration: $elapsedTime")
Write-Host ("File: $dumpFile")
