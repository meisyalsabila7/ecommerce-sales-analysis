-- ============================================================
-- FILE: 01_cleaning.sql
-- Tujuan: Membersihkan data mentah e-commerce
-- Dataset: Olist Brazilian E-Commerce (Kaggle)
-- ============================================================


-- 1. CEK DUPLIKAT
-- Cek apakah ada order_id yang muncul lebih dari sekali
SELECT
    order_id,
    COUNT(*) AS jumlah
FROM olist_orders_dataset
GROUP BY order_id
HAVING COUNT(*) > 1;


-- 2. CEK NULL VALUES
-- Lihat kolom mana yang banyak null
SELECT
    COUNT(*) AS total_baris,
    COUNT(order_id) AS order_id_filled,
    COUNT(customer_id) AS customer_id_filled,
    COUNT(order_status) AS status_filled,
    COUNT(order_purchase_timestamp) AS tanggal_filled
FROM olist_orders_dataset;


-- 3. FILTER HANYA ORDER YANG DELIVERED
-- Hapus status cancelled, unavailable, dll
CREATE TABLE orders_clean AS
SELECT *
FROM olist_orders_dataset
WHERE order_status = 'delivered'
  AND order_delivered_customer_date IS NOT NULL;


-- 4. STANDARISASI FORMAT TANGGAL
-- Ekstrak tahun dan bulan dari timestamp
SELECT
    order_id,
    DATE(order_purchase_timestamp) AS tanggal_beli,
    EXTRACT(YEAR FROM order_purchase_timestamp) AS tahun,
    EXTRACT(MONTH FROM order_purchase_timestamp) AS bulan
FROM orders_clean;


-- 5. GABUNGKAN TABEL UTAMA (JOIN)
-- Buat tabel analisis master
CREATE TABLE master_orders AS
SELECT
    o.order_id,
    o.customer_id,
    DATE(o.order_purchase_timestamp) AS order_date,
    EXTRACT(YEAR FROM o.order_purchase_timestamp) AS tahun,
    EXTRACT(MONTH FROM o.order_purchase_timestamp) AS bulan,
    p.product_category_name AS kategori,
    oi.price AS harga_satuan,
    oi.freight_value AS ongkir,
    (oi.price + oi.freight_value) AS total_item,
    pay.payment_value AS total_bayar,
    pay.payment_type AS metode_bayar,
    c.customer_city AS kota,
    c.customer_state AS provinsi
FROM orders_clean o
LEFT JOIN olist_order_items_dataset oi ON o.order_id = oi.order_id
LEFT JOIN olist_products_dataset p ON oi.product_id = p.product_id
LEFT JOIN olist_order_payments_dataset pay ON o.order_id = pay.order_id
LEFT JOIN olist_customers_dataset c ON o.customer_id = c.customer_id
WHERE oi.price IS NOT NULL;


-- ============================================================
-- FILE: 02_eda.sql
-- Tujuan: Eksplorasi data untuk menemukan insight
-- ============================================================


-- 1. TOTAL REVENUE PER BULAN (Tren Bulanan)
SELECT
    tahun,
    bulan,
    ROUND(SUM(total_bayar), 2) AS total_revenue,
    COUNT(DISTINCT order_id) AS jumlah_transaksi,
    ROUND(AVG(total_bayar), 2) AS avg_order_value
FROM master_orders
GROUP BY tahun, bulan
ORDER BY tahun, bulan;


-- 2. REVENUE PER KATEGORI PRODUK
SELECT
    kategori,
    COUNT(DISTINCT order_id) AS jumlah_order,
    ROUND(SUM(total_bayar), 2) AS total_revenue,
    ROUND(AVG(total_bayar), 2) AS avg_order_value,
    ROUND(
        SUM(total_bayar) * 100.0 / SUM(SUM(total_bayar)) OVER (), 2
    ) AS persen_revenue
FROM master_orders
WHERE kategori IS NOT NULL
GROUP BY kategori
ORDER BY total_revenue DESC
LIMIT 10;


-- 3. PERBANDINGAN REVENUE YEAR-OVER-YEAR (YoY)
SELECT
    bulan,
    SUM(CASE WHEN tahun = 2017 THEN total_bayar ELSE 0 END) AS revenue_2017,
    SUM(CASE WHEN tahun = 2018 THEN total_bayar ELSE 0 END) AS revenue_2018,
    ROUND(
        (SUM(CASE WHEN tahun = 2018 THEN total_bayar ELSE 0 END) -
         SUM(CASE WHEN tahun = 2017 THEN total_bayar ELSE 0 END)) * 100.0 /
        NULLIF(SUM(CASE WHEN tahun = 2017 THEN total_bayar ELSE 0 END), 0),
    2) AS pertumbuhan_persen
FROM master_orders
GROUP BY bulan
ORDER BY bulan;


-- 4. ANALISIS METODE PEMBAYARAN
SELECT
    metode_bayar,
    COUNT(*) AS jumlah_transaksi,
    ROUND(SUM(total_bayar), 2) AS total_revenue,
    ROUND(AVG(total_bayar), 2) AS avg_nilai,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS persen_transaksi
FROM master_orders
GROUP BY metode_bayar
ORDER BY jumlah_transaksi DESC;


-- 5. TOP 10 KOTA BERDASARKAN REVENUE
SELECT
    kota,
    provinsi,
    COUNT(DISTINCT customer_id) AS jumlah_pelanggan,
    COUNT(DISTINCT order_id) AS jumlah_order,
    ROUND(SUM(total_bayar), 2) AS total_revenue
FROM master_orders
GROUP BY kota, provinsi
ORDER BY total_revenue DESC
LIMIT 10;


-- 6. DISTRIBUSI NILAI ORDER (untuk deteksi outlier)
SELECT
    MIN(total_bayar) AS nilai_minimum,
    PERCENTILE_CONT(0.25) WITHIN GROUP (ORDER BY total_bayar) AS q1,
    PERCENTILE_CONT(0.50) WITHIN GROUP (ORDER BY total_bayar) AS median,
    ROUND(AVG(total_bayar), 2) AS rata_rata,
    PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY total_bayar) AS q3,
    MAX(total_bayar) AS nilai_maksimum
FROM master_orders;


-- ============================================================
-- FILE: 03_rfm_analysis.sql
-- Tujuan: Segmentasi pelanggan menggunakan metode RFM
-- RFM = Recency, Frequency, Monetary
-- ============================================================


-- LANGKAH 1: Hitung nilai RFM per pelanggan
-- Tanggal referensi: hari setelah transaksi terakhir di dataset
WITH rfm_base AS (
    SELECT
        customer_id,
        -- Recency: berapa hari sejak transaksi terakhir
        DATE_PART('day',
            (SELECT MAX(order_date) FROM master_orders) + INTERVAL '1 day'
            - MAX(order_date)
        ) AS recency_hari,
        -- Frequency: berapa kali bertransaksi
        COUNT(DISTINCT order_id) AS frequency,
        -- Monetary: total nilai transaksi
        ROUND(SUM(total_bayar), 2) AS monetary
    FROM master_orders
    GROUP BY customer_id
),

-- LANGKAH 2: Beri skor 1-5 untuk masing-masing dimensi
rfm_scores AS (
    SELECT
        customer_id,
        recency_hari,
        frequency,
        monetary,
        -- Recency: semakin kecil hari = semakin baik (skor 5)
        NTILE(5) OVER (ORDER BY recency_hari DESC) AS r_score,
        -- Frequency: semakin sering = semakin baik (skor 5)
        NTILE(5) OVER (ORDER BY frequency ASC) AS f_score,
        -- Monetary: semakin besar = semakin baik (skor 5)
        NTILE(5) OVER (ORDER BY monetary ASC) AS m_score
    FROM rfm_base
),

-- LANGKAH 3: Gabungkan skor menjadi label segmen
rfm_segments AS (
    SELECT
        customer_id,
        recency_hari,
        frequency,
        monetary,
        r_score,
        f_score,
        m_score,
        CONCAT(r_score, f_score, m_score) AS rfm_code,
        CASE
            WHEN r_score >= 4 AND f_score >= 4 AND m_score >= 4 THEN 'Champions'
            WHEN r_score >= 3 AND f_score >= 3 THEN 'Loyal Customers'
            WHEN r_score >= 4 AND f_score <= 2 THEN 'New Customers'
            WHEN r_score >= 3 AND f_score <= 2 AND m_score >= 3 THEN 'Potential Loyalist'
            WHEN r_score <= 2 AND f_score >= 3 AND m_score >= 3 THEN 'At Risk'
            WHEN r_score <= 2 AND f_score >= 4 THEN 'Cant Lose Them'
            WHEN r_score <= 2 AND f_score <= 2 THEN 'Lost Customers'
            ELSE 'Others'
        END AS segmen
    FROM rfm_scores
)

-- LANGKAH 4: Ringkasan per segmen
SELECT
    segmen,
    COUNT(customer_id) AS jumlah_pelanggan,
    ROUND(AVG(recency_hari), 0) AS avg_hari_sejak_beli,
    ROUND(AVG(frequency), 1) AS avg_frekuensi,
    ROUND(AVG(monetary), 2) AS avg_nilai_transaksi,
    ROUND(SUM(monetary), 2) AS total_revenue_segmen
FROM rfm_segments
GROUP BY segmen
ORDER BY total_revenue_segmen DESC;


-- ============================================================
-- BONUS: Query untuk Tableau (export ke CSV)
-- Gunakan hasil query ini sebagai data source di Tableau
-- ============================================================

-- Export data bulanan untuk visualisasi tren
SELECT
    tahun,
    bulan,
    TO_CHAR(DATE_TRUNC('month', order_date), 'YYYY-MM') AS periode,
    kategori,
    kota,
    metode_bayar,
    COUNT(DISTINCT order_id) AS transaksi,
    COUNT(DISTINCT customer_id) AS pelanggan_unik,
    ROUND(SUM(total_bayar), 2) AS revenue,
    ROUND(AVG(total_bayar), 2) AS aov
FROM master_orders
GROUP BY tahun, bulan, periode, kategori, kota, metode_bayar
ORDER BY tahun, bulan;
