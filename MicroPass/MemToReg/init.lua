local GlobalToReg = require("FFTKernelGen.MicroPass.MemToReg.GlobalToReg")
local LocalToReg = require("FFTKernelGen.MicroPass.MemToReg.LocalToReg")

local function MemToReg(indent_num, pass_info, kernel_info, micro_pass_info,
                        dest_var_list, src, id_variable_list)
    if micro_pass_info.input_type_ == 'global' then
        return GlobalToReg(indent_num, pass_info, kernel_info, micro_pass_info,
            dest_var_list, src, id_variable_list.lid_dim2_)
    elseif micro_pass_info.input_type_ == 'local' then
        return LocalToReg(indent_num, pass_info, kernel_info, micro_pass_info,
                       dest_var_list, src, id_variable_list.lid_dim2_)
    end

end

return MemToReg