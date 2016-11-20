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
