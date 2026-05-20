-- ============================================================
-- FILE: 02_eda.sql
-- Proyek: Analisis Performa Penjualan E-commerce
-- Dataset: Olist Brazilian E-Commerce (Kaggle)
-- Tools: PostgreSQL + pgAdmin
-- ============================================================


-- ============================================================
-- BAGIAN 1: EKSPLORASI AWAL
-- ============================================================

-- 1.1 Lihat isi tabel orders
SELECT * FROM orders LIMIT 10;


-- 1.2 Cek semua status pesanan
SELECT
    order_status,
    COUNT(*) AS jumlah
FROM orders
GROUP BY order_status
ORDER BY jumlah DESC;
-- Temuan: 96.478 dari 99.441 pesanan berstatus delivered (97%)


-- 1.3 Cek kategori produk terbanyak
SELECT
    product_category_name,
    COUNT(*) AS jumlah
FROM products
WHERE product_category_name IS NOT NULL
GROUP BY product_category_name
ORDER BY jumlah DESC
LIMIT 10;
-- Temuan: cama_mesa_banho (sprei/handuk) paling banyak produknya


-- 1.4 Cek kota pelanggan terbanyak
SELECT
    customer_city,
    COUNT(*) AS jumlah
FROM customers
GROUP BY customer_city
ORDER BY jumlah DESC
LIMIT 10;
-- Temuan: Sao Paulo dominasi dengan 15.540 pelanggan


-- ============================================================
-- BAGIAN 2: ANALISIS REVENUE PER KATEGORI
-- ============================================================

-- 2.1 Total revenue per kategori (JOIN 3 tabel)
SELECT
    p.product_category_name AS kategori,
    COUNT(DISTINCT o.order_id) AS jumlah_order,
    ROUND(SUM(oi.price)::numeric, 2) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
  AND p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY total_revenue DESC
LIMIT 10;
-- Temuan: beleza_saude revenue tertinggi (1,2 juta+)
-- meski jumlah produknya hanya peringkat 4


-- 2.2 Average Order Value (AOV) per kategori
SELECT
    p.product_category_name AS kategori,
    COUNT(DISTINCT o.order_id) AS jumlah_order,
    ROUND(SUM(oi.price)::numeric, 2) AS total_revenue,
    ROUND(AVG(oi.price)::numeric, 2) AS avg_harga_per_item
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
JOIN products p ON oi.product_id = p.product_id
WHERE o.order_status = 'delivered'
  AND p.product_category_name IS NOT NULL
GROUP BY p.product_category_name
ORDER BY avg_harga_per_item DESC
LIMIT 10;
-- Temuan: pcs (komputer) AOV tertinggi 1.098 tapi volume kecil (177 order)
-- relogios_presentes masuk top 10 AOV sekaligus top 10 revenue = kategori paling sehat


-- ============================================================
-- BAGIAN 3: ANALISIS TREN BULANAN
-- ============================================================

-- 3.1 Revenue per bulan
SELECT
    EXTRACT(YEAR FROM order_purchase_timestamp) AS tahun,
    EXTRACT(MONTH FROM order_purchase_timestamp) AS bulan,
    COUNT(DISTINCT o.order_id) AS jumlah_order,
    ROUND(SUM(oi.price)::numeric, 2) AS total_revenue
FROM orders o
JOIN order_items oi ON o.order_id = oi.order_id
WHERE o.order_status = 'delivered'
GROUP BY tahun, bulan
ORDER BY tahun, bulan;


-- 3.2 Pertumbuhan revenue bulan ke bulan (MoM Growth)
WITH revenue_bulanan AS (
    SELECT
        EXTRACT(YEAR FROM order_purchase_timestamp) AS tahun,
        EXTRACT(MONTH FROM order_purchase_timestamp) AS bulan,
        ROUND(SUM(oi.price)::numeric, 2) AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
    GROUP BY tahun, bulan
)
SELECT
    tahun,
    bulan,
    total_revenue,
    LAG(total_revenue) OVER (ORDER BY tahun, bulan) AS revenue_bulan_lalu,
    ROUND(
        (total_revenue - LAG(total_revenue) OVER (ORDER BY tahun, bulan))
        * 100.0 /
        NULLIF(LAG(total_revenue) OVER (ORDER BY tahun, bulan), 0)
    , 2) AS pertumbuhan_persen
FROM revenue_bulanan
ORDER BY tahun, bulan;
-- Temuan: November 2017 lonjakan 52% kemungkinan efek Black Friday / harbolnas
-- Desember 2017 turun 26% = pola klasik post-harbolnas
-- Tren 2017 ke 2018 naik konsisten = bisnis tumbuh sehat


-- 3.3 Perbandingan revenue per bulan 2017 vs 2018 (YoY)
SELECT
    bulan,
    ROUND(SUM(CASE WHEN tahun = 2017 THEN total_revenue ELSE 0 END)::numeric, 2) AS revenue_2017,
    ROUND(SUM(CASE WHEN tahun = 2018 THEN total_revenue ELSE 0 END)::numeric, 2) AS revenue_2018,
    ROUND(
        (SUM(CASE WHEN tahun = 2018 THEN total_revenue ELSE 0 END) -
         SUM(CASE WHEN tahun = 2017 THEN total_revenue ELSE 0 END)) * 100.0 /
        NULLIF(SUM(CASE WHEN tahun = 2017 THEN total_revenue ELSE 0 END), 0)
    , 2) AS pertumbuhan_yoy_persen
FROM (
    SELECT
        EXTRACT(YEAR FROM order_purchase_timestamp) AS tahun,
        EXTRACT(MONTH FROM order_purchase_timestamp) AS bulan,
        ROUND(SUM(oi.price)::numeric, 2) AS total_revenue
    FROM orders o
    JOIN order_items oi ON o.order_id = oi.order_id
    WHERE o.order_status = 'delivered'
      AND EXTRACT(YEAR FROM order_purchase_timestamp) IN (2017, 2018)
    GROUP BY tahun, bulan
) sub
GROUP BY bulan
ORDER BY bulan;
-- Temuan: bandingkan bulan yang sama antara 2017 dan 2018
-- untuk melihat pertumbuhan bisnis secara year-over-year


-- ============================================================
-- BAGIAN 4: RINGKASAN INSIGHT
-- ============================================================
-- 1. beleza_saude menang revenue karena volume tinggi (8.647 order)
-- 2. pcs harga tertinggi per item tapi volume kecil = potensi pasar belum maksimal
-- 3. relogios_presentes kombinasi volume + harga seimbang = kategori paling profitable
-- 4. 97% pesanan delivered = tingkat keberhasilan pengiriman sangat tinggi
-- 5. Sao Paulo dominasi pelanggan (15.540) = target market utama
-- 6. November 2017 lonjakan 52% = efek harbolnas / Black Friday
-- 7. Tren keseluruhan 2017-2018 positif = bisnis tumbuh sehat
