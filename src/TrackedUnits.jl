module TrackedUnits

using MacroTools
using MacroTools: postwalk, @capture
using Unitful

export @convert_units, @get_units, @track_units
export tracked_variables

const _tracked_units = Dict{Symbol, Any}()

"""
    tracked_variables()

Return a dict of tracked variables and the units associated to them.
"""
tracked_variables() = copy(_tracked_units)

"""
    @track_units var = expr

Track the variable `var` and associate it with the units that can be deduced
from its definition, either through unitful quantities from Unitful.jl or
other tracked units.
"""
macro track_units(expr)
    @capture(expr, var_ = def_) || throw(ArgumentError("expression must be an assignment to get its units tracked"))

    unitful_def = postwalk(def) do elem
        if elem isa Symbol
            if elem in keys(_tracked_units)
                return quote
                    $(esc(elem)) * _tracked_units[$(QuoteNode(elem))]
                end
            elseif elem == Symbol("@u_str")
                return elem
            else
                return esc(elem)
            end
        else
            return elem
        end
    end

    return quote
        quantity = 1 * $unitful_def
        _tracked_units[$(QuoteNode(var))] = unit(quantity)
        $(esc(var)) = ustrip(quantity)
    end
end

"""
    @get_units expr

Return the units of an expression formed of unitful quantities from Unitful.jl
and tracked units.
"""
macro get_units(expr)
    postwalk(expr) do elem
        if elem isa Symbol
            if elem in keys(_tracked_units)
                return _tracked_units[elem]
            else
                return esc(elem)
            end
        else
            return elem
        end
    end
end

"""
    @convert_units var new_units

Convert the tracked variable `var` to new units.
"""
macro convert_units(var, new_unit)
    return quote
        key = $(QuoteNode(var))
        quantity = uconvert($new_unit, $(esc(var)) * _tracked_units[key])
        _tracked_units[key] = unit(quantity)
        $(esc(var)) = ustrip(quantity)
    end
end

end # module
