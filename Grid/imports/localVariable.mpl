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