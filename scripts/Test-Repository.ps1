[CmdletBinding()]
param(
    [switch]$CheckRemoteAssets
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$repoPath = Join-Path $root 'repo.json'
$legacyPath = Join-Path $root 'pluginmaster.json'

$repoText = Get-Content -LiteralPath $repoPath -Raw
$legacyText = Get-Content -LiteralPath $legacyPath -Raw
$plugins = @($repoText | ConvertFrom-Json)
$legacyPlugins = @($legacyText | ConvertFrom-Json)

if ($plugins.Count -eq 0) {
    throw 'repo.json must contain at least one plugin.'
}

$requiredFields = @(
    'Author',
    'Name',
    'InternalName',
    'AssemblyVersion',
    'Description',
    'ApplicableVersion',
    'RepoUrl',
    'DalamudApiLevel',
    'IconUrl',
    'Punchline',
    'DownloadLinkInstall',
    'DownloadLinkUpdate'
)

foreach ($plugin in $plugins) {
    foreach ($field in $requiredFields) {
        if (-not $plugin.PSObject.Properties.Name.Contains($field) -or
            [string]::IsNullOrWhiteSpace([string]$plugin.$field)) {
            throw "$($plugin.InternalName): required field '$field' is missing or empty."
        }
    }

    if ($plugin.AssemblyVersion -notmatch '^\d+\.\d+\.\d+\.\d+$') {
        throw "$($plugin.InternalName): AssemblyVersion must contain four numeric components."
    }

    if ($plugin.DownloadLinkInstall -ne $plugin.DownloadLinkUpdate) {
        throw "$($plugin.InternalName): install and update links must match."
    }
}

$duplicateNames = $plugins |
    Group-Object -Property InternalName |
    Where-Object Count -gt 1
if ($duplicateNames) {
    throw "Duplicate InternalName values: $($duplicateNames.Name -join ', ')"
}

$repoCanonical = $plugins | ConvertTo-Json -Depth 20 -Compress
$legacyCanonical = $legacyPlugins | ConvertTo-Json -Depth 20 -Compress
if ($repoCanonical -cne $legacyCanonical) {
    throw 'repo.json and pluginmaster.json must contain identical plugin data.'
}

if ($CheckRemoteAssets) {
    $remoteErrors = @()
    foreach ($plugin in $plugins) {
        foreach ($url in @($plugin.IconUrl, $plugin.DownloadLinkInstall) | Select-Object -Unique) {
            try {
                $response = Invoke-WebRequest -Uri $url -Method Head -MaximumRedirection 5
                if ($response.StatusCode -lt 200 -or $response.StatusCode -ge 400) {
                    throw "HTTP $($response.StatusCode)"
                }
            }
            catch {
                $remoteErrors += "$($plugin.InternalName): $url ($($_.Exception.Message))"
            }
        }
    }

    if ($remoteErrors.Count -gt 0) {
        throw "Remote assets are unavailable:`n- $($remoteErrors -join "`n- ")"
    }
}

Write-Host "Validated $($plugins.Count) plugin(s)."
