function Initialize-Terminal {
    # Меняем кодировку терминала на UTF-8
    $null = chcp 65001
    $env:PGCLIENTENCODING = "UTF8"
}

function Set-Log {
    # Преобразуем входные значения
    if ($(1, 'true', 'on') -contains $log) {
        return $true
    } elseif ($(0, 'false', 'off') -contains $log) {
       return $false
    } else {
        Write-Host "Ошибка: Неверное значение для параметра -log. Используйте 0, 1, true, false, on или off." -ForegroundColor Red
        exit 1
    }
}

function Set-Tenant {
    # Если параметр tenant не передан, выводим список доступных тенантов для выбора
    if (-not $tenant) {
        Write-Host "Available tenants:"
        for ($i = 0; $i -lt $tenants.Length; $i++) {
            Write-Host ("{0,2}. {1,-15}" -f ($i + 1), $tenants[$i])
        }
        
        # Спрашиваем пользователя, чтобы он ввел номер тенанта
        Write-Host ""
        $tenantNumber = Read-Host "Please enter the tenant number"

        # Объявляем переменную $number
        $number = 0
        
        # Преобразуем ввод в целое число и проверяем корректность выбора
        if ([int]::TryParse($tenantNumber, [ref]$number) -and $number -gt 0 -and $number -le $tenants.Length) {
            $tenant = $tenants[$number - 1]
        }
        else {
            Write-Host "Error: Invalid tenant number" -ForegroundColor Red
            exit 1
        }
    }
    return $tenant
}

function Set-Service {
    # Если параметр service не передан, выводим список доступных сервисов для выбора
    if (-not $service) {
        Write-Host "Available services:"
        for ($i = 0; $i -lt $services.Length; $i++) {
            Write-Host ("{0,2}. {1,-15}" -f ($i + 1), $services[$i])
        }
        
        # Спрашиваем пользователя, чтобы он ввел номер сервиса
        Write-Host ""
        $serviceNumber = Read-Host "Please enter the service number"

        # Объявляем переменную $number
        $number = 0
        
        # Преобразуем ввод в целое число и проверяем корректность выбора
        if ([int]::TryParse($serviceNumber, [ref]$number) -and $number -gt 0 -and $number -le $services.Length) {
            $service = $services[$number - 1]
        }
        else {
            Write-Host "Error: Invalid service number" -ForegroundColor Red
            exit 1
        }
    }
    return $service
}

function Set-Port {
    # Выбор порта в зависимости от тенанта
    # Перед вызовом должен быть определен $tenant
    if (-not $tenant) {
        Write-Host "tenant is not defined." -ForegroundColor Red
        exit
    }

    if (-not $port) {
        $port = $defaultPort  # Порт по умолчанию

        if ($tenantSettings.ContainsKey($tenant)) {
            if ($tenantSettings[$tenant].ContainsKey("port")) {
                $portData = $tenantSettings[$tenant]["port"]

                if ($portData -is [hashtable] -and $portData.ContainsKey($service)) {
                    $port = $portData[$service]
                } else {
                    $port = $portData
                }
                
                if (-not ($port -is [int])) {
                    Write-Host "port для тенанта $tenant задан в неверном формате" -ForegroundColor Red
                    exit
                }
            }
        } else {
            Write-Host "Не заданы настройки для тенанта $tenant" -ForegroundColor Red
            exit  
        }
    }
    return $port
}

function Set-Username {
    # Выбора username в зависимости от тенанта
    # Перед вызовом должен быть определен $tenant
    if (-not $tenant) {
        Write-Host "tenant is not defined." -ForegroundColor Red
        exit
    }

    if ($tenantSettings.ContainsKey($tenant)) {
        if ($tenantSettings[$tenant].ContainsKey("username")) {
            $username = $tenantSettings[$tenant]["username"]

            if (-not ($username -is [string])) {
                Write-Host "username для тенанта $tenant задан в неверном формате" -ForegroundColor Red
                exit
            }
        } else {
            Write-Host "Не заданы настройки username для тенанта $tenant" -ForegroundColor Red
            exit
        }
    }  else {
        Write-Host "Не заданы настройки для тенанта $tenant" -ForegroundColor Red
        exit  
    }
    return $username
}

function Set-PgHost {
    # Выбора pghost в зависимости от тенанта
    # Перед вызовом должен быть определен $tenant
    if (-not $tenant) {
        Write-Host "tenant is not defined." -ForegroundColor Red
        exit
    }

    if ($tenantSettings.ContainsKey($tenant)) {
        if ($tenantSettings[$tenant].ContainsKey("host")) {
            $pghost = $tenantSettings[$tenant]["host"]

            if (-not ($pghost -is [string])) {
                Write-Host "host для тенанта $tenant задан в неверном формате" -ForegroundColor Red
                exit
            }
        } else {
            Write-Host "Не заданы настройки host для тенанта $tenant" -ForegroundColor Red
            exit
        }
    }  else {
        Write-Host "Не заданы настройки для тенанта $tenant" -ForegroundColor Red
        exit  
    }
    return $pghost
}

function Get-DBPrefix {
    # Выбора pghost в зависимости от тенанта
    # Перед вызовом должен быть определен $tenant
    if (-not $tenant) {
        Write-Host "tenant is not defined." -ForegroundColor Red
        exit
    }

    $prefix = $defaultDBPrefix

    if ($tenantSettings.ContainsKey($tenant)) {
        if ($tenantSettings[$tenant].ContainsKey("prefix")) {
            $prefix = $tenantSettings[$tenant]["prefix"]

            if (-not ($prefix -is [string])) {
                Write-Host "prefix для тенанта $tenant задан в неверном формате" -ForegroundColor Red
                exit
            }
        }
    }  else {
        Write-Host "Не заданы настройки для тенанта $tenant" -ForegroundColor Red
        exit  
    }
    return $prefix
}

function Get-DBSuffix {
    # Выбора pghost в зависимости от тенанта
    # Перед вызовом должен быть определен $tenant
    if (-not $tenant) {
        Write-Host "tenant is not defined." -ForegroundColor Red
        exit
    }

    $suffix = $defaultDBSuffix

    if ($tenantSettings.ContainsKey($tenant)) {
        if ($tenantSettings[$tenant].ContainsKey("suffix")) {
            $suffix = $tenantSettings[$tenant]["suffix"]

            if (-not ($suffix -is [string])) {
                Write-Host "suffix для тенанта $tenant задан в неверном формате" -ForegroundColor Red
                exit
            }
        }
    }  else {
        Write-Host "Не заданы настройки для тенанта $tenant" -ForegroundColor Red
        exit  
    }
    return $suffix
}

function Set-PgPassword {
    # Запрашиваем пароль от postgreql и сохраняем его в окружение текущего терминала

    # Запрашиваем ввод пароля
    $pgPassword = Read-Host -Prompt "pgpassword" -AsSecureString

    # Преобразуем SecureString в обычную строку
    $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($pgPassword)
    $pgPasswordPlainText = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)

    # Устанавливаем переменную окружения
    $env:PGPASSWORD = $pgPasswordPlainText

    # Очищаем переменную
    Clear-Variable -Name pgPasswordPlainText
}

function Remove-PgPassword {
    # Очистить переменную окружения
    Remove-Item Env:PGPASSWORD
}

function Get-LogFilePath {
    param (
        [string]$prefix
    )

    # param (
    if (-not (Test-Path -Path $logsDir)) {
        New-Item -ItemType Directory -Path $logsDir | Out-Null
    }

    # Создаем директорию для сервиса, если её нет
    $serviceLogDir = Join-Path -Path $logsDir -ChildPath $service
    if (-not (Test-Path -Path $serviceLogDir)) {
        New-Item -ItemType Directory -Path $serviceLogDir | Out-Null
    }

    # Форматируем имя лог-файла с текущей датой и временем
    $logFileName = "$prefix-$tenant-$service-$(Get-Date -Format yyyyMMddHHmm).log"
    
    # Полный путь к лог-файлу
    return Join-Path -Path $serviceLogDir -ChildPath $logFileName
}

function Start-Command {
    param (
        [string]$pgCommandPath,
        [string]$pgCommandArgumentList,
        [string]$logPrefix
    )

    if ($logEnabled) {
        $logFilePath = Get-LogFilePath -prefix $logprefix
    
        # Скрываем курсор
        [CursorControl]::HideCursor()
    
        $process = Start-Process -FilePath $pgCommandPath `
            -ArgumentList $pgCommandArgumentList `
            -RedirectStandardError $logFilePath `
            -NoNewWindow -PassThru
        Write-Host "log: $logFilePath" -ForegroundColor Yellow
        Write-Host "Все данные будут записаны в лог-файл." -ForegroundColor DarkGray
        # Анимация лодера
        $loaderChars = @('.', '..', '...', '....', '.....', '......', ' .....', '  ....', '   ...', '    ..', '     .', '      ', '      ', '      ')
    
        while (!$process.HasExited) {
            foreach ($char in $loaderChars) {
                $elapsedTime = $stopwatch.Elapsed.ToString("hh\:mm\:ss")  # Получаем прошедшее время в формате ЧЧ:ММ:СС
                Write-Host -NoNewline "`rRestore duration: $elapsedTime $char"  # Обновляем символ и время на той же строке
                Start-Sleep -Milliseconds 200  # Небольшая пауза для плавности анимации
            }
        }
        Write-Host -NoNewline "`r$(' ' * 50)"
    } else {
        $process = Start-Process -FilePath "$pgCommandPath" `
            -ArgumentList $pgCommandArgumentList `
            -NoNewWindow -PassThru
    }
    # Ожидаем завершения процесса
    $process.WaitForExit()

    # Восстанавливаем курсор
    [CursorControl]::ShowCursor()
}

# Определение функции для скрытия и показа курсора
Add-Type @"
using System;
using System.Runtime.InteropServices;
public class CursorControl {
    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern IntPtr GetStdHandle(int nStdHandle);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool GetConsoleCursorInfo(IntPtr hConsoleOutput, out CONSOLE_CURSOR_INFO lpConsoleCursorInfo);

    [DllImport("kernel32.dll", SetLastError = true)]
    public static extern bool SetConsoleCursorInfo(IntPtr hConsoleOutput, ref CONSOLE_CURSOR_INFO lpConsoleCursorInfo);

    public struct CONSOLE_CURSOR_INFO {
        public int dwSize;
        public bool bVisible;
    }

    const int STD_OUTPUT_HANDLE = -11;

    public static void HideCursor() {
        IntPtr handle = GetStdHandle(STD_OUTPUT_HANDLE);
        CONSOLE_CURSOR_INFO info;
        GetConsoleCursorInfo(handle, out info);
        info.bVisible = false;  // Скрыть курсор
        SetConsoleCursorInfo(handle, ref info);
    }

    public static void ShowCursor() {
        IntPtr handle = GetStdHandle(STD_OUTPUT_HANDLE);
        CONSOLE_CURSOR_INFO info;
        GetConsoleCursorInfo(handle, out info);
        info.bVisible = true;  // Показать курсор
        SetConsoleCursorInfo(handle, ref info);
    }
}
"@
