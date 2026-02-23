# Basys 3 UART to LED Controller with FIFO

## 專案簡介 (Project Description)
本專案基於 Xilinx Artix-7 (Basys 3 開發板)，實作了一個完整的 UART 序列通訊接收器與硬體解碼系統。使用者透過 PC 端的終端機軟體輸入字元，FPGA 端透過自定義的 UART RX 模組接收訊號，經過 FIFO IP 進行資料緩衝後，由主控邏輯將 ASCII 碼解碼並驅動對應的實體 LED。

本專案結合了純 RTL (Verilog) 硬體狀態機設計與 Vivado 內建 IP 的整合應用，是非常適合做為硬體加速器資料傳輸前置作業的基礎架構。

## 系統架構 (System Architecture)
整體資料流向：`PC 鍵盤` -> `USB (UART)` -> `Basys 3 (RX Pin B18)` -> `UART_RX` -> `FIFO` -> `LED_Controller` -> `LEDs`

* **Clocking Wizard (IP):** 接收板載 100MHz 時脈，輸出系統所需之穩定時脈。
* **UART_RX (RTL):** 具備 16 倍超取樣 (16x Oversampling) 的 UART 接收狀態機，Baud Rate 設定為 115200。
* **FIFO Generator (IP):** 作為資料緩衝區，吸收 UART 傳輸速率與後端解碼邏輯的速率差異，防止連續輸入時掉字。
* **LED_Controller (RTL):** 監聽 FIFO 狀態，讀出資料後進行 ASCII 解碼。
  * 輸入 `'A'` ~ `'P'`：分別單獨點亮 LED[0] ~ LED[15]。
  * 輸入其他字元：於 LED[7:0] 直接顯示該字元之 ASCII 碼二進位值。

## 開發環境 (Environment)
* **Hardware:** Digilent Basys 3 (Artix-7 `xc7a35tcpg236-1`)
* **Software:** Xilinx Vivado (Synthesis & Implementation)
* **Terminal:** PuTTY, Tera Term, 或 MobaXterm

## Vivado IP 配置清單 (IP Configurations)
若要重建此專案，請於 Vivado IP Catalog 中手動生成並配置以下 IP：

1. **Clocking Wizard (`clk_wiz_0`)**
   * Input Clock: `100 MHz`
   * Output Clock: `100 MHz` (或依需求調整，需與 RTL 參數匹配)
2. **FIFO Generator (`fifo_generator_0`)**
   * Interface Type: `Native`
   * Fifo Implementation: `Common Clock Block RAM` (同步 FIFO)
   * Read/Write Width: `8 bits`
   * Read/Write Depth: `64`

## 腳位約束 (Pin Constraints)
請在 XDC 檔案中加入以下主要腳位綁定 (LVCMOS33)：
* `clk_100m` : `W5` (100MHz Oscillator)
* `uart_rx`  : `B18` (USB-RS232 RX)
* `led[15:0]`: `U16`, `E19`, `U19`, `V19`, `W18`, `U15`, `U14`, `V14`, `V13`, `V3`, `W3`, `U3`, `P3`, `N3`, `P1`, `L1`

## 測試流程 (How to Test)
1. 透過 Vivado 生成 Bitstream (`.bit`) 並燒錄至 Basys 3 開發板。
2. 使用 MicroUSB 連接 Basys 3 與 PC。
3. 開啟終端機軟體，選擇對應的 COM Port。
4. 設定 Serial 參數：
   * Baud Rate: `115200`
   * Data bits: `8`
   * Stop bits: `1`
   * Parity: `None`
5. 於終端機內敲擊鍵盤，觀察板載 16 顆 LED 的變化。

## 開發者 (Developer)
黃偉哲 (Weijhe Huang)