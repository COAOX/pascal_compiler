# TechKomp Pascal Compiler
A Pascal subset compiler written in C++, using Bison and Flex.

# Compiling
Make sure flex and bison are present in your PATH, then simply make.

# Running
```
./comp [.pas file]
```

The resulting intermediary code can be compiled down to machine language using the provided vm in the /vm/ folder. 
The same folder also contains three example Pascal source code files that can be used to test compilation.  
