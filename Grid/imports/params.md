# 回顾一下参数绑定顺序
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

