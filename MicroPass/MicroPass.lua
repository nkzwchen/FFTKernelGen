-- local function MicroPass(padding_num)
--     --- param lid, input, output, rw 
--     local code_block = {}
--     local local_id = Variable.create_variable('local_id', 'uint2')
--     local local_id_value = string.format("(uint2)(lid.x & %d, lid / %d)", Info.kernel_info.local_row_ - 1, Info.kernel_info.local_row_)
--     table.insert(code_block, Sentence.CLAllocateVar(padding_num, local_id, local_id_value))

--     local R = {}
    
--     for i = 1, Info.micro_pass_info.element_per_thread_ do
--         table.insert(R, Variable.create_variable(string.format("R%d", i - 1), 'float2'))   
--     end
--     table.insert(code_block, Sentence.CLAllocateMultiVar(padding_num, R, "float2")) 

--     table.insert(code_block, ReadFromInput(padding_num + 1, local_id, R))

--     return GetCodeBlock(padding_num, code_block)
-- end

-- function CodeBlock.MicroPass(padding_num)
--     return  ConvertCodeBlockToString(MicroPass(padding_num))
-- end
