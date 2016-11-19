with(Threads:-Task):
fun:=proc()
    Continue(passed,x,Task=[`+`,1,2,3],y,Tasks=[`*`,[1,2],[2,3,3]],z);
end proc:
Start(passed,x,Task=[fun],Tasks=[`+`,[2,3,3],[6,6,6]]);