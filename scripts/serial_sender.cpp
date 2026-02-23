#include <iostream>
#include <windows.h>
#include <random>
#include <thread>
#include <chrono>

int main() {
    // 1. 開啟 COM3 
    const char* portName = "\\\\.\\COM3";
    HANDLE hSerial = CreateFile(
        portName,
        GENERIC_READ | GENERIC_WRITE,
        0,
        0,
        OPEN_EXISTING,
        FILE_ATTRIBUTE_NORMAL,
        0
    );

    if (hSerial == INVALID_HANDLE_VALUE) {
        if (GetLastError() == ERROR_FILE_NOT_FOUND) {
            std::cerr << "錯誤: 找不到 " << portName << " (請確認開發板是否已連接且 Port 正確)" << std::endl;
        } else {
            std::cerr << "錯誤: 無法開啟 " << portName << std::endl;
        }
        return 1;
    }

    // 2. 設定 Serial Port 參數 (Baud Rate: 115200, Data bits: 8, Parity: None, Stop bits: 1)
    DCB dcbSerialParams = {0};
    dcbSerialParams.DCBlength = sizeof(dcbSerialParams);

    if (!GetCommState(hSerial, &dcbSerialParams)) {
        std::cerr << "錯誤: 無法取得 COM Port 狀態" << std::endl;
        CloseHandle(hSerial);
        return 1;
    }

    dcbSerialParams.BaudRate = CBR_115200;
    dcbSerialParams.ByteSize = 8;
    dcbSerialParams.StopBits = ONESTOPBIT;
    dcbSerialParams.Parity   = NOPARITY;

    if (!SetCommState(hSerial, &dcbSerialParams)) {
        std::cerr << "錯誤: 無法設定 COM Port 參數" << std::endl;
        CloseHandle(hSerial);
        return 1;
    }

    // 3. 設定 Timeout
    COMMTIMEOUTS timeouts = {0};
    timeouts.ReadIntervalTimeout         = 50;
    timeouts.ReadTotalTimeoutConstant    = 50;
    timeouts.ReadTotalTimeoutMultiplier  = 10;
    timeouts.WriteTotalTimeoutConstant   = 50;
    timeouts.WriteTotalTimeoutMultiplier = 10;
    SetCommTimeouts(hSerial, &timeouts);

    std::cout << "成功連接到 COM3 (115200, 8, N, 1)。" << std::endl;
    std::cout << "開始不斷傳輸隨機的 8-bit 資料 (按 Ctrl+C 終止程式)..." << std::endl;

    // 設定隨機數生成器 (產生 0-255 的隨機 byte)
    std::random_device rd;  
    std::mt19937 gen(rd()); 
    std::uniform_int_distribution<> distrib(0, 255);

    // 4. 無窮迴圈不斷傳送亂數
    while (true) {
        unsigned char randomByte = static_cast<unsigned char>(distrib(gen));
        
        DWORD bytesWritten;
        if (!WriteFile(hSerial, &randomByte, 1, &bytesWritten, NULL)) {
            std::cerr << "錯誤: 寫入 COM Port 失敗!" << std::endl;
            break;
        } else if (bytesWritten == 1) {
            // 在終端機印出目前傳送的資料
            std::cout << "傳送資料: 0x" << std::hex << (int)randomByte 
                      << std::dec << " (" << (int)randomByte << ")" << std::endl;
        }

        // 稍微延遲一下以免傳輸太快把終端機洗頻或把 FIFO 塞爆 (根據需求可調整或移除)
        Sleep(100);
    }

    // 5. 關閉控制代碼
    CloseHandle(hSerial);
    return 0;
}
