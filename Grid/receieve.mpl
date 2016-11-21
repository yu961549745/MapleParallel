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