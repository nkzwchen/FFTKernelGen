local GlobalToReg = require("FFTKernelGen.MicroPass.MemToReg.GlobalToReg")

local function MemToReg(indent_num, pass_info, kernel_info, micro_pass_info,
                        dest_var_list, src, id_variable_list) 
    return GlobalToReg(indent_num, pass_info, kernel_info, micro_pass_info,
                       dest_var_list, src, id_variable_list.lid_dim2_)
end

return MemToReg