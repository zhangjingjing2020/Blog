# GO 单元测试

* 建立单元测试文件夹
* 文件名``name_test.go`` 以_test结尾
* 文件内容

> 引入需要测试的包接口

````
package name

import (
	"testing"
)

func TestApi(t *testing.T) {
	log.Println("test")
}
````

* 执行 ``go test``
* 指定执行文件和函数 ``go test -v -run funcName fileName`` 

> -v 显示详情

``go test``是有缓存的，代码和命令不变的情况下会直接返回上次一结果，避免这种情况可以加``-count=1``

````
go test -v -run funcName fileName -count=1
````

