module calculate_vector (
    input wire aclk,              // Тактовый сигнал
    input wire aresetn,           // Сброс (активен низкий)
    
    // AXI Stream Slave интерфейс для входных данных
    input wire s_axis_tdata,      // Входной бит (1 бит)
    input wire s_axis_tvalid,     // Данные валидны
    output wire s_axis_tready,    // Готовность принимать данные
    input wire s_axis_tlast,      // Последний бит в последовательности
    
    // AXI Stream Master интерфейс для выходных данных
    output wire m_axis_tdata,     // Выходной бит (1 бит)
    output wire m_axis_tvalid,    // Данные валидны
    input wire m_axis_tready,     // Приемник готов
    output wire m_axis_tlast      // Последний бит результата
);

// Внутренние сигналы для связи с bit_receiver
wire br_m_axis_tdata;    // Выходной бит от bit_receiver
wire br_m_axis_tvalid;   // Валидность данных от bit_receiver
wire br_m_axis_tlast;    // Последний бит от bit_receiver
reg  int_m_axis_tready;  // Готовность принимать данные от bit_receiver

// Внутренние сигналы для связи с shift_register_processor
wire en = br_m_axis_tvalid; // Сигнал разрешения
wire [127:0] out_row;       // Текущая строка матрицы
wire valid;                 // Валидность строки

// Регистры для вычислений
reg [127:0] acc;       // Аккумулятор для операции XOR
reg [127:0] result;    // Регистр результата
reg [6:0] bit_index;   // Счетчик битов для передачи (0-127)
reg state;             // Текущее состояние машины состояний

// Определение состояний
localparam RECEIVING = 1'b0;    // Прием входных битов
localparam TRANSMITTING = 1'b1; // Передача результата

// Инстанцирование модуля bit_receiver
bit_receiver bit_rx (
    .aclk(aclk),
    .aresetn(aresetn),
    .s_axis_tdata(s_axis_tdata),
    .s_axis_tvalid(s_axis_tvalid),
    .s_axis_tready(s_axis_tready),
    .s_axis_tlast(s_axis_tlast),
    .m_axis_tdata(br_m_axis_tdata),
    .m_axis_tvalid(br_m_axis_tvalid),
    .m_axis_tready(int_m_axis_tready),
    .m_axis_tlast(br_m_axis_tlast)
);

// Инстанцирование shift_register_processor
shift_register_processor shift_reg_proc (
    .clk(aclk),
    .rst(~aresetn),
    .en(en),
    .out_row(out_row),
    .valid(valid)
);

// Управление выходным интерфейсом m_axis
assign m_axis_tdata = (state == RECEIVING) ? br_m_axis_tdata : result[bit_index];
assign m_axis_tvalid = (state == RECEIVING) ? br_m_axis_tvalid : 1'b1;
assign m_axis_tlast = (state == RECEIVING) ? br_m_axis_tlast : (bit_index == 127);

// Логика обработки и передачи
always @(posedge aclk or negedge aresetn) begin
    if (!aresetn) begin
        state <= RECEIVING;
        int_m_axis_tready <= 1'b1;
        bit_index <= 0;
        acc <= 128'b0;
        result <= 128'b0;
    end else begin
        case (state)
     RECEIVING: begin
    int_m_axis_tready <= 1'b1;
    if (br_m_axis_tvalid && int_m_axis_tready) begin
        if (br_m_axis_tdata) begin
            acc <= acc ^ out_row;
        end
        if (br_m_axis_tlast) begin
            result <= br_m_axis_tdata ? (acc ^ out_row) : acc;
            acc <= 128'b0;
            state <= TRANSMITTING;
            int_m_axis_tready <= 1'b0; // Немедленно отключить готовность
        end
    end
end
            TRANSMITTING: begin
                int_m_axis_tready <= 0; // Приостановить прием новых битов
                if (m_axis_tvalid && m_axis_tready) begin
                    if (bit_index < 127) begin
                        bit_index <= bit_index + 1; // Передача следующего бита
                    end else begin
                        state <= RECEIVING; // Все биты переданы, возврат к приему
                    end
                end
            end
        endcase
    end
end

endmodule