# vmmanager6_firewall
Скрипт настройки фаервола для отдельной VM в VMmanager 6

Запускать нужно на узле, где расположена VM

## Список правил
Скрипт позволяет посмотреть правила nftables для VM (чтобы посмотреть имя vm, запустите на узле команду `virsh list`)
`./firewall.sh <vm_name> list`

## Удалить правило
Чтобы удалить правило по номеру handle из списка выше

`./firewall.sh <vm_name> remove <handle_id>`

## Добавить правило
Чтобы добавить правило, запустите с параметрами

`./firewall.sh <vm_name> add --direction in|out [--ports <ports>] [--ip <ip>]`

Для направления `in` добавляется правило, запрещающее подключение на виртуальную машину с указанных ip адресов на указанные порты. 

Для направления `out` добавляется правило, запрещающее подключение с виртуальной машины на указанный ip и на указанные порты.

Если не указать порт, то будут заблокированы все порты. 

Если не указать ip, то будут заблокированы все ip.