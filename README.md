# Инструкция по установке и настройке

## 1. Установка компонентов через веб-интерфейс:

   - Перейдите в раздел "Параметры системы" -> "Изменить набор компонентов"
   - Из подраздела "Пакеты OPKG" установите "Модули ядра для поддержки файловых систем", "Поддержка открытых пакетов"
   - Из подраздела "USB-накопители" установите "Файловая система Ext"

## 2. Установка Entware:

   - Отформатируйте флешку в формат Ext4
   - Вставьте флешку в роутер, она останется в роутере, на ней будет храниться Entware
   - Зайдите на неё как на сетевой диск через веб-интерфейс в разделе "Приложения"
   - Создайте папку `install` в корне флешки
   - Положите в эту папку инсталлятор `mipsel-installer.tar.gz`
   - В веб-интерфейсе выберите диск как накопитель в разделе "OPKG" и сохраните изменения
   - Далее пару минут будет происходить установка, можно открыть ещё одну страничку веб-интерфейса и перейти в раздел "Диагностика" -> "Журнал", чтобы наблюдать за ходом установки.
   - Убедитесь, что установка прошла успешно, в конце будет сообщение об успешной установке Entware и логин/пароль для захода через ssh в терминал, а не в интерпретатор команд CLI (по порту 222, а не 22), но если в компонентах SSH-сервер не установлен, то будет 22.

## 3. Размещение и настройка скриптов в директориях-триггерах

   - Поместите скрипты из папки opt так же, как они лежат в репозитории. Это можно сделать через веб-интерфейс, корень сетевого диска вставленной флешки - это и есть `/opt`.
   - Укажите ID интерфейса VPN в скрипте toggle_rerouting.sh (можно узнать в переменной при включении/выключении VPN, выведя его в лог роутера `logger $system_name` в скрипте)
   - Выполните следующие команды в терминале:
     ```
     opkg update && opkg upgrade
     opkg install nano bind-dig ipset iptables cron
     chmod +x /opt/etc/ndm/netfilter.d/fwmark.sh
     chmod +x /opt/etc/ndm/iflayerchanged.d/toggle_rerouting.sh
     chmod +x /opt/bin/recreate_ip_set.sh
     (crontab -l 2>/dev/null; echo "0 */12 * * * /opt/bin/recreate_ip_set.sh") | crontab -
     reboot
     ```
   - После этого роутер перезагрузится

## 4. Дополнение файла unblock.txt:

   - При изменении файла unblock.txt достаточно будет выключить и включить VPN в настройках роутера, если делать это вручную
   - Автоматически каждые 12 часов (можно сделать другое расписание, изменив запись в cron в пункте 3) из файла будет резолвиться новый набор IP для маршрутизации
   - С помощью скрипта domain_extractor.py можно собрать все домены, которые нужны для использования сайта. Используется Selenium на дефолтном профиле пользователя Google Chrome для сбора всех URL, с которых пришёл ответ на посланный клиентом запрос, а уникальные отфильтровываются.

## TODO
   - Инструкция для пользования скриптом domain_extractor.py c нуля
   - Полностью автоматизированная установка окружения для скрипта и рассовывания файлов/команд на роутере
   - Попробовать собирать все полученные пары домен:ip, чтобы затем можно было вытащить диапазоны/подсети, на которых возможно появление "плавающего" домена


