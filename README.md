# CcallableRecorder

```
module MyLibrary
    using CcallableRecorder

    @ccallable_record foo(x::Cint, y::Cdouble)::Cdouble = x + y
    @ccallable_record bar(x::Cdouble, y::Cdouble, z::Cdouble)::Cdouble = x*y + z

    @dump_headerfile "mylib.h"
end
```

```
julia> read("mylib.h", String) |> print
// Header automatically generated from module Main.MyLibrary

double foo(int, double);
double bar(double, double, double);
```
