#!/bin/sh

function check_ip() {
    local IP=$1
    VALID_CHECK=$(echo $IP|awk -F. '$1<=255&&$2<=255&&$3<=255&&$4<=255{print "yes"}')
    if echo $IP|grep -E "^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$" >/dev/null; then
        if [ $VALID_CHECK == "yes" ]; then
            return 0
        else
            echo "IP $IP 错误!"
            return 1
        fi
    else
        echo "IP 错误!"
        return 1
    fi
}
while true; do
    read -p "请输入Tars服务器IP: " IP
    check_ip $IP
    [ $? -eq 0 ] && break
done

do_type=$1

tars_type=$2

project_name=$3

local_ip=$IP


if [ "$do_type" != "install" ] && [ "$do_type" != "update" ];then
	echo "ERROR: ${tars_type} 第一个参数为安装还是更新，请填（install/update）"
	exit 0
fi

if [ "$do_type" == "update" ];then
    old_tars_path=${tars_type}"/tars"
    old_src_path=${tars_type}"/src/servant"
    oid_script=$tars_type"/script"

    if [ -d "$old_tars_path"];then
        echo "tars文件夹,不存在请先install"
        exit 0
    fi

    if [ -d "$old_src_path"];then
        echo "/src/servant文件夹,不存在请先install"
        exit 0
    fi

    if [ -d "$oid_script"];then
        echo "script文件夹,不存在,请先install"
        exit 0
    fi
    
    if [ -f "$old_tars_path/${appName}Service.tars"];then
        currentTimeStamp=`date "+%Y%m%d%H%M%S"` 
        mv $old_tars_file_path ${tars_type}/tars/${appName}Service.${currentTimeStamp}.tars
    fi
    cp impl.tars ./${tars_type}/tars/${appName}Service.tars

    proto_php_name="tars.proto.php"
    php ../src/vendor/phptars/tars2php/src/tars2php.php ./${proto_php_name}
    exit 0
fi


appName=`echo "$project_name" | awk '{for (i=1;i<=NF;i++)printf toupper(substr($i,0,1))substr($i,2,length($i))" ";printf "\n"}' `
appName=`echo "$appName" | sed 's/ //g'`

if [ "$tars_type" != "server" ] && [ "$tars_type" != "client" ];then
	echo "ERROR: ${tars_type} 第二个参数为服务类型，请填（server/client）"
	exit 0
fi

if [ ! -n "$project_name" ];then
	echo '请输入项目名'
	exit 0
fi

if [ -d "$tars_type" ];then
	echo $tars_type"文件夹已经存在"
	exit 0
fi

if [ ! -n "$local_ip" ];then
	echo '请输入参数3 ip'
	exit 0
fi

if [ -d "impl.tars" ];then
	echo "请先定义impl.tars文件"
	exit 0
fi

class_name=`cat impl.tars | grep interface | awk '{print $NF}' | grep -Eo "\<[[:alnum:]_]+\>"`

if [ ! -n "$class_name" ];then
	echo 'impl.tar文件内容错误'
	exit 0
fi


mkdir $tars_type
mkdir -p $tars_type"/src"
mkdir -p $tars_type"/script"
mkdir -p $tars_type"/tars"
mkdir -p $tars_type"/src/service"
mkdir -p $tars_type"/src/model"
mkdir -p $tars_type"/src/traits"

cp impl.tars ./${tars_type}/tars/${appName}Service.tars

proto_php_name="tars.proto.php"
with_servant=true
namespace="Server"

if [ "$tars_type" == "client" ];then
	with_servant="false"
	proto_php_name="tarsClient.proto.php"
	namespace=${appName}"ClientServer"
	
	client_proto_php_path=$tars_type"/tars/tars.proto.php"
	touch $client_proto_php_path
cat>$client_proto_php_path<<EOF
<?php
return array(
    'appName' => '${appName}',
    'serverName' => 'Client',//发布服务器时需要注意使用此名称
    'objName' => 'Obj',
);

EOF

fi

proto_php_path=$tars_type"/tars/"$proto_php_name
touch $proto_php_path
cat>$proto_php_path<<EOF
<?php
return array(
    'appName' => '${appName}',
    'serverName' => 'Server',//发布服务器时需要注意使用此名称
    'objName' => 'Obj',
    'withServant' => ${with_servant}, //决定是服务端,还是客户端的自动生成
    'tarsFiles' => array(
        './${appName}Service.tars',
    ),
    'dstPath' => '../src/servant',
    'namespacePrefix' => '${namespace}\servant',
);
EOF

composer_json=$tars_type"/src/composer.json"
touch $composer_json

if [ "$tars_type" == "client" ];then
cat>$composer_json<<EOF
{
    "name" : "${appName}Service",
    "description": "${appName}Server",
    "require": {
        "phptars/tars-server": "~0.1",
        "phptars/tars-deploy": "~0.1",
        "phptars/tars2php": "~0.1",
        "phptars/tars-log": "~0.1",
        "ext-zip" : ">=0.0.1",
        "catfan/medoo": "^1.5",
    },
    "autoload": {
        "psr-4": {
            "${namespace}\\\" : "./"
        }
    },
    "minimum-stability": "stable",
    "scripts" : {
        "deploy" : "\\\Tars\\\deploy\\\Deploy::run"
    },
    "repositories": {
        "tars": {
            "type": "composer",
            "url": "https://raw.githubusercontent.com/Tencent/Tars/master/php/dist/tarsphp.json"
        }
    }
}
EOF
fi


if [ "$tars_type" == "client" ];then
cat>$composer_json<<EOF
{
    "name" : "${appName}Service",
    "description": "${appName}Server",
    "require": {
        "phptars/tars-server": "~0.1",
        "phptars/tars-deploy": "~0.1",
        "phptars/tars2php": "~0.1",
        "phptars/tars-log": "~0.1",
        "ext-zip" : ">=0.0.1",
        "catfan/medoo": "^1.5",
        "illuminate/database": "5.6.*",
        "illuminate/events": "5.6.*",
        "illuminate/support": "5.6.*",
        "joshcam/mysqli-database-class": "dev-master",
        "elasticsearch/elasticsearch": "~1.0"
    },
    "autoload": {
        "psr-4": {
            "${namespace}\\\" : "./"
        }
    },
    "minimum-stability": "stable",
    "scripts" : {
        "deploy" : "\\\Tars\\\deploy\\\Deploy::run"
    },
    "repositories": {
        "tars": {
            "type": "composer",
            "url": "https://raw.githubusercontent.com/Tencent/Tars/master/php/dist/tarsphp.json"
        }
    }
}
EOF

fi

cd ${tars_type}/src/
composer install
cd ../../

index_php=$tars_type"/src/index.php"
touch $index_php

cat>$index_php<<EOF
<?php
require_once __DIR__.'/vendor/autoload.php';
use \Tars\cmd\Command;

//php tarsCmd.php  conf restart
\$config_path = \$argv[1];
\$pos = strpos(\$config_path, '--config=');

\$config_path = substr(\$config_path, $pos + 9);

\$cmd = strtolower(\$argv[2]);

\$class = new Command(\$cmd, \$config_path);
\$class->run();
EOF

mkdir ${tars_type}/src/servant

tars2php_sh=$tars_type"/script/tars2php.sh"
touch $tars2php_sh

cat>$tars2php_sh<<EOF
#!/bin/bash
cd ../tars/
php ../src/vendor/phptars/tars2php/src/tars2php.php ./${proto_php_name}
EOF
chmod u+x ${tars2php_sh}
cd ${tars_type}/tars/

php ../src/vendor/phptars/tars2php/src/tars2php.php ./${proto_php_name}

cd ../../

cd ${tars_type}"/src/servant/"${appName}"/Server/Obj"
base_implace_class_file_name=`ls *php`
if [ ! -n "$base_implace_class_file_name" ];then
	echo "[ ERROR ] : impl文件错误，未生成接口文件，请删除${tars_type}重试！"
	exit 0
fi

base_implace_class_file_name=`echo $base_implace_class_file_name | sed 's/.php//g'`

implace_class_file_name=`echo $base_implace_class_file_name | sed 's/$/Impl/g'`

cd ../../../../../..

services_php=${tars_type}"/src/services.php"
touch $services_php

# server
if [ "$tars_type" == "server" ];then

mkdir -p ${tars_type}"/src/impl"
implace_class_file_path=${tars_type}"/src/impl/${implace_class_file_name}.php"
touch $implace_class_file_path

cat>$implace_class_file_path<<EOF
<?php
namespace ${namespace}\Impl;

use ${namespace}\servant\\${appName}\Server\Obj\\${base_implace_class_file_name};

class ${implace_class_file_name} implements ${base_implace_class_file_name}
{
    public function functionName($param)
    {
        return 'test ok !!';
    }
}
?>

EOF

cat>$services_php<<EOF
<?php
return array(
	'home-api'=> '\\${namespace}\servant\\${appName}\Server\Obj\\${base_implace_class_file_name}',
	'home-class'=> '\\${namespace}\impl\\${implace_class_file_name}', 
);

EOF

fi

# client
if [ "$tars_type" == "client" ];then

mkdir -p ${tars_type}"/src/component"
component_controller_path=${tars_type}"/src/component/Controller.php"
touch $component_controller_path

mkdir -p ${tars_type}"/src/controller"
index_controller_path=${tars_type}"/src/controller/"${class_name}"Controller.php"
touch $index_controller_path

cat>$services_php<<EOF
<?php
return array(
	'namespaceName' => '${namespace}\\\'
);
EOF

cat>$component_controller_path<<EOF
<?php
namespace ${namespace}\component;

use Tars\core\Request;
use Tars\core\Response;

class Controller
{
    protected \$request;
    protected \$response;

    public function __construct(Request \$request, Response \$response)
    {
        // 验证cookie、get参数、post参数、文件上传

        \$this->request = \$request;
        \$this->response = \$response;
    }

    public function getResponse()
    {
        return \$this->response;
    }

    public function getRequest()
    {
        return \$this->request;
    }

    public function cookie(\$key, \$value = '', \$expire = 0, \$path = '/', \$domain = '', \$secure = false, \$httponly = false)
    {
        \$this->response->cookie(\$key, \$value, \$expire, \$path, \$domain, \$secure, \$httponly);
    }

    // 给客户端发送数据
    public function sendRaw(\$result)
    {
        \$this->response->send(\$result);
    }

    public function header(\$key, \$value)
    {
        \$this->response->header(\$key, \$value);
    }

    public function status(\$http_status_code)
    {
        \$this->response->status(\$http_status_code);
    }
}

EOF

cat>$index_controller_path<<EOF
<?php

namespace ${namespace}\controller;

use Tars\core\Request;
use Tars\core\Response;
use ${namespace}\component\Controller;
use ${namespace}\conf\ENVConf;
use ${namespace}\servant\\${appName}\Server\Obj\\${base_implace_class_file_name};
use Tars\client\CommunicatorConfig;

class ${class_name}Controller extends Controller
{
    public \$servant;
    public function __construct(Request \$request, Response \$response)
    {
        parent::__construct(\$request, \$response);
        \$config = new CommunicatorConfig();
        \$config->setLocator(ENVConf::\$locator);
        \$config->setModuleName('${appName}.${namespace}');
        \$config->setSocketMode(3);
        \$this->servant = new ${base_implace_class_file_name}(\$config);
    }

    /*
    curl "192.168.91.53:20002/Index/hello?a=b" -i
    public function actionFunctionName()
    {
        \$result=\$this->servant->functionName('param');
        \$this->sendRaw('result:' . \$result);
    }
    */
}

EOF

fi


mkdir ${tars_type}"/src/conf"
ENVConf_php=${tars_type}"/src/conf/ENVConf.php"
touch $ENVConf_php

cat>$ENVConf_php<<EOF
<?php

namespace ${namespace}\conf;

class ENVConf
{
    public static \$locator = 'tars.tarsregistry.QueryObj@tcp -h ${local_ip} -p 17890';

    public static \$socketMode = 3;

    public static function getTarsConf()
    {
        \$table = \$_SERVER->table;
        \$result = \$table->get('tars:php:tarsConf');
        \$tarsConf = unserialize(\$result['tarsConfig']);

        return \$tarsConf;
    }
}
EOF


if [ "$tars_type" == "client" ];then
echo "SUCCESS"
echo "请在controller下写入代码逻辑"
echo "src下执行 composer run-script deploy 打包"
fi
if [ "$tars_type" == "server" ];then
echo "SUCCESS"
echo "请在impl下写入代码逻辑"
echo "src下执行 composer run-script deploy 打包"
fi