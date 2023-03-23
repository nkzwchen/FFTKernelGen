local Info = require("FFTKernelGen.Util.Info")
local Variable = require("FFTKernelGen.Util.Variable")
local CodeBlock = require("FFTKernelGen.Util.CodeBlock")
local Sentence = require("FFTKernelGen.Util.Sentence")
local MicroPassRead = require("FFTKernelGen.MicroPass.Read")

local MicroPass = {}

local function MicroPassCodeBlock(padding_num)
    --- param lid, input, output, rw 
    local code_block = {}
    local local_id = Variable.CreateVariable('local_id', 'uint2')
    local local_id_value = string.format("(uint2)(lid.x & %d, lid / %d)", Info.kernel_info.local_row_ - 1, Info.kernel_info.local_row_)
    table.insert(code_block, Sentence.CLAllocateVar(padding_num, local_id, local_id_value))

    local R = {}
    
    for i = 1, Info.micro_pass_info.element_per_thread_ do
        table.insert(R, Variable.CreateVariable(string.format("R%d", i - 1), 'float2'))   
    end
    table.insert(code_block, Sentence.CLAllocateMultiVar(padding_num, R, "float2")) 

    table.insert(code_block, MicroPassRead.CodeBlock(padding_num + 1, local_id, R))

    return CodeBlock.GetCodeBlock(padding_num, code_block)
end

function MicroPass.Gen(padding_num)
    return  CodeBlock.ConvertCodeBlockToString(MicroPassCodeBlock(padding_num))
end

return MicroPass

