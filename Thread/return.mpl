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