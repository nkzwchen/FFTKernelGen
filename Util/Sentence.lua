local Sentence = {}

local function CLPadding(padding_num)
    return string.rep("    ", padding_num)
end

function Sentence.CLAllocateVar(padding_num, var, value)
    local str = {CLPadding(padding_num)}
    table.insert(str, string.format("__%s %s %s", var.mem_type_, var.data_type_, var.name_))

    if value then
        table.insert(str, string.format(" = (%s);\n", value))
    else
        table.insert(str, ";\n")
    end

    return table.concat(str)
end

function Sentence.CLAllocateMultiVar(padding_num, var_tables, data_type, mem_type)
    local str = {CLPadding(padding_num)}

    if not(mem_type) then
        mem_type = "private"
    end

    table.insert(str, string.format("__%s %s ", mem_type, data_type))

    local var_str = {}
    for idx, var in pairs(var_tables) do
        assert(var.mem_type_ == mem_type, string.format("CLAllocatMultiVar %s mem type %s should be %s", var.name_, var.mem_type_, mem_type))
        assert(var.data_type_ == data_type, string.format("CLAllocatMultiVar %s data type %s should be %s", var.name_, var.data_type_, data_type))
        table.insert(var_str, var.name_)
    end
    table.insert(str, table.concat(var_str, ", "))
    table.insert(str, ";\n")

    return table.concat(str)
end

function Sentence.CLSetVar(padding_num, var, value)
    local str = {CLPadding(padding_num)}
    table.insert(str, string.format("%s = (%s);\n", var.name_, value))
    return table.concat(str)
end

function Sentence.CLRead(padding_num, var_table, src, offset, stride, stride_offset)
    local sentence_table = {}
    for idx, var in pairs(var_table) do
        table.insert(sentence_table, CLPadding(padding_num))
        table.insert(sentence_table, string.format("%s = %s[", var.name_, src.name_))
        if src_offset then
            table.insert(sentence_table, string.format("%s + ", offset.name_))
        end

        table.insert(
            sentence_table, 
            string.format(
                "%d];\n", (idx - 1) * stride + stride_offset)
            )
    end
    return table.concat(sentence_table)
end

return Sentence
-- function AddCLWriteSentence(var_table, offset, dest, stride)
--     local sentence_table = {}
--     for idx, var in pairs(var_table) do
--         table.insert(
--             sentence_table, 
--             string.format(
--                 "%s[%s + %d] = ;", dest.name_, offset.name_, (idx - 1) * stride, var.name_)
--             )
--     end
--     return table.concat(sentence_table, '\n', 0, -1)
-- end

-- function AddCLTwiddleSentence(var_table, tw1, tw2, tmp, tmp_tw)
--     local sentence_table = {}
--     for idx, var in pairs(var_table) do
--         table.insert(
--         sentence_table, 
--         AddTwiddleFactorMultiplySentence(var, tw1, tmp)
--         )
--         if idx == #var_table then
--             break
--         end
--         table.insert(
--             sentence_table, 
--             AddComplexMulitplySentence(tw1, tw2, tmp_tw)
--         )      
--     end 
--     return table.concat(sentence_table, '\n')
-- end

-- function AddCLComplexMulitplySentence(dest, mul, tmp)
--     return string.format("{ComplexMultiply(%s, %s ,%s)}", dest.name_, mul.name_, tmp.name_)
-- end

-- function AddCLTwiddleFactorMultiplySentence(var, twiddle_factor, tmp)
--     return string.format("{DirectionComplexMultiply(%s, %s, %s)}", var, twiddle_factor, tmp)
-- end 

-- function AddCLBasicDFTSentence(length, param_table)
--     local param = {}
--     for idx, var in param_table:
--         table.insert(
--             param,
--             var.name_
--         )
--     end
--     return string.format("{BasicDFT%d(%s)}", length, table.concat(param, ", "))  
-- end

-- function AddCLBarrierSentence()
--     return "barrier(CLK_LOCAL_MEM_FENCE);"
-- end

-- -- function AddReadCodeBlock():
-- -- end
-- -- // <cur, ret, prev>
-- -- // function block
-- -- __kernel __attribute__((always_inline))
-- -- void MicroPass1(uint2 lid, __local real* dest, __local real* src){
-- --     // init varible
-- --     // 使用 dict 表示 <name, type>
-- --     // <name, type> 
-- --     // -------> floatn, uintn array
-- --     // mid initer(lid_name) 
-- --     __private real R0, R1, R2, R3;
-- --     add_init_variable_sentence((UINT2, 'mid'), initer('lid', 'lid.y / 4, lid.y & 3'))
-- --     string.format("(lid.y / (%d)), (lid.y & (%d))", a, b)
-- --     __private uint2 mid = (uint2)(lid.y / 4, lid.y & 3);
    
-- --     // Code block (READ)
-- --     {
        
-- --         // lid initer
-- --         __private uint offset = lid.y * WGS0 + lid.x;
        
-- --         add_read_operation_sentence(['R0', 'R1', 'R2', 'R3'], 'offset', 64 * WGS0);
-- --         // L2L block R0, R1, R2, R3, offset block
-- --         {
-- --             R0 = src[offset];
-- --             R1 = src[offset + 64 * WGS0];
-- --             R2 = src[offset + 128 * WGS0];
-- --             R3 = src[offset + 192 * WGS0];
-- --         }
-- --     }
    
-- --     // Code block (LOCAL FFT) 
-- --    {   
-- --        // init data
-- --        __private real tmp;
-- --        // LOCAL FFT_BLOCK
-- --        add_local_fft_sentence(['R0', 'R1', 'R2', 'R3'], 'tmp');
-- --        {FORWARD_FFT4(R0, R1, R2, R3, tmp)}
-- --    }
   
-- --    // Code block
-- --    {
-- --       // local twiddle (mid, offset, Rarray)
-- --       {
-- --           __private real tmp;
-- --           __private float2 tmp_tw;
-- --           __private float2 tw1 = local_twiddle_buffer_[64 + mid.x];                
-- --           __private float2 tw2 = tw1;
-- --           {FORWARD_TWIDDLE(R1, tw1, tmp)}
-- --           {UPDATE_TW(tw1, tw2, tmp_tw)}
-- --           {FORWARD_TWIDDLE(R2, tw1, tmp)}
-- --           {UPDATE_TW(tw1, tw2, tmp_tw)}
-- --           {FORWARD_TWIDDLE(R3, tw1, tmp)}
-- --       }
-- --    }
   
-- --    // code block
-- --    {   
-- --       // mid initer
-- --       // write
-- --       {
-- --           __private uint offset = (mid.x * 16 + mid.y) * WGS0 + lid.x;
-- --           dest[offset] = R0;
-- --           dest[offset + 4 * WGS0] = R1;
-- --           dest[offset + 8 * WGS0] = R2;
-- --           dest[offset + 12 * WGS0] = R3;
-- --        }
-- --    }
-- -- }
