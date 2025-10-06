#!/system/bin/sh
# 安装脚本

MODDIR=${0%/*}

ui_print "=========================================="
ui_print " 小米15 Pro 亮屏快充模块"
ui_print " 适用于骁龙8 Elite处理器"
ui_print " 需要二次打包、修改、请@coolapk希望你问心无愧"
ui_print "=========================================="
ui_print ""

# 检测设备
DEVICE=$(getprop ro.product.device)
PROCESSOR=$(getprop ro.hardware)

ui_print "- 检测设备信息..."
ui_print "  设备: $DEVICE"
ui_print "  处理器: $PROCESSOR"
ui_print ""

# 警告信息
ui_print "⚠️  重要提示:"
ui_print "  1. 此模块会在充电时修改温控设置"
ui_print "  2. 拔掉充电器会自动恢复原始温控"
ui_print "  3. 不当设置可能影响电池寿命"
ui_print "  4. 建议温度不超过 50°C"
ui_print ""

# 设置权限
ui_print "- 设置文件权限..."
set_perm_recursive $MODDIR 0 0 0755 0644
set_perm $MODDIR/service.sh 0 0 0755
set_perm $MODDIR/uninstall.sh 0 0 0755
set_perm $MODDIR/config.conf 0 0 0644

# 创建日志目录
mkdir -p $MODDIR/logs

ui_print ""
ui_print "✓ 安装完成！"
ui_print ""
ui_print "📝 使用说明:"
ui_print "  1. 重启手机后模块自动生效"
ui_print "  2. 配置文件位于: $MODDIR/config.conf"
ui_print "  3. 修改 TEMP_LIMIT 可调整温控限制"
ui_print "  4. 默认充电时限制 45°C"
ui_print ""
ui_print "📖 查看日志:"
ui_print "  $MODDIR/fastcharge.log"
ui_print ""
ui_print "=========================================="