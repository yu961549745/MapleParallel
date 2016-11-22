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
+ Create--用于创建一个线程来计算表达式
+ Self----用于返回线程id
+ Sleep---用于线程睡眠
+ Wait----等待某个线程结束

### Create
Create 用于创建一个线程，并返回一个线程id，可以用于传递给 Wait 来等待线程结束。
```
Create(expr,var,opt1,...)
```
其中`expr`是需要在新的线程中计算的表达式
+ 如果 `expr` 是一个函数调用，则参数的计算将在当前线程完成，具体的调用将在新的线程完成。
+ 否则，整个表达式都将在新的线程中完成。
其中`var`可以用于接收`expr`的返回值。
```
with(Threads):
id:=Create(int(sin(x)^x,x),res);
res;
Wait(id);
res;
```

### Sleep
```
Sleep(n)
```
可以使当前线程水面`n`秒，`n`也可以是小于1的数。

注意不要使用`Sleep`来同步线程，使用`Mutex`或者`ConditionVariable`。

### Self
`Self()`用于返回当前线程的id，主线程的id为0.

### Wait
```
Wait(id1,id2,...)
```
等待id列表中所有的线程结束

## Mutex
Mutex用于对操作进行加锁同步。
+ Create 创建一个新的锁
+ Destroy 释放一个锁的相关资源
+ Lock 加锁
+ Unlock 解锁

Maple2016提供了`option lock`。

```
with(Threads:-Mutex):
with(Threads:-Task):
m:=Create();
c:=1;
fun:=proc()
    global c,m;
    Lock(m);
    print(c);
    c:=c+1;
    Unlock(m); 
end proc:
Start(null,Tasks=[fun,seq([],i=1..10)]);
Destroy(m);
```

## ConditionVariable
ConditionVariable提供了更加丰富的同步功能，两个典型的应用是：
+ 在某些点交换数据
+ 生产者-消费者模型：生产者提供任务，通知消费者来完成任务。
ConditionVariable和Mutex的主要区别在于， ConditionVariable可以选择使通知一个等待线程，还是通知所有等待线程。
+ Create------创建 
+ Destroy-----销毁
+ Wait--------等待
+ Signal------通知一个
+ Broadcast---通知全部

# Grid
Grid包在Maple15引入，并在Maple2015有较大更新。

+ 并行实现
    + Map
    + Seq
+ 基本用法
    + Launch
    + Barrier
    + Interrupt
    + MyNode
    + NumNodes
+ 通信
    + Send
    + Receive
+ 服务器
    + Status
    + Setup
    + Server
    + Run[2015]
    + Get[2015]
    + GetLastResult[2015]
    + Set[2015]
    + Wait[2015]
    + WaitForFirst[2015]

## 基本用法

### Launch
```
Launch(code,args,options)
```

参数                    | 意义
------------------------|----------------------
code                    | 命令字符串或者函数
args                    | 传递的参数
numnodes = posint       | 指定进程个数
printer = procedure     | 输出回调函数
checkabort = procedure  | 提前中断的回调函数
imports = {list,set}    | 引入变量
exports = {list,set}    | 导出变量
clear = truefalse       | 是否清除状态
allexternal = truefalse | 是否让node0在外部运行

+ code  可以是包含Maple命令的字符串，也可以是一个函数，但是需要这个函数不依赖于外部变量。
+ args  如果code是一个函数，则将会把args作为参数传递。
+ 所有node上执行的代码都是相同的，可以利用`MyNode`来分配不同的任务。
+ 整个任务将在node0结束后立即结束，其它节点将被中断。
+ 返回值是node0中的返回值。
+ numnodes 用于指定进程个数，在本地模式下，这个是由`kernerlopts(numcpus)`决定的，在远程模式下，这是由`Grid[Status]`的第二个返回参数决定的。
+ imports 用于导入当前变量，可以有3种形式：`name=value`,`assigned names`,`string representing global names`;
+ exports 用于返回node0中的变量，这个列表只能包含global names。 
+ printer 用于在具有外部字符串输出时调用，默认为`printf`,以一个字符串参数进行调用。
+ checkabort 一个无参调用的函数，将被周期性的调用，返回`true`则中断所有节点，返回`false`则继续执行。在本地模式下是无效的。
+ clear 仅在本地模式下使用，默认为`true`表示调用结束后重置各节点的状态。
+ allexternal 仅在本地模式下有效。
+ 在分布式模式下运行，需要预先进行配置。

```
fun:=proc()
    uses Grid;
    printf("node %d / %d --- %a \n",MyNode(),NumNodes(),[_passed]);
    Barrier();
end proc:
Grid:-Launch(fun,1,2,3);
Grid:-Launch("rand();"):
```

### Barrier
Barrier ：
+ 用于中断所有node，直到所有node都执行了 Barrier 命令，可用于同步。
+ 在 hpc 模式下无效。

### MyNode
返回当前进程标记，标记为 0..(N-1)。

### NumNodes
返回总的进程个数

### Interrupt
```
Interrupt()
Interrupt(node)
```
+ 用于中断一个进程
+ node为进程id
+ 无参调用可以在主线程中使用，用于停止由`Grid:-Run`所创建的命令
+ node0 不能被中断。
+ 中断进程造成的死锁能够被检测到，并自动终止相关进程。
+ mpi 模式下无效。

### 一些例子
```
x:=1:y:=2:z:=3:w:=4:
fun:=proc()
    uses Grid;
    global x,y,z;
    local w:=1;
    printf("%d --> %a \n",MyNode(),[x,y,z,w]);
    x:=233+MyNode();
    y:=666+MyNode();
    z:=888+MyNode();
    w:=999+MyNode();
    Barrier();
end proc:
Grid:-Launch(fun,imports={'x','y'},exports={'x','z','w'});
[x,y,z,w];
```
+ x和z对比，说明全局变量必须声明imports才能导入。
+ z说明，全局变量声明了导出，修改就能生效。
+ w说明，说明全局变量才能导出，局部变量不行。
+ 返回结果表明，只有node0的全局变量值才有效。
并且需要注意的是：
+ print/printf是原子的，但是各进程/线程之间的调用顺序是未知的，所以尽可能的在同一句输出，或者运行完成后再输出。
+ 需要考虑 Barrier 的特性和 node0 返回的特性。

## 进程通信
```
Send(node,msg)
```
+ node 指定节点编号
+ msg 可以是任意类型的参数，可以为NULL和seq，但是具有last name evaluation的嵌套表达式不会对子表达式进行求值。
+ Send只有在传输阶段会中断程序，传输完成后立即返回NULL，不管是否Receive。
+ 所有计算都已经完成的死锁可以被自动检测并终止。

```
Receive()
Receive(node)
```
+ 在接收到信息前会中断进程，若指定了node则接收到了该node的信息再终止，若不指定，则在接收到第一个参数后终止。


```
N:=kernelopts(numcpus):
x:=Array(1..N):
fun:=proc()
    uses Grid;
    global x;
    local node,i,id,v;
    node:=MyNode();
    if node<>0 then
        Send(0,node,node^2);
    else
        for i from 1 to NumNodes()-1 do
            id,v:=Receive();
            x[id+1]:=v;
        end do;
        x[1]:=0;
    end if;
    return NULL;
end proc:
Grid:-Launch(fun,imports=["x"],exports=["x"]);
print(convert(x,list));
```

当一个进程需要接收其它进程的信息时，尽管写成如下形式，经简单测试，不会造成信息丢失，但总觉得不好。
当接收无序输入时，还是推荐不要指定接收的节点编号。
```
fun:=proc()
    uses Grid;
    local node,i,N;
    node:=MyNode();
    N:=NumNodes();
    if node<>0 then
        Threads:-Sleep(N-node);
        print(node);
        Send(0,evalf(Pi-3+node,100));
    else
        for i from 1 to N-1 do
            print(Receive(i));
        end do;
    end if;
end proc:
Grid:-Launch(fun);
```

## 参数传递
[参数传递]()
三种imports方式可以分为两种类型:
+ assigned name, global name string : 从global空间提取对应信息，放入Grid命名空间中去。
+ name=value ： 从value取值，放入Grid命名空间的 name 中去。

从上述总结可以看出，
+ 第一种类型的变量来源只能是global的，而第二种类型可以是local的。

另外需要注意的是
+ 在传递procedure和module时，要注意_last name evaluation_ 的作用
+ 在传递 procedure / set / list 作为参数时，需要传入补位参数。