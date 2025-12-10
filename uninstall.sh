#!/bin/sh

# Скрипт удаления luci-app-byedpi-advanced

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}Удаление luci-app-byedpi-advanced...${NC}"

# Останавливаем сервис
if [ -x "/etc/init.d/byedpi" ]; then
    /etc/init.d/byedpi stop
    /etc/init.d/byedpi disable
    rm -f /etc/init.d/byedpi
    echo -e "${GREEN}✓ Сервис остановлен и удален${NC}"
fi

# Удаляем файлы LuCI
rm -f /usr/lib/lua/luci/controller/byedpi.lua
rm -f /usr/lib/lua/luci/model/cbi/byedpi.lua
rm -rf /usr/lib/lua/luci/view/byedpi
echo -e "${GREEN}✓ Файлы LuCI удалены${NC}"

# Удаляем скрипты
rm -f /usr/sbin/byedpi-autodetect
rm -f /usr/sbin/byedpi-manager
rm -f /usr/libexec/rpcd/byedpi
echo -e "${GREEN}✓ Скрипты удалены${NC}"

# Удаляем конфиги (оставляем резервную копию)
if [ -f "/etc/config/byedpi" ]; then
    mv "/etc/config/byedpi" "/etc/config/byedpi.backup.$(date +%s)"
    echo -e "${GREEN}✓ Конфиг перемещен в резервную копию${NC}"
fi

# Удаляем логи
rm -f /tmp/byedpi-autodetect.log
rm -f /var/log/byedpi.log

echo -e "${GREEN}✓ Удаление завершено!${NC}"
echo ""
echo "Примечание: ByeDPI (основная программа) не была удалена."
echo "Для полного удаления выполните: opkg remove byedpi"
