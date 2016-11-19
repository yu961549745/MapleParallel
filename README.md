# MapleParallel
Maple Parallel Programming Study Note.

Maple具有两种并行编程模型：
+ Task ： 单进程多线程并行，可以共享内存，但是需要注意共享变量的访问。并且要注意Maple内置函数可能不是线程安全的。需要在`threadsafe`页面中查看Maple内置函数是否线程安全。Maple线程安全的检查只更新到Maple18，Maple2016引入了`CodeTools:-ThreadSafetyCheck`来简单的检查函数是否安全，检查是否使用了global变量和lexical变量。
+ Grid ： 多进程并行，不共享内存，共享变量需要通讯，传入变量和函数需要显式声明。

另外，并行程序的内部是并行执行的，但是并行程序的启动和其它代码是串行的，只有当并行任务完成之后，后续代码才会继续执行。

# Threads————Maple多线程
Maple会自动指定线程到各个CPU执行。

+ 线程全局变量
    + global
    + kernerl options / interface variables
    + global module ： module 的局部变量也是全局唯一的。
+ 线程局部变量
    + 局部变量，环境变量
    + module 中声明了 thread_local 的变量
+ 原子性操作
    + 变量赋值
    + interface 交互 : print printf interface
    + 文件操作
    + 调用外部函数

局限性：
+ 大部分Maple库函数都不是线程安全的。只有声明了threadsafe的函数才是线程安全的。（很不幸，sovle不是线程安全的）
+ 需要合理编程才能有效提高效率。

## Task Model
+ Start 创建并执行task tree根节点。
+ Continue 创建 task tree 子节点。
+ Return 允许提前结束Task，不会中断正在运行的task，但是会阻止创建新的task。

Maple多线程包含两种实现：
+ Task模型：这是一个高级接口，一个task就是一个线程，用户只需关心task的内容而不需要关心线程的具体实现。
+ Threads包：正确有效的利用这个工具编写多线程程序是困难的，强烈建议直接使用Task模型。
+ 只有Maple主线程才能调用外部函数，

### Start 基本用法
```
with(Threads:-Task):
printf("root exec\n");
Start(print,1,2,3);
printf("single task\n");
Start(null,Task=[print,1,2,3]);
printf("multi tasks\n");
Start(null,Task=[print,1],Task=[print,2],Task=[print,3]);
print("multi tasks with same function\n");
Start(null,Tasks=[print,[1],[2],[3]]);
print("complex parameters\n");
Start(passed,1,Task=[`+`,1,2,3],Tasks=[`*`,[2,3,3],[4,5,6]],x,y,z);
```
Start的模型为：
```
fc(arg1,arg2,...,argn) <==> Start(fc,arg1,...,argn);
```
其中 arg1..argn 既可以是参数，也可以是一个函数调用，如果是函数的话，将以多线程的形式调用。

Maple的Start内置了两个根函数 `null` 和 `passed` ，前者不范围任何值，后者返回所有输入参数。

总结输入参数具有以下4种类型：
+ 第一个参数是根函数
+ 普通参数
+ Task=[fcn,arg1,...,argn] ：单个task
+ Tasks=[fcn,[args1],[args2],...,[argsn]] : 多个task

### Continue
Continue的用法和Start类似，但是区别在于Continue只能作为Start的子节点存在，Start和Continue共同构造了一颗task tree. 

任务的执行从叶节点开始，每层的每一个节点都完成之后才会执行上一层的任务。

```
with(Threads:-Task):
fun:=proc()
    Continue(passed,x,Task=[`+`,1,2,3],y,Tasks=[`*`,[1,2],[2,3,3]],z);
end proc:
Start(passed,x,Task=[fun],Tasks=[`+`,[2,3,3],[6,6,6]]);
```

### Return
`Return(value)`能够通过Start返回`value`，一旦返回，将不再执行新的任务，但不会中断正在执行的任务。
```
with(Threads:-Task):
randomize():
roll:=rand(10):
nTasks:=10:
TaskExec:=Array(1..nTasks):
fun:=proc()
    local x;
    global TaskExec;
    TaskExec[_passed]:=1;
    x:=roll();
    if x>5 then
        Return(x);
    end if;
    return x;
end proc:
Start(null,Tasks=[fun,seq([i],i=1..10)]);
print(convert(TaskExec,list));
```

## 具有多线程实现的函数
Threads包下具有
+ Add
+ Mul 
+ Map 
+ Seq 
这些函数是普通函数的多线程实现，是基于Task模型实现的。和普通函数的唯一区别是，调用时可以指定最大task数。
以Add为例，即为`Add[tasksize=s](...)`。

## Threads基础实现
+ Create
+ Self
+ Sleep
+ Wait

## Mutex

## ConditionVariable