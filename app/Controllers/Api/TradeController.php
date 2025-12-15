<?php

namespace App\Controllers\Api;

use App\Controllers\ApiController;
use App\Models\PortfolioModel;
use App\Libraries\MarketService;
use App\Models\WalletModel;
use App\Models\TransaksiModel;

class TradeController extends ApiController
{
    // GET: Lihat Portfolio dengan Profit/Loss Realtime
    public function portfolio()
    {
        $userId = $this->request->user_id;
        $model = new PortfolioModel();
        $portfolios = $model->where('user_id', $userId)->findAll();

        $marketService = new MarketService();
        $enrichedData = [];
        $totalPortfolioValue = 0;

        foreach ($portfolios as $item) {
            // --- FIX START ---
            // 1. Ambil data pasar (ini mengembalikan Array)
            $marketData = $marketService->getPrice($item['symbol']);

            // 2. Ambil harga spesifik dari array
            $currentPrice = 0.0;
            if ($marketData && isset($marketData['price'])) {
                $currentPrice = (float) $marketData['price'];
            } else {
                // Fallback ke harga rata-rata jika gagal ambil data pasar (misal offline)
                $currentPrice = (float) $item['average_price'];
            }
            // --- FIX END ---

            $qty = (float) $item['quantity'];
            $avgPrice = (float) $item['average_price'];

            $currentValue = $qty * $currentPrice;
            $investmentValue = $qty * $avgPrice;

            $pnl = $currentValue - $investmentValue;

            // Hindari division by zero
            $pnlPercent = ($investmentValue > 0) ? ($pnl / $investmentValue) * 100 : 0;

            $totalPortfolioValue += $currentValue;

            $enrichedData[] = [
                'id' => $item['id'],
                'symbol' => $item['symbol'],
                'quantity' => $qty,
                'average_price' => $avgPrice,
                'current_price' => $currentPrice,
                'current_value' => $currentValue,
                'pnl' => $pnl,
                'pnl_percent' => round($pnlPercent, 2)
            ];
        }

        // Hitung Total Cash Balance dari Transaksi
        $cashBalance = $this->getUserCashBalance($userId);

        return $this->success([
            'cash_balance' => $cashBalance,
            'portfolio_value' => $totalPortfolioValue,
            'net_worth' => $cashBalance + $totalPortfolioValue,
            'holdings' => $enrichedData
        ]);
    }

    // POST: Beli Saham (Buy)
    public function buy()
    {
        $rules = [
            'symbol' => 'required',
            'quantity' => 'required|numeric|greater_than[0]',
            'wallet_id' => 'required|numeric'
        ];
        if (!$this->validate($rules))
            return $this->error($this->validator->getErrors());

        $symbol = strtoupper($this->request->getVar('symbol'));
        $qty = (float) $this->request->getVar('quantity');
        $walletId = $this->request->getVar('wallet_id');
        $userId = $this->request->user_id;

        // 1. Validasi Wallet Milik User
        $walletModel = new WalletModel();
        $wallet = $walletModel->where('id', $walletId)->where('user_id', $userId)->first();
        if (!$wallet) {
            return $this->error("Wallet tidak ditemukan atau bukan milik Anda.");
        }

        // 2. Hitung Saldo Wallet (Dynamic Calculation)
        $currentBalance = $this->getWalletBalance($userId, $walletId);

        // 3. Ambil Harga Pasar
        $marketService = new MarketService();

        try {
            $marketData = $marketService->getPrice($symbol);
        } catch (\Exception $e) {
            // Jika koneksi ke API saham gagal, return error JSON bersih (bukan HTML crash)
            return $this->error("Gagal koneksi ke data pasar: " . $e->getMessage());
        }

        // Validasi apakah data ada dan memiliki key 'price'
        if (!$marketData || !isset($marketData['price'])) {
            return $this->error("Gagal mengambil harga pasar untuk simbol: $symbol (Data Kosong)", 400);
        }

        // Extract nilai float dari array
        $currentPrice = (float) $marketData['price'];
        // --- FIX END ---

        $totalCost = $currentPrice * $qty;

        if ($currentBalance < $totalCost) {
            return $this->error("Saldo Wallet tidak cukup. Butuh: " . number_format($totalCost, 0) . ", Ada: " . number_format($currentBalance, 0));
        }

        $portfolioModel = new PortfolioModel();
        $trxModel = new TransaksiModel();

        $db = \Config\Database::connect();
        $db->transStart();

        try {
            // A. Catat Transaksi Pengeluaran (Investasi)
            $trxModel->insert([
                'user_id' => $userId,
                'wallet_id' => $walletId,
                'category_id' => null,
                'amount' => $totalCost,
                'type' => 'Pengeluaran',
                'title' => "Beli Saham $symbol",
                'deskripsi' => "Investasi $symbol x $qty lembar @ $currentPrice",
                'date' => date('Y-m-d H:i:s')
            ]);

            // B. Update Portfolio (Average Down)
            $existing = $portfolioModel->where('user_id', $userId)->where('symbol', $symbol)->first();

            if ($existing) {
                $oldQty = (float) $existing['quantity'];
                $oldAvg = (float) $existing['average_price'];

                $newTotalQty = $oldQty + $qty;
                // Rumus Average Price baru
                $newAvgPrice = (($oldQty * $oldAvg) + ($qty * $currentPrice)) / $newTotalQty;

                $portfolioModel->update($existing['id'], [
                    'quantity' => $newTotalQty,
                    'average_price' => $newAvgPrice
                ]);
            } else {
                $portfolioModel->insert([
                    'user_id' => $userId,
                    'symbol' => $symbol,
                    'quantity' => $qty,
                    'average_price' => $currentPrice
                ]);
            }

            $db->transComplete();

            return $this->success([
                'symbol' => $symbol,
                'quantity_bought' => $qty,
                'price' => $currentPrice,
                'total_cost' => $totalCost,
                'wallet_remaining_balance' => $currentBalance - $totalCost
            ], "Berhasil membeli $symbol");

        } catch (\Exception $e) {
            $db->transRollback();
            return $this->error($e->getMessage(), 500);
        }
    }

    // POST: Jual Saham (Sell)
    public function sell()
    {
        // 1. Validasi
        $rules = [
            'symbol' => 'required',
            'quantity' => 'required|numeric|greater_than[0]',
            'wallet_id' => 'required|numeric'
        ];
        if (!$this->validate($rules))
            return $this->error($this->validator->getErrors());

        $symbol = strtoupper($this->request->getVar('symbol'));
        $qtyToSell = (float) $this->request->getVar('quantity');
        $walletId = $this->request->getVar('wallet_id');
        $userId = $this->request->user_id;

        // Validasi Wallet
        $walletModel = new WalletModel();
        $wallet = $walletModel->where('id', $walletId)->where('user_id', $userId)->first();
        if (!$wallet) {
            return $this->error("Wallet tidak ditemukan.");
        }

        // 2. Cek apakah User punya asetnya
        $portfolioModel = new PortfolioModel();
        $existing = $portfolioModel->where('user_id', $userId)->where('symbol', $symbol)->first();

        if (!$existing) {
            return $this->error("Anda tidak memiliki aset $symbol");
        }

        $currentQty = (float) $existing['quantity'];
        if ($currentQty < $qtyToSell) {
            return $this->error("Jumlah aset tidak cukup. Punya: $currentQty, Ingin Jual: $qtyToSell");
        }

        // 3. Cek Harga Pasar
        $marketService = new MarketService();

        // --- FIX START ---
        $marketData = $marketService->getPrice($symbol);

        if (!$marketData || !isset($marketData['price'])) {
            return $this->error("Gagal mengambil harga pasar saat ini. Transaksi dibatalkan.");
        }

        // Extract harga
        $currentPrice = (float) $marketData['price'];
        // --- FIX END ---

        // 4. Hitung Penerimaan (Revenue)
        $totalRevenue = $currentPrice * $qtyToSell;

        $trxModel = new TransaksiModel();
        $db = \Config\Database::connect();
        $db->transStart();

        try {
            // A. Catat Transaksi Pemasukan
            $trxModel->insert([
                'user_id' => $userId,
                'wallet_id' => $walletId,
                'category_id' => null,
                'amount' => $totalRevenue,
                'type' => 'Pemasukan',
                'title' => "Jual Saham $symbol",
                'deskripsi' => "Jual $symbol x $qtyToSell lembar @ $currentPrice",
                'date' => date('Y-m-d H:i:s')
            ]);

            // B. Update Portfolio
            $remainingQty = $currentQty - $qtyToSell;

            if ($remainingQty <= 0) {
                // Jika habis, hapus baris dari tabel
                $portfolioModel->delete($existing['id']);
            } else {
                // Jika masih ada sisa, update quantity saja
                $portfolioModel->update($existing['id'], [
                    'quantity' => $remainingQty
                ]);
            }

            $db->transComplete();

            return $this->success([
                'symbol' => $symbol,
                'quantity_sold' => $qtyToSell,
                'price_at_sell' => $currentPrice,
                'total_revenue' => $totalRevenue,
            ], "Berhasil menjual $symbol");

        } catch (\Exception $e) {
            $db->transRollback();
            return $this->error($e->getMessage(), 500);
        }
    }

    public function getPrice()
    {
        $symbol = strtoupper($this->request->getVar('symbol'));

        if (!$symbol) {
            return $this->error("Parameter 'symbol' wajib diisi", 400);
        }

        $marketService = new MarketService();
        $data = $marketService->getPrice($symbol);

        if (!$data) {
            return $this->error("Gagal mengambil harga untuk $symbol", 404);
        }

        // --- FIX: Return structured data correctly ---
        return $this->success([
            'symbol' => $symbol,
            'price' => $data['price'], // Kirim harga spesifik
            'change_percent' => $data['changePercent'] ?? 0,
            'timestamp' => date('Y-m-d H:i:s')
        ]);
    }

    public function getMarketStocks()
    {
        $symbols = [
            'BBCA.JK',
            'TLKM.JK',
            'BBRI.JK',
            'BMRI.JK',
            'ASII.JK',
            'GOTO.JK',
            'BTC-USD',
            'ETH-USD'
        ];

        $marketService = new MarketService();
        $stockData = [];

        foreach ($symbols as $symbol) {
            $data = $marketService->getPrice($symbol);

            // Pastikan data valid sebelum akses array key
            if ($data && isset($data['price'])) {
                $stockData[] = [
                    'symbol' => $symbol,
                    'name' => $this->getCompanyName($symbol),
                    'price' => $data['price'],
                    'timestamp' => date('Y-m-d H:i:s'),
                    'price_formatted' => number_format($data['price'], 0),
                    'change_percent' => $data['changePercent'],
                    'change_percent_formatted' => number_format($data['changePercent'], 2) . '%',
                    // Tambahkan flag is_up untuk UI Flutter (hijau/merah)
                    'is_up' => $data['changePercent'] >= 0
                ];
            }
        }

        return $this->success($stockData);
    }

    // Helper sederhana untuk nama perusahaan
    private function getCompanyName($symbol)
    {
        $names = [
            'BBCA.JK' => 'Bank Central Asia',
            'TLKM.JK' => 'Telkom Indonesia',
            'BBRI.JK' => 'Bank Rakyat Indonesia',
            'BMRI.JK' => 'Bank Mandiri',
            'ASII.JK' => 'Astra International',
            'GOTO.JK' => 'GoTo Gojek Tokopedia',
            'BTC-USD' => 'Bitcoin',
            'ETH-USD' => 'Ethereum'
        ];
        return $names[$symbol] ?? $symbol;
    }

    // Helper: Hitung Total Cash User (Sum Semua Wallet)
    private function getUserCashBalance($userId)
    {
        $trxModel = new TransaksiModel();

        // Sum Income
        $pemasukan = $trxModel
            ->where('user_id', $userId)
            ->groupStart()
            ->where('type', 'Pemasukan')
            ->orWhere('type', 'INCOME')
            ->groupEnd()
            ->selectSum('amount')->get()->getRow()->amount ?? 0;

        // Sum Expense
        $pengeluaran = $trxModel
            ->where('user_id', $userId)
            ->groupStart()
            ->where('type', 'Pengeluaran')
            ->orWhere('type', 'EXPENSE')
            ->orWhere('type', 'Penarikan')
            ->groupEnd()
            ->selectSum('amount')->get()->getRow()->amount ?? 0;

        return $pemasukan - $pengeluaran;
    }

    // Private Helper: Calculate Wallet Balance Dynamically
    private function getWalletBalance($userId, $walletId)
    {
        $trxModel = new TransaksiModel();

        // Sum Income
        $pemasukan = $trxModel
            ->where('user_id', $userId)
            ->where('wallet_id', $walletId)
            ->groupStart()
            ->where('type', 'Pemasukan')
            ->orWhere('type', 'INCOME')
            ->groupEnd()
            ->selectSum('amount')->get()->getRow()->amount ?? 0;

        // Sum Expense
        $pengeluaran = $trxModel
            ->where('user_id', $userId)
            ->where('wallet_id', $walletId)
            ->groupStart()
            ->where('type', 'Pengeluaran')
            ->orWhere('type', 'EXPENSE')
            ->orWhere('type', 'Penarikan')
            ->groupEnd()
            ->selectSum('amount')->get()->getRow()->amount ?? 0;

        return $pemasukan - $pengeluaran;
    }
}