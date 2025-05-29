module tb_calculate_vector;

    // Сигналы управления
    reg aclk, aresetn;
    reg s_axis_tdata, s_axis_tvalid, s_axis_tlast;
    wire s_axis_tready;
    
    // AXI Stream Master интерфейс для получения результата
    wire m_axis_tdata;
    wire m_axis_tvalid;
    reg  m_axis_tready;
    wire m_axis_tlast;
    
    // Массив для входной последовательности битов
    reg [0:0] bit_sequence [0:639];
    integer i;
    
    // Регистр для сбора результата
    reg [127:0] received_result;
    integer bit_count;

    // Экземпляр модуля calculate_vector
    calculate_vector dut (
        .aclk(aclk),
        .aresetn(aresetn),
        .s_axis_tdata(s_axis_tdata),
        .s_axis_tvalid(s_axis_tvalid),
        .s_axis_tready(s_axis_tready),
        .s_axis_tlast(s_axis_tlast),
        .m_axis_tdata(m_axis_tdata),
        .m_axis_tvalid(m_axis_tvalid),
        .m_axis_tready(m_axis_tready),
        .m_axis_tlast(m_axis_tlast)
    );

    // Генерация тактового сигнала
    initial begin
        aclk = 0;
       forever #5 aclk = ~aclk;  // Частота 100 МГц
    end

    // Логика тестбенча
    initial begin
        // Инициализация
        aresetn = 0;
        s_axis_tvalid = 0;
        s_axis_tlast = 0;
        m_axis_tready = 1;  // Всегда готов принимать данные
        bit_count = 0;
        received_result = 128'b0;
        #10 aresetn = 1;

        // Загрузка последовательности из файла
        $readmemb("sequence.txt", bit_sequence);

        // Отправка последовательности в модуль
        for (i = 0; i < 640; i = i + 1) begin
            @(posedge aclk);
            while (!s_axis_tready) begin
                @(posedge aclk);
            end
            s_axis_tdata = bit_sequence[i];
            s_axis_tvalid = 1;
            s_axis_tlast = (i == 639);
        end
        @(posedge aclk);
        s_axis_tvalid = 0;
        s_axis_tlast = 0;

   // Ожидание и сбор результата
bit_count = 0;  // Сбрасываем счетчик перед началом передачи
while (bit_count < 128) begin
    @(posedge aclk);
    if (m_axis_tvalid && m_axis_tready) begin
        received_result[bit_count] = m_axis_tdata;
        bit_count = bit_count + 1;  // Увеличиваем счетчик с первого бита
        if (m_axis_tlast && bit_count == 128) begin
            $display("Результат: %h", received_result);
        end
    end
end

        // Завершение симуляции
        $display("Симуляция завершена");
        $finish;
    end

endmodule