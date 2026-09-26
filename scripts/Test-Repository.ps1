[CmdletBinding()]
param(
    [switch]$CheckRemoteAssets
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$repoPath = Join-Path $root 'repo.json'
$maintainer = 'blackappleD'
# 在 upstream-sources.json 中登记了上游的插件是 fork，必须署名原作者；其余为自研插件
$forkNames = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'upstream-sources.json') -Raw |
    ConvertFrom-Json | ForEach-Object InternalName)

$repoText = Get-Content -LiteralPath $repoPath -Raw
$plugins = @($repoText | ConvertFrom-Json)

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

    # 署名必须包含维护者 blackappleD；fork 插件还必须包含原作者
    $authors = @($plugin.Author -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($authors -cnotcontains $maintainer) {
        throw "$($plugin.InternalName): Author must include '$maintainer'."
    }
    if ($forkNames -contains $plugin.InternalName -and
        @($authors | Where-Object { $_ -cne $maintainer }).Count -eq 0) {
        throw "$($plugin.InternalName): Author must also credit the original author(s)."
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
