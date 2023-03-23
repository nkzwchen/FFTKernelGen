GlobalRead = require("FFTKernelGen.MicroPass.Read.GlobalRead")

local MicroPassRead = {}

function MicroPassRead.CodeBlock(padding_num, offset, input, local_id) 
    return GlobalRead.CodeBlock(padding_num, offset, input, local_id)
end

return MicroPassRead