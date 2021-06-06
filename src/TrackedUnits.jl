module TrackedUnits

using MacroTools
using MacroTools: postwalk, @capture
using Unitful

export @track_units, @get_units, @convert_units

const _tracked_units = Dict{Symbol, Any}()

macro track_units(expr)
    @capture(expr, var_ = def_) || error("Expression must be an assignment to get its units tracked")

    unitful_def = postwalk(def) do elem
        if elem isa Symbol && elem in keys(_tracked_units)
            return quote
                $elem * _tracked_units[$(QuoteNode(elem))]
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

macro get_units(expr)
    postwalk(expr) do elem
        if elem isa Symbol && elem in keys(_tracked_units)
            return _tracked_units[elem]
        else
            return elem
        end
    end
end

macro convert_units(var, new_unit)
    return quote
        key = $(QuoteNode(var))
        quantity = uconvert($new_unit, $(esc(var)) * _tracked_units[key])
        _tracked_units[key] = unit(quantity)
        $(esc(var)) = ustrip(quantity)
    end
end

end # module
