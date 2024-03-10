# wise-crane
将多架构统一镜像高效的迁移至私有环境的镜像仓库例如Harbor，采用标准的docker命令非常复杂，谷歌因此推出了[Crane](https://github.com/google/go-containerregistry/tree/main/cmd/crane)开源小工具，非常便捷。

不过我们平常并不需要针对所有架构进行统一标签的处理，更多时候我们只关心x86/amd64和arm/aarch64两种架构。如果直接基于crane工具进行镜像转移，则会下载很多不必要的镜像层。

该程序基于谷歌容器镜像工具crane优化的脚本，针对只需要处理amd64和aarch64两种架构的场景。

![crane](https://github.com/wise2c-devops/wise-crane/assets/3273357/6bfe09ff-fd74-403c-88aa-9f265e64129c)

Usage: /usr/local/bin/mycrane.sh <pull|push|manifest> <registry_image|tarfile> [<tarfile|registry_image>]

e.g.: 

      /usr/local/bin/mycrane.sh pull grafana/grafana:10.4.0 grafana-10.4.0.tar

      /usr/local/bin/mycrane.sh push grafana-10.4.0.tar 192.168.0.1/library/grafana:10.4.0

      /usr/local/bin/mycrane.sh manifest 192.168.0.1/library/grafana:10.4.0

      /usr/local/bin/mycrane.sh manifest grafana-10.4.0.tar


命令用法：/usr/local/bin/mycrane.sh <pull|push|manifest> <镜像名|tar压缩包文件> [<tar压缩包文件|镜像名>]

例如：

      /usr/local/bin/mycrane.sh pull grafana/grafana:10.4.0 grafana-10.4.0.tar

      /usr/local/bin/mycrane.sh push grafana-10.4.0.tar 192.168.0.1/library/grafana:10.4.0

      /usr/local/bin/mycrane.sh manifest 192.168.0.1/library/grafana:10.4.0

      /usr/local/bin/mycrane.sh manifest grafana-10.4.0.tar

![Screenshot01](https://github.com/wise2c-devops/wise-crane/assets/3273357/98bebde2-3c60-488d-a2e8-f0591d8a7f6a)

![Screenshot02](https://github.com/wise2c-devops/wise-crane/assets/3273357/c35c82c0-c246-40d7-bfc0-cf9e3998de14)

![Screenshot03](https://github.com/wise2c-devops/wise-crane/assets/3273357/94ac69ba-30bd-4dea-a17f-00b61b9afa83)
