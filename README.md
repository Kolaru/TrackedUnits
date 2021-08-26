# TrackedUnits.jl

This package offer some convenient function to strip quantities from their units while still storing the units for future use. It allows to work with pure number without losing units information.

## Usage

```julia
julia> using TrackedUnits

julia> using Unitful

julia> @track_units x = 2u"m"
2

julia> @track_units dt = 12.3u"fs"
12.3

julia> @track_units v = x/dt
0.16260162601626016

julia> v
0.16260162601626016

julia> @get_units v
m fs^-1

julia> tracked_variables()
Dict{Symbol, Any} with 3 entries:
  :v  => m fs^-1
  :dt => fs
  :x  => m
```