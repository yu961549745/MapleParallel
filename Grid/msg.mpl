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