# beget_yaml
Скрипт для установки расширения [PHP YAML](http://php.net/manual/ru/book.yaml.php) на сервере хостинг-провайдера BeGet. Для установки расширения необходимо в корне аккаунта зайти в [виртуальное окружение](https://beget.com/ru/articles/webapp_main) и выполнить следующую команду, указав название папки сайта, которому требуются расширение и версию PHP, с которой работает сайт:
```
curl -sO https://raw.githubusercontent.com/denyev/beget_yaml/master/beget_yaml.sh && bash beget_yaml.sh <папка_сайта> <версия_php>
```

