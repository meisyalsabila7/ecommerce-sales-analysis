# Analisis Performa Penjualan E-commerce

> Proyek analisis data untuk mengidentifikasi tren penjualan, perilaku pelanggan, dan peluang pertumbuhan pada platform e-commerce.

---

## Latar Belakang & Pernyataan Masalah

Perusahaan e-commerce menghadapi tantangan dalam memahami faktor-faktor yang mempengaruhi konversi dan retensi pelanggan. Proyek ini bertujuan menjawab pertanyaan bisnis berikut:

1. Kategori produk mana yang memberikan revenue terbesar?
2. Di tahap mana pelanggan paling banyak drop-off dalam funnel pembelian?
3. Apa pola pembelian pelanggan berdasarkan segmentasi RFM?
4. Bagaimana tren revenue bulanan dibandingkan tahun sebelumnya?

---

## Struktur Proyek

```
ecommerce-sales-analysis/
│
├── data/
│   ├── raw/                  # Data mentah (tidak dimodifikasi)
│   └── processed/            # Data setelah dibersihkan
│
├── sql/
│   ├── 01_cleaning.sql       # Script pembersihan data
│   ├── 02_eda.sql            # Query eksplorasi data
│   └── 03_rfm_analysis.sql   # Query segmentasi RFM
│
├── dashboard/
│   └── ecommerce_dashboard.twbx  # File Tableau dashboard
│
├── reports/
│   └── insight_summary.pdf   # Ringkasan temuan & rekomendasi
│
└── README.md
```

---

## Dataset

| Keterangan | Detail |
|---|---|
| Sumber | [Kaggle - Brazilian E-Commerce Public Dataset (Olist)](https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce) |
| Ukuran | ~100.000 transaksi |
| Periode | 2016 – 2018 |
| Lisensi | CC BY-NC-SA 4.0 |

**Tabel utama yang digunakan:**
- `olist_orders_dataset` — data pesanan
- `olist_order_items_dataset` — detail item per pesanan
- `olist_customers_dataset` — data pelanggan
- `olist_products_dataset` — data produk
- `olist_order_payments_dataset` — data pembayaran

---

## Tools & Teknologi

| Tool | Kegunaan |
|---|---|
| SQL (PostgreSQL) | Pembersihan data, EDA, segmentasi RFM |
| Tableau Public | Dashboard interaktif & visualisasi |
| Excel | Validasi data & pivot analisis awal |

---

## Metodologi

### 1. Pembersihan Data (SQL)
- Menghapus baris duplikat
- Menangani nilai null pada kolom kritis
- Menstandarkan format tanggal dan nama kategori
- Menggabungkan tabel menggunakan JOIN

### 2. Eksplorasi Data (EDA)
- Analisis distribusi revenue per kategori
- Tren penjualan bulanan (MoM & YoY)
- Analisis funnel konversi
- Identifikasi outlier pada nilai transaksi

### 3. Segmentasi Pelanggan (RFM Analysis)
- **Recency** — Kapan terakhir pelanggan bertransaksi?
- **Frequency** — Seberapa sering pelanggan bertransaksi?
- **Monetary** — Berapa total nilai transaksi pelanggan?

### 4. Visualisasi (Tableau)
- Dashboard interaktif dengan filter kategori, wilayah, dan periode
- Funnel chart konversi
- Tren revenue YoY
- Peta distribusi pelanggan

---

## Temuan Utama

| # | Temuan | Dampak |
|---|---|---|
| 1 | Kategori Fashion mendominasi 38% total revenue | Tinggi |
| 2 | Drop-off terbesar terjadi antara Tambah Keranjang → Checkout (42% → 28%) | Tinggi |
| 3 | AOV meningkat 6% setelah fitur rekomendasi produk diperbarui | Sedang |
| 4 | Churn meningkat 3%, mayoritas dari segmen one-time buyer | Tinggi |

---

## Rekomendasi Bisnis

1. **Program loyalitas** — Buat tier reward untuk mengkonversi one-time buyer menjadi repeat buyer
2. **Optimasi checkout** — Sederhanakan form & tambah opsi QRIS dan COD untuk mengurangi drop-off
3. **Iklan Q4 di Elektronik** — Kategori ini memiliki AOV tertinggi, cocok untuk campaign akhir tahun
4. **Re-engagement campaign** — Kirim email/notifikasi untuk pelanggan yang tidak transaksi >60 hari

---

## Dashboard Preview

> *Lihat dashboard interaktif di [Tableau Public](https://public.tableau.com/views/EcommerceSalesAnalysis_17790812171360/DashboardPenjualanE-commerce?:language=en-US&:sid=&:redirect=auth&:display_count=n&:origin=viz_share_link)*

---

## Cara Menjalankan

1. Clone repository ini
   ```bash
   git clone https://github.com/username/ecommerce-sales-analysis.git
   ```

2. Download dataset dari Kaggle dan letakkan di folder `data/raw/`

3. Jalankan SQL script secara berurutan:
   ```
   01_cleaning.sql → 02_eda.sql → 03_rfm_analysis.sql
   ```

4. Buka file `dashboard/ecommerce_dashboard.twbx` di Tableau Desktop atau Tableau Public

---

## Tentang Saya

**Meisya Salsabila I.P.** 

- 📧 meisyasalsa7@gmail.com
- 💼 [LinkedIn](https://www.linkedin.com/in/meisyasalsabila/)

---
