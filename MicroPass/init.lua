local Info = require("FFTKernelGen.Util.Info")
local Variable = require("FFTKernelGen.Util.Variable")
local CodeBlock = require("FFTKernelGen.Util.CodeBlock")
local Statement = require("FFTKernelGen.Util.Statement")
local MemToReg= require("FFTKernelGen.MicroPass.MemToReg")

local MicroPassMethod = {}

function MicroPassMethod:GenCodeBlock(indent_num)
    --- init 
    local code_block = {}

    local src = Variable.CreateVariable('src', 'float2*')

    local lid_dim2 = Variable.CreateVariable('lid_dim2', 'uint2')
    local lid_dim2_value = string.format("(uint2)(lid.x & %d, lid / %d)", Info.kernel_info.local_row_ - 1, Info.kernel_info.local_row_)
 
    table.insert(code_block, Statement.CLDefineVar(indent_num, lid_dim2, lid_dim2_value))
    local id_variable_list = {lid_dim2_ = lid_dim2}

    local R = {}
    
    for i = 1, Info.micro_pass_info.element_per_thread_ do
        table.insert(R, Variable.CreateVariable(string.format("R%d", i - 1), 'float2'))   
    end

    table.insert(code_block, Statement.CLDefineMultiVar(indent_num, R, "float2")) 


    --- Mem To register
    table.insert(code_block, MemToReg(indent_num + 1, Info.pass_info, Info.kernel_info, Info.micro_pass_info, R, src, id_variable_list))
    return CodeBlock.GetCodeBlock(indent_num, code_block)
end

function MicroPassMethod:GenString(indent_num)
    return  CodeBlock.ConvertCodeBlockToString(self:GenCodeBlock(indent_num))
end

local function MicroPass(indent_num)
    local ret = {}
    for k, v in pairs(MicroPassMethod) do
        ret[k] = v
    end
    return ret:GenString(indent_num)
end

return MicroPass

