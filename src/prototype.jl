using MacroTools
using MacroTools: postwalk, @capture
using Unitful

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

macro get_unit(expr)
    postwalk(expr) do elem
        if elem isa Symbol && elem in keys(_tracked_units)
            return _tracked_units[elem]
        else
            return elem
        end
    end
end

macro convert_unit(var, new_unit)
    return quote
        key = $(QuoteNode(var))
        quantity = uconvert($new_unit, $(esc(var)) * _tracked_units[key])
        _tracked_units[key] = unit(quantity)
        $(esc(var)) = ustrip(quantity)
    end
end


@track_units t = 22 * u"s"
@track_units x = u"12m"
@track_units v = x/t

@get_unit v / t
@get_unit x/t^2

_tracked_units

@convert_unit t u"ms"

t

@get_unit t