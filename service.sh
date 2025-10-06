#!/system/bin/sh
# 快充服务脚本

MODDIR=${0%/*}
CONFIG_FILE="$MODDIR/config.conf"
LOG_FILE="$MODDIR/fastcharge.log"

# 日志函数
log_info() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
}

# 读取配置文件
load_config() {
    if [ -f "$CONFIG_FILE" ]; then
        . "$CONFIG_FILE"
    else
        # 默认配置
        TEMP_LIMIT=45
        SCREEN_ON_CHARGE=1
    fi
}

# 备份原始温控值
backup_thermal() {
    THERMAL_PATH="/sys/class/power_supply/battery"
    
    if [ -f "$THERMAL_PATH/temp" ]; then
        ORIGINAL_TEMP=$(cat "$THERMAL_PATH/temp" 2>/dev/null)
        echo "$ORIGINAL_TEMP" > "$MODDIR/original_temp.bak"
    fi
    
    # 备份小米温控配置
    THERMAL_CONFIGS=(
        "/vendor/etc/thermal-engine.conf"
        "/vendor/etc/thermal-engine-normal.conf"
        "/vendor/etc/thermal-engine-8elite.conf"
    )
    
    for cfg in "${THERMAL_CONFIGS[@]}"; do
        if [ -f "$cfg" ]; then
            cp -f "$cfg" "$MODDIR/$(basename $cfg).bak"
        fi
    done
}

# 启用亮屏快充
enable_screen_on_charge() {
    log_info "启用亮屏快充..."
    
    # 小米快充相关节点
    CHARGE_NODES=(
        "/sys/class/power_supply/battery/input_suspend"
        "/sys/class/power_supply/battery/constant_charge_current_max"
        "/sys/class/qcom-battery/restricted_charging"
        "/sys/class/power_supply/usb/pd_active"
    )
    
    # 解除充电限制
    echo 0 > /sys/class/power_supply/battery/input_suspend 2>/dev/null
    echo 0 > /sys/class/qcom-battery/restricted_charging 2>/dev/null
    
    # 允许最大充电电流
    echo 12000000 > /sys/class/power_supply/battery/constant_charge_current_max 2>/dev/null
    
    log_info "亮屏快充已启用"
}

# 修改温控限制
modify_thermal() {
    local temp_limit=$1
    log_info "设置温控限制为 ${temp_limit}°C"
    
    # 小米温控节点
    THERMAL_NODES=(
        "/sys/class/thermal/thermal_zone0/trip_point_0_temp"
        "/sys/class/thermal/thermal_zone1/trip_point_0_temp"
        "/sys/devices/virtual/thermal/thermal_zone*/trip_point_0_temp"
    )
    
    # 将温度限制转换为毫摄氏度（部分内核使用）
    local temp_millidegree=$((temp_limit * 1000))
    
    for node in "${THERMAL_NODES[@]}"; do
        if [ -w "$node" ]; then
            echo "$temp_millidegree" > "$node" 2>/dev/null
            log_info "已修改温控节点: $node"
        fi
    done
    
    # 修改电池温控
    echo "$temp_limit" > /sys/class/power_supply/battery/temp_warm 2>/dev/null
}

# 恢复原始温控
restore_thermal() {
    log_info "恢复原始温控设置..."
    
    if [ -f "$MODDIR/original_temp.bak" ]; then
        ORIGINAL_TEMP=$(cat "$MODDIR/original_temp.bak")
    fi
    
    # 恢复备份的配置文件
    for backup in "$MODDIR"/*.bak; do
        if [ -f "$backup" ]; then
            original_name=$(basename "$backup" .bak)
            cp -f "$backup" "/vendor/etc/$original_name" 2>/dev/null
        fi
    done
    
    # 重启温控服务
    setprop vendor.sys.thermal.restart 1
    
    log_info "温控已恢复"
}

# 监控充电状态
monitor_charging() {
    local prev_status=""
    
    while true; do
        # 获取充电状态
        local charge_status=$(cat /sys/class/power_supply/battery/status 2>/dev/null)
        
        if [ "$charge_status" = "Charging" ] || [ "$charge_status" = "Fast" ]; then
            if [ "$prev_status" != "charging" ]; then
                log_info "检测到充电，应用快充设置..."
                backup_thermal
                enable_screen_on_charge
                modify_thermal "$TEMP_LIMIT"
                prev_status="charging"
            fi
        else
            if [ "$prev_status" = "charging" ]; then
                log_info "检测到拔出充电器，恢复原始设置..."
                restore_thermal
                prev_status="discharging"
            fi
        fi
        
        sleep 5
    done
}

# 主函数
main() {
    log_info "=== 小米15 Pro 快充模块启动 ==="
    
    # 等待系统启动完成
    while [ "$(getprop sys.boot_completed)" != "1" ]; do
        sleep 2
    done
    
    log_info "系统启动完成，加载配置..."
    load_config
    
    log_info "配置加载完成: 温控=${TEMP_LIMIT}°C, 亮屏快充=${SCREEN_ON_CHARGE}"
    
    # 启动监控
    monitor_charging &
}

# 执行主函数
main