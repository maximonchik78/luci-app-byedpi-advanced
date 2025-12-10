#!/bin/bash
# test-install.sh
echo "Тестирование установки..."

# 1. Проверка структуры
echo "1. Проверка структуры файлов:"
[ -f "install.sh" ] && echo "✓ install.sh" || echo "✗ install.sh"
[ -f "uninstall.sh" ] && echo "✓ uninstall.sh" || echo "✗ uninstall.sh"
[ -f "files/usr/sbin/byedpi-autodetect" ] && echo "✓ byedpi-autodetect" || echo "✗ byedpi-autodetect"
[ -f "luasrc/view/byedpi/autodetect.htm" ] && echo "✓ autodetect.htm" || echo "✗ autodetect.htm"

# 2. Проверка прав
echo -e "\n2. Проверка прав доступа:"
chmod +x install.sh 2>/dev/null && echo "✓ install.sh executable"
chmod +x uninstall.sh 2>/dev/null && echo "✓ uninstall.sh executable"

# 3. Проверка синтаксиса Lua
echo -e "\n3. Проверка синтаксиса Lua файлов:"
if command -v luac >/dev/null; then
    luac -p luasrc/controller/byedpi.lua && echo "✓ controller/byedpi.lua"
    luac -p luasrc/model/cbi/byedpi.lua && echo "✓ model/cbi/byedpi.lua"
fi

echo -e "\nТестирование завершено!"
