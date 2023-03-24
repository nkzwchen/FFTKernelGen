local Variable = require("FFTKernelGen.Util.Variable")
local CodeBlock = require("FFTKernelGen.Util.CodeBlock")
local Statement = require("FFTKernelGen.Util.Statement")

local GlobalToRegMethod = {}

-- assign global memory offset value
-- {
--  group_id = (utin2)(get_group_id(0), get_group_id(1))

--  element_id = (
--                x_ = group_id.x * local_row + lid_dim2.x + local_row_offset, 
--                y_ = lid_dim2.y + local_col_offset
--               )

--  offset = group_id.y * idist + (element_id.y * global_row + element_id.x) * instride
-- }
function GlobalToRegMethod:AssignOffsetValue(indent_num, offset)
    local code_block = {}

    -- group_id = (uint2)(get_group_id(0), get_group_id(1))
    local group_id = Variable.CreateVariable('group_id', 'uint2')
    local group_id_value = "(uint2)(get_group_id(0), get_group_id(1))"
    table.insert(code_block, Statement.CLDefineVar(indent_num, group_id, group_id_value))

    -- element_id = (
    --     x_ = group_id.x * local_row + lid_dim2.x,
    --     y_ = lid_dim2.y
    --    )

    local element_id = Variable.CreateVariable('element_id', 'uint2')
    local element_id_value = {
                                x_ = {string.format("%s.x * %d + %s.x",
                                                group_id.name_,
                                                self.kernel_info_.local_row_,
                                                self.lid_dim2_.name_)
                                    },
                                y_ = {string.format("%s.y",
                                    self.lid_dim2_.name_)
                                    }
                            }

    table.insert(code_block, Statement.CLAssignValue(indent_num, element_id, string.format("(uint2)(%s, %s)", 
                                                                                    table.concat(element_id_value.x_),
                                                                                    table.concat(element_id_value.y_)
                                                                                    )))
    
    -- offset = group_id.y * idist + (element_id.y * global_row + element_id.x) * instride
    local offset_value

    if self.pass_info_.instride_ > 1
    then
        offset_value = string.format("%s.y * %d + (%s.y * %d + %s.x) * %d",
                                        group_id.name_,
                                        self.pass_info_.idist_,
                                        element_id.name_,
                                        self.kernel_info_.global_row_,
                                        element_id.name_,
                                        self.pass_info_.instride_
                                    )
    else
        offset_value = string.format("%s.y * %d + (%s.y * %d + %s.x)",
                group_id.name_,
                self.pass_info_.idist_,
                element_id.name_,
                self.kernel_info_.global_row_,
                element_id.name_)
    end

    table.insert(code_block, Statement.CLAssignValue(indent_num, offset, offset_value))
    return CodeBlock.GetCodeBlock(indent_num,  code_block)
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
function GlobalToRegMethod:MemToReg(indent_num, offset)
    local code_block = {}
    local lwIn = Variable.CreateVariable('lwIn', 'float2*')
    local lwIn_Value = string.format("%s + %s", self.src_.name_, offset.name_)

    table.insert(code_block, Statement.CLDefineVar(indent_num, lwIn, lwIn_Value))

    for gid = 1, self.micro_pass_info_.col_group_num_ do
        local group_vars = {}
        local stride = (self.pass_info_.cur_ / self.micro_pass_info_.cur_) * self.kernel_info_.global_row_
        local const_offset = (gid - 1) * (self.micro_pass_info_.col_group_stride_) * (self.kernel_info_.global_row_)

        for i = 1, self.micro_pass_info_.cur_ do
            table.insert(group_vars, self.dest_var_list_[i + (gid - 1) * self.micro_pass_info_.cur_])
        end 
        
        local read_str = Statement.CLRead(indent_num + 1, group_vars, lwIn, nil, stride, const_offset)
        table.insert(code_block, CodeBlock.GetCodeBlock(indent_num + 1, {read_str}))
    end

    return CodeBlock.GetCodeBlock(indent_num, code_block)
end

-- create code block read from global mem
-- {
--    uint offset;
--    {assign offset value}
--    {move from global mem to reg}
-- }
function GlobalToRegMethod:GenCodeBlock(indent_num)
    local code_block = {}
    local offset = Variable.CreateVariable('offset', 'uint')
    table.insert(code_block, Statement.CLDefineVar(indent_num, offset))

    table.insert(code_block, self:AssignOffsetValue(indent_num + 1, offset))

    table.insert(code_block, self:MemToReg(indent_num + 1, offset))

    return CodeBlock.GetCodeBlock(indent_num, code_block)
end

local function GlobalToReg(indent_num, pass_info, kernel_info, micro_pass_info,
                           dest_var_list, src, lid_dim2)

    local ret = {}
    ret.pass_info_ = pass_info
    ret.kernel_info_ = kernel_info
    ret.micro_pass_info_ = micro_pass_info
    ret.dest_var_list_ = dest_var_list 
    ret.src_ = src
    ret.lid_dim2_ = lid_dim2

    for k,v in pairs(GlobalToRegMethod) do
        ret[k] = v
    end

    return ret:GenCodeBlock(indent_num)

end

return GlobalToReg