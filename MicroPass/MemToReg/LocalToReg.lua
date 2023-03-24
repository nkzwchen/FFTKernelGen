local Variable = require("FFTKernelGen.Util.Variable")
local CodeBlock = require("FFTKernelGen.Util.CodeBlock")
local Statement = require("FFTKernelGen.Util.Statement")

local LocalToRegMethod = {}

-- create code block move from mem to register
-- {
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
function LocalToRegMethod:MemToReg(indent_num, offset)
    local code_block = {}
    for gid = 1, self.micro_pass_info_.col_group_num_ do
        local group_vars = {}
        local stride = (self.pass_info_.cur_ / self.micro_pass_info_.cur_) * self.micro_pass_info_.local_read_mem_row_
        local const_offset = (gid - 1) * (self.micro_pass_info_.col_group_stride_) * (self.micro_pass_info_.local_read_mem_row_)

        for i = 1, self.micro_pass_info_.cur_ do
            table.insert(group_vars, self.dest_var_list_[i + (gid - 1) * self.micro_pass_info_.cur_])
        end 
        
        local read_str = Statement.CLRead(indent_num + 1, group_vars, self.src_, nil, stride, const_offset)
        table.insert(code_block, CodeBlock.GetCodeBlock(indent_num + 1, {read_str}))
    end

    return CodeBlock.GetCodeBlock(indent_num, code_block)
end

-- create code block read from global mem
-- {
--    uint offset = (lid_dim2.y * local_mem_row + lid_dim2.x + local_row_offset);
--    {move from local mem to reg}
-- }

function LocalToRegMethod:GenCodeBlock(indent_num)
    local code_block = {}

--   uint offset = (lid_dim2.y * local_mem_row + lid_dim2.x + local_row_offset);
    local offset = Variable.CreateVariable('offset', 'uint')
    local offset_value = {string.format("%s.y * %d + %s.x", self.lid_dim2_.name_, self.micro_pass_info_.local_read_mem_row_, self.lid_dim2_.name_)}
    if self.micro_pass_info_.row_offset_ ~= 0 then
        table.insert(offset_value, string.format(" + %d", self.micro_pass_info_.row_offset_))
    end

    table.insert(code_block, Statement.CLDefineVar(indent_num, offset, table.concat(offset_value)))

--  {move from local mem to reg}
    table.insert(code_block, self:MemToReg(indent_num + 1, offset))
    table.insert(code_block, Statement.CLBarrier(indent_num))

    return CodeBlock.GetCodeBlock(indent_num, code_block)
end

local function LocalToReg(indent_num, pass_info, kernel_info, micro_pass_info,
                           dest_var_list, src, lid_dim2)

    local ret = {}
    ret.pass_info_ = pass_info
    ret.kernel_info_ = kernel_info
    ret.micro_pass_info_ = micro_pass_info
    ret.dest_var_list_ = dest_var_list
    ret.src_ = src
    ret.lid_dim2_ = lid_dim2

    for k,v in pairs(LocalToRegMethod) do
        ret[k] = v
    end
    return ret:GenCodeBlock(indent_num)

end

return LocalToReg