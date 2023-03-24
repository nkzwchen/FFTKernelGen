local RegToLocal = require("FFTKernelGen.MicroPass.RegToMem.RegToLocal")

local function RegToMem(indent_num, pass_info, kernel_info, micro_pass_info,
                        dest, src_var_list, id_variable_list) 
    return RegToLocal(indent_num, pass_info, kernel_info, micro_pass_info,
                       dest, src_var_list, id_variable_list.lid_dim2_, id_variable_list.mid_)
end

return RegToMem