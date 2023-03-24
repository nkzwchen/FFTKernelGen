local Variable = require("FFTKernelGen.Util.Variable")
local CodeBlock = require("FFTKernelGen.Util.CodeBlock")
local Statement = require("FFTKernelGen.Util.Statement")

local RegToLocalMethod = {}

-- assign local memory offset value
-- {
--  element_id = (
--                x_ = lid_dim2.x + row_offset, 
--                y_ = mid.y * cur * prev + mid.x
--               )

--  offset = (element_id.y * local_mem_write_row + element_id.x)
-- }

function RegToLocalMethod:AssignOffsetValue(indent_num, offset)
    local code_block = {}

--  element_id = (
--                x_ = lid_dim2.x + local_row_offset, 
--                y_ = mid.y * cur * prev + mid.x
--               )

    local element_id = Variable.CreateVariable('element_id', 'uint2')
    local element_id_value = {
                                x_= {string.format("%s.x", self.lid_dim2_.name_)},
                                y_ = {string.format("%s.y * %d + %s.x", self.mid_.name_, self.micro_pass_info_.cur_ * self.micro_pass_info_ .prev_, self.mid_.name_)}
                             }
    
    if self.micro_pass_info_.row_offset_ > 0 then
        table.insert(element_id_value.x_, string.format("+ %d", self.micro_pass_info_.row_offset_))
    end

    table.insert(code_block, Statement.CLAssignValue(indent_num, element_id, string.format("(uint2)(%s, %s)", 
                                                                                    table.concat(element_id_value.x_),
                                                                                    table.concat(element_id_value.y_)
                                                                                    )))
    
    -- offset = (element_id.y * local_mem_write_row + element_id.x)

    local offset_value = string.format("%s.y * %d +  %s.x",
                                        element_id.name_,
                                        self.micro_pass_info_.local_write_mem_row_,
                                        element_id.name_
                                    )


    table.insert(code_block, Statement.CLAssignValue(indent_num, offset, offset_value))
    return CodeBlock.GetCodeBlock(indent_num,  code_block)
end

-- create code block move from register to mem
-- {
--     __private float2* lwIn = input + offset 
--     stride = (gid - 1) * col_group_stride * write_mem_row
--     {
--         const_offset = (gid - 1) * col_group_stride * write_mem_row
--         input[offset + const_offset] = R0 
--         input[offset + const_offset + stride] = R1
--         input[offset + const_offset + 2 * stride] = R2
--         input[offset + const_offset + 3 * stride] = R3
--     }
--     {
--         .......
--     }
-- }

function RegToLocalMethod:MemToReg(indent_num, offset)
    local code_block = {}

    for gid = 1, self.micro_pass_info_.col_group_num_ do
        local group_vars = {}
        local stride = (self.micro_pass_info_.prev_) * self.micro_pass_info_.local_write_mem_row_
        local const_offset = (gid - 1) * (self.micro_pass_info_.col_group_stride_) * (self.micro_pass_info_.local_write_mem_row_)

        for i = 1, self.micro_pass_info_.cur_ do
            table.insert(group_vars, self.src_var_list_[i + (gid - 1) * self.micro_pass_info_.cur_])
        end

        local write_str = Statement.CLWrite(indent_num + 1, group_vars, self.dest_, offset, stride, const_offset)

        table.insert(code_block, CodeBlock.GetCodeBlock(indent_num + 1, {write_str}))
    end

    return CodeBlock.GetCodeBlock(indent_num, code_block)
end

-- create code block read from global mem
-- {
--    uint offset;
--    {assign offset value}
--    {move from global mem to reg}
-- }
function RegToLocalMethod:GenCodeBlock(indent_num)
    local code_block = {}
    local offset = Variable.CreateVariable('offset', 'uint')
    table.insert(code_block, Statement.CLDefineVar(indent_num, offset))

    table.insert(code_block, self:AssignOffsetValue(indent_num + 1, offset))

    table.insert(code_block, self:MemToReg(indent_num + 1, offset))

    return CodeBlock.GetCodeBlock(indent_num, code_block)
end

local function RegToLocal(indent_num, pass_info, kernel_info, micro_pass_info,
                          dest, src_var_list, lid_dim2, mid)

    local ret = {}
    ret.pass_info_ = pass_info
    ret.kernel_info_ = kernel_info
    ret.micro_pass_info_ = micro_pass_info
    ret.src_var_list_ = src_var_list 
    ret.dest_ = dest
    ret.lid_dim2_ = lid_dim2
    ret.mid_ = mid

    for k,v in pairs(RegToLocalMethod) do
        ret[k] = v
    end

    return ret:GenCodeBlock(indent_num)

end

return RegToLocal