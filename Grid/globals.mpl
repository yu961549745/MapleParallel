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
Grid:-Launch(fun,imports={'x','y'},exports={'x','w'});
[x,y,z,w];