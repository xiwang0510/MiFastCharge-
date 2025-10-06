米系快充模块
暂时适用于小米15 Pro（骁龙8 Elite处理器）的Magisk模块，实现亮屏快充和智能温控管理。
✨ 功能特性

✅ 亮屏快充：解除亮屏充电限制，屏幕开启时也能快速充电
✅ 智能温控：充电时临时调整温控限制，拔掉充电器自动恢复
✅ 真实电量显示：从电量计芯片读取真实电量，解决跳电问题
✅ 自动校准：充电时自动校准电量，保持显示准确
✅ 灵活配置：可自定义温度限制，满足不同需求
✅ 完全卸载：卸载时自动恢复所有设置，无残留文件
✅ 实时监控：自动检测充电状态，动态调整参数

📦 模块结构
xiaomi15pro_fastcharge/
├── module.prop          # 模块信息
├── service.sh           # 后台服务脚本（核心功能）
├── install.sh           # 安装脚本
├── uninstall.sh         # 卸载脚本
├── config.conf          # 配置文件（可自定义）
└── README.md            # 说明文档
🚀 安装步骤

下载模块：将所有文件打包为 ZIP 格式
刷入模块：在 Magisk Manager 中选择 "从本地安装"
重启手机：模块会在重启后自动生效
验证效果：插入充电器测试亮屏快充

⚙️ 配置说明
编辑 /data/adb/modules/xiaomi15pro_fastcharge/config.conf 文件：
bash# 充电时的温度限制（单位：摄氏度）
TEMP_LIMIT=45

# 是否启用亮屏快充（1=启用，0=禁用）
SCREEN_ON_CHARGE=1
温度建议
温度设置适用场景风险等级40-42°C日常使用，更安全⭐ 低43-45°C平衡性能与安全（推荐）⭐⭐ 中46-50°C追求极限充电速度⭐⭐⭐ 高
⚠️ 警告：温度设置过高可能影响电池寿命！
📊 工作原理

启动监控：系统启动后，模块自动运行后台服务
检测充电：每5秒检测一次充电状态
应用设置：

插入充电器：启用亮屏快充 + 临时修改温控
拔出充电器：自动恢复原始温控设置


日志记录：所有操作记录在日志文件中

📝 查看日志
bash# 通过 ADB 查看日志
adb shell cat /data/adb/modules/xiaomi15pro_fastcharge/fastcharge.log

# 或在终端模拟器中查看
su
cat /data/adb/modules/xiaomi15pro_fastcharge/fastcharge.log
🗑️ 卸载模块
方法一：Magisk Manager（推荐）

打开 Magisk Manager
找到 "小米15 Pro 亮屏快充模块"
点击卸载
重启手机

方法二：手动卸载
bashsu
sh /data/adb/modules/xiaomi15pro_fastcharge/uninstall.sh
reboot
卸载后会：

✅ 停止所有后台进程
✅ 恢复原始温控配置
✅ 删除所有临时文件
✅ 清理备份文件
✅ 重启温控服务

⚠️ 注意事项

仅适用于小米15 Pro：其他机型未测试，可能无效或有风险
需要Root权限：必须安装 Magisk 并获取 Root 权限
温度设置需谨慎：建议不超过 50°C
可能影响保修：修改系统文件可能影响保修
定期检查电池：使用后注意观察电池健康度

🔧 故障排除
问题1：模块安装后无效果

检查是否已重启手机
确认 Magisk 版本是否支持（建议 v24.0+）
查看日志文件排查错误

问题2：充电速度没有提升

确认使用原装充电器和数据线
检查 config.conf 中 SCREEN_ON_CHARGE 是否为 1
查看日志确认模块是否正常运行

问题3：手机发热严重

降低 TEMP_LIMIT 值（如改为 40°C）
避免边充电边玩游戏
考虑在通风环境下充电

问题4：卸载后设置未恢复

手动执行：sh /data/adb/modules/xiaomi15pro_fastcharge/uninstall.sh
重启温控服务：setprop vendor.sys.thermal.restart 1
