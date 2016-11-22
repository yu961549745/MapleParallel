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