# DalamudPlugins

这是 `blackappleD` 维护的 Dalamud 国服自定义插件仓库。目前收录：

- [Ice's Cosmic Exploration (ICE)](https://github.com/blackappleD/Ices-Cosmic-Exploration)

## 添加仓库

仓库发布到 GitHub 后，在 Dalamud 中添加以下自定义仓库地址：

```text
https://raw.githubusercontent.com/blackappleD/DalamudPlugins/main/repo.json
```

路径：`Dalamud -> 插件安装器 -> 设置 -> 自定义插件仓库`。

`repo.json` 是插件仓库入口。

## 仓库结构

```text
.
|-- repo.json                 # 主插件目录
|-- icons/ice.png             # ICE 图标
|-- scripts/Test-Repository.ps1
`-- .github/workflows/validate.yml
```

## 发布 ICE

插件源码位于 `D:\workspace\Ices-Cosmic-Exploration`，远程仓库为
`blackappleD/Ices-Cosmic-Exploration`。版本号以 `ICE/ICE.csproj` 中的
`Version`、`AssemblyVersion` 和 `FileVersion` 为准，三者必须一致。

1. 在插件源码仓库完成改动并运行 Release 构建。
2. 创建 `v<版本号>` tag 和 GitHub Release。
3. 将构建产生的 `ICE.zip` 上传为 Release asset；文件名必须保持为 `ICE.zip`。
4. 修改 `repo.json` 中的 `AssemblyVersion`、`DownloadLinkInstall` 和
   `DownloadLinkUpdate`。
5. 运行本地校验，然后提交插件目录仓库。

```powershell
./scripts/Test-Repository.ps1
./scripts/Test-Repository.ps1 -CheckRemoteAssets
```

第一条命令验证 JSON 结构。第二条还会验证远程图标及 Release 下载链接，
应该在 GitHub Release 发布后运行。

## 版本规则

- 使用四段纯数字版本号：`A.B.C.D`。
- 已发布版本必须严格递增。
- 同步上游后，按 ICE 源码仓库中的维护规则决定本地修订号。
- `AssemblyVersion` 必须与 `ICE.zip` 内插件程序集的版本一致。

## 发布前检查

- [ ] ICE Release 构建成功。
- [ ] GitHub Release tag 为 `v<版本号>`。
- [ ] Release 中存在名为 `ICE.zip` 的资产。
- [ ] `repo.json` 中的版本和下载链接均已更新。
- [ ] `./scripts/Test-Repository.ps1 -CheckRemoteAssets` 通过。
- [ ] Dalamud 客户端可以安装并加载插件。
