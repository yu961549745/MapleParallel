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
printf("执行完毕\n");