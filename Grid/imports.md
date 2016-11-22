# 参数导入

## 可能性
允许格式：
+ name=value
+ assigned name
+ string representing global names

传递类型：
+ 变量
    + 全局变量
    + proc局部变量
    + moudle局部变量
+ 函数
    + 自举函数
    + 非自举函数
+ module

传递方式：
+ imports
+ 参数 

传递位置
+ 顶层空间
+ 函数内部
+ module内部

这些可能的组合太多了，所以这里不尝试任意组合，只求找到每一种类型的参数的正确传递方式。

## 建议结果
### 全局变量
全局变量可以采用3种方式进行 import , 其中最方便的是 string 和 unevaluated name, 只需注意在调用部分声明 global 即可。
```
x:=1:y:=2:z:=3:w:=4:
fun:=proc()
    global x,y,z;
    print(x,y,z,w);
end proc:
Grid:-Launch(fun,imports=[':-x'=x,'y',"z"]);
```
### 局部变量
有两种方式来传递局部变量：
+ 通过参数传递，此时考虑scope和eval的规则即可。
+ 通过声明 `':-global'=local` 对来传递，其中显式声明变量是全局是必要的，并且这种声明不会影响对应全局变量的取值。
```
gfun:=proc(x)
    uses Grid; 
    global y,z,w,u,v;
    print(x,y,z,w,u,v);
    Barrier();
end proc:
Foo:=module()
    option package;
    local x:=1,z:=3;
    export fun;
    fun:=proc()
        local y:=2,w:=4,u:=5,v:=6;
        Grid:-Launch(gfun,x,imports=[':-y'=y,':-z'=z,'w'=w,'u',"v"]);
    end proc:
end module:
Foo:-fun();
y;z;
``` 

### procedure / set / list
先来看 `Grid:-Launch` 的函数声明
```
Launch:=proc (
    NumNodes::posint := "ALL_NODES", 
    code := "", 
    Printer::procedure := NULL, 
    CheckAbort::procedure := NULL, 
    Exports::{list, set} := NULL, 
    Imports::{list, set} := NULL, 
    { 
        allexternal::truefalse := true, 
        checkabort::procedure := CheckAbort, 
        clear::truefalse := true, 
        exports::{list, set} := Exports, 
        imports::{list, set} := Imports, 
        numnodes::{"ALL_NODES", posint} := NumNodes, 
        printer::procedure := Printer 
    })
    localGridInterface:-Launch(numnodes, code, gridcmdargs = _rest, _options);
end proc:
```
再来回顾一下Maple的参数类型和参数绑定顺序：

先看参数类型：
+ required positional parameters : var::type 
+ seq parameters : var::seq
+ uneval or evaln parameters : var::uneval or  var::evaln
+ optional ordered parameters :  var::type:=value
+ expected ordered parameters :  var::expects(type):=value , 
  和 optional 的区别在于 optional 可以因为类型不匹配被省略，但是 expected 只能省略，不能不匹配。
+ keyword parameters : {keyword::type=value}

再来看参数绑定顺序：
+ uneval/evaln， 首先从左至右依次绑定参数，直至右边绑定完或者左边没有可以绑定的，如果类型不匹配将会报错。
  即右边的前面所有参数必须依次匹配uneval/evaln的参数类型，因此在存在uneval/evaln参数时，合理的做法是将它们依次声明为前几个参数。
+ keyword，然后匹配关键字参数，同一个keyword多个匹配则生效的是最后一个。
+ positional/ordered，最后依次匹配普通参数和默认值参数
    + 如果匹配则直接赋值。
    + 如果类型不匹配且没有默认值，将会报错。
    + 如果类型不匹配但有默认值，则会使用默认值。
    + 如果存在seq参数则会匹配到最后一个类型匹配的参数。
    + 如果还有剩余参数，若声明了`$`则报错，否则赋值给`_rest`

因此，可以分析得到，第一个参数因为是字符串或者函数，所以 NumNodes 会是默认值，
然后调用命令是函数或者字符串，赋值给 code ，再之后的剩余参数作为函数的参数，
但是问题在于还有 procedure 和 {set,list} 的参数类型匹配，所以不能直接传递这3种类型的参数，
需要指定了这些参数对应的值之后，才能传递这些类型的参数，这个太麻烦了。

这里给出了4种传递函数作为参数的方式
```
f1:=proc()
    return 1;
end proc:
f2:=proc()
    return 2;
end proc:
f3:=proc()
    return 3;
end proc:
f4:=proc()
    return 4;
end proc:
fun:=proc(f1)
    global f2,f3,f4;
    print(f1(),f2(),f3(),f4());
end proc:
coverArgs:={},{}:
Grid:-Launch(fun,coverArgs,eval(f1),imports=['f2',"f3",':-f4'=eval(f4)]);
```
+ 其中补位参数`converArgs`能够跳过 `procedure` 的匹配，做到不影响 `Printer`和`CheckAbort`的取值，
+ 然后又填充了 `Imports`和`Exports`, 在指定`imports`和`exports`这两个值并不影响结果，
+ 又根据函数的 _last name evaluation_ 规则，传递函数的值需要 `eval`，
+ 同时也说明了函数内部的其它函数不能直接展开，需要都传递给Grid.

## 总结
三种imports方式可以分为两种类型:
+ assigned name, global name string : 从global空间提取对应信息，放入Grid命名空间中去。
+ name=value ： 从value取值，放入Grid命名空间的 name 中去。

从上述总结可以看出，
+ 第一种类型的变量来源只能是global的，而第二种类型可以是local的。

另外需要注意的是
+ 在传递procedure和module时，要注意_last name evaluation_ 的作用
+ 在传递 procedure / set / list 作为参数时，需要传入补位参数。