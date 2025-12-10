#!/bin/sh

# Скрипт удаления luci-app-byedpi-advanced

set -e

echo "========================================"
echo "Удаление luci-app-byedpi-advanced"
echo "========================================"

# Останавливаем сервис
if [ -x "/etc/init.d/byedpi" ]; then
    echo "Останавливаю сервис ByeDPI..."
    /etc/init.d/byedpi stop >/dev/null 2>&1 || true
    /etc/init.d/byedpi disable >/dev/null 2>&1 || true
    rm -f /etc/init.d/byedpi
    echo "Сервис остановлен и удален"
fi

# Удаляем файлы LuCI
echo "Удаляю файлы LuCI..."
rm -f /usr/lib/lua/luci/controller/byedpi.lua 2>/dev/null || true
rm -f /usr/lib/lua/luci/model/cbi/byedpi.lua 2>/dev/null || true
rm -rf /usr/lib/lua/luci/view/byedpi 2>/dev/null || true
echo "Файлы LuCI удалены"

# Удаляем скрипты
echo "Удаляю скрипты..."
rm -f /usr/sbin/byedpi-autodetect 2>/dev/null || true
rm -f /usr/sbin/byedpi-manager 2>/dev/null || true
rm -f /usr/libexec/rpcd/byedpi 2>/dev/null || true
echo "Скрипты удалены"

# Удаляем конфиги (оставляем резервную копию)
if [ -f "/etc/config/byedpi" ]; then
    echo "Сохраняю резервную копию конфига..."
    cp "/etc/config/byedpi" "/etc/config/byedpi.backup.$(date +%s)"
    rm -f "/etc/config/byedpi"
    echo "Конфиг перемещен в резервную копию"
fi

# Удаляем директории
echo "Удаляю директории..."
rm -rf /etc/byedpi 2>/dev/null || true
rm -rf /var/log/byedpi 2>/dev/null || true

# Удаляем логи
echo "Очищаю логи..."
rm -f /tmp/byedpi-autodetect.log 2>/dev/null || true
rm -f /tmp/byedpi-detection.log 2>/dev/null || true

echo ""
echo "========================================"
echo "Удаление завершено!"
echo "========================================"
echo ""
echo "Примечание:"
echo "1. ByeDPI (основная программа) не была удалена"
echo "2. Резервная копия конфига сохранена: /etc/config/byedpi.backup.*"
echo ""
echo "Для полного удаления выполните:"
echo "  opkg remove byedpi"
echo ""
