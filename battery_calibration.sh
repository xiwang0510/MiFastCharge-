#!/system/bin/sh
# 电量校准工具 - 手动执行电量校准

MODDIR="/data/adb/modules/xiaomi15pro_fastcharge"

echo "=========================================="
echo "  小米15 Pro 电量校准工具"
echo "=========================================="
echo ""

# 检查Root权限
if [ "$(id -u)" != "0" ]; then
    echo "❌ 错误: 需要Root权限！"
    echo "请使用: su -c sh battery_calibration.sh"
    exit 1
fi

# 读取当前系统电量
echo "📊 读取电量信息..."
SYSTEM_CAP=$(cat /sys/class/power_supply/battery/capacity 2>/dev/null)
echo "   系统显示电量: ${SYSTEM_CAP}%"

# 读取真实电量（多种方法）
echo ""
echo "🔍 检测真实电量..."

# 方法1: Fuel Gauge芯片
if [ -f "/sys/class/power_supply/bms/capacity_raw" ]; then
    FG_CAP=$(cat /sys/class/power_supply/bms/capacity_raw)
    echo "   [Fuel Gauge] ${FG_CAP}%"
fi

# 方法2: 电压计算
VOLTAGE=$(cat /sys/class/power_supply/battery/voltage_now 2>/dev/null)
if [ -n "$VOLTAGE" ]; then
    VOLTAGE_MV=$((VOLTAGE / 1000))
    # 简化的电压-电量映射
    if [ "$VOLTAGE_MV" -ge 8800 ]; then
        VOLTAGE_CAP=100
    elif [ "$VOLTAGE_MV" -le 6000 ]; then
        VOLTAGE_CAP=0
    else
        VOLTAGE_CAP=$(( (VOLTAGE_MV - 6000) * 100 / 2800 ))
    fi
    echo "   [电压] ${VOLTAGE_MV}mV -> ${VOLTAGE_CAP}%"
fi

# 方法3: 库仑计数
CHARGE_FULL=$(cat /sys/class/power_supply/battery/charge_full 2>/dev/null)
CHARGE_NOW=$(cat /sys/class/power_supply/battery/charge_now 2>/dev/null)
if [ -n "$CHARGE_FULL" ] && [ -n "$CHARGE_NOW" ] && [ "$CHARGE_FULL" -gt 0 ]; then
    COULOMB_CAP=$(( CHARGE_NOW * 100 / CHARGE_FULL ))
    echo "   [库仑计] ${COULOMB_CAP}% (${CHARGE_NOW}/${CHARGE_FULL})"
fi

# 确定真实电量（优先使用Fuel Gauge）
if [ -n "$FG_CAP" ]; then
    REAL_CAP=$FG_CAP
    METHOD="Fuel Gauge"
elif [ -n "$COULOMB_CAP" ]; then
    REAL_CAP=$COULOMB_CAP
    METHOD="库仑计"
elif [ -n "$VOLTAGE_CAP" ]; then
    REAL_CAP=$VOLTAGE_CAP
    METHOD="电压"
else
    echo ""
    echo "❌ 无法读取真实电量！"
    exit 1
fi

echo ""
echo "✓ 真实电量: ${REAL_CAP}% (来源: ${METHOD})"

# 计算偏差
DIFF=$((REAL_CAP - SYSTEM_CAP))
if [ "$DIFF" -lt 0 ]; then
    DIFF_ABS=$((-DIFF))
else
    DIFF_ABS=$DIFF
fi

echo "   偏差: ${DIFF}% (绝对值: ${DIFF_ABS}%)"

# 判断是否需要校准
echo ""
if [ "$DIFF_ABS" -le 2 ]; then
    echo "✅ 电量准确，无需校准！"
    exit 0
elif [ "$DIFF_ABS" -le 5 ]; then
    echo "⚠️  电量有轻微偏差，建议校准"
else
    echo "❌ 电量偏差较大，强烈建议校准！"
fi

# 询问是否执行校准
echo ""
echo -n "是否立即执行校准？(y/n): "
read -r ANSWER

if [ "$ANSWER" != "y" ] && [ "$ANSWER" != "Y" ]; then
    echo "已取消校准"
    exit 0
fi

# 执行校准
echo ""
echo "🔧 开始校准..."

# 步骤1: 更新系统电量显示
echo "   [1/4] 更新系统电量..."
echo "$REAL_CAP" > /sys/class/power_supply/battery/capacity 2>/dev/null
setprop sys.battery.capacity "$REAL_CAP"
sleep 1

# 步骤2: 重置电量计芯片
echo "   [2/4] 重置电量计芯片..."
echo 1 > /sys/class/power_supply/bms/device/fg_reset 2>/dev/null
sleep 1

# 步骤3: 清除电池统计
echo "   [3/4] 清除电池统计缓存..."
dumpsys battery reset 2>/dev/null
dumpsys batterystats --reset 2>/dev/null
sleep 1

# 步骤4: 通知系统更新
echo "   [4/4] 通知系统更新..."
am broadcast -a android.intent.action.BATTERY_CHANGED \
    --ei level "$REAL_CAP" --ei scale 100 2>/dev/null

# 强制刷新状态栏
dumpsys battery set level "$REAL_CAP" 2>/dev/null
sleep 1
dumpsys battery reset 2>/dev/null

echo ""
echo "✅ 校准完成！"
echo ""
echo "📝 校准后信息:"
echo "   原电量: ${SYSTEM_CAP}%"
echo "   新电量: ${REAL_CAP}%"
echo "   调整: ${DIFF}%"
echo ""
echo "💡 建议:"
echo "   1. 如果仍显示错误，请重启手机"
echo "   2. 为获得最佳效果，建议充满电后再校准一次"
echo "   3. 定期（每周）运行此工具保持电量准确"
echo ""
echo "=========================================="