#!/system/bin/sh
# 卸载脚本 - 确保完全移除模块，无残留

MODDIR=${0%/*}
LOG_FILE="/data/local/tmp/fastcharge_uninstall.log"

log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_info "=== 开始卸载小米15 Pro 快充模块 ==="

# 停止所有相关进程
log_info "停止监控进程..."
killall -9 service.sh 2>/dev/null
pkill -f "fastcharge" 2>/dev/null

# 恢复备份的配置文件
log_info "恢复原始配置文件..."
if [ -d "$MODDIR" ]; then
    for backup in "$MODDIR"/*.bak; do
        if [ -f "$backup" ]; then
            original_name=$(basename "$backup" .bak)
            original_path="/vendor/etc/$original_name"
            
            if [ -f "$original_path" ]; then
                log_info "恢复: $original_path"
                cp -f "$backup" "$original_path"
                chmod 644 "$original_path"
            fi
        fi
    done
fi

# 恢复温控设置
log_info "恢复温控设置..."

# 重置温控节点为默认值
THERMAL_NODES=(
    "/sys/class/thermal/thermal_zone0/trip_point_0_temp"
    "/sys/class/thermal/thermal_zone1/trip_point_0_temp"
)

for node in "${THERMAL_NODES[@]}"; do
    if [ -w "$node" ]; then
        echo "45000" > "$node" 2>/dev/null
        log_info "重置温控节点: $node"
    fi
done

# 恢复电池温控
echo "45" > /sys/class/power_supply/battery/temp_warm 2>/dev/null

# 重启温控服务
log_info "重启温控服务..."
setprop vendor.sys.thermal.restart 1
stop vendor.thermal-engine
sleep 1
start vendor.thermal-engine

# 恢复充电限制为系统默认
log_info "恢复充电设置..."
echo 0 > /sys/class/power_supply/battery/input_suspend 2>/dev/null
echo 0 > /sys/class/qcom-battery/restricted_charging 2>/dev/null

# 清理日志文件
log_info "清理模块文件..."
rm -f "$MODDIR/fastcharge.log"
rm -f "$MODDIR"/*.bak
rm -f "$MODDIR/original_temp.bak"

# 清理临时文件
rm -f /data/local/tmp/fastcharge_*

log_info "=== 卸载完成！所有设置已恢复 ==="
log_info "建议重启手机以确保完全恢复"

# 显示通知（如果系统支持）
am broadcast -a android.intent.action.SHOW_TOAST \
    --es message "快充模块已卸载，建议重启手机" 2>/dev/null

# 保留卸载日志供用户查看
log_info "卸载日志已保存至: $LOG_FILE"