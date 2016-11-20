fun:=proc()
    uses Grid;
    printf("node %d / %d --- %a \n",MyNode(),NumNodes(),[_passed]);
    Barrier();
end proc:
Grid:-Launch(fun,1,2,3);
Grid:-Launch("rand();"):