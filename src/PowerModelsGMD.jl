module PowerModelsGMD
const _PMGMD = PowerModelsGMD

    import PowerModels
    const _PM = PowerModels
    import InfrastructureModels
    const _IM = InfrastructureModels

    import PowerModels: pm_it_name, pm_it_sym, nw_ids, nws, ismultinetwork
    import InfrastructureModels: optimize_model!, @im_fields, nw_id_default

    import JSON
    import JuMP
    import Memento

    # Create module level logger
    const _LOGGER = Memento.getlogger(@__MODULE__)
    __init__() = Memento.register(_LOGGER)

    # Suppresses information and warning messages:
    function silence()
        Memento.info(_LOGGER, "Suppressing information and warning messages for the rest of this session. 
        Use the Memento package for more fine-grained control of logging.")
        Memento.setlevel!(Memento.getlogger(_IM), "error")
        Memento.setlevel!(Memento.getlogger(_PM), "error")
        Memento.setlevel!(Memento.getlogger(_PMGMD), "error")
    end

    function logger_config!(level)
        Memento.config!(Memento.getlogger("PowerModelsGMD"), level)
    end


    # Add core functions, network formulations, and problem specifications:
    include("core/base.jl")
    include("core/constraint_template.jl")
    include("core/constraint.jl")
    include("core/data.jl")
    include("core/objective.jl")
    include("core/ref.jl")
    include("core/solution.jl")
    include("core/variable.jl")

    include("form/acp.jl")
    include("form/dcp.jl")
    include("form/shared.jl")
    include("form/wr.jl")
    include("form/wrm.jl")

    include("prob/gmd_matrix.jl")
    include("prob/gmd_mld_decoupled.jl")
    include("prob/gmd_mld.jl")
    include("prob/gmd_msse.jl")
    include("prob/gmd_opf_decoupled.jl")
    include("prob/gmd_opf_ts_decoupled.jl")
    include("prob/gmd_opf_ts.jl")
    include("prob/gmd_opf.jl")
    include("prob/gmd_ots_ts.jl")
    include("prob/gmd_ots.jl")
    include("prob/gmd_pf_decoupled.jl")
    include("prob/gmd.jl")
    include("prob/gmd_blocker_placement.jl")
end
