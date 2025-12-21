import Pkg

"To install Julia Pkgs: `@install Pkg1, Pkg2, Pkg3, ...` runs `Pkg.add` and `using` if not already loaded"
macro install(pkgs...)
    new_pkgs = Symbol[]
    f = first(pkgs)
    if isa(f, Expr)
        new_pkgs = f.args
    elseif isa(f, Symbol)
        new_pkgs = [f]
    else
        throw("unknown type of first(pkgs): $(typeof(f))")
    end
    
    caller_module = __module__
    new_pkgs = filter(pkg -> !isdefined(caller_module, pkg), new_pkgs)
    isempty(new_pkgs) && return nothing
    
    installed = Set(keys(Pkg.project().dependencies))
    not_installed = filter(pkg -> string(pkg) ∉ installed, new_pkgs)
    Pkg.add.(string.(not_installed))
    
    usings = [:(using $pkg) for pkg in new_pkgs]
    esc(Expr(:block, usings...))
end
