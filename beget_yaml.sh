#! /usr/bin/env bash

# check docker

if [[ $(grep -c docker /proc/self/cpuset) == 0 ]]; then
    echo -e "\e[32mCome to Docker, please. Use the following command\e[0m"
    echo -e "\e[32mssh localhost -p 222\e[0m"
    exit 1
fi

# check homedir

if [[ `pwd` != ${HOME} ]];
    then
    echo -e "run ONLY in home dir as ${HOME}\n"
    exit 1
fi

usage(){
    echo -e "Usage:   $0 sitename phpversion"
    echo -e "Example: $0 beget.ru 5.5"
    exit 1
}

test $# != 2  && usage

SITE_PATH=$(readlink -f $(echo $1 | sed -e "s/\/.*//g"))
CGI_BIN="$SITE_PATH/public_html/cgi-bin"
PHP_INI="$SITE_PATH/public_html/cgi-bin/php.ini"
PHP_VERSION=$2

test ! -d $1 && { echo -e 'NO SUCH SITE\n'; usage; }
test ! -f /usr/local/php-cgi/$PHP_VERSION/bin/phpize && { echo -e 'NO SUCH PHP VERSION\n'; usage; }

mkdir -p ${HOME}/.beget/tmp
mkdir -p ${HOME}/.local
mkdir -p $CGI_BIN

## libyaml

TMP_LIBYAML=${HOME}/.beget/tmp/libyaml
test -d $TMP_LIBYAML && { echo -e "\e[34m$TMP_LIBYAML has been removed\e[0m"; rm -rf $TMP_LIBYAML; }
mkdir -p $TMP_LIBYAML && \
cd $TMP_LIBYAML && \
wget http://pyyaml.org/download/libyaml/yaml-0.1.6.tar.gz && \
tar -xf yaml-0.1.6.tar.gz && \
cd yaml-0.1.6 && \
./configure --prefix=${HOME}/.local/lib/php/$PHP_VERSION/libyaml && \
make -s -j4 && make install > /dev/null && touch .installed

test ! -f .installed && { echo -e "\e[31mlibyaml make install failed\e[0m"; exit 1; }

rm -rf $TMP_LIBYAML

## php yaml

TMP_YAML=${HOME}/.beget/tmp/yaml
test -d $TMP_YAML && { echo -e "\e[34m$TMP_YAML has been removed\e[0m"; rm -rf $TMP_YAML; }
mkdir -p $TMP_YAML && cd $TMP_YAML && \
wget http://pecl.php.net/get/yaml-1.2.0.tgz && \
tar -xf yaml-1.2.0.tgz && \
cd yaml-1.2.0 && \
/usr/local/php-cgi/$PHP_VERSION/bin/phpize && \
./configure  --prefix=${HOME}/.local/lib/php/$PHP_VERSION/yaml \
             --with-yaml=${HOME}/.local/lib/php/$PHP_VERSION/libyaml \
             --with-php-config=/usr/local/php-cgi/$PHP_VERSION/bin/php-config && \
make -s -j4 && cp -v modules/yaml.so $CGI_BIN/ && touch .installed

test ! -f .installed && { echo -e "\e[31myaml make install failed\e[0m"; exit 1; }

rm -rf $TMP_YAML

##  php.ini
##  TODO Нужно сделать проверку на версию PHP в файле php.ini

test -e $PHP_INI || cp -v /usr/local/php-cgi/$PHP_VERSION/php.ini $CGI_BIN && \

if ! grep -q "extension = $SITE_PATH/public_html/cgi-bin/yaml.so" $PHP_INI; then
    echo -e "[PHP]\nextension = $SITE_PATH/public_html/cgi-bin/yaml.so" | tee -a $PHP_INI
fi

##  check_yaml

cat > $SITE_PATH/public_html/check_yaml.php <<_EOF
<?php
\$message = '';
\$yaml_info = '';
\$style_center = '.center {margin-top: 5%; margin-left: 5%;}';
if (extension_loaded('yaml'))
{
    \$style_center = '.center {text-align: center; margin-top: 10%;}';
    \$yaml_info = new ReflectionExtension('yaml');
    \$yaml_info->info();
}
elseif (stat('${HOME}/.local/lib/php/$PHP_VERSION') == FALSE)
{
    \$message  = '<p>Необходимо предоставить <em>общий доступ</em> к директории <strong>.local</strong>, которая находится в корне аккаунта.</p>';
    \$message .= '<p>Это можно сделать с помощью <a href="https://fm-new.beget.ru/" target="_blank">файлового менеджера</a>.</p>';
    \$message .= '<ul>Зайдите в папку <strong>.local</strong> и нажмите на следующие кнопки:</ul>';
    \$message .= '<li>Инструменты</li>';
    \$message .= '<li>Настроить общий доступ к текущей директории</li>';
    \$message .= '<li>Чтение и запись</li>';
    \$message .= '<li>Включая вложенные папки</li>';
    \$message .= '<li>Открыть доступ</li>';
}
elseif (substr(php_sapi_name(), 0, 3) !== 'cgi')
{
    \$message  = "<p>Необходимо, чтобы PHP для домена <em>\$_SERVER[HTTP_HOST]</em> работал <em>в режиме CGI</em>.</p>";
    \$message .= '<p>Его можно включить, обратившись в техническую поддержку.</p>';
    \$message .= '<p>Напишите, пожалуйста, <a href="https://cp.beget.ru/support" target="_blank">тикет</a> и скопируйте в него данное сообщение.</p';
}
elseif (FALSE)
{
    \$message = 'dummy';
}
else
{
    \$message = "Что-то пошло не так :(";
}
?>
<!DOCTYPE html>
<html lang="ru">
    <head>
        <meta charset="utf-8">
        <title>YAML | Проверка работы расширения</title>
        <style type="text/css">
            body, td, th, h1, h2 {font-family: sans-serif;}
            a:hover {text-decoration: underline;}
            table {border-collapse: collapse;}
<?php
            echo \$style_center . PHP_EOL;
?>
            .center table { margin-left: auto; margin-right: auto; text-align: left;}
            .center th { text-align: center !important; }
            td, th { border: 1px solid #000000; font-size: 75%; vertical-align: baseline;}
            h2 {font-size: 125%;}
            .e {background-color: #ccccff; font-weight: bold; color: #000000;}
            .h {background-color: #9999cc; font-weight: bold; color: #000000;}
            .v {background-color: #cccccc; color: #000000;}
        </style>
    </head>
    <body class="center">
        <div class="center">
<?php
echo \$message . PHP_EOL;
?>
        </div>
    </body>
</html>
_EOF

echo -e "\e[32myaml make install completed\e[0m"
echo -e "\e[32mhttp://$(echo $1 | sed -e "s/\/.*//g")/check_yaml.php\e[0m"
exit 0
