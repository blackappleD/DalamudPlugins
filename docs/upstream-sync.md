# 上游同步与发布流程

本文件是每日上游同步定时任务的操作手册，也可用于手动同步。各插件的上游地址、版本规则、
tag 格式和发布方式统一记录在 [scripts/upstream-sources.json](../scripts/upstream-sources.json)。
插件源码仓库默认放在本仓库的同级目录（例如 `D:\workspace\AutoDuty`）。

## 1. 检查上游

```powershell
./scripts/Get-UpstreamStatus.ps1
```

脚本会补齐缺失的上游 remote，拉取 `origin` 与各上游分支（不拉取上游 tag，避免与 fork 的
tag 冲突），并输出每个插件落后上游的提交数和上游最新 tag。全部为 `up to date` 时本次无需处理；
带 `SKIP` 标记的插件按下文跳过条件处理。

`tag` 列仅供参考，部分上游的 tag 与程序集版本不是同一套编号。计算新版本时，上游版本以
`upstream/<分支>` 最新提交中的 `VersionFile`（或插件清单）为准；只有 AutoDuty 以上游 Release tag 为准。

## 2. 跳过条件

遇到以下情况时跳过该插件并在报告中说明原因，不要强行处理：

- 当前不在配置的分支上，或已跟踪文件有未提交改动（可能是维护者正在进行的工作）。
- 本地分支领先 `origin`（有未推送的提交），或落后 `origin`（脚本输出中的 `SKIP` 标记）。
- 合并冲突无法有把握地解决，或解决后构建失败。

## 3. 合并上游

```powershell
git fetch upstream --no-tags
git merge --no-ff upstream/<分支>
```

- 只用 `merge`，不使用 rebase、cherry-pick 或 force push；永远不要推送到上游。
- 解决冲突时保留 fork 的定制内容：`-bld` InternalName 与清单文件名、`Author` 中的
  `blackappleD`、中文本地化、fork 自己的 release workflow 与版本规则、已有的功能修复。
  上游的新功能与修复应完整保留。
- 无法确定的冲突执行 `git merge --abort` 并跳过。
- 插件有中文本地化时，为上游新增的用户可见文案补充简体中文（有繁中文件的一并补充）。
- 只暂存本次涉及的文件（`git add <文件>` 或 `git add -u`），不要提交工作区里未跟踪的构建产物。

## 4. 构建验证

```powershell
dotnet build <项目 csproj> -c Release
```

构建必须成功，且 `bin/Release/<InternalName>/latest.zip` 已生成，才能继续发布。

## 5. 版本号与发布

1. 按 `upstream-sources.json` 中该插件的 `VersionRule` 计算新版本：上游版本升级时按规则
   重置本地修订号，否则本地修订号 +1。新版本必须严格大于 `repo.json` 中当前的
   `AssemblyVersion`。
2. 有 `VersionFile` 的插件更新版本文件，提交 `chore: bump version to <版本>`。
3. `git push origin <分支>`。
4. 按 `Release` 字段发布：
   - 由 tag 触发的 workflow：推送 `TagFormat` 格式的 tag，然后用 `gh run watch` 等待完成。
   - AutoDuty：`gh release create <tag> --generate-notes` 触发 publish workflow 上传资产。
   - 本地构建上传（Saucy、BlueMageHelper）：将 `latest.zip` 复制为 `Asset` 名称后执行
     `gh release create <tag> <资产> --title "<tag> — 国服维护版" --generate-notes`。
5. 用 `gh release view <tag> --json assets` 确认 Release 中存在正确名称的资产。

## 6. 更新插件仓库

1. 修改 `repo.json` 中该插件的 `AssemblyVersion`、`DownloadLinkInstall`、`DownloadLinkUpdate`。
2. 运行校验：

   ```powershell
   ./scripts/Test-Repository.ps1 -CheckRemoteAssets
   ```

3. 提交 `chore: bump <InternalName> to <版本>`（多个插件合并为一次提交），推送 `main`。

## 署名规则

`repo.json` 与各插件清单中的 `Author` 必须同时包含原作者和 `blackappleD`，
`Test-Repository.ps1` 会校验 `repo.json` 中的署名（区分大小写）。插件清单中的 `Author`
不在本仓库 CI 的校验范围内，修改署名时需要与 `repo.json` 同步更新；合并上游后也要确认清单中的署名没有被覆盖。
