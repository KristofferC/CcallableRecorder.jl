module CcallableRecorder

using Base: _ccallable

export @ccallable_record, @dump_headerfile, dump_headerfile

using ExprTools

# TODO Fill out
function to_c_type(expr)
    if expr isa Symbol
        expr == :Cint     ? "int"     :
        expr == :Cfloat   ? "float"   :
        expr == :Cdouble  ? "double"  :
        expr == :Cchar    ? "char"    :
        expr == :Cshort   ? "short"   :
        expr == :Csize_t  ? "size_t"  :
        expr == :Cssize_t ? "ssize_t" :
        error("unhandled c type $(expr)")
    elseif expr isa Expr
        if expr.args[1] == :Ptr
            return string(to_c_type(expr.args[2]) , "*")
        else
            error("unhandled c type $(expr)")
        end
    end
end

struct CSignature
    name::Symbol
    argtypes::Vector{Any}
    rettype::Symbol
end

function to_c_string(sig::CSignature)
    sprint() do io
        print(io, to_c_type(sig.rettype), " ")
        print(io, sig.name)
        print(io, "(")
        join(io, to_c_type.(sig.argtypes), ", ")
        print(io, ");")
    end
end

const C_SIGNATURES = Dict{Module, Vector{CSignature}}()

macro ccallable_record(ex)
    m = __module__
    def = splitdef(ex)
    args = def[:args]
    argtypes = Any[]
    for arg in args
        push!(argtypes, last(arg.args))
    end
    
    if !haskey(C_SIGNATURES, m)
        C_SIGNATURES[m] = CSignature[]
    end
    
    # TODO: Do not insert this signature if the expand_ccallable fails.
    push!(C_SIGNATURES[m], CSignature(def[:name], argtypes, def[:rtype]))
    return quote
        $(Base.expand_ccallable(nothing, ex))
    end
end

function dump_headerfile(mod::Module, file::AbstractString)
    open(file, "w") do io
        print(io, "// Header automatically generated from module $mod\n\n")
        # TODO: Recurse into child modules?
        for sig in C_SIGNATURES[mod]
            println(io, to_c_string(sig))
        end
    end
end

macro dump_headerfile(file)
    :($dump_headerfile($__module__, $file))
end

end # module CcallableRecorder
