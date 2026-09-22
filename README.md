# DalamudPlugins

这是 `blackappleD` 维护的 Dalamud 国服自定义插件仓库。目前收录：

| 插件 | InternalName | 源码仓库 | Release tag 格式 | Release 资产名 |
|------|--------------|----------|------------------|----------------|
| Ice's Cosmic Exploration (ICE) | `ICE-bld` | [blackappleD/Ices-Cosmic-Exploration](https://github.com/blackappleD/Ices-Cosmic-Exploration) | `v<版本号>` | `ICE.zip` |
| Allagan Market（国服维护版） | `AllaganMarket-bld` | [blackappleD/AllaganMarket-CN](https://github.com/blackappleD/AllaganMarket-CN) | `v<版本号>` | `AllaganMarket-bld.zip` |
| AutoDuty（国服维护版） | `AutoDuty-bld` | [blackappleD/AutoDuty](https://github.com/blackappleD/AutoDuty) | `<版本号>` | `AutoDuty-bld.zip` |
| GatherBuddy Reborn（国服维护版） | `GatherBuddyReborn-bld` | [blackappleD/GatherBuddyReborn](https://github.com/blackappleD/GatherBuddyReborn) | `<版本号>` | `GatherbuddyReborn.zip` |

各插件当前版本以 [repo.json](repo.json) 中的 `AssemblyVersion` 为准。

## 添加仓库

在 Dalamud 中添加以下自定义仓库地址：

```text
https://raw.githubusercontent.com/blackappleD/DalamudPlugins/main/repo.json
```

路径：`Dalamud -> 插件安装器 -> 设置 -> 自定义插件仓库`。

`repo.json` 是插件仓库入口。

## 仓库结构

```text
.
|-- repo.json                 # 主插件目录
|-- icons/ice.png             # ICE 图标（其余插件图标使用外部链接）
|-- scripts/Test-Repository.ps1
`-- .github/workflows/validate.yml
```

## 发布新版本

各插件源码在对应的 fork 仓库中维护（见上表）。版本号以插件工程文件
（`.csproj`）中的 `Version`、`AssemblyVersion` 和 `FileVersion` 为准，三者必须一致。

1. 在插件源码仓库完成改动并运行 Release 构建。
2. 按上表的 tag 格式创建 tag 和 GitHub Release。
3. 将构建产物上传为 Release asset；文件名必须与上表的资产名一致。
4. 修改 `repo.json` 中对应插件的 `AssemblyVersion`、`DownloadLinkInstall` 和
   `DownloadLinkUpdate`（如有 `Changelog` 也一并更新）。
5. 运行本地校验，然后提交本仓库。

```powershell
./scripts/Test-Repository.ps1
./scripts/Test-Repository.ps1 -CheckRemoteAssets
```

第一条命令验证 JSON 结构。第二条还会验证远程图标及 Release 下载链接，
应该在 GitHub Release 发布后运行。

## 版本规则

- 使用四段纯数字版本号：`A.B.C.D`。
- 已发布版本必须严格递增。
- 同步上游后，按各插件源码仓库中的维护规则决定本地修订号。
- `repo.json` 中的 `AssemblyVersion` 必须与 Release 资产内插件程序集的版本一致。

## 发布前检查

- [ ] 插件 Release 构建成功。
- [ ] GitHub Release tag 符合该插件的 tag 格式。
- [ ] Release 中存在名称正确的 zip 资产。
- [ ] `repo.json` 中的版本和下载链接均已更新。
- [ ] `./scripts/Test-Repository.ps1 -CheckRemoteAssets` 通过。
- [ ] Dalamud 客户端可以安装并加载插件。
