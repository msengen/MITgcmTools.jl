
using Markdown
using InteractiveUtils
using MITgcmTools, ClimateModels, PlutoUI, Printf, Plots
using UUIDs


##################
# helpers
##################
# change a parameter
function update_param(file_name, group_name, param_name, new_param_value)
    # read the contents of the data file into a namelist 
    data_file = file_name
    fil = joinpath(rundir, data_file)
    nml = read(fil, MITgcm_namelist())

    # which param group do you want to modify?
    nmlgroup = group_name
    group_idx =findall(nml.groups.==Symbol(nmlgroup))[1]
    parms = nml.params[group_idx]

    # what parameter do you want to modify?
    p_name = param_name
    p_value = new_param_value

    # write changed parameter
    # tmptype= haskey(nml.params[group_idx], Symbol(p_name)) ? typeof(nml.params[group_idx][Symbol(p_name)]) : typeof(p_value)
    #nml.params[group_idx][Symbol(p_name)]=parse(tmptype,p_value)
    nml.params[group_idx][Symbol(p_name)] = p_value
    tmpfil=joinpath(rundir,data_file)
    rm(tmpfil)
    write(tmpfil,nml)
    tmpfil=joinpath("tracked_parameters",data_file)
    ClimateModels.git_log_fil(config_obj,tmpfil,"updated $(p_name) parameter file in $(data_file) to $(p_value)")
end
##################
# END helpers
##################


##################
# TODO: copy and paste in the correct config_id
# (from the output of darwin-setup)
##################
MITgcm_path[1] = "/home/msengen/darwin3" # CHANGE ME 
config_id = "maggie_test_1" # CHANGE ME

# reload the config 
config_name = "darwin-single-box"
folder = joinpath(MITgcm_path[1], "verification/darwin-single-box/run")
config_obj = MITgcm_config(configuration=config_name, ID=config_id, folder=folder)
rundir = joinpath(folder, config_id, "run")

##################
# Modify runtime parameters here
# file > group > parameter
##################

# timing 
update_param("data", "PARM03", "nenditer", 2880) # end after 1 year

# temperature
update_param("data", "PARM01", "tRef", 30.0)

# nutrients 
# NO3
update_param("data.ptracers", "PTRACERS_PARM01", "PTRACERS_ref( :, 2)", 2)
#PO4
update_param("data.ptracers", "PTRACERS_PARM01", "PTRACERS_ref( :, 5)", 0.1)
# FeT
update_param("data.ptracers", "PTRACERS_PARM01", "PTRACERS_ref( :, 6)", 1e-3)

# Prochlorococcus
update_param("data.ptracers", "PTRACERS_PARM01", "PTRACERS_ref( :,21)", 1e-3)


# TODO: save file to output dir with info about runtime params


##################
# run model
##################
println("launching...")
t = @elapsed begin
    MITgcm_launch(config_obj)
end
println("run completed")
println("time elapse: ", t, " seconds")

# TODO: print out the subfolder (i.e. "ecco_gud_DATE_0001")

