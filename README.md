# portfolio-optimization
Sử dụng R để tối ưu hóa danh mục cổ phiếu PVD, VCB, VIC, VIX 
# Tối ưu hóa danh mục cổ phiếu: PVD, VCB, VIC, VIX
## 1. Mục tiêu đề tài

Xây dựng và tối ưu hóa danh mục đầu tư từ 4 mã cổ phiếu **PVD, VCB, VIC, VIX** trên thị trường chứng khoán Việt Nam, dựa trên dữ liệu giá đóng cửa lịch sử từ **10/11/2022 đến 10/11/2025**, áp dụng lý thuyết danh mục hiện đại (Markowitz Portfolio Theory) kết hợp mô phỏng Monte Carlo và phân tích rủi ro VaR/CVaR.

## 2. Dữ liệu

- **Nguồn:** Giá đóng cửa lịch sử 4 mã cổ phiếu, định dạng Excel (`.xlsx`)
- **Khoảng thời gian:** 10/11/2022 – 10/11/2025 (748 quan sát)
- **Biến số:** `Thoi_gian`, `PVD`, `VCB`, `VIC`, `VIX`

## 3. Phương pháp thực hiện

1. **Xử lý dữ liệu chuỗi thời gian:** chuyển data frame thành đối tượng `xts`
2. **Tính tỷ suất sinh lợi:** lợi nhuận log-return = ln(giá hôm nay / giá hôm qua)
3. **Ma trận hiệp phương sai:** đo lường rủi ro và mối tương quan giữa các mã
4. **Mô phỏng Monte Carlo:** 10.000 kịch bản lợi nhuận dựa trên phân phối chuẩn đa biến (`MASS::mvrnorm`)
5. **Bài toán tối ưu:**
   - *Nghiệm nguyên:* chọn đúng 2/4 mã có phương sai danh mục thấp nhất (tỷ trọng 50%-50%)
   - *Đa mục tiêu (Markowitz):* tối đa hóa lợi nhuận – tối thiểu hóa rủi ro trên cả 4 mã, ràng buộc full-investment & long-only, tìm đường biên hiệu quả bằng `PortfolioAnalytics` (`optimize.portfolio`, phương pháp random 5000 danh mục)
6. **Phân tích rủi ro:** tính VaR và CVaR (Expected Shortfall) ở mức tin cậy 95% cho danh mục được chọn

## 4. Kết quả chính

### 4.1. Bài toán nghiệm nguyên (chọn đúng 2 mã)

Tính phương sai danh mục cho toàn bộ 6 tổ hợp 2 mã (tỷ trọng 50-50), sắp xếp theo rủi ro tăng dần:

| Tổ hợp | Phương sai |
|---|---|
| **VCB - VIC** | **0.0002668442** |
| PVD - VCB | 0.0002797138 |
| PVD - VIC | 0.0003084112 |
| VCB - VIX | 0.0004216901 |
| VIC - VIX | 0.0004570803 |
| PVD - VIX | 0.0005220128 |

→ **Tổ hợp tối ưu: VCB - VIC**, có phương sai danh mục thấp nhất trong 6 tổ hợp.

### 4.2. Bài toán đa mục tiêu (Markowitz, cả 4 mã)

Chạy mô phỏng 5.000 danh mục ngẫu nhiên tuân thủ ràng buộc full-investment và long-only, tìm điểm cân bằng tốt nhất giữa rủi ro (StdDev) và lợi nhuận (mean):

| Mã | Trọng số tối ưu |
|---|---|
| PVD | 24.0% |
| VCB | 34.6% |
| VIC | 37.0% |
| VIX | 4.40% |

- **Rủi ro hàng ngày (StdDev):** 0.01483 (~1.48%)
- **Lợi nhuận kỳ vọng hàng ngày (mean):** 0.000876  (~0.0876%)

→ Danh mục tối ưu tập trung phần lớn vào **VCB và VIC** ( 71.6% vốn), cho thấy đây là hai thành phần đóng góp hiệu quả nhất vào cân bằng rủi ro – lợi nhuận.

### 4.3. Phân tích rủi ro (VaR & CVaR)

Để minh họa cách đo lường rủi ro thực tế,**tự chọn (gán)** một tỷ trọng danh mục cụ thể — không phải kết quả tối ưu hóa từ các bước trên, mà là ví dụ áp dụng công thức VaR/CVaR: **50% PVD – 50% VIC**, vốn đầu tư giả định 100 triệu VNĐ, mức tin cậy 95%:

- **VaR (1 ngày):** 2.795.293 VNĐ — có 5% khả năng mất ít nhất số tiền này trong 1 ngày
- **CVaR/ES (1 ngày):** 3.515.997 VNĐ — mức lỗ trung bình dự kiến trong 5% kịch bản xấu nhất

## 5. Yêu cầu cài đặt (R packages)

```r
install.packages(c("readxl", "xts", "PerformanceAnalytics",
                    "MASS", "PortfolioAnalytics", "dplyr"))
```

## 6. Cách chạy

```r
# Mở portfolio_optimization.R trong RStudio, chỉnh lại đường dẫn file dữ liệu
data <- read_excel("data/PVD_VCB_VIC_VIX.xlsx")

# Chạy toàn bộ script từ đầu đến cuối
```

## 7. Lý thuyết áp dụng

Đề tài dựa trên khung lý thuyết **Modern Portfolio Theory** của Harry Markowitz (1952): nhà đầu tư ác cảm rủi ro tìm cách tối đa hóa lợi nhuận với mức rủi ro cho trước, hoặc tối thiểu hóa rủi ro với mức lợi nhuận mục tiêu — tập hợp các danh mục tối ưu này tạo thành **đường biên hiệu quả (Efficient Frontier)**.
