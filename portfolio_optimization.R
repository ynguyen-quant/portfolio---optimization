install.packages("PerformanceAnalytics")
library(readxl)
library(xts)
library(PerformanceAnalytics)
library(MASS)
library(PortfolioAnalytics)
library(readxl)

data <- read_excel("C:/data.xlsx")
head(data)

prices_xts <- xts(data[, -1], order.by = as.Date(data$Thoi_gian))
prices_xts

#Biểu đồ thể hiện giá đóng cửa của 4 mã theo chuỗi thời gian:
plot(prices_xts, main = "Giá đóng cửa lịch sử 4 mã chứng khoán", col = c("black", "red", "blue", "green"),legend.loc = "topleft")

#Công thức tính tỷ suất lợi nhuận = ln(Giá hôm nay/Giá hôm qua)
returns_daily <- Return.calculate(prices_xts, method = "log")
returns_daily

#Làm sạch dữ liệu bằng cách xóa dòng NA (trống) đầu tiên:
returns_daily_clean <- na.omit(returns_daily)
returns_daily_clean

#Hiệp phương sai (các phần tử còn lại) đo lường xu hướng mà hai cổ phiếu di
chuyển cùng nhau.
cov_matrix <- cov(returns_daily_clean)
cov_matrix

#Mô phỏng Monte Carlo (dựa trên dữ liệu thật)
loi_nhuan_trung_binh <- colMeans(returns_daily_clean)
so_lan_mo_phong <- 10000
n <- ncol(returns_daily_clean)
loi_nhuan_mo_phong <- MASS::mvrnorm(n = so_lan_mo_phong,
                                    mu = loi_nhuan_trung_binh,
                                    Sigma = cov_matrix)
head(loi_nhuan_mo_phong)
cov(loi_nhuan_mo_phong)
cov_matrix

#1. Bài toán tối ưu, nghiệm nguyên

#Tạo tất cả tổ hợp 2 mã cổ phiếu
symbols <- colnames(returns_daily_clean)
combos <- combn(symbols, 2, simplify = FALSE)

#Tính rủi ro (phương sai danh mục) cho từng tổ hợp
risks <- sapply(combos, function(combo) 
  {w <- rep(1/2, 2) # 50%-50%
  cov_sub <- cov_matrix[combo, combo]
  var_portfolio <- t(w) %*% cov_sub %*% w
  return(as.numeric(var_portfolio))})
  
#Tìm tổ hợp rủi ro nhỏ nhất
results <- data.frame(
  To_hop = sapply(combos, paste, collapse = " - "),
  Phuong_sai = risks)
results <- results[order(results$Phuong_sai), ]
results

#Hiển thị kết quả tối ưu
best_combo <- results[1, ]
cat("Tổ hợp 2 mã tối ưu là:", best_combo$To_hop,
    "với phương sai =", round(best_combo$Phuong_sai, 8), "\n")

#2. Bài toán tối ưu, đa mục tiêu

install.packages("PortfolioAnalytics")
library(PortfolioAnalytics)

# Lấy tên các tài sản từ dữ liệu
asset_names <- colnames(returns_daily_clean)

# Khởi tạo thông số
pspec <- portfolio.spec(assets = asset_names)

# Thêm các ràng buộc 

# Ràng buộc 1: Tổng trọng số = 1 (Đầu tư toàn bộ)
pspec <- add.constraint(portfolio = pspec, type = "full_investment")
# Ràng buộc 2: Không bán khống (Trọng số >= 0)
pspec <- add.constraint(portfolio = pspec, type = "long_only")

# Thêm các mục tiêu

#Mục tiêu 1: Tối thiểu hóa rủi ro (Standard Deviation)
pspec <- add.objective(portfolio = pspec, type = "risk", name = "StdDev")

# Mục tiêu 2: Tối đa hóa lợi nhuận 
pspec <- add.objective(portfolio = pspec, type = "return", name = "mean")
                          
# Chạy mô phỏng để vẽ đường biên hiệu quả
 ef_random <- optimize.portfolio(R = returns_daily_clean,
                                    portfolio = pspec,
                                    optimize_method = "random",
                                    search_size = 5000,
                                    trace = TRUE)
ef_random

#3. Phân tích rủi ro danh mục 50% PVD - 50% VIC

library(PerformanceAnalytics)
library(xts)
ten_cp<- c("PVD", "VCB", "VIC", "VIX")
trong_so_danh_muc <- c(0.50, 0.0, 0.50, 0.0)
names(trong_so_danh_muc) <- ten_cp
loi_nhuan_danh_muc_mo_phong <- loi_nhuan_mo_phong %*% trong_so_danh_muc
loi_nhuan_danh_muc_xts <- xts(loi_nhuan_danh_muc_mo_phong, order.by = Sys.Date() + 1:10000)
VON_DAU_TU <- 100000000 # Giả sử vốn đầu tư là 100 triệu VNĐ
DO_TIN_CAY <- 0.95 # Mức tin cậy 95%

# a. Tính Value-at-Risk (VaR)
var_percent <- VaR(loi_nhuan_danh_muc_xts, p = DO_TIN_CAY, method = "historical")

# b. Tính Conditional VaR (CVaR)/ Expected Shortfall (ES)
cvar_percent <- ES(loi_nhuan_danh_muc_xts, p = DO_TIN_CAY, method = "historical")
var_tien <- -1 * var_percent * VON_DAU_TU
cvar_tien <- -1 * cvar_percent * VON_DAU_TU
var_tien
var_percent
cvar_tien
cvar_percent