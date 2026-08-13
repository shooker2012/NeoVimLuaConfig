param(
    [ValidateRange(2, 20)]
    [int]$Runs = 5,

    [ValidateRange(1, 300)]
    [int]$TimeoutSeconds = 30
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$repoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..\..')).Path
$temporaryRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("nvim-config-modernization-{0}" -f [guid]::NewGuid())
$hasFailure = $false
$executableBaselineMs = 367.068
$historicalReferenceMs = 327.0
$bestEffortTargetMs = 200.0

function Invoke-NvimWithTimeout {
    param(
        [Parameter(Mandatory)]
        [string[]]$Arguments
    )

    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = 'nvim'
    $startInfo.WorkingDirectory = $repoRoot
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in $Arguments) {
        [void]$startInfo.ArgumentList.Add($argument)
    }

    $process = [System.Diagnostics.Process]::new()
    $process.StartInfo = $startInfo
    if (-not $process.Start()) {
        throw 'Failed to start nvim.'
    }

    $stdoutTask = $process.StandardOutput.ReadToEndAsync()
    $stderrTask = $process.StandardError.ReadToEndAsync()
    $completed = $process.WaitForExit($TimeoutSeconds * 1000)
    if (-not $completed) {
        $process.Kill($true)
        $process.WaitForExit()
    }

    $result = [pscustomobject]@{
        TimedOut = -not $completed
        ExitCode = if ($completed) { $process.ExitCode } else { $null }
        Stdout = $stdoutTask.GetAwaiter().GetResult()
        Stderr = $stderrTask.GetAwaiter().GetResult()
    }
    $process.Dispose()
    return $result
}

function Get-StartupTimeMilliseconds {
    param(
        [Parameter(Mandatory)]
        [string]$LogPath
    )

    $lines = Get-Content -LiteralPath $LogPath
    $startedLine = $lines | Where-Object { $_ -match 'NVIM STARTED' } | Select-Object -Last 1
    if ($null -eq $startedLine -or $startedLine -notmatch '^\s*(\d+(?:\.\d+)?)') {
        throw "Unable to parse total startup time from $LogPath"
    }
    return [double]$Matches[1]
}

function Get-StartupBottlenecks {
    param(
        [Parameter(Mandatory)]
        [string]$LogPath,

        [int]$Limit = 10
    )

    $entries = foreach ($line in Get-Content -LiteralPath $LogPath) {
        if ($line -match '^\s*(?<clock>\d+(?:\.\d+)?)\s+(?<elapsed>\d+(?:\.\d+)?)\s+(?<self>\d+(?:\.\d+)?):\s+(?<event>.+)$') {
            [pscustomobject]@{
                Clock = [double]$Matches.clock
                Elapsed = [double]$Matches.elapsed
                Self = [double]$Matches.self
                Event = $Matches.event.Trim()
            }
        }
    }

    return @($entries |
        Where-Object { $_.Self -gt 0 -and $_.Event -ne 'NVIM STARTED' } |
        Sort-Object Self -Descending |
        Select-Object -First $Limit)
}

function Get-VeryLazyReport {
    param(
        [Parameter(Mandatory)]
        [string]$ReportPath
    )

    $luaReportPath = $ReportPath.Replace('\', '/')
    $registerCommand = 'lua vim.g.nvim_modernization_started=vim.uv.hrtime(); vim.api.nvim_create_autocmd("User",{pattern="VeryLazy",once=true,callback=function() vim.schedule(function() local names={}; for name,plugin in pairs(require("lazy.core.config").plugins) do if plugin._.loaded then names[#names+1]=name end end; table.sort(names); vim.fn.writefile({vim.json.encode({elapsed_ms=(vim.uv.hrtime()-vim.g.nvim_modernization_started)/1000000,plugins=names})},[[' + $luaReportPath + ']]); vim.g.nvim_modernization_very_lazy_done=true end) end})'
    $waitCommand = 'lua vim.wait(2000,function() return vim.g.nvim_modernization_very_lazy_done==true end,10)'
    # Headless sessions never receive UIEnter naturally. Trigger it explicitly
    # so lazy.nvim schedules the same VeryLazy event used by an interactive UI.
    $result = Invoke-NvimWithTimeout -Arguments @('--headless', '--cmd', $registerCommand, '-c', 'doautocmd UIEnter', '-c', $waitCommand, '-c', 'qa!')

    if ($result.TimedOut -or $result.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $ReportPath)) {
        return $null
    }

    return (Get-Content -Raw -LiteralPath $ReportPath | ConvertFrom-Json)
}

try {
    [void](New-Item -ItemType Directory -Path $temporaryRoot)

    Write-Host '== Headless startup diagnostics =='
    $diagnostics = Invoke-NvimWithTimeout -Arguments @('--headless', '-c', 'messages', '-c', 'qa!')
    $diagnosticOutput = ($diagnostics.Stdout, $diagnostics.Stderr -join [Environment]::NewLine).Trim()

    if ($diagnostics.TimedOut) {
        Write-Error "Headless startup timed out after $TimeoutSeconds seconds." -ErrorAction Continue
        $hasFailure = $true
    } elseif ($diagnostics.ExitCode -ne 0) {
        Write-Error "Headless startup exited with code $($diagnostics.ExitCode)." -ErrorAction Continue
        $hasFailure = $true
    }

    $suspiciousLines = @($diagnosticOutput -split '\r?\n' | Where-Object { $_ -match '(?i)(\bE\d+:|Error|deprecated)' })
    if ($suspiciousLines.Count -gt 0) {
        Write-Warning 'Startup messages contain possible errors or deprecations:'
        $suspiciousLines | ForEach-Object { Write-Host "  $_" }
        $hasFailure = $true
    } else {
        Write-Host 'No E<number>, Error, or deprecated messages detected.'
    }

    Write-Host "`n== Startup timing ($Runs runs; first run discarded) =="
    $measurements = [System.Collections.Generic.List[double]]::new()
    $timingRuns = [System.Collections.Generic.List[object]]::new()
    for ($index = 1; $index -le $Runs; $index++) {
        $logPath = Join-Path $temporaryRoot ("startuptime-{0}.log" -f $index)
        $timing = Invoke-NvimWithTimeout -Arguments @('--headless', '--startuptime', $logPath, '-c', 'qa!')
        if ($timing.TimedOut) {
            Write-Error "Startup timing run $index timed out after $TimeoutSeconds seconds." -ErrorAction Continue
            $hasFailure = $true
            continue
        }
        if ($timing.ExitCode -ne 0) {
            Write-Error "Startup timing run $index exited with code $($timing.ExitCode)." -ErrorAction Continue
            $hasFailure = $true
            continue
        }

        $milliseconds = Get-StartupTimeMilliseconds -LogPath $logPath
        $measurements.Add($milliseconds)
        $timingRuns.Add([pscustomobject]@{ Milliseconds = $milliseconds; LogPath = $logPath; Run = $index })
        Write-Host ("Run {0}: {1:N3} ms{2}" -f $index, $milliseconds, $(if ($index -eq 1) { ' (warm-up)' } else { '' }))
    }

    if ($measurements.Count -ne $Runs) {
        $hasFailure = $true
    } else {
        $stableMeasurements = @($measurements | Select-Object -Skip 1 | Sort-Object)
        $middle = [int][math]::Floor($stableMeasurements.Count / 2)
        $median = if ($stableMeasurements.Count % 2 -eq 0) {
            ($stableMeasurements[$middle - 1] + $stableMeasurements[$middle]) / 2
        } else {
            $stableMeasurements[$middle]
        }
        Write-Host ("Median after warm-up: {0:N3} ms" -f $median)

        $baselineDelta = $median - $executableBaselineMs
        $historicalDelta = $median - $historicalReferenceMs
        $targetDelta = $median - $bestEffortTargetMs
        Write-Host ("Executable baseline: {0:N3} ms; delta: {1:+0.000;-0.000;0.000} ms ({2:+0.0;-0.0;0.0}%)" -f $executableBaselineMs, $baselineDelta, (($baselineDelta / $executableBaselineMs) * 100))
        Write-Host ("Historical reference: {0:N3} ms; delta: {1:+0.000;-0.000;0.000} ms (reference only)" -f $historicalReferenceMs, $historicalDelta)
        Write-Host ("Best-effort target: {0:N3} ms; delta: {1:+0.000;-0.000;0.000} ms" -f $bestEffortTargetMs, $targetDelta)

        if ($median -gt $bestEffortTargetMs) {
        Write-Host "`nBest-effort target was not reached; highest self-time entries:"
            $profileRun = $timingRuns |
                Select-Object -Skip 1 |
                Sort-Object { [math]::Abs($_.Milliseconds - $median) } |
                Select-Object -First 1
            foreach ($entry in Get-StartupBottlenecks -LogPath $profileRun.LogPath) {
                Write-Host ("  {0,8:N3} ms  {1}" -f $entry.Self, $entry.Event)
            }
        } else {
            Write-Host 'Best-effort target reached.'
        }

        Write-Host "`n== VeryLazy completion report =="
        $veryLazyPath = Join-Path $temporaryRoot 'very-lazy.json'
        $veryLazy = Get-VeryLazyReport -ReportPath $veryLazyPath
        if ($null -eq $veryLazy) {
            Write-Error 'Unable to capture the VeryLazy completion report.' -ErrorAction Continue
            $hasFailure = $true
        } else {
            Write-Host ("VeryLazy supplemental work: {0:N3} ms after configuration startup" -f [double]$veryLazy.elapsed_ms)
            Write-Host ("Loaded plugins after VeryLazy ({0}): {1}" -f @($veryLazy.plugins).Count, (@($veryLazy.plugins) -join ', '))
        }
    }
} finally {
    if (Test-Path -LiteralPath $temporaryRoot) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force
    }
}

if ($hasFailure) {
    exit 1
}
