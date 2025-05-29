module bit_receiver (
    input wire aclk,
    input wire aresetn,
    
    // AXI Stream Slave интерфейс для загрузки последовательности
    input wire s_axis_tdata,      // 1 бит данных
    input wire s_axis_tvalid,     // Данные валидны
    output reg s_axis_tready,     // Готовность принимать
    input wire s_axis_tlast,      // Последний бит
    
    // AXI Stream Master интерфейс для передачи последовательности
    output reg m_axis_tdata,      // 1 бит данных
    output reg m_axis_tvalid,     // Данные валидны
    input wire m_axis_tready,     // Приёмник готов
    output reg m_axis_tlast,      // Последний бит
    
    // Выход для значения счетчика (опционально)
    output reg [31:0] bit_count_out  // Значение счетчика переданных битов
);

    reg [31:0] bit_counter;  // Внутренний регистр счетчика

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axis_tready <= 1;   // Готов принимать данные после сброса
            m_axis_tvalid <= 0;   // Выходные данные не валидны
            m_axis_tdata <= 0;    // Сбрасываем данные
            m_axis_tlast <= 0;    // Сбрасываем флаг последнего бита
            bit_counter <= 0;     // Сбрасываем счетчик
            bit_count_out <= 0;   // Сбрасываем выходной порт счетчика
        end else begin
            // Связываем вход и выход напрямую
            s_axis_tready <= m_axis_tready;  // Готовность принимать зависит от приёмника
            if (s_axis_tvalid && m_axis_tready) begin
                m_axis_tdata <= s_axis_tdata;    // Передаём данные сразу
                m_axis_tvalid <= s_axis_tvalid;  // Валидность выходных данных
                m_axis_tlast <= s_axis_tlast;    // Передаём флаг последнего бита
                bit_counter <= bit_counter + 1;  // Увеличиваем счетчик при передаче бита
                bit_count_out <= bit_counter + 1; // Обновляем выходной порт (текущее значение +1)
            end else begin
                m_axis_tvalid <= 0;  // Если приёмник не готов, данные не валидны
            end
        end
    end
endmodule