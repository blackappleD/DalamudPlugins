[CmdletBinding()]
param(
    # 各插件源码仓库所在的父目录，默认与本仓库同级
    [string]$WorkspaceRoot = (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)),
    [switch]$AsJson
)

$ErrorActionPreference = 'Stop'
$sources = @(Get-Content -LiteralPath (Join-Path $PSScriptRoot 'upstream-sources.json') -Raw | ConvertFrom-Json)
$results = @()

foreach ($source in $sources) {
    $path = Join-Path $WorkspaceRoot $source.Directory
    $result = [ordered]@{
        InternalName = $source.InternalName
        Path         = $path
        Branch       = $source.Branch
        Dirty        = $false
        AheadOrigin  = 0
        BehindOrigin = 0
        Upstreams    = @()
        Error        = $null
    }

    try {
        if (-not (Test-Path -LiteralPath (Join-Path $path '.git'))) {
            throw "source repository not found: $path"
        }

        $currentBranch = (git -C $path branch --show-current).Trim()
        if ($currentBranch -ne $source.Branch) {
            throw "on branch '$currentBranch', expected '$($source.Branch)'"
        }

        # 只统计已跟踪文件的改动，未跟踪的构建产物不影响合并
        $result.Dirty = [bool](git -C $path status --porcelain --untracked-files=no)

        git -C $path fetch --quiet --no-tags origin
        if ($LASTEXITCODE -ne 0) {
            throw 'failed to fetch origin'
        }
        # 本地与 origin 不一致（有未推送或未拉取的提交）时，定时任务应跳过该插件
        $counts = (git -C $path rev-list --left-right --count "HEAD...origin/$($source.Branch)") -split '\s+'
        if ($LASTEXITCODE -ne 0) {
            throw "origin/$($source.Branch) not found"
        }
        $result.AheadOrigin = [int]$counts[0]
        $result.BehindOrigin = [int]$counts[1]

        foreach ($upstream in $source.Upstreams) {
            $remotes = @(git -C $path remote)
            if ($remotes -notcontains $upstream.Remote) {
                git -C $path remote add $upstream.Remote $upstream.Url
            }
            # 上游 tag 可能与 fork 自己的 tag 同名，不拉取 tag，改用 ls-remote 读取最新 tag
            git -C $path fetch --quiet --no-tags $upstream.Remote
            if ($LASTEXITCODE -ne 0) {
                throw "failed to fetch $($upstream.Remote)"
            }
            $latestTag = git -C $path ls-remote --tags --refs --sort=-v:refname $upstream.Remote |
                Select-Object -First 1 |
                ForEach-Object { ($_ -split 'refs/tags/')[1] }

            $ref = "$($upstream.Remote)/$($upstream.Branch)"
            $behind = git -C $path rev-list --count "HEAD..$ref"
            if ($LASTEXITCODE -ne 0) {
                throw "$ref not found"
            }
            $result.Upstreams += [ordered]@{
                Ref        = $ref
                Behind     = [int]$behind
                LatestTag  = $latestTag
                LastCommit = (git -C $path log -1 --format='%cs %h %s' $ref)
            }
        }
    }
    catch {
        $result.Error = $_.Exception.Message
    }

    $results += [pscustomobject]$result
}

if ($AsJson) {
    $results | ConvertTo-Json -Depth 5
    return
}

foreach ($result in $results) {
    $notes = @()
    if ($result.Dirty) { $notes += 'uncommitted changes' }
    if ($result.AheadOrigin -gt 0) { $notes += "ahead of origin by $($result.AheadOrigin)" }
    if ($result.BehindOrigin -gt 0) { $notes += "behind origin by $($result.BehindOrigin)" }
    $suffix = if ($notes) { " (SKIP: $($notes -join ', '))" } else { '' }
    foreach ($upstream in $result.Upstreams) {
        $state = if ($upstream.Behind -gt 0) { "BEHIND $($upstream.Behind)" } else { 'up to date' }
        Write-Host "$($result.InternalName) <- $($upstream.Ref): $state$suffix | tag $($upstream.LatestTag) | $($upstream.LastCommit)"
    }
    if ($result.Error) {
        Write-Host "[ERROR] $($result.InternalName): $($result.Error)" -ForegroundColor Red
    }
}
