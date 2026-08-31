export getAllSpinupForcing
export accumulateSpinupForcing

"""
    getAllSpinupForcing(forcing, spin_seq, tem_helpers)

prepare the spinup forcing all forcing setups in the spinup sequence

# Arguments:
- `forcing`: a forcing NT that contains the forcing time series set for ALL locations
- `spin_seq`: a sequence of information to carry out spinup at different steps with information on models to use, forcing, stopping critera, etc.
- `tem_helpers`: helper NT with necessary objects for model run and type consistencies

# Returns:
- `spinup_forcing::NamedTuple`: A NamedTuple containing aggregated forcing data for each spinup sequence

# Examples
```jldoctest
julia> using Sindbad

julia> # Prepare spinup forcing for all sequences
julia> # spinup_forcing = getAllSpinupForcing(forcing, spin_sequences, tem_helpers)
```
"""
function getAllSpinupForcing(forcing, spin_sequences::Tuple{Vararg{SpinupSequenceWithAggregator}}, tem_helpers)
    return accumulateSpinupForcing(spin_sequences, forcing, tem_helpers, (;))
end

"""
    accumulateSpinupForcing(spin_sequences, forcing, tem_helpers, spinup_forcing)

Derive the spinup forcing for each sequence in `spin_sequences` and collect them into a NamedTuple keyed by the forcing name, deriving each distinct name only once.

# Arguments:
- `spin_sequences`: a tuple of spinup sequences still to be processed
- `forcing`: a forcing NT that contains the forcing time series set for a location
- `tem_helpers`: helper NT with necessary objects for model run and type consistencies
- `spinup_forcing`: the NamedTuple of forcings accumulated so far

# Notes:
- The sequences are consumed recursively with `Base.tail` rather than with a `for` loop, so that each sequence is handled by its own method specialisation. The forcing name is read from the sequence's type parameter, which lets the "already derived" check resolve at compile time.
"""
function accumulateSpinupForcing end

accumulateSpinupForcing(::Tuple{}, _, _, spinup_forcing) = spinup_forcing

function accumulateSpinupForcing(spin_sequences::Tuple{SpinupSequenceWithAggregator{F},Vararg}, forcing, tem_helpers, spinup_forcing) where {F}
    if F ∉ keys(spinup_forcing)
        seq_forc = getSpinupForcing(forcing, first(spin_sequences), tem_helpers.vals.forcing_types)
        spinup_forcing = set_namedtuple_field(spinup_forcing, (F, seq_forc))
    end
    return accumulateSpinupForcing(Base.tail(spin_sequences), forcing, tem_helpers, spinup_forcing)
end

"""
    getSpinupForcing(forcing, sequence, ::Val{forcing_types})

prepare the spinup forcing set for a given spinup sequence

# Arguments:
- `forcing`: a forcing NT that contains the forcing time series set for a location
- `sequence`: a with all information needed to run a spinup sequence
- `:Val{forcing_types}`: a type dispatch with the tuple of pairs of forcing name and time/no time types
"""
function getSpinupForcing(forcing, sequence::SpinupSequenceWithAggregator, ::Val{forcing_types}) where {forcing_types}
    seq_forcing = map(forcing_types) do fnt
        f_name = first(fnt)
        f_type = last(fnt)
        v = getproperty(forcing, f_name)
        spv = getSpinupForcingVariable(v, sequence, f_type)
        Pair(f_name, spv)
    end
    return (; seq_forcing...)
end


"""
    getSpinupForcingVariable(v, sequence, ::ForcingWithTime)

get the aggregated spinup forcing variable

# Arguments:
- `v`: a forcing variable
- `sequence`: a with all information needed to run a spinup sequence
- `::ForcingWithTime`: a type dispatch to indicate that the variable has a time axis
"""
function getSpinupForcingVariable(v, sequence::SpinupSequenceWithAggregator, ::ForcingWithTime)
    timeAggregateForcingV(v, sequence.aggregator_indices, sequence.aggregator, sequence.aggregator_type)
end

"""
    getSpinupForcingVariable(v, _, ::ForcingWithoutTime)

get the spinup forcing variable without time axis

# Arguments:
- `v`: a forcing variable
- `sequence`: a with all information needed to run a spinup sequence
- `::ForcingWithoutTime`: a type dispatch to indicate that the variable has NO time axis
"""
function getSpinupForcingVariable(v, _, ::ForcingWithoutTime)
    v
end

"""
    getSpinupForcing(forcing, loc_forcing_t, time_aggregator, tem_helpers, ::TimeIndexed)

aggregate the forcing variable with time where an aggregation/collection is needed in time

# Arguments:
- `v`: a forcing variable
- `aggregator`: a time aggregator object needed to time aggregate the data 
- `ag_type::TimeNoDiff`: a type dispatch to indicate that the variable has to be aggregated in time
"""
function timeAggregateForcingV(v, _, aggregator, ag_type::TimeNoDiff)
    vt=do_time_sampling(v, aggregator, ag_type)
    vt[:]
end

"""
    getSpinupForcing(forcing, loc_forcing_t, time_aggregator, tem_helpers, ::TimeIndexed)

aggregate the forcing variable with time where an aggregation/collection is needed in time

# Arguments:
- `v`: a forcing variable
- `aggregator`: a time aggregator object/index needed to slice data 
- `::TimeIndexed`: a type dispatch to just slice the variable time series using index
"""
function timeAggregateForcingV(v, aggregator_index, _, ::TimeIndexed)
    v[aggregator_index]
end
