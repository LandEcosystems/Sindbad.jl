export cFireBurnedArea_forcing

struct cFireBurnedArea_forcing <: cFireBurnedArea end

function define(params::cFireBurnedArea_forcing, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        f_burnt_area ⇐ forcing
    end
    c_fire_fba = f_burnt_area # in forcing called it f_burnt_area # f_burnt_area
    # ## pack land variables
    @pack_nt begin
        c_fire_fba ⇒ land.diagnostics
    end
    return land
end

function compute(params::cFireBurnedArea_forcing, forcing, land, helpers)
    ## unpack land variables
    @unpack_nt begin
        f_burnt_area ⇐ forcing
    end
    # f_b = ... # some other pre process step, if needed
    c_fire_fba = f_burnt_area # ? set to new value

    @pack_nt begin
        c_fire_fba ⇒ land.diagnostics
    end
    return land
end

purpose(::Type{cFireBurnedArea_forcing}) = "Uses fire forcing data to calculate emissions."

@doc """

$(getModelDocString(cFireBurnedArea_forcing))

---

# Extended help

*Created by*
  - Nuno | nunocarvalhais
"""
cFireBurnedArea_forcing