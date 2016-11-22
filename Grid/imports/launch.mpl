Launch:=proc (
    NumNodes::posint := "ALL_NODES", 
    code := "", 
    Printer::procedure := NULL, 
    CheckAbort::procedure := NULL, 
    Exports::{list, set} := NULL, 
    Imports::{list, set} := NULL, 
    { 
        allexternal::truefalse := true, 
        checkabort::procedure := CheckAbort, 
        clear::truefalse := true, 
        exports::{list, set} := Exports, 
        imports::{list, set} := Imports, 
        numnodes::{"ALL_NODES", posint} := NumNodes, 
        printer::procedure := Printer 
    })
    localGridInterface:-Launch(numnodes, code, gridcmdargs = _rest, _options);
end proc: