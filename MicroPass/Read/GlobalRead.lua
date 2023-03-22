local Info = require("FFTKernelGen.Info")
local Util = require("FFTKernelGen.Util")
local Sentence = require("FFTKernel.Sentence")

local GlobalRead = {}
-- create code block calculate global read offset value
-- {
--  group_id = (utin2)(get_group_id(0), get_group_id(1))

--  element_id = (
--                x_ = group_id.x * local_row + local_id.x + local_row_offset, 
--                y_ = local_id.y + local_col_offset
--               )

--  offset = group_id.y * idist + (element_id.y * global_row + element_id.x) * instride
-- }

-- offset, local_id: previous scope variable
local function GlobalReadOffset(padding_num, offset, local_id, local_row_offset, local_col_offset)

    if not(local_row_offset) then
        local_row_offset = 0
    end

    if not(local_col_offset) then
        local_col_offset = 0
    end

    local code_block = {}

    -- group_id = (uint2)(get_group_id(0), get_group_id(1))
    local group_id = Util.create_variable('group_id', 'uint2')
    local group_id_value = "(uint2)(get_group_id(0), get_group_id(1))"
    table.insert(code_block, Sentence.CLAllocateVar(padding_num, group_id, group_id_value))

    -- element_id = (
    --     x_ = group_id.x * local_row + local_id.x + local_row_offset, 
    --     y_ = local_id.y + local_col_offset
    --    )

    local element_id = Util.create_variable('element_id', 'uint2')
    local element_id_value = {
                                x_ = {string.format("%s.x * %d + %s.x",
                                                group_id.name_,
                                                Info.kernel_info.local_row_,
                                                local_id.name_)
                                      },
                                y_ = {string.format("%s.y",
                                                    local_id.name_)
                                     }
                             }

    if local_row_offset > 0 then
        table.insert(element_id_value.x_, string.format(" + %d", local_row_offset))
    end

    if local_col_offset > 0 then
        table.insert(element_id_value.y_, string.format(" + %d", local_col_offset))
    end

    table.insert(code_block, Sentence.CLAllocateVar(padding_num, element_id, string.format("(uint2)(%s, %s)", 
                                                                                    table.concat(element_id_value.x_),
                                                                                    table.concat(element_id_value.y_)
                                                                                    )))
    
    -- offset = group_id.y * idist + (element_id.y * global_row + element_id.x) * instride
    local offset_value

    if Info.pass_info.instride_ > 1
    then
        offset_value = string.format("%s.y * %d + (%s.y * %d + %s.x) * %d",
                                        group_id.name_,
                                        Info.pass_info.idist_,
                                        element_id.name_,
                                        Info.kernel_info.global_row_,
                                        element_id.name_,
                                        Info.pass_info.instride_
                                    )
    else
        offset_value = string.format("%s.y * %d + (%s.y * %d + %s.x)",
                group_id.name_,
                Info.pass_info.idist_,
                element_id.name_,
                Info.kernel_info.global_row_,
                element_id.name_)
    end

    table.insert(code_block, Sentence.CLSetVar(padding_num, offset, offset_value))
    return Util.GetCodeBlock(padding_num,  code_block)
end

-- create code block move from mem to register
-- {
--     __private float2* lwIn = input + offset 
--     {
--         R0 = input[offset]
--         R1 = input[offset + stride]
--         R2 = input[offset + 2 * stride]
--         R3 = input[offset + 3 * stride]
--     }
--     {
--         .......
--     }
-- }

-- input: input address, offset: global read offset, var: global vars

local function GlobalInputToReg(padding_num, var_tables, input, offset)
    local code_block = {}
    local lwIn = Util.create_variable('lwIn', 'float2*')
    local lwIn_Value = string.format("input + %s", offset.name_)

    table.insert(code_block, Sentence.CLAllocateVar(padding_num, lwIn, lwIn_Value))

    local col_group_offset = 0

    for gid = 1, Info.micro_pass_info.col_group_num_ do
        local group_vars = {}
        local stride = (Info.pass_info.cur_ / Info.micro_pass_info.cur_ * Info.pass_info.ret_ * Info.pass_info.prev_)
        local stride_offset = (gid - 1) * (Info.micro_pass_info.col_group_stride_ * Info.pass_info.ret_ * Info.pass_info.prev_)

        for i = 1, Info.micro_pass_info.cur_ do
            table.insert(group_vars, var_tables[i + (gid - 1) * Info.micro_pass_info.cur_])
        end 
        
        local read_str = Sentence.CLRead(padding_num + 1, group_vars, lwIn, nil, stride, stride_offset)
        table.insert(code_block, Util.GetCodeBlock(padding_num + 1, {read_str}))
    end

    return Util.GetCodeBlock(padding_num, code_block)
end

-- create code block read from global mem
-- {
--    uint offset;
--    {cal offset}
--    {move from global mem to reg}
-- }

-- input: input address, offset: global read offset, var: global vars

function GlobalRead.CodeBlock():
    local code_block = {}
    local offset = Util.create_variable('offset', 'uint')
    table.insert(code_block, Sentence.CLAllocateVar(padding_num, offset))

    table.insert(code_block, ReadOffset(padding_num + 1, offset, local_id))

    table.insert(code_block, InputToReg(padding_num + 1, offset, var_tables))

    return Util.GetCodeBlock(padding_num, code_block)
end

