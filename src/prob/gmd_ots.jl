"Solve GMD OTS mitigation with nonlinear ac polar relaxation"
function solve_ac_gmd_ots(file, optimizer; kwargs...)
    return solve_gmd_ots( file, _PM.ACPPowerModel, optimizer; kwargs...)
end


"Solve GMD MLS OTS mitigation with second order cone relaxation"
function solve_soc_gmd_ots(file, optimizer; kwargs...)
    return solve_gmd_ots( file, _PM.SOCWRPowerModel, optimizer; kwargs...)
end


"Solve GMD MLS OTS mitigation with quadratic constrained least squares relaxation"
function solve_qc_gmd_ots(file, optimizer; kwargs...)
    return solve_gmd_ots( file, _PM.QCLSPowerModel, optimizer; kwargs...)
end


function solve_gmd_ots(file, model_type::Type, optimizer; kwargs...)
    return _PM.solve_model(
        file,
        model_type,
        optimizer,
        build_gmd_ots;
        ref_extensions = [
            _PM.ref_add_on_off_va_bounds!,
            ref_add_gmd!
        ],
        solution_processors = [
            solution_gmd_qloss!,
            solution_gmd!,
        ],
        kwargs...,
    )
end
