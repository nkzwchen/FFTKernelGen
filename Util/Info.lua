-- global variable
local Info = {}

Info.pass_info = {}
Info.kernel_info = {}
Info.micro_pass_info = {}

-- pass info
Info.pass_info.cur_ = 256
Info.pass_info.prev_ = 64
Info.pass_info.ret_ = 1
Info.pass_info.batch_ = 64
Info.pass_info.fft_length_ = 16384
Info.pass_info.instride_ = 1
Info.pass_info.outstride_ = 1
Info.pass_info.idist_ = 16384
Info.pass_info.odist_ = 16384
Info.pass_info.direction_ = 'forward'

-- kernel info
Info.kernel_info.global_work_size = {4096, Info.pass_info.batch_}
Info.kernel_info.local_work_size = {512, 1}

Info.kernel_info.global_row_ = Info.pass_info.ret_ * Info.pass_info.prev_
Info.kernel_info.local_row_ = 8

Info.kernel_info.global_col_ = Info.pass_info.cur_

-- micro kernel info
Info.micro_pass_info.cur_ = 4
Info.micro_pass_info.prev_ = 1
Info.micro_pass_info.ret_ = 64

Info.micro_pass_info.input_type_ = 'local'
Info.micro_pass_info.element_per_thread_ = 8

Info.micro_pass_info.row_offset_ = 0
Info.micro_pass_info.local_read_mem_row_ = Info.kernel_info.local_row_
Info.micro_pass_info.local_write_mem_row_ = Info.kernel_info.local_row_
Info.micro_pass_info.row_len_ = Info.kernel_info.local_row_ 

Info.micro_pass_info.col_group_num_ =  Info.micro_pass_info.element_per_thread_ / Info.micro_pass_info.cur_
Info.micro_pass_info.col_group_stride_ = Info.pass_info.cur_ / Info.micro_pass_info.element_per_thread_

return Info

