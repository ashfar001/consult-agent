# Windows PowerShell 5.1. This script is copied from the installed app's assets.
# The release ZIP is data; nothing from it runs until the complete bundle is in place.
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$work = $PSScriptRoot
$ready = Join-Path $work 'ready'
$cancel = Join-Path $work 'cancel'
$commit = Join-Path $work 'commit'
$started = Join-Path $work 'started'
$stage = $null
$backup = $null
$agent = $null
$newAgent = $null
$oldMoved = $false
$newMoved = $false
$committed = $false
$exitCode = 1

function Assert-PlainItem($Item) {
    if ($Item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
        throw 'The app or its install path contains a Windows link. Use the releases page to update it manually.'
    }
}

function Assert-PlainTree([string]$Path) {
    foreach ($item in Get-ChildItem -LiteralPath $Path -Force) {
        Assert-PlainItem $item
        if ($item.PSIsContainer) { Assert-PlainTree $item.FullName }
    }
}

function Assert-Bundle([string]$Path) {
    $files = @(
        'ConsultAgent.exe', 'flutter_windows.dll', 'sqlite3.dll',
        'screen_retriever_windows_plugin.dll', 'window_manager_plugin.dll'
    )
    $rootNames = $files + @('data', 'native_assets.json')
    $dataNames = @('app.so', 'icudtl.dat', 'flutter_assets')
    foreach ($item in Get-ChildItem -LiteralPath $Path -Force) {
        # Flutter plugins can add runtime DLLs in a later version. The release
        # digest authenticates their bytes, so permit root DLLs while keeping
        # user files out of the install folder.
        if ($item.Name -notin $rootNames -and
            !(!$item.PSIsContainer -and $item.Extension -ieq '.dll')) {
            throw 'The install folder contains files outside the app bundle. Use the releases page to update it manually.'
        }
    }
    $data = Join-Path $Path 'data'
    foreach ($item in Get-ChildItem -LiteralPath $data -Force) {
        if ($item.Name -notin $dataNames) {
            throw 'The app data folder contains files outside the release bundle. Use the releases page to update it manually.'
        }
    }
    foreach ($file in $files + @(
        'data\app.so', 'data\icudtl.dat', 'data\flutter_assets\AssetManifest.bin',
        'data\flutter_assets\assets\updater\install.ps1'
    )) {
        $item = Get-Item -LiteralPath (Join-Path $Path $file) -Force
        if ($item.PSIsContainer -or $item.Length -eq 0) {
            throw 'The app folder is missing required release files. Use the releases page to update it manually.'
        }
    }
}

function Test-ContainsPath([string]$Parent, [string]$Child) {
    $root = $Parent.TrimEnd('\')
    $path = $Child.TrimEnd('\')
    return $path.Equals($root, [StringComparison]::OrdinalIgnoreCase) -or
        $path.StartsWith($root + '\', [StringComparison]::OrdinalIgnoreCase)
}

function Expand-Release([string]$Zip, [string]$Destination) {
    Add-Type -AssemblyName System.IO.Compression
    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($Zip)
    try {
        if ($archive.Entries.Count -gt 4096) { throw 'The release ZIP has too many entries.' }
        $names = [Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
        $buffer = [byte[]]::new(65536)
        $totalBytes = 0L
        foreach ($entry in $archive.Entries) {
            $name = $entry.FullName.Replace('\', '/')
            $isDirectory = $name.EndsWith('/')
            $relative = $name.TrimEnd('/')
            $parts = $relative.Split('/')
            foreach ($part in $parts) {
                if (!$part -or $part -match '[\x00-\x1f<>:"|?*]|[. ]$' -or
                    $part -match '^(CON|PRN|AUX|NUL|COM[0-9\u00b9\u00b2\u00b3]|LPT[0-9\u00b9\u00b2\u00b3]|CONIN\$|CONOUT\$)(\.|$)') {
                    throw 'The release ZIP contains an unsafe path.'
                }
            }
            if (!$names.Add($relative) -or
                (($entry.ExternalAttributes -shr 16) -band 0xf000) -eq 0xa000 -or
                ($entry.ExternalAttributes -band [int][IO.FileAttributes]::ReparsePoint)) {
                throw 'The release ZIP contains a duplicate or linked entry.'
            }
            $target = [IO.Path]::GetFullPath((Join-Path $Destination ($parts -join '\')))
            if ($target.Length -ge 250 -or !(Test-ContainsPath $Destination $target)) {
                throw 'The release ZIP has an unsafe or overly long install path.'
            }
            $totalBytes += $entry.Length
            if ($totalBytes -gt 512MB) { throw 'The extracted release ZIP is too large.' }
            if ($isDirectory) {
                if ($entry.Length -ne 0) { throw 'The release ZIP has an invalid directory.' }
                [void][IO.Directory]::CreateDirectory($target)
                continue
            }
            [void][IO.Directory]::CreateDirectory([IO.Path]::GetDirectoryName($target))
            $source = $entry.Open()
            try {
                $output = [IO.File]::Open($target, [IO.FileMode]::CreateNew)
                try {
                    $bytesWritten = 0L
                    while (($count = $source.Read($buffer, 0, $buffer.Length)) -gt 0) {
                        $bytesWritten += $count
                        if ($bytesWritten -gt $entry.Length) { throw 'The release ZIP has an invalid file size.' }
                        $output.Write($buffer, 0, $count)
                    }
                    if ($bytesWritten -ne $entry.Length) { throw 'The release ZIP has an incomplete file.' }
                } finally {
                    $output.Dispose()
                }
            } finally {
                $source.Dispose()
            }
        }
    } finally {
        $archive.Dispose()
    }
}

function Start-Agent([string]$Path, [string]$Signal) {
    $info = [Diagnostics.ProcessStartInfo]::new($Path)
    $info.WorkingDirectory = [IO.Path]::GetDirectoryName($Path)
    $info.UseShellExecute = $false
    $info.EnvironmentVariables.Remove('CONSULT_AGENT_UPDATE_STARTUP_SIGNAL')
    if ($Signal) { $info.EnvironmentVariables['CONSULT_AGENT_UPDATE_STARTUP_SIGNAL'] = $Signal }
    return [Diagnostics.Process]::Start($info)
}

function Write-Status([string]$Path, [string]$Message) {
    [IO.File]::WriteAllText($Path + '.tmp', $Message)
    Move-Item -LiteralPath ($Path + '.tmp') -Destination $Path -Force
}

try {
    $request = [IO.File]::ReadAllText((Join-Path $work 'handoff.json')) | ConvertFrom-Json
    $exe = [IO.Path]::GetFullPath([string]$request.executable)
    $install = [IO.Path]::GetDirectoryName($exe)
    $parent = [IO.Directory]::GetParent($install)
    if ([IO.Path]::GetFileName($exe) -ne 'ConsultAgent.exe' -or
        !$parent -or $install -notmatch '^[a-z]:\\') {
        throw 'Install ConsultAgent in its own local folder before using in-app updates.'
    }

    for ($dir = [IO.DirectoryInfo]::new($install); $dir; $dir = $dir.Parent) {
        Assert-PlainItem $dir
    }
    foreach ($location in $request.protectedPaths) {
        $protected = [IO.Path]::GetFullPath($location)
        if ((Test-ContainsPath $install $protected) -or (Test-ContainsPath $protected $install)) {
            throw 'This install overlaps a data, log or project folder. Use the releases page to update it manually.'
        }
    }

    $agent = [Diagnostics.Process]::GetProcessById([int]$request.processId)
    [void]$agent.Handle
    if ($agent.MainModule.FileName -ne $exe) {
        throw 'The running app could not be matched to its install folder.'
    }
    Assert-PlainTree $install
    Assert-Bundle $install

    # A sibling keeps both folder moves on the same volume. These probes catch
    # read-only installs and parents before the user has to close the app.
    $operation = '.consult-agent-update-' + [Guid]::NewGuid().ToString('N')
    $stage = Join-Path $parent.FullName $operation
    $backup = $stage + '-backup'
    $probe = Join-Path $install ($operation + '.probe')
    try {
        [IO.File]::WriteAllText($probe, '')
        [IO.File]::Delete($probe)
        [void][IO.Directory]::CreateDirectory($stage)
    } catch {
        throw 'The app folder or its parent is not writable. Ask your administrator to update it from the releases page.'
    }

    $archive = Join-Path $work 'release.zip'
    if ($request.sha256 -cnotmatch '^[a-f0-9]{64}$' -or
        (Get-FileHash -LiteralPath $archive -Algorithm SHA256).Hash -ne $request.sha256) {
        throw 'The download failed its SHA-256 check. Try downloading it again.'
    }
    Expand-Release $archive $stage
    Assert-Bundle $stage
    $nextExe = Join-Path $stage 'ConsultAgent.exe'
    $next = [Diagnostics.FileVersionInfo]::GetVersionInfo($nextExe)
    $nextVersion = [version]::new($next.ProductMajorPart, $next.ProductMinorPart, $next.ProductBuildPart)
    $old = [Diagnostics.FileVersionInfo]::GetVersionInfo($exe)
    $oldVersion = [version]::new($old.ProductMajorPart, $old.ProductMinorPart, $old.ProductBuildPart)
    if ($nextVersion.ToString() -ne $request.version -or $nextVersion -le $oldVersion) {
        throw 'The downloaded executable version does not match the newer GitHub release.'
    }

    [IO.File]::WriteAllText($ready, 'ready')
    $timer = [Diagnostics.Stopwatch]::StartNew()
    while (!$agent.WaitForExit(200)) {
        if ([IO.File]::Exists($cancel) -or $timer.Elapsed.TotalSeconds -ge 60) { return }
    }
    if ([IO.File]::Exists($cancel) -or ![IO.File]::Exists($commit)) { return }
    $committed = $true

    # Recheck the live folder immediately before moving it.
    Assert-PlainTree $install
    Assert-Bundle $install
    [IO.Directory]::Move($install, $backup)
    $oldMoved = $true
    [IO.Directory]::Move($stage, $install)
    $newMoved = $true

    $newAgent = Start-Agent $exe $started
    $timer.Restart()
    while (!$newAgent.WaitForExit(200) -and $timer.Elapsed.TotalSeconds -lt 45) {
        if ([IO.File]::Exists($started) -and
            [IO.File]::ReadAllText($started) -eq [string]$newAgent.Id) {
            $exitCode = 0
            break
        }
    }
    if ($exitCode -ne 0) { throw 'The updated app did not reach sign-in.' }

    # The new process acknowledged startup. It is now safe to discard the old bundle.
    try {
        [IO.Directory]::Delete($backup, $true)
    } catch {
        # An antivirus or other process can briefly keep an old file open.
        # Retain any files that could not be removed.
    }
} catch {
    $problem = $_.Exception.Message
    if ($committed) {
        try {
            if ($newAgent -and !$newAgent.HasExited) {
                $newAgent.Kill()
                if (!$newAgent.WaitForExit(10000)) { throw 'Could not stop the updated app.' }
            }
            if ($newMoved) { [IO.Directory]::Move($install, $stage) }
            if ($oldMoved) { [IO.Directory]::Move($backup, $install) }
            $message = 'The update failed. Your previous version was restored. ' + $problem
            Write-Status $request.resultFile $message
            [void](Start-Agent $exe '')
        } catch {
            $message = 'The update could not restart ConsultAgent. Open the releases page for a manual update. ' +
                'If an app backup exists, it is at ' + $backup + '. ' + $_.Exception.Message
            try { Write-Status $request.resultFile $message } catch {}
            Add-Type -AssemblyName System.Windows.Forms
            [void][Windows.Forms.MessageBox]::Show($message, 'ConsultAgent update')
        }
    } else {
        Write-Status (Join-Path $work 'prepare-error') $problem
        # Leave the error available until the app has read it.
        $timer = [Diagnostics.Stopwatch]::StartNew()
        while (![IO.File]::Exists($cancel) -and $timer.Elapsed.TotalSeconds -lt 10) {
            Start-Sleep -Milliseconds 200
        }
    }
} finally {
    if ($agent) { $agent.Dispose() }
    if ($newAgent) { $newAgent.Dispose() }
    if ($stage -and [IO.Directory]::Exists($stage)) {
        Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue
    }
    Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue
}
exit $exitCode
