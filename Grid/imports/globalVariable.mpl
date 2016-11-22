x:=1:y:=2:z:=3:w:=4:
fun:=proc()
    global x,y,z;
    print(x,y,z,w);
end proc:
Grid:-Launch(fun,imports=[':-x'=x,'y',"z"]);