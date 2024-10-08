# Статический список тенантов в нужном порядке
# В данной последовательности будут выводиться данные по тенантам
$tenants = @(
    "local",
    "dev",
    "test"
)

$services = @(
    "service1",
    "service2"
)

# Настройки для подключения к базам данных
$tenantSettings = @{
    "local" = @{
        "host"     = "host"
        "username" = "username"
        "port"     = @{
            "service1"      = 5430
            "service2"      = 5431
        }
    }
    "dev"  = @{
        "host"     = "host"
        "username" = "username"
        "port"     = 54321
    }
    "test"  = @{
        "host"     = "host"
        "username" = "username"
        "port"     = 54322
    }
}

# Путь к pg_dump.exe
$pgDumpPath = ""

# Путь к pg_restore.exe
$pgRestorePath = ""

# Директория, где хранятся бэкапы
$baseDir = ""

# Определяем директорию для логов
$logsDir = Join-Path -Path $baseDir -ChildPath "logs"

# Расширение файлов для дампов
$dumpFileExtension = "sql"

# Префикс для имен баз данных
$dbPrefix = ''

# Порт по умолчанию для подключения к базе сервиса
$defaultPort = 5432
